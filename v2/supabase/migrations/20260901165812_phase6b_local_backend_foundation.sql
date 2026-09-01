create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create type public.workspace_status as enum ('ACTIVE', 'ARCHIVED');
create type public.workspace_member_role as enum ('OWNER', 'STAFF');
create type public.workspace_member_status as enum ('ACTIVE', 'INACTIVE');
create type public.workspace_creation_grant_status as enum ('ACTIVE', 'REVOKED', 'EXHAUSTED');
create type public.workspace_invite_status as enum ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED');
create type public.service_type as enum ('BASE', 'ADDON', 'REMOVAL', 'OTHER');
create type public.appointment_status as enum ('BOOKED', 'ARRIVED', 'COMPLETED', 'CANCELLED', 'NO_SHOW');
create type public.transaction_type as enum ('INCOME', 'EXPENSE');
create type public.transaction_item_type as enum ('SERVICE', 'ADDON', 'REMOVAL', 'ADJUSTMENT', 'DISCOUNT', 'OTHER');
create type public.availability_override_type as enum ('CLOSED', 'ADD_SLOT', 'REMOVE_SLOT');
create type public.migration_run_status as enum ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 1 and 120),
  status public.workspace_status not null default 'ACTIVE',
  created_by_account_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  account_id uuid not null references auth.users(id),
  role public.workspace_member_role not null default 'OWNER',
  status public.workspace_member_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, account_id),
  unique (workspace_id, id)
);

create table public.workspace_creation_grants (
  id uuid primary key default gen_random_uuid(),
  account_id uuid references auth.users(id),
  email text,
  status public.workspace_creation_grant_status not null default 'ACTIVE',
  max_workspaces smallint not null default 3 check (max_workspaces between 1 and 3),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  check (account_id is not null or nullif(btrim(email), '') is not null)
);

create unique index workspace_creation_grants_account_active_uidx
  on public.workspace_creation_grants (account_id)
  where account_id is not null and status = 'ACTIVE';
create unique index workspace_creation_grants_email_active_uidx
  on public.workspace_creation_grants (lower(email))
  where email is not null and status = 'ACTIVE';

create table public.workspace_invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  target_email text not null check (nullif(btrim(target_email), '') is not null),
  token_hash bytea not null unique,
  role public.workspace_member_role not null default 'OWNER',
  status public.workspace_invite_status not null default 'PENDING',
  expires_at timestamptz not null,
  created_by_account_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  unique (workspace_id, id)
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  display_name text not null check (nullif(btrim(display_name), '') is not null),
  phone text,
  email text,
  social_handle text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (workspace_id, id)
);

create table public.customer_merges (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  source_customer_id uuid not null,
  target_customer_id uuid not null,
  merged_at timestamptz not null default now(),
  merged_by_account_id uuid not null references auth.users(id),
  unique (workspace_id, id),
  check (source_customer_id <> target_customer_id),
  foreign key (workspace_id, source_customer_id) references public.customers(workspace_id, id),
  foreign key (workspace_id, target_customer_id) references public.customers(workspace_id, id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  name text not null check (nullif(btrim(name), '') is not null),
  service_type public.service_type not null,
  default_price bigint not null check (default_price >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (workspace_id, id)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  customer_id uuid not null,
  business_date date not null,
  start_time time,
  status public.appointment_status not null default 'BOOKED',
  channel text,
  channel_note text,
  deposit_amount bigint not null default 0 check (deposit_amount >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (workspace_id, id),
  foreign key (workspace_id, customer_id) references public.customers(workspace_id, id)
);

create table public.appointment_services (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  appointment_id uuid not null,
  service_id uuid,
  service_name_snapshot text not null check (nullif(btrim(service_name_snapshot), '') is not null),
  quoted_price_snapshot bigint not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (workspace_id, id),
  foreign key (workspace_id, appointment_id) references public.appointments(workspace_id, id),
  foreign key (workspace_id, service_id) references public.services(workspace_id, id)
);

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  name text not null check (nullif(btrim(name), '') is not null),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, id)
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  transaction_type public.transaction_type not null,
  business_date date not null,
  customer_id uuid,
  appointment_id uuid,
  amount bigint not null check (amount >= 0),
  category_id uuid,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (workspace_id, id),
  foreign key (workspace_id, customer_id) references public.customers(workspace_id, id),
  foreign key (workspace_id, appointment_id) references public.appointments(workspace_id, id),
  foreign key (workspace_id, category_id) references public.expense_categories(workspace_id, id)
);

create unique index transactions_one_income_checkout_per_appointment_uidx
  on public.transactions (workspace_id, appointment_id)
  where transaction_type = 'INCOME' and appointment_id is not null and deleted_at is null;

create table public.transaction_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  transaction_id uuid not null,
  service_id uuid,
  item_type public.transaction_item_type not null,
  name_snapshot text not null check (nullif(btrim(name_snapshot), '') is not null),
  unit_amount bigint not null,
  quantity integer not null default 1 check (quantity > 0),
  line_amount bigint not null,
  sort_order integer not null default 0,
  unique (workspace_id, id),
  foreign key (workspace_id, transaction_id) references public.transactions(workspace_id, id),
  foreign key (workspace_id, service_id) references public.services(workspace_id, id)
);

