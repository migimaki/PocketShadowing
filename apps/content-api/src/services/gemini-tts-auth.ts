/**
 * OAuth2 Authentication for Gemini-TTS API
 * Handles Google Cloud service account authentication and token management
 */

import { Logger } from '../utils/logger';

const logger = new Logger('GeminiTTSAuth');

interface ServiceAccountCredentials {
  client_email: string;
  private_key: string;
  project_id?: string;
}

interface TokenCache {
  accessToken: string;
  expiresAt: number; // Unix timestamp in milliseconds
}

let tokenCache: TokenCache | null = null;

/**
 * Parse service account credentials from environment variable
 */
export function parseServiceAccountCredentials(): ServiceAccountCredentials {
  const credentials = process.env.GOOGLE_CLOUD_TTS_CREDENTIALS;

  if (!credentials) {
    throw new Error('GOOGLE_CLOUD_TTS_CREDENTIALS environment variable is not set');
  }

  try {
    const credentialsObj = JSON.parse(credentials);

    if (!credentialsObj.client_email || !credentialsObj.private_key) {
      throw new Error('Invalid credentials: missing client_email or private_key');
    }

    return credentialsObj;
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error('Invalid GOOGLE_CLOUD_TTS_CREDENTIALS JSON format');
    }
    throw error;
  }
}

/**
 * Generate JWT token for Google OAuth2 authentication
 */
async function generateJWT(credentials: ServiceAccountCredentials): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: 'RS256',
    typ: 'JWT'
  };

  const claimSet = {
    iss: credentials.client_email,
    scope: 'https://www.googleapis.com/auth/cloud-platform',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600, // 1 hour expiration
    iat: now
  };

  // Encode header and claim set
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const signatureInput = `${encodedHeader}.${encodedClaimSet}`;

  // Sign with private key
  const signature = await signWithPrivateKey(signatureInput, credentials.private_key);
  const encodedSignature = base64UrlEncode(signature);

  return `${signatureInput}.${encodedSignature}`;
}

/**
 * Base64 URL-safe encoding
 */
function base64UrlEncode(data: string | Buffer): string {
  const base64 = Buffer.from(data).toString('base64');
  return base64
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * Sign data with RSA private key
 */
async function signWithPrivateKey(data: string, privateKey: string): Promise<Buffer> {
  // Import crypto module for signing
  const crypto = await import('crypto');

  const sign = crypto.createSign('RSA-SHA256');
  sign.update(data);
  sign.end();

  return sign.sign(privateKey);
}

/**
 * Exchange JWT for OAuth2 access token
 */
async function exchangeJwtForAccessToken(jwt: string): Promise<{ accessToken: string; expiresIn: number }> {
  const tokenEndpoint = 'https://oauth2.googleapis.com/token';

  const response = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to exchange JWT for access token: ${response.status} ${errorText}`);
  }

  const data = await response.json() as {
    access_token: string;
    expires_in: number;
  };

  return {
    accessToken: data.access_token,
    expiresIn: data.expires_in, // Typically 3600 seconds (1 hour)
  };
}

/**
 * Generate a new OAuth2 access token
 */
async function generateAccessToken(): Promise<{ accessToken: string; expiresAt: number }> {
  logger.info('Generating new OAuth2 access token...');

  const credentials = parseServiceAccountCredentials();
  const jwt = await generateJWT(credentials);
  const { accessToken, expiresIn } = await exchangeJwtForAccessToken(jwt);

  // Calculate expiration time (subtract 5 minutes for safety margin)
  const expiresAt = Date.now() + (expiresIn - 300) * 1000;

  logger.info('Successfully generated OAuth2 access token', {
    expiresIn: `${expiresIn}s`,
    expiresAt: new Date(expiresAt).toISOString(),
  });

  return { accessToken, expiresAt };
}

/**
 * Get cached OAuth2 access token or generate a new one
 * Tokens are cached for their validity period (typically 1 hour)
 */
export async function getCachedToken(): Promise<string> {
  const now = Date.now();

  // Check if we have a valid cached token
  if (tokenCache && tokenCache.expiresAt > now) {
    logger.debug('Using cached OAuth2 token', {
      expiresIn: `${Math.floor((tokenCache.expiresAt - now) / 1000)}s`,
    });
    return tokenCache.accessToken;
  }

  // Generate new token
  logger.info('Token expired or not cached, generating new token...');
  const { accessToken, expiresAt } = await generateAccessToken();

  // Cache the token
  tokenCache = { accessToken, expiresAt };

  return accessToken;
}

/**
 * Clear the token cache (useful for testing or forcing token refresh)
 */
export function clearTokenCache(): void {
  logger.debug('Clearing token cache');
  tokenCache = null;
}
