-- 2.0.79 (16.10.2026): Botschutz-Meldung alle 10 Min an allen Geraeten,
-- Wecker erst nach 90 Min, Nachtruhe 23-6 Uhr (kein Wecker, Meldung alle 30 Min).
alter table public.notification_settings
  add column if not exists nacht_von integer not null default 23,
  add column if not exists nacht_bis integer not null default 6;
alter table public.notification_settings
  alter column botschutz_vibration_sek set default 600,
  alter column botschutz_wecker_min set default 90;
update public.notification_settings
  set botschutz_an = true, botschutz_vibration_sek = 600, botschutz_wecker_min = 90,
      nacht_von = 23, nacht_bis = 6, updated_at = now();
