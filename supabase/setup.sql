-- TalkBoard cloud sync: run once in the Supabase SQL editor.
--
-- One row per family board. The board is only reachable through the functions
-- below, and only with its sync code. The table itself has row level security
-- turned on with no policies, so the public (anon) key cannot read or list it.
-- Only a SHA-256 hash of each sync code is stored.

create table if not exists public.tb_boards (
  code_hash   text primary key,
  data        jsonb not null,
  version     bigint not null default 1,
  updated_at  timestamptz not null default now(),
  updated_by  text
);

alter table public.tb_boards enable row level security;
revoke all on public.tb_boards from anon, authenticated;

create or replace function public.tb_hash(p_code text)
returns text language sql immutable
set search_path = public
as $$ select encode(sha256(convert_to(p_code, 'UTF8')), 'hex') $$;

-- Cheap check: what version is in the cloud? (no board data)
create or replace function public.tb_meta(p_code text)
returns jsonb language plpgsql security definer
set search_path = public
as $$
declare r public.tb_boards;
begin
  if p_code is null or length(p_code) < 24 then raise exception 'invalid code'; end if;
  select * into r from public.tb_boards where code_hash = public.tb_hash(p_code);
  if not found then return null; end if;
  return jsonb_build_object('version', r.version, 'updated_at', r.updated_at, 'updated_by', r.updated_by);
end $$;

-- Download the board
create or replace function public.tb_get(p_code text)
returns jsonb language plpgsql security definer
set search_path = public
as $$
declare r public.tb_boards;
begin
  if p_code is null or length(p_code) < 24 then raise exception 'invalid code'; end if;
  select * into r from public.tb_boards where code_hash = public.tb_hash(p_code);
  if not found then return null; end if;
  return jsonb_build_object('version', r.version, 'updated_at', r.updated_at,
                            'updated_by', r.updated_by, 'data', r.data);
end $$;

-- Upload the board. p_base is the cloud version this device last synced with;
-- if the cloud has moved on since then, nothing is written (unless p_force)
-- and the device is told there's a conflict.
create or replace function public.tb_put(p_code text, p_data jsonb, p_base bigint, p_device text, p_force boolean default false)
returns jsonb language plpgsql security definer
set search_path = public
as $$
declare h text := public.tb_hash(p_code); cur bigint;
begin
  if p_code is null or length(p_code) < 24 then raise exception 'invalid code'; end if;
  select version into cur from public.tb_boards where code_hash = h for update;
  if not found then
    insert into public.tb_boards(code_hash, data, version, updated_by) values (h, p_data, 1, p_device);
    return jsonb_build_object('ok', true, 'version', 1);
  end if;
  if cur <> coalesce(p_base, 0) and not p_force then
    return jsonb_build_object('ok', false, 'conflict', true, 'version', cur);
  end if;
  update public.tb_boards
     set data = p_data, version = cur + 1, updated_at = now(), updated_by = p_device
   where code_hash = h;
  return jsonb_build_object('ok', true, 'version', cur + 1);
end $$;

revoke all on function public.tb_meta(text), public.tb_get(text),
  public.tb_put(text, jsonb, bigint, text, boolean) from public;
grant execute on function public.tb_meta(text), public.tb_get(text),
  public.tb_put(text, jsonb, bigint, text, boolean) to anon;