create table public.availability_templates (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  weekday smallint not null check (weekday between 0 and 6),
  start_time time not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  unique (workspace_id, id)
);

create table public.availability_overrides (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  business_date date not null,
  override_type public.availability_override_type not null,
  start_time time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, id),
  check ((override_type = 'CLOSED' and start_time is null) or
         (override_type in ('ADD_SLOT', 'REMOVE_SLOT') and start_time is not null))
);

create table public.workspace_settings (
  workspace_id uuid primary key references public.workspaces(id),
  logo_ref text,
  timezone text not null default 'Asia/Taipei',
  currency text not null default 'TWD' check (currency = 'TWD'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.workspace_themes (
  workspace_id uuid primary key references public.workspaces(id),
  theme_key text not null default 'default',
  color_tokens jsonb not null default '{}'::jsonb check (jsonb_typeof(color_tokens) = 'object'),
  card_alpha numeric(4,3) not null default 1 check (card_alpha between 0 and 1),
  updated_at timestamptz not null default now()
);

create table public.account_preferences (
  account_id uuid primary key references auth.users(id) on delete cascade,
  locale text not null default 'zh-TW',
  timezone text not null default 'Asia/Taipei',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.migration_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  source_key text not null,
  status public.migration_run_status not null default 'PENDING',
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, id),
  unique (workspace_id, source_key)
);

create table public.legacy_id_maps (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id),
  migration_run_id uuid not null,
  legacy_source_entity text not null,
  legacy_source_id text not null,
  v2_entity_type text not null,
  v2_entity_id uuid not null,
  created_at timestamptz not null default now(),
  unique (workspace_id, id),
  unique (migration_run_id, legacy_source_entity, legacy_source_id),
  unique (migration_run_id, v2_entity_type, v2_entity_id),
  foreign key (workspace_id, migration_run_id) references public.migration_runs(workspace_id, id)
);

create index workspace_members_account_idx on public.workspace_members (account_id, status);
create index workspace_invites_workspace_idx on public.workspace_invites (workspace_id, status);
create index customers_workspace_idx on public.customers (workspace_id) where deleted_at is null;
create index services_workspace_idx on public.services (workspace_id) where deleted_at is null;
create index appointments_workspace_date_idx on public.appointments (workspace_id, business_date) where deleted_at is null;
create index transactions_workspace_date_idx on public.transactions (workspace_id, business_date) where deleted_at is null;

create function private.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create function private.prevent_workspace_id_change()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.workspace_id is distinct from old.workspace_id then
    raise exception using errcode = '23514', message = 'workspace_id is immutable';
  end if;
  return new;
