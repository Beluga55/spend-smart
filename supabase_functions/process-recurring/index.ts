// =====================================================
// SUPABASE EDGE FUNCTION: process-recurring
// Automatically creates expenses from recurring templates
// Run daily via pg_cron at midnight
// =====================================================
//
// To deploy this function:
// 1. Install Supabase CLI: npm install -g supabase
// 2. Run: supabase functions deploy process-recurring
// 3. Or paste this code into Supabase Dashboard → Edge Functions → New
//
// To setup pg_cron (run in SQL Editor):
// SELECT cron.schedule('process-recurring', '0 0 * * *',
//   $$
//   SELECT net.http_post(
//     url:='https://your-project.supabase.co/functions/v1/process-recurring',
//     headers:='{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
//   );
//   $$
// );
// =====================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RecurringExpense {
  id: string
  user_id: string
  amount: number
  category_id: string | null
  note: string | null
  frequency: 'daily' | 'weekly' | 'monthly' | 'yearly'
  start_date: string
  end_date: string | null
  last_created: string | null
  is_active: boolean
}

function calculateNextDue(recurring: RecurringExpense): string | null {
  const lastCreated = recurring.last_created
    ? new Date(recurring.last_created)
    : new Date(recurring.start_date)
  const endDate = recurring.end_date ? new Date(recurring.end_date) : null
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  let nextDue = new Date(lastCreated)

  while (nextDue <= today) {
    switch (recurring.frequency) {
      case 'daily':
        nextDue.setDate(nextDue.getDate() + 1)
        break
      case 'weekly':
        nextDue.setDate(nextDue.getDate() + 7)
        break
      case 'monthly':
        nextDue.setMonth(nextDue.getMonth() + 1)
        break
      case 'yearly':
        nextDue.setFullYear(nextDue.getFullYear() + 1)
        break
    }
  }

  if (endDate && nextDue > endDate) return null

  return nextDue.toISOString().split('T')[0]
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    if (!supabaseServiceKey) {
      throw new Error('SUPABASE_SERVICE_ROLE_KEY is not set')
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get all active recurring expenses
    const { data: recurrings, error: fetchError } = await supabase
      .from('recurring_expenses')
      .select('*')
      .eq('is_active', true)

    if (fetchError) {
      throw fetchError
    }

    const results = {
      processed: 0,
      created: [] as string[],
      errors: [] as string[],
    }

    for (const recurring of recurrings || []) {
      try {
        const nextDue = calculateNextDue(recurring as RecurringExpense)

        if (!nextDue) {
          // Recurring has ended, could optionally deactivate it
          continue
        }

        const today = new Date().toISOString().split('T')[0]

        // Check if we already created an expense for this recurring today
        const { data: existingExpense } = await supabase
          .from('expenses')
          .select('id')
          .eq('recurring_id', recurring.id)
          .eq('date', nextDue)
          .single()

        if (existingExpense) {
          // Already created for this date
          continue
        }

        // Create the expense
        const { data: newExpense, error: insertError } = await supabase
          .from('expenses')
          .insert({
            user_id: recurring.user_id,
            amount: recurring.amount,
            category_id: recurring.category_id,
            date: nextDue,
            note: recurring.note,
            recurring_id: recurring.id,
          })
          .select()
          .single()

        if (insertError) {
          results.errors.push(`Failed to create expense for recurring ${recurring.id}: ${insertError.message}`)
          continue
        }

        // Update last_created on the recurring expense
        await supabase
          .from('recurring_expenses')
          .update({ last_created: nextDue })
          .eq('id', recurring.id)

        results.processed++
        results.created.push(newExpense.id)

      } catch (err) {
        results.errors.push(`Error processing recurring ${recurring.id}: ${err}`)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Processed ${results.processed} recurring expenses`,
        data: results,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
