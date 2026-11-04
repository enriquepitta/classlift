create table public.faculty_schedule_catalogs (
  id text primary key,
  period text not null,
  year integer not null,
  term smallint not null check (term in (1, 2)),
  plan text not null,
  source_url text not null,
  source_hash text not null,
  careers jsonb not null check (jsonb_typeof(careers) = 'object'),
  total integer not null check (total > 0),
  scheduled integer not null check (scheduled > 0),
  updated_at timestamptz not null default now()
);

alter table public.faculty_schedule_catalogs enable row level security;
revoke all on public.faculty_schedule_catalogs from anon, authenticated;
grant select on public.faculty_schedule_catalogs to anon, authenticated;
grant all on public.faculty_schedule_catalogs to service_role;
create policy "Published faculty schedules are readable"
  on public.faculty_schedule_catalogs for select to anon, authenticated using (true);

-- The shared token stays in Vault. Only the service role can check it.
create function public.verify_faculty_sync_token(input_token text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select coalesce(input_token <> '' and input_token = (
    select decrypted_secret from vault.decrypted_secrets
    where name = 'faculty_schedule_sync_token' limit 1
  ), false);
$$;
revoke all on function public.verify_faculty_sync_token(text) from public, anon, authenticated;
grant execute on function public.verify_faculty_sync_token(text) to service_role;