end;
$$;

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'profiles', 'workspaces', 'workspace_members', 'customers', 'services',
    'appointments', 'expense_categories', 'availability_overrides',
    'workspace_settings', 'account_preferences', 'migration_runs'
  ] loop
    execute format('create trigger set_updated_at before update on public.%I for each row execute function private.set_updated_at()', table_name);
  end loop;
  foreach table_name in array array[
    'workspace_members', 'workspace_invites', 'customers', 'customer_merges',
    'services', 'appointments', 'appointment_services', 'transactions',
    'transaction_items', 'expense_categories', 'availability_templates',
    'availability_overrides', 'workspace_settings', 'workspace_themes',
    'migration_runs', 'legacy_id_maps'
  ] loop
    execute format('create trigger protect_workspace_id before update on public.%I for each row execute function private.prevent_workspace_id_change()', table_name);
  end loop;
end;
$$;

create function private.is_workspace_member(target_workspace_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select (select auth.uid()) is not null and exists (
    select 1
    from public.workspace_members as member
    join public.workspaces as workspace on workspace.id = member.workspace_id
    where member.workspace_id = target_workspace_id
      and member.account_id = (select auth.uid())
      and member.status = 'ACTIVE'
      and workspace.status = 'ACTIVE'
      and workspace.deleted_at is null
  );
$$;
revoke execute on function private.is_workspace_member(uuid) from public, anon;
grant execute on function private.is_workspace_member(uuid) to authenticated;

create function private.create_workspace(workspace_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  current_account_id uuid := auth.uid();
  current_email text;
  creation_grant public.workspace_creation_grants%rowtype;
  owned_workspace_count integer;
  created_workspace_id uuid;
begin
  if current_account_id is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  if nullif(btrim(workspace_name), '') is null then
    raise exception using errcode = '22023', message = 'Workspace name is required';
  end if;
  select lower(user_record.email) into current_email
    from auth.users as user_record where user_record.id = current_account_id;
  if not found then
    raise exception using errcode = '28000', message = 'Auth user not found';
  end if;
  select grant_record.* into creation_grant
    from public.workspace_creation_grants as grant_record
   where grant_record.status = 'ACTIVE'
     and (grant_record.expires_at is null or grant_record.expires_at > now())
     and (grant_record.account_id = current_account_id or
          (grant_record.email is not null and lower(grant_record.email) = current_email))
   order by (grant_record.account_id is not null) desc, grant_record.created_at
   limit 1 for update;
  if not found then
    raise exception using errcode = '42501', message = 'Workspace creation grant required';
  end if;
  select count(*)::integer into owned_workspace_count
    from public.workspace_members as member
    join public.workspaces as workspace on workspace.id = member.workspace_id
   where member.account_id = current_account_id and member.role = 'OWNER'
     and member.status = 'ACTIVE' and workspace.status = 'ACTIVE' and workspace.deleted_at is null;
  if owned_workspace_count >= least(creation_grant.max_workspaces, 3) then
    raise exception using errcode = 'P0001', message = 'Workspace limit reached';
  end if;
  insert into public.workspaces (name, created_by_account_id)
    values (btrim(workspace_name), current_account_id) returning id into created_workspace_id;
  insert into public.workspace_members (workspace_id, account_id, role, status)
    values (created_workspace_id, current_account_id, 'OWNER', 'ACTIVE');
  insert into public.workspace_settings (workspace_id) values (created_workspace_id);
  insert into public.workspace_themes (workspace_id) values (created_workspace_id);
  return created_workspace_id;
end;
$$;
revoke execute on function private.create_workspace(text) from public, anon;
grant execute on function private.create_workspace(text) to authenticated;

create function private.accept_invite(raw_token text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  current_account_id uuid := auth.uid();
  current_email text;
  accepted_invite public.workspace_invites%rowtype;
begin
  if current_account_id is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  if nullif(raw_token, '') is null then
    raise exception using errcode = '22023', message = 'Invite token is required';
  end if;
  select lower(user_record.email) into current_email
    from auth.users as user_record where user_record.id = current_account_id;
  if not found or current_email is null then
    raise exception using errcode = '28000', message = 'Auth email required';
  end if;
  update public.workspace_invites as invite
     set status = 'ACCEPTED', accepted_at = now()
   where invite.token_hash = extensions.digest(raw_token, 'sha256')
     and invite.status = 'PENDING' and invite.expires_at > now()
     and lower(invite.target_email) = current_email
  returning invite.* into accepted_invite;
  if not found then
    raise exception using errcode = 'P0001', message = 'Invite is invalid, expired, or already accepted';
  end if;
  insert into public.workspace_members (workspace_id, account_id, role, status)
    values (accepted_invite.workspace_id, current_account_id, accepted_invite.role, 'ACTIVE')
  on conflict (workspace_id, account_id)
    do update set role = excluded.role, status = 'ACTIVE', updated_at = now();
  return accepted_invite.workspace_id;
end;
$$;
revoke execute on function private.accept_invite(text) from public, anon;
grant execute on function private.accept_invite(text) to authenticated;

create function private.workspace_id_from_logo_path(object_name text)
returns uuid language plpgsql immutable set search_path = '' as $$
declare path_parts text[] := string_to_array(object_name, '/');
begin
  if array_length(path_parts, 1) = 3
     and path_parts[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     and path_parts[2] = 'logo' and path_parts[3] <> '' then
    return path_parts[1]::uuid;
  end if;
  return null;
exception when invalid_text_representation then return null;
end;
$$;
revoke execute on function private.workspace_id_from_logo_path(text) from public, anon;
grant execute on function private.workspace_id_from_logo_path(text) to authenticated;

alter table public.profiles enable row level security;
alter table public.account_preferences enable row level security;
alter table public.workspace_creation_grants enable row level security;

create policy profiles_select on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_insert on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy profiles_delete on public.profiles for delete to authenticated using (id = (select auth.uid()));

create policy account_preferences_select on public.account_preferences for select to authenticated
  using (account_id = (select auth.uid()));
create policy account_preferences_insert on public.account_preferences for insert to authenticated
  with check (account_id = (select auth.uid()));
create policy account_preferences_update on public.account_preferences for update to authenticated
  using (account_id = (select auth.uid())) with check (account_id = (select auth.uid()));
create policy account_preferences_delete on public.account_preferences for delete to authenticated
  using (account_id = (select auth.uid()));

alter table public.workspaces enable row level security;
create policy workspaces_select on public.workspaces for select to authenticated using (private.is_workspace_member(id));
create policy workspaces_insert on public.workspaces for insert to authenticated with check (private.is_workspace_member(id));
create policy workspaces_update on public.workspaces for update to authenticated
  using (private.is_workspace_member(id)) with check (private.is_workspace_member(id));
create policy workspaces_delete on public.workspaces for delete to authenticated using (private.is_workspace_member(id));

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'workspace_members', 'workspace_invites', 'customers', 'customer_merges',
    'services', 'appointments', 'appointment_services', 'transactions',
    'transaction_items', 'expense_categories', 'availability_templates',
    'availability_overrides', 'workspace_settings', 'workspace_themes',
    'migration_runs', 'legacy_id_maps'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('create policy %I on public.%I for select to authenticated using (private.is_workspace_member(workspace_id))', table_name || '_select', table_name);
    execute format('create policy %I on public.%I for insert to authenticated with check (private.is_workspace_member(workspace_id))', table_name || '_insert', table_name);
    execute format('create policy %I on public.%I for update to authenticated using (private.is_workspace_member(workspace_id)) with check (private.is_workspace_member(workspace_id))', table_name || '_update', table_name);
    execute format('create policy %I on public.%I for delete to authenticated using (private.is_workspace_member(workspace_id))', table_name || '_delete', table_name);
  end loop;
end;
$$;

revoke all on all tables in schema public from anon;
grant select, insert, update, delete on public.profiles, public.account_preferences to authenticated;
grant select, update, delete on public.workspaces to authenticated;
grant select on public.workspace_members to authenticated;
revoke insert on public.workspaces from authenticated;
revoke insert, update, delete on public.workspace_members from authenticated;
grant select, insert, update, delete on
  public.workspace_invites, public.customers, public.customer_merges, public.services,
  public.appointments, public.appointment_services, public.transactions,
  public.transaction_items, public.expense_categories, public.availability_templates,
  public.availability_overrides, public.workspace_settings, public.workspace_themes,
  public.migration_runs, public.legacy_id_maps
to authenticated;
revoke all on public.workspace_creation_grants from authenticated;

create view public.account_workspace_financials
with (security_invoker = true)
as
select
  member.account_id,
  workspace.id as workspace_id,
  workspace.name as workspace_name,
  coalesce(sum(financial_transaction.amount) filter (
    where financial_transaction.transaction_type = 'INCOME' and financial_transaction.deleted_at is null
  ), 0)::bigint as revenue,
  coalesce(sum(financial_transaction.amount) filter (
    where financial_transaction.transaction_type = 'EXPENSE' and financial_transaction.deleted_at is null
  ), 0)::bigint as expense,
  (coalesce(sum(financial_transaction.amount) filter (
     where financial_transaction.transaction_type = 'INCOME' and financial_transaction.deleted_at is null
   ), 0) -
   coalesce(sum(financial_transaction.amount) filter (
     where financial_transaction.transaction_type = 'EXPENSE' and financial_transaction.deleted_at is null
   ), 0))::bigint as net
from public.workspace_members as member
join public.workspaces as workspace on workspace.id = member.workspace_id
left join public.transactions as financial_transaction on financial_transaction.workspace_id = workspace.id
where member.account_id = (select auth.uid())
  and member.status = 'ACTIVE' and workspace.status = 'ACTIVE' and workspace.deleted_at is null
group by member.account_id, workspace.id, workspace.name;

revoke all on public.account_workspace_financials from public, anon;
grant select on public.account_workspace_financials to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('workspace-assets', 'workspace-assets', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp']::text[])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists workspace_assets_select on storage.objects;
drop policy if exists workspace_assets_insert on storage.objects;
drop policy if exists workspace_assets_update on storage.objects;
drop policy if exists workspace_assets_delete on storage.objects;

create policy workspace_assets_select on storage.objects for select to authenticated using (
  bucket_id = 'workspace-assets'
  and private.workspace_id_from_logo_path(name) is not null
  and private.is_workspace_member(private.workspace_id_from_logo_path(name))
);
create policy workspace_assets_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'workspace-assets'
  and private.workspace_id_from_logo_path(name) is not null
  and private.is_workspace_member(private.workspace_id_from_logo_path(name))
);
create policy workspace_assets_update on storage.objects for update to authenticated using (
  bucket_id = 'workspace-assets'
  and private.workspace_id_from_logo_path(name) is not null
  and private.is_workspace_member(private.workspace_id_from_logo_path(name))
) with check (
  bucket_id = 'workspace-assets'
  and private.workspace_id_from_logo_path(name) is not null
  and private.is_workspace_member(private.workspace_id_from_logo_path(name))
);
create policy workspace_assets_delete on storage.objects for delete to authenticated using (
  bucket_id = 'workspace-assets'
  and private.workspace_id_from_logo_path(name) is not null
  and private.is_workspace_member(private.workspace_id_from_logo_path(name))
);

comment on schema private is 'Non-exposed security helpers and atomic RPC contracts.';
comment on function private.create_workspace(text) is 'Grant-gated atomic workspace and OWNER membership creation; max three active owned workspaces.';
comment on function private.accept_invite(text) is 'Atomic hashed-token invite acceptance with expiry and replay protection.';
comment on index public.transactions_one_income_checkout_per_appointment_uidx is 'MVP checkout invariant: one active INCOME transaction per appointment.';
