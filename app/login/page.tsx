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
            <input name="user" type="email" autoComplete="email" required placeholder="name@beispiel.de" />
          </label>
          <label className="authField">
            <span>Passwort</span>
            <input name="password" type="password" autoComplete={isLogin ? 'current-password' : 'new-password'} minLength={6} required placeholder="Mindestens 6 Zeichen" />
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
