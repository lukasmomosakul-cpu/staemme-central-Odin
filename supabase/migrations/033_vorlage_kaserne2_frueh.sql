-- 033: LKav-Rush W260 - Kaserne 2 direkt (statt Stufe 1) in Schritt 12.
-- BELEGT (Quests.setQuestData de259, Seitenquellen 05/08/09/15): Aufgabe
-- 1200 "Bereitmachen zum Plündern" = Kaserne Stufe 2 -> 10 Speer + 10
-- Schwert. Danach 1205 "Zu deinen Diensten!" (1 Einheit rekrutieren) und
-- 1220 "Der Beginn einer Armee" (weitere Einheit, 10 Speer + 10 Schwert).
-- Rekrutieren und Abschliessen uebernimmt GodBot ab v571.
update public.bau_vorlagen
set queue = 'main:1;farm:1;storage:1;iron:4;wood:1;stone:1;wood:1;stone:1;wood:1;stone:1;main:2;barracks:2;iron:2;iron:2;iron:1;wood:1;wood:4;stone:1;stone:1;stone:2;main:1;farm:1;storage:2;market:1;hide:1;main:4;storage:1;hide:1;main:2;smith:1;wall:1;smith:1;farm:1;smith:1;storage:1;barracks:3;smith:1;wall:1;smith:1;stable:1;wall:1;farm:2;storage:1;iron:1;stable:2;wood:2;stone:3;farm:2;wall:2;market:2;storage:2;iron:3;stable:2;main:3;wood:3;stone:3;farm:3;storage:2;iron:2;main:2;wood:2;stone:2;farm:2;stable:5',
    beschreibung = replace(replace(beschreibung,
      'Kaserne vorgezogen - direkt nach', 'Kaserne 2 vorgezogen - direkt nach'),
      'Danach Einheiten rekrutieren und Aufgaben abschließen: „Der Beginn einer Armee“ (weitere Einheit rekrutieren) gibt 10 Speer + 10 Schwert fürs Farmen. Aufgaben abschließen bisher von Hand. ',
      'Kaserne 2 = Aufgabe „Bereitmachen zum Plündern“ (10 Speer + 10 Schwert), danach 1 Speer für „Zu deinen Diensten!“ und „Der Beginn einer Armee“ (nochmal 10 + 10). Rekrutieren und Abschließen macht GodBot ab v571. ')
where team_id is null and lower(name) = lower('LKav-Rush W260');
