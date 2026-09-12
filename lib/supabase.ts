import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

export const supabase =
  supabaseUrl && supabaseAnonKey
    ? createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          // Die Sitzung (Refresh-Token) liegt im localStorage und ueberlebt
          // App-Neustarts. Deshalb muss das Passwort nirgends gespeichert werden.
          persistSession: true,
          autoRefreshToken: true,
        },
      })
    : null
