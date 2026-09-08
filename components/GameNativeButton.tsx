'use client';

type Props = {
  accountId: string;
};

export default function GameNativeButton({ accountId }: Props) {
  const openGame = () => {
    // /game-top navigates the existing Capacitor WebView to Die Stämme as the
    // top-level document. This keeps the game inside the app while avoiding the
    // third-party iframe context that prevents the site's login/hCaptcha flow.
    window.location.assign(`/game-top/?account=${encodeURIComponent(accountId)}`);
  };

  return (
    <button type="button" className="iconButton" onClick={openGame} title="Die Stämme öffnen" aria-label="Die Stämme öffnen">
      🎮
    </button>
  );
}
