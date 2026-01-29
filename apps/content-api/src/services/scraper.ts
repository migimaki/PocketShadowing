import axios from 'axios';
import * as cheerio from 'cheerio';
import type { NewsArticle } from '../types/index';
import { Logger } from '../utils/logger';

const logger = new Logger('Scraper');

/**
 * Scrapes the latest news article from Euronews
 */
export async function scrapeLatestNews(): Promise<NewsArticle> {
  try {
    logger.info('Fetching latest news from Euronews...');

    // Fetch the Euronews homepage
    const response = await axios.get('https://www.euronews.com/', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      timeout: 10000,
    });

    const $ = cheerio.load(response.data);

    // Find the first main article link
    // Euronews typically has articles in specific sections
    let articleUrl = '';
    let title = '';

    // Look for actual article links (not category pages)
    // Article URLs typically have dates or longer slugs like: /2024/10/31/article-title
    $('a[href*="/news/"]').each((_, element) => {
      const href = $(element).attr('href');
      if (href && !articleUrl) {
        const fullUrl = href.startsWith('http') ? href : `https://www.euronews.com${href}`;

        // Filter out category pages - articles have longer paths with multiple segments
        const pathSegments = href.split('/').filter(s => s.length > 0);

        // Valid article URLs have at least 4 segments: news, category, date/year, title
        // Or at minimum 3 segments with a longer title
        const isArticle = pathSegments.length >= 4 ||
                         (pathSegments.length >= 3 && href.split('/').pop()!.length > 20);

        if (isArticle) {
          articleUrl = fullUrl;
          title = $(element).text().trim() ||
                  $(element).find('h1, h2, h3, h4').first().text().trim() ||
                  $(element).attr('title') ||
                  'Latest News';

          logger.debug('Found article candidate', { url: articleUrl, pathSegments: pathSegments.length });
          return false; // break the loop
        }
      }
      return true; // continue the loop
    });

    if (!articleUrl) {
      throw new Error('Could not find any article URL on Euronews homepage');
    }

    logger.info('Found article URL', { url: articleUrl, title });

    // Fetch the article page
    const articleResponse = await axios.get(articleUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      timeout: 10000,
    });

    const $article = cheerio.load(articleResponse.data);

    // Extract article title if not already found
    if (!title || title === 'Latest News') {
      title = $article('h1').first().text().trim() ||
              $article('meta[property="og:title"]').attr('content') ||
              'Latest News';
    }

    // Extract article content
    // Try multiple selectors for different news site structures
    const contentSelectors = [
      'article p',
      '.article__content p',
      '.c-article-content p',
      '[class*="article"] p',
      '[class*="Article"] p',
      '[class*="story"] p',
      '[class*="content"] p',
      'main p',
      'p',
    ];

    let paragraphs: string[] = [];
    for (const selector of contentSelectors) {
      const elements = $article(selector);
      logger.debug(`Trying selector: ${selector}, found ${elements.length} elements`);

      if (elements.length > 0) {
        elements.each((_, element) => {
          const text = $article(element).text().trim();
          // Filter out short paragraphs, navigation, ads, etc.
          if (text && text.length > 50 && !text.includes('cookie') && !text.includes('Subscribe')) {
            paragraphs.push(text);
          }
        });
        if (paragraphs.length >= 3) {
          logger.debug(`Found sufficient content with selector: ${selector}`);
          break; // Found enough content
        }
      }
    }

    if (paragraphs.length === 0) {
      throw new Error('Could not extract article content');
    }

    const content = paragraphs.join('\n\n');

    logger.info('Successfully scraped article', {
      title,
      contentLength: content.length,
      paragraphCount: paragraphs.length,
    });

    return {
      title,
      content,
      url: articleUrl,
      publishedDate: new Date(),
    };

  } catch (error) {
    logger.error('Error scraping Euronews', error);
    throw new Error(`Failed to scrape news: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
