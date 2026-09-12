'use client';

import { FormEvent, useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

export default function LoginPage() {
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // Bestehende Sitzung wiederherstellen. Frueher wurde hierfuer das Passwort
  // per Android-Bruecke im Klartext auf dem Geraet abgelegt - unnoetig, weil
  // Supabase den Refresh-Token selbst persistiert.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      if (!supabase) return;
      const { data } = await supabase.auth.getSession();
      if (!cancelled && data.session) window.location.href = '/';
    })();
    return () => { cancelled = true; };
  }, []);

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setMessage('');
    setBusy(true);
    const form = new FormData(e.currentTarget);
    const nextEmail = String(form.get('user') || '').trim();
    const nextPassword = String(form.get('password') || '');
    setEmail(nextEmail);
    setPassword(nextPassword);

    if (!supabase) {
      setMessage('Supabase ist noch nicht verbunden. Bitte die Umgebungsvariablen setzen.');
      setBusy(false);
      return;
    }

    if (mode === 'login') {
      const { error } = await supabase.auth.signInWithPassword({ email: nextEmail, password: nextPassword });
      if (error) {
        setMessage(error.message);
      } else {
        window.location.href = '/';
      }
    } else {
      const { error } = await supabase.auth.signUp({ email: nextEmail, password: nextPassword });
      setMessage(error ? error.message : 'Registrierung erfolgreich. Prüfe ggf. deine E-Mail zur Bestätigung.');
      if (!error) setMode('login');
    }
    setBusy(false);
  }

  const isLogin = mode === 'login';

  return (
    <main className="authPage">
      <section className="authCard">
        <div className="authBrand">
          <div className="authLogo">⚔</div>
          <div>
            <div className="authBrandName">Teamzentrale Odin</div>
            <div className="authBrandSub">Sicher. Zentral. Für dein Team.</div>
          </div>
        </div>

        <div className="authIntro">
          <div className="authBadge">{isLogin ? 'WILLKOMMEN ZURÜCK' : 'NEUES TEAMKONTO'}</div>
          <h1>{isLogin ? 'Anmelden' : 'Konto erstellen'}</h1>
          <p>
            {isLogin
              ? 'Melde dich an, um deine Teamzentrale zu öffnen.'
              : 'Erstelle dein Konto und starte deine eigene Teamzentrale.'}
          </p>
        </div>

        <form onSubmit={submit} className="authForm">
          <label className="authField">
            <span>E-Mail-Adresse</span>
            <input name="user" type="email" autoComplete="email" required placeholder="name@beispiel.de" value={email} onChange={e => setEmail(e.target.value)} />
          </label>
          <label className="authField">
            <span>Passwort</span>
            <input name="password" type="password" autoComplete={isLogin ? 'current-password' : 'new-password'} minLength={6} required placeholder="Mindestens 6 Zeichen" value={password} onChange={e => setPassword(e.target.value)} />
          </label>
          <button className="button authButton" type="submit" disabled={busy}>
            {busy ? 'Bitte warten…' : isLogin ? 'Anmelden' : 'Konto erstellen'}
          </button>
        </form>

        {message && <div className="authNotice">{message}</div>}

        <div className="authDivider"><span>oder</span></div>
        <button className="authSwitch" type="button" onClick={() => { setMode(isLogin ? 'signup' : 'login'); setMessage(''); }}>
          {isLogin ? 'Noch kein Konto? Jetzt registrieren' : 'Bereits ein Konto? Jetzt anmelden'}
        </button>
        <a className="authBack" href="/">← Zur Teamzentrale</a>
        <div className="authFooter">Teamzentrale Odin · Zugang nur für berechtigte Nutzer</div>
      </section>
    </main>
  );
}
