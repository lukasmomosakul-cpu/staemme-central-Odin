'use client';

import { FormEvent, useState } from 'react';
import { supabase } from '../../lib/supabase';

export default function LoginPage() {
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setMessage('');
    setBusy(true);
    const form = new FormData(e.currentTarget);
    const email = String(form.get('user') || '');
    const password = String(form.get('password') || '');
    if (!supabase) {
      setMessage('Supabase ist noch nicht verbunden. Bitte die Umgebungsvariablen setzen.');
      setBusy(false);
      return;
    }
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setMessage(error ? error.message : 'Anmeldung erfolgreich.');
    if (!error) window.location.href = '/';
    setBusy(false);
  }

  return <main className="authPage"><section className="authCard"><div className="authLogo">⚔</div><div className="eyebrow">TEAMZENTRALE ODIN</div><h1>Anmelden</h1><p className="muted">Verwalte dein Team und alle freigegebenen Spielaccounts zentral.</p><form onSubmit={submit}><label className="field">E-Mail<input name="user" type="email" autoComplete="username" required placeholder="name@beispiel.de" /></label><label className="field">Passwort<input name="password" type="password" autoComplete="current-password" required placeholder="••••••••" /></label><button className="button authButton" type="submit" disabled={busy}>{busy ? 'Anmelden…' : 'Anmelden'}</button></form>{message && <div className="authNotice">{message}</div>}<a className="authBack" href="/">← Zur Teamzentrale</a></section></main>;
}
