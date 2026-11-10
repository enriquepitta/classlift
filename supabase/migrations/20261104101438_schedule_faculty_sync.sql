create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'faculty_schedule_sync_token') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'faculty_schedule_sync_token');
  end if;
end;
$$;

select cron.schedule(
  'faculty-schedules-new', '0 */6 * * *',
  $job$
    select net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name = 'faculty_schedule_project_url') || '/functions/v1/sync-faculty-schedules',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'faculty_schedule_anon_jwt'),
        'x-sync-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'faculty_schedule_sync_token')
      ),
      body := '{"plan":"new"}'::jsonb,
      timeout_milliseconds := 120000
    );
  $job$
);

select cron.schedule(
  'faculty-schedules-previous', '10 */6 * * *',
  $job$
    select net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name = 'faculty_schedule_project_url') || '/functions/v1/sync-faculty-schedules',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'faculty_schedule_anon_jwt'),
        'x-sync-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'faculty_schedule_sync_token')
      ),
      body := '{"plan":"previous"}'::jsonb,
      timeout_milliseconds := 120000
    );
  $job$
);
