import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

// Bruecke der Odin-App (MainActivity.OdinAppBridge).
type Bruecke = {
  aktuelleSitzung?: () => string
  updateSupabaseTokens?: (zugang: string, erneuerung: string) => void
}
const bruecke: Bruecke | undefined =
  typeof window !== 'undefined'
    ? (window as unknown as { Android?: Bruecke }).Android
    : undefined

const inOdinApp =
  typeof bruecke?.aktuelleSitzung === 'function' &&
  typeof bruecke?.updateSupabaseTokens === 'function'

// Ablaufzeit (Sekunden) aus dem Zugangstoken.
function ablaufAus(jwt: string): number | null {
  try {
    const teil = jwt.split('.')[1]
    const b64 = teil.replace(/-/g, '+').replace(/_/g, '/')
    const exp = JSON.parse(atob(b64 + '='.repeat((4 - (b64.length % 4)) % 4))).exp
    return typeof exp === 'number' ? exp : null
  } catch {
    return null
  }
}

// Nur der Sitzungsschluessel, nicht "-code-verifier" o. Ae.
const istSitzung = (key: string) => key.endsWith('-auth-token')

// EINE Ablage fuer das Tokenpaar: die App.
//
// Belegt in den Auth-Protokollen vom 22.09. (15:28, 17:56, 22:25): Der Dienst
// erneuert stuendlich, das Dashboard behielt in localStorage das alte Paar.
// getSession() erneuert bei abgelaufenem Token AUCH mit autoRefreshToken:false
// (auth-js __loadSession) - mit dem laengst verbrauchten Token. Antwort:
// refresh_token_already_used, danach Abmeldung.
//
// Deshalb liest supabase-js das Paar bei jedem Zugriff aus der App und reicht
// jedes neue sofort zurueck. localStorage haelt nur noch den Rest der Sitzung
// (Benutzer usw.). Einen veralteten Token gibt es damit nicht mehr.
const odinSpeicher = {
  getItem(key: string): string | null {
    const lokal = localStorage.getItem(key)
    if (!istSitzung(key) || !lokal) return lokal
    try {
      const roh = bruecke!.aktuelleSitzung!()
      if (!roh) return lokal
      const paar = JSON.parse(roh) as { access_token?: string; refresh_token?: string }
      if (!paar.access_token || !paar.refresh_token) return lokal
      const s = JSON.parse(lokal)
      if (s.access_token === paar.access_token && s.refresh_token === paar.refresh_token) return lokal
      s.access_token = paar.access_token
      s.refresh_token = paar.refresh_token
      const exp = ablaufAus(paar.access_token)
      if (exp) {
        s.expires_at = exp
        s.expires_in = Math.max(0, exp - Math.floor(Date.now() / 1000))
      }
      const neu = JSON.stringify(s)
      localStorage.setItem(key, neu)
      return neu
    } catch {
      return lokal
    }
  },
  setItem(key: string, value: string): void {
    localStorage.setItem(key, value)
    if (!istSitzung(key)) return
    try {
      const s = JSON.parse(value) as { access_token?: string; refresh_token?: string }
      if (s.access_token && s.refresh_token) bruecke!.updateSupabaseTokens!(s.access_token, s.refresh_token)
    } catch {
      /* unbrauchbarer Wert - App behaelt ihr Paar */
    }
  },
  removeItem(key: string): void {
    localStorage.removeItem(key)
  },
}

export const supabase =
  supabaseUrl && supabaseAnonKey
    ? createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          persistSession: true,
          // In der App erneuert der Dienst regelmaessig; supabase-js nur noch
          // bei Bedarf, und dann mit dem aktuellen Paar aus der App.
          autoRefreshToken: !inOdinApp,
          ...(inOdinApp ? { storage: odinSpeicher } : {}),
        },
      })
    : null
