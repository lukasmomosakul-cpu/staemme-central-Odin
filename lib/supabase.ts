import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

// In der Odin-App erneuert der Dienst den Token selbst. Erneuert supabase-js
// zusaetzlich, dreht sich das Erneuerungstoken weiter und die jeweils andere
// Seite sitzt auf einem verbrauchten - genau daran flog man im Dashboard
// staendig raus. Drinnen also nur EIN Erneuerer: der Dienst. Die Oberflaeche
// holt sich das aktuelle Paar ueber die Bruecke.
const inOdinApp =
  typeof window !== 'undefined' &&
  typeof (window as unknown as { Android?: { aktuelleSitzung?: () => string } })
    .Android?.aktuelleSitzung === 'function';

export const supabase =
  supabaseUrl && supabaseAnonKey
    ? createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          // Die Sitzung (Refresh-Token) liegt im localStorage und ueberlebt
          // App-Neustarts. Deshalb muss das Passwort nirgends gespeichert werden.
          persistSession: true,
          autoRefreshToken: !inOdinApp,
        },
      })
    : null
