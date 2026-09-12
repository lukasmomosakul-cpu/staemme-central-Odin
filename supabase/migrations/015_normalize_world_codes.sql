-- 015: Weltangaben vereinheitlichen (256 -> de256)
-- Die Spielseite erwartet die Serverkennung; /page/play/256 liefert "invalid data".
update public.game_accounts set world = 'de' || world where world ~ '^[0-9]+$';
