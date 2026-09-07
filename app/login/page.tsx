'use client';

import { FormEvent, useState } from 'react';

export default function LoginPage() {
  const [message, setMessage] = useState('');
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setMessage('Demo-Anmeldung erfolgreich. Backend-Authentifizierung folgt als nächster Schritt.');
  }
  return <main className="authPage"><section className="authCard"><div className="authLogo">⚔</div><div className="eyebrow">TEAMZENTRALE ODIN</div><h1>Anmelden</h1><p className="muted">Verwalte dein Team und alle freigegebenen Spielaccounts zentral.</p><form onSubmit={submit}><label className="field">E-Mail oder Benutzername<input name="user" autoComplete="username" required placeholder="z. B. max" /></label><label className="field">Passwort<input name="password" type="password" autoComplete="current-password" required placeholder="••••••••" /></label><button className="button authButton" type="submit">Anmelden</button></form>{message && <div className="authNotice">✓ {message}</div>}<a className="authBack" href="/">← Zur Teamzentrale</a></section></main>;
}
