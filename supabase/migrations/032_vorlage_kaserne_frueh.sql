-- 032: LKav-Rush W260 - Kaserne vorgezogen (Fetteruruk 09.10.2026).
-- Erster Spike: Kaserne -> Einheiten rekrutieren -> Aufgabe "Der Beginn
-- einer Armee" (Rekrutiere eine weitere Einheit) = 10 Speer + 10 Schwert
-- (belegt: Questlines-Daten de259, Seitenquelle 13).
-- Voraussetzungen davor: Aufgabe "In Fahrt kommen" (Holz 3 + Lehm 3,
-- belegt de261 09.10.) und Kaserne braucht HG 3. Kaserne 1 jetzt Schritt 12
-- statt 24. Endstufen unveraendert, alle Gebaeude-Voraussetzungen geprueft.
update public.bau_vorlagen
set queue = 'main:1;farm:1;storage:1;iron:4;wood:1;stone:1;wood:1;stone:1;wood:1;stone:1;main:2;barracks:1;iron:2;iron:2;iron:1;wood:1;wood:4;stone:1;stone:1;stone:2;main:1;farm:1;storage:2;market:1;hide:1;main:4;storage:1;hide:1;main:2;smith:1;wall:1;smith:1;barracks:1;farm:1;smith:1;storage:1;barracks:3;smith:1;wall:1;smith:1;stable:1;wall:1;farm:2;storage:1;iron:1;stable:2;wood:2;stone:3;farm:2;wall:2;market:2;storage:2;iron:3;stable:2;main:3;wood:3;stone:3;farm:3;storage:2;iron:2;main:2;wood:2;stone:2;farm:2;stable:5',
    beschreibung = 'Mit Ausbau-Belohnungen optimiert (150/150/100 je Stufe). 09.10.: Kaserne vorgezogen - direkt nach Holz 3/Lehm 3 (Aufgabe „In Fahrt kommen“) und HG 3. '
      || 'Danach Einheiten rekrutieren und Aufgaben abschließen: „Der Beginn einer Armee“ (weitere Einheit rekrutieren) gibt 10 Speer + 10 Schwert fürs Farmen. Aufgaben abschließen bisher von Hand. '
      || 'Sim.-Werte vom 04.10. (Stall 1 ~32 h, 10 LKav ~39 h) gelten für die alte Reihenfolge. Nach Stall 1 LKav in der Schmiede erforschen (von Hand). '
      || 'Endstufen: HG 15, Rohstoffe 15, Kaserne 5, Schmiede 5, Stall 10, Hof 12, Speicher 10, Wall 5, Markt 3, Versteck 2. '
      || 'Ohne Belohnungssystem auf der Welt NICHT verwenden (dann langsamer als der klassische Plan).'
where team_id is null and lower(name) = lower('LKav-Rush W260');
