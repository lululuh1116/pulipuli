begin;
select plan(27);

select is(
  (select count(*)::integer from information_schema.tables
   where table_schema = 'public' and table_type = 'BASE TABLE'
     and table_name = any(array[
       'profiles','workspaces','workspace_members','workspace_creation_grants','workspace_invites',
       'customers','customer_merges','services','appointments','appointment_services',
       'transactions','transaction_items','expense_categories','availability_templates',
       'availability_overrides','workspace_settings','workspace_themes','account_preferences',
       'migration_runs','legacy_id_maps'
     ])),
  20, 'all 20 approved Phase 6B tables exist'
);

select is(
  (select count(*)::integer from information_schema.tables
   where table_schema = 'public' and table_name = any(array[
     'brands','staff','staff_schedules','commissions','payroll','offline_queue',
     'global_transactions','global_customers','global_analytics'
   ])),
  0, 'forbidden entities do not exist'
);

select is(
  (select count(*)::integer from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
     and c.relname = any(array[
       'profiles','workspaces','workspace_members','workspace_creation_grants','workspace_invites',
       'customers','customer_merges','services','appointments','appointment_services',
       'transactions','transaction_items','expense_categories','availability_templates',
       'availability_overrides','workspace_settings','workspace_themes','account_preferences',
       'migration_runs','legacy_id_maps'
     ])),
  20, 'RLS is enabled on every approved public table'
);

select is(
  (select count(*)::integer from pg_policies
   where schemaname = 'public' and tablename <> 'workspace_creation_grants'),
  76, 'all accessible public tables have four CRUD policies'
);

select ok(not has_table_privilege('anon', 'public.customers', 'SELECT'), 'anon cannot select customers');
select ok(not has_table_privilege('anon', 'public.transactions', 'INSERT'), 'anon cannot insert transactions');
select ok(not has_table_privilege('authenticated', 'public.workspace_members', 'INSERT'), 'authenticated cannot directly insert membership');
select ok(not has_table_privilege('authenticated', 'public.workspace_creation_grants', 'SELECT'), 'authenticated cannot read creation grants');

select is(
  (select count(*)::integer from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'private' and p.proname = any(array['is_workspace_member','create_workspace','accept_invite'])
     and p.prosecdef),
  3, 'three required functions are security definer'
);
select ok(
  (select p.provolatile = 's' and coalesce(array_to_string(p.proconfig, ','), '') like '%search_path=%'
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'private' and p.proname = 'is_workspace_member'),
  'membership helper is stable with fixed search_path'
);
select ok(not has_function_privilege('anon', 'private.is_workspace_member(uuid)', 'EXECUTE'), 'anon cannot execute membership helper');
select ok(has_function_privilege('authenticated', 'private.is_workspace_member(uuid)', 'EXECUTE'), 'authenticated can execute membership helper');

select ok(
  (select 'security_invoker=true' = any(coalesce(c.reloptions, array[]::text[]))
   from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'account_workspace_financials'),
  'account aggregate view is security invoker'
);

select cmp_ok(
  (select count(*)::integer from pg_constraint con
   join pg_class rel on rel.oid = con.conrelid
   join pg_namespace n on n.oid = rel.relnamespace
   where n.nspname = 'public' and con.contype = 'f' and cardinality(con.conkey) = 2),
  '>=', 8, 'at least eight composite foreign keys enforce workspace integrity'
);

select is(
  (select count(*)::integer from information_schema.columns
   where table_schema = 'public' and column_name = 'assigned_member_id'),
  0, 'assigned_member_id is absent'
);
select is(
  (select count(*)::integer from information_schema.columns
   where table_schema = 'public' and column_name in
     ('default_price','deposit_amount','amount','unit_amount','line_amount')
     and data_type <> 'bigint'),
  0, 'all money source columns use bigint semantics'
);
select is(
  (select count(*)::integer from information_schema.columns
   where table_schema = 'public' and column_name = 'business_date' and data_type <> 'date'),
  0, 'business dates use date'
);
select is(
  (select count(*)::integer from information_schema.columns
   where table_schema = 'public' and column_name = 'start_time'
     and data_type not like 'time%'),
  0, 'appointment and availability start times use time'
);

select is(
  (select count(*)::integer from information_schema.triggers
   where trigger_schema = 'public' and trigger_name = 'protect_workspace_id'),
  16, 'workspace immutable trigger covers all scoped tables'
);
select ok(
  (select indexdef like 'CREATE UNIQUE INDEX%WHERE%'
   from pg_indexes where schemaname = 'public'
     and indexname = 'transactions_one_income_checkout_per_appointment_uidx'),
  'checkout invariant uses a partial unique index'
);
select is(
  (select data_type from information_schema.columns
   where table_schema = 'public' and table_name = 'workspace_invites' and column_name = 'token_hash'),
  'bytea', 'invite stores only a binary token hash'
);
select ok(
  not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workspace_invites'
      and column_name in ('token','raw_token')
  ), 'invite table has no raw token column'
);

select ok(
  (select not public and file_size_limit = 5242880
          and allowed_mime_types @> array['image/jpeg','image/png','image/webp']::text[]
   from storage.buckets where id = 'workspace-assets'),
  'workspace-assets bucket is private, 5 MiB, and image-only'
);
select is(
  (select count(*)::integer from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'workspace_assets_%'),
  4, 'storage objects have four workspace policies'
);

select throws_ok(
  $$insert into public.transactions (
      workspace_id, transaction_type, business_date, amount
    ) values ('20000000-0000-0000-0000-000000000001', 'EXPENSE', current_date, -1)$$,
  '23514', null, 'transaction amount cannot be negative'
);
select lives_ok(
  $$insert into public.transaction_items (
      workspace_id, transaction_id, item_type, name_snapshot, unit_amount, quantity, line_amount
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '60000000-0000-0000-0000-000000000002',
      'DISCOUNT', 'Fixture Discount', -100, 1, -100
    )$$,
  'transaction item line amount may be negative'
);

select ok(
  exists (
    select 1 from pg_indexes
    where schemaname = 'public' and tablename = 'legacy_id_maps'
      and indexdef like '%(migration_run_id, legacy_source_entity, legacy_source_id)%'
  ),
  'legacy mapping has rerun idempotency uniqueness'
);

select * from finish();
rollback;
