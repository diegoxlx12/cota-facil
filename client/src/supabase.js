import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase não configurado: defina VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY na Vercel.')
}

export const supabase = createClient(supabaseUrl || 'https://aqonktnmwzwjxurrrjxu.supabase.co', supabaseAnonKey || 'sb_publishable_Z31tXub-4lSCOFeIcNfm8w_mvx7ixG8')
