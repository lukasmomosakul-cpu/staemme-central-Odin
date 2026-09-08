'use client';

type Props = {
  accountId: string;
};

export default function GameNativeButton({ accountId }: Props) {
  const openGame = () => {
    // Always enter Odin's internal game route. The external game page is
    // rendered by app/game/page.tsx inside its iframe.
    window.location.assign(`/game/?account=${encodeURIComponent(accountId)}`);
  };

  return (
    <button
      type="button"
      className="gameIconButton"
      onClick={openGame}
      title="Die Stämme in Odin öffnen"
      aria-label="Die Stämme in Odin öffnen"
    >
      🎮
    </button>
  );
}
