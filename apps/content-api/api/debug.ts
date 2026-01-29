import type { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Debug endpoint to check environment variables
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {

  const envCheck = {
    hasSupabaseUrl: !!process.env.SUPABASE_URL,
    hasSupabaseKey: !!process.env.SUPABASE_SERVICE_KEY,
    hasGeminiKey: !!process.env.GEMINI_API_KEY,
    hasTtsCredentials: !!process.env.GOOGLE_CLOUD_TTS_CREDENTIALS,
    hasApiSecret: !!process.env.API_SECRET,
    hasCronSecret: !!process.env.CRON_SECRET,
    hasDebug: !!process.env.DEBUG,
    supabaseUrlLength: process.env.SUPABASE_URL?.length || 0,
    supabaseKeyLength: process.env.SUPABASE_SERVICE_KEY?.length || 0,
    allEnvKeys: Object.keys(process.env).filter(k =>
      k.includes('SUPABASE') ||
      k.includes('GEMINI') ||
      k.includes('GOOGLE') ||
      k.includes('API') ||
      k.includes('CRON')
    ).sort(),
    totalEnvVars: Object.keys(process.env).length,
  };

  res.status(200).json(envCheck);
}
