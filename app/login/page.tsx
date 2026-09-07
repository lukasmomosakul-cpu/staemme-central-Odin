'use client';

import { FormEvent, useState } from 'react';
import { supabase } from '../../lib/supabase';

export default function LoginPage() {
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setMessage('');
    setBusy(true);
    const form = new FormData(e.currentTarget);
    const email = String(form.get('user') || '').trim();
    const password = String(form.get('password') || '');

    if (!supabase) {
      setMessage('Supabase ist noch nicht verbunden. Bitte die Umgebungsvariablen setzen.');
      setBusy(false);
      return;
    }

    if (mode === 'login') {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) setMessage(error.message);
      else window.location.href = '/';
    } else {
      const { error } = await supabase.auth.signUp({ email, password });
      setMessage(error ? error.message : 'Registrierung erfolgreich. Prüfe ggf. deine E-Mail zur Bestätigung.');
      if (!error) setMode('login');
    }
    setBusy(false);
  }

  return (
    <main className="authPage">
      <section className="authCard">
        <div className="authLogo">⚔</div>
        <div className="eyebrow">TEAMZENTRALE ODIN</div>
        <h1>{mode === 'login' ? 'Anmelden' : 'Konto erstellen'}</h1>
        <p className="muted">
          {mode === 'login'
            ? 'Verwalte dein Team und alle freigegebenen Spielaccounts zentral.'
            : 'Erstelle dein Konto für die Teamzentrale Odin.'}
        </p>
        <form onSubmit={submit}>
          <label className="field">E-Mail<input name="user" type="email" autoComplete="email" required placeholder="name@beispiel.de" /></label>
          <label className="field">Passwort<input name="password" type="password" autoComplete={mode === 'login' ? 'current-password' : 'new-password'} minLength={6} required placeholder="Mindestens 6 Zeichen" /></label>
          <button className="button authButton" type="submit" disabled={busy}>{busy ? 'Bitte warten…' : mode === 'login' ? 'Anmelden' : 'Konto erstellen'}</button>
        </form>
        {message && <div className="authNotice">{message}</div>}
        <button className="authSwitch" type="button" onClick={() => { setMode(mode === 'login' ? 'signup' : 'login'); setMessage(''); }}>
          {mode === 'login' ? 'Noch kein Konto? Jetzt registrieren' : 'Bereits ein Konto? Jetzt anmelden'}
        </button>
        <a className="authBack" href="/">← Zur Teamzentrale</a>
      </section>
    </main>
  );
}
