begin;
select plan(58);

insert into storage.objects (id, bucket_id, name, metadata)
values (
  'a0000000-0000-0000-0000-000000000001', 'workspace-assets',
  '20000000-0000-0000-0000-000000000001/logo/fixture-a.png',
  '{"mimetype":"image/png"}'::jsonb
);

create function pg_temp.cross_count(target_table text)
returns integer language plpgsql as $$
declare visible_rows integer;
begin
  if target_table = 'workspaces' then
    select count(*)::integer into visible_rows from public.workspaces
      where id = '20000000-0000-0000-0000-000000000001';
  elsif target_table = 'storage.objects' then
    select count(*)::integer into visible_rows from storage.objects
      where bucket_id = 'workspace-assets' and name like '20000000-0000-0000-0000-000000000001/%';
  else
    execute format('select count(*)::integer from public.%I where workspace_id = $1', target_table)
      into visible_rows using '20000000-0000-0000-0000-000000000001'::uuid;
  end if;
  return visible_rows;
end;
$$;

create function pg_temp.cross_insert(target_table text)
returns void language plpgsql as $$
begin
  case target_table
    when 'workspaces' then
      insert into public.workspaces (id, name, created_by_account_id)
      values ('20000000-0000-0000-0000-000000000091', 'Denied Workspace', '10000000-0000-0000-0000-000000000002');
    when 'workspace_members' then
      insert into public.workspace_members (id, workspace_id, account_id, role)
      values ('21000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'OWNER');
    when 'customers' then
      insert into public.customers (id, workspace_id, display_name)
      values ('30000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', 'Denied Customer');
    when 'services' then
      insert into public.services (id, workspace_id, name, service_type, default_price)
      values ('40000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', 'Denied Service', 'BASE', 1);
    when 'appointments' then
      insert into public.appointments (id, workspace_id, customer_id, business_date, status, deposit_amount)
      values ('50000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', current_date, 'BOOKED', 0);
    when 'appointment_services' then
      insert into public.appointment_services (id, workspace_id, appointment_id, service_id, service_name_snapshot, quoted_price_snapshot)
      values ('51000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Denied Snapshot', 1);
    when 'transactions' then
      insert into public.transactions (id, workspace_id, transaction_type, business_date, amount)
      values ('60000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', 'EXPENSE', current_date, 1);
    when 'transaction_items' then
      insert into public.transaction_items (id, workspace_id, transaction_id, item_type, name_snapshot, unit_amount, quantity, line_amount)
      values ('61000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', 'OTHER', 'Denied Item', 1, 1, 1);
    when 'expense_categories' then
      insert into public.expense_categories (id, workspace_id, name)
      values ('70000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', 'Denied Category');
    when 'availability_templates' then
      insert into public.availability_templates (id, workspace_id, weekday, start_time)
      values ('80000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', 1, time '09:00');
    when 'availability_overrides' then
      insert into public.availability_overrides (id, workspace_id, business_date, override_type)
      values ('81000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000001', current_date, 'CLOSED');
    when 'workspace_settings' then
      insert into public.workspace_settings (workspace_id)
      values ('20000000-0000-0000-0000-000000000001');
    when 'workspace_themes' then
      insert into public.workspace_themes (workspace_id)
      values ('20000000-0000-0000-0000-000000000001');
    when 'storage.objects' then
      insert into storage.objects (id, bucket_id, name, metadata)
      values ('a0000000-0000-0000-0000-000000000091', 'workspace-assets', '20000000-0000-0000-0000-000000000001/logo/denied.png', '{"mimetype":"image/png"}'::jsonb);
  end case;
end;
$$;

create function pg_temp.cross_update(target_table text)
returns integer language plpgsql as $$
declare affected integer;
begin
  if target_table = 'workspaces' then
    update public.workspaces set name = name where id = '20000000-0000-0000-0000-000000000001';
  elsif target_table = 'storage.objects' then
    update storage.objects set metadata = metadata
      where bucket_id = 'workspace-assets' and name like '20000000-0000-0000-0000-000000000001/%';
  else
    execute format('update public.%I set workspace_id = workspace_id where workspace_id = $1', target_table)
      using '20000000-0000-0000-0000-000000000001'::uuid;
  end if;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

create function pg_temp.cross_delete(target_table text)
returns integer language plpgsql as $$
declare affected integer;
begin
  if target_table = 'workspaces' then
    delete from public.workspaces where id = '20000000-0000-0000-0000-000000000001';
  elsif target_table = 'storage.objects' then
    delete from storage.objects
      where bucket_id = 'workspace-assets' and name like '20000000-0000-0000-0000-000000000001/%';
  else
    execute format('delete from public.%I where workspace_id = $1', target_table)
      using '20000000-0000-0000-0000-000000000001'::uuid;
  end if;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated","email":"account-b@pulipuli.example.invalid"}';

select is(pg_temp.cross_count(target_table), 0, 'Account B SELECT denied for A1 ' || target_table)
from unnest(array[
  'workspaces','workspace_members','customers','services','appointments','appointment_services',
  'transactions','transaction_items','expense_categories','availability_templates',
  'availability_overrides','workspace_settings','workspace_themes','storage.objects'
]) as target_table;

select throws_ok(
  format('select pg_temp.cross_insert(%L)', target_table), null, null,
  'Account B INSERT denied for A1 ' || target_table
)
from unnest(array[
  'workspaces','workspace_members','customers','services','appointments','appointment_services',
  'transactions','transaction_items','expense_categories','availability_templates',
  'availability_overrides','workspace_settings','workspace_themes','storage.objects'
]) as target_table;

select is(pg_temp.cross_update(target_table), 0, 'Account B UPDATE affects zero A1 rows for ' || target_table)
from unnest(array[
  'workspaces','customers','services','appointments','appointment_services','transactions',
  'transaction_items','expense_categories','availability_templates','availability_overrides',
  'workspace_settings','workspace_themes','storage.objects'
]) as target_table;
select throws_ok(
  $$select pg_temp.cross_update('workspace_members')$$, '42501', null,
  'Account B UPDATE membership is denied by privilege'
);

select is(pg_temp.cross_delete(target_table), 0, 'Account B DELETE affects zero A1 rows for ' || target_table)
from unnest(array[
  'workspaces','customers','services','appointments','appointment_services','transactions',
  'transaction_items','expense_categories','availability_templates','availability_overrides',
  'workspace_settings','workspace_themes'
]) as target_table;
select throws_ok(
  $$select pg_temp.cross_delete('workspace_members')$$, '42501', null,
  'Account B DELETE membership is denied by privilege'
);
select throws_ok(
  $$select pg_temp.cross_delete('storage.objects')$$, null, null,
  'Account B direct SQL DELETE from A1 storage is denied'
);

select lives_ok(
  $$insert into storage.objects (id, bucket_id, name, metadata)
    values ('a0000000-0000-0000-0000-000000000092', 'workspace-assets',
      '20000000-0000-0000-0000-000000000003/logo/allowed-b.png',
      '{"mimetype":"image/png"}'::jsonb)$$,
  'Account B inserts its own B1 logo object'
);
select is(
  (select count(*)::integer from storage.objects
   where name = '20000000-0000-0000-0000-000000000003/logo/allowed-b.png'),
  1, 'Account B reads its own B1 logo object'
);

select * from finish();
rollback;
