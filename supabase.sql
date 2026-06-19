-- Supabase setup for the candle counters.
-- Run this once in the SQL editor.

create table if not exists public.candle_counters (
  color text primary key,
  total bigint not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.candle_counters (color, total)
values
  ('dorada', 16248),
  ('roja', 12984),
  ('negra', 19532)
on conflict (color) do nothing;

drop function if exists public.increment_candle_counter(text, integer);

create or replace function public.increment_candle_counter(
  p_color text,
  p_increment integer default 13
)
returns table (total bigint)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_color not in ('dorada', 'roja', 'negra') then
    raise exception 'Invalid candle color: %', p_color;
  end if;

  return query
  insert into public.candle_counters as cc (color, total, updated_at)
  values (p_color, p_increment, now())
  on conflict (color)
  do update set
    total = cc.total + excluded.total,
    updated_at = now()
  returning cc.total;
end;
$$;

alter table public.candle_counters enable row level security;

drop policy if exists "Public read candle counters" on public.candle_counters;
create policy "Public read candle counters"
on public.candle_counters
for select
using (true);

grant select on public.candle_counters to anon, authenticated;
grant execute on function public.increment_candle_counter(text, integer) to anon, authenticated;
