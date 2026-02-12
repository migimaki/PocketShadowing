/**
 * List all series from Supabase
 * Useful for finding series IDs to test with
 *
 * Usage: npx tsx scripts/list-series.ts
 */

import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function listSeries() {
  console.log('Fetching series from Supabase...\n');

  const { data: series, error } = await supabase
    .from('series')
    .select('id, name, difficulty_level, line_count, batch_number')
    .order('batch_number', { ascending: true })
    .order('name', { ascending: true });

  if (error) {
    console.error('Error fetching series:', error);
    process.exit(1);
  }

  if (!series || series.length === 0) {
    console.log('No series found in database.');
    return;
  }

  console.log(`Found ${series.length} series:\n`);

  // Group by batch
  const batches = series.reduce((acc, s) => {
    const batch = s.batch_number || 0;
    if (!acc[batch]) acc[batch] = [];
    acc[batch].push(s);
    return acc;
  }, {} as Record<number, typeof series>);

  Object.entries(batches)
    .sort(([a], [b]) => Number(a) - Number(b))
    .forEach(([batch, seriesInBatch]) => {
      console.log(`\n📦 Batch ${batch} (${seriesInBatch.length} series):`);
      console.log('─'.repeat(80));

      seriesInBatch.forEach((s) => {
        console.log(`
  Name: ${s.name}
  ID: ${s.id}
  Difficulty: ${s.difficulty_level}
  Lines: ${s.line_count}
        `.trim());
        console.log('');
      });
    });

  console.log('\n' + '─'.repeat(80));
  console.log('\nTest commands:');
  console.log(`  ./scripts/test-generation.sh local 1  # Test batch 1 locally`);
  console.log(`  ./scripts/test-generation.sh ${series[0].id}  # Test specific series`);
}

listSeries().catch(console.error);
