begin;
select plan(14);

select throws_ok(
  $$insert into public.appointments (
      workspace_id, customer_id, business_date, status, deposit_amount
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000004', current_date, 'BOOKED', 0
    )$$,
  '23503', null, 'A appointment cannot reference B customer'
);
select throws_ok(
  $$insert into public.appointment_services (
      workspace_id, appointment_id, service_id, service_name_snapshot, quoted_price_snapshot
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '50000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000003', 'Cross workspace', 1
    )$$,
  '23503', null, 'A appointment service cannot reference B service'
);
select throws_ok(
  $$insert into public.transactions (
      workspace_id, transaction_type, business_date, customer_id, amount
    ) values (
      '20000000-0000-0000-0000-000000000001', 'EXPENSE', current_date,
      '30000000-0000-0000-0000-000000000004', 1
    )$$,
  '23503', null, 'A transaction cannot reference B customer'
);
select throws_ok(
  $$insert into public.transactions (
      workspace_id, transaction_type, business_date, appointment_id, amount
    ) values (
      '20000000-0000-0000-0000-000000000001', 'EXPENSE', current_date,
      '50000000-0000-0000-0000-000000000003', 1
    )$$,
  '23503', null, 'A transaction cannot reference B appointment'
);
select throws_ok(
  $$insert into public.customer_merges (
      workspace_id, source_customer_id, target_customer_id, merged_by_account_id
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000004',
      '30000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001'
    )$$,
  '23503', null, 'A merge cannot use B source customer'
);
select throws_ok(
  $$insert into public.customer_merges (
      workspace_id, source_customer_id, target_customer_id, merged_by_account_id
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000004',
      '10000000-0000-0000-0000-000000000001'
    )$$,
  '23503', null, 'A merge cannot use B target customer'
);

select throws_ok(
  $$update public.customers set workspace_id = '20000000-0000-0000-0000-000000000003'
    where id = '30000000-0000-0000-0000-000000000001'$$,
  '23514', 'workspace_id is immutable', 'customer cannot move workspace'
);
select throws_ok(
  $$update public.appointments set workspace_id = '20000000-0000-0000-0000-000000000003'
    where id = '50000000-0000-0000-0000-000000000001'$$,
  '23514', 'workspace_id is immutable', 'appointment cannot move workspace'
);
select throws_ok(
  $$update public.transactions set workspace_id = '20000000-0000-0000-0000-000000000003'
    where id = '60000000-0000-0000-0000-000000000001'$$,
  '23514', 'workspace_id is immutable', 'transaction cannot move workspace'
);

select throws_ok(
  $$insert into public.transactions (
      workspace_id, transaction_type, business_date, appointment_id, amount
    ) values (
      '20000000-0000-0000-0000-000000000001', 'INCOME', current_date,
      '50000000-0000-0000-0000-000000000001', 1
    )$$,
  '23505', null, 'appointment allows only one active income checkout'
);
select throws_ok(
  $$insert into public.legacy_id_maps (
      workspace_id, migration_run_id, legacy_source_entity, legacy_source_id,
      v2_entity_type, v2_entity_id
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '90000000-0000-0000-0000-000000000001',
      'fixture_customer', 'fixture-legacy-1', 'customer', gen_random_uuid()
    )$$,
  '23505', null, 'legacy mapping rerun cannot duplicate a source entity id'
);

select lives_ok(
  $$insert into public.customers (workspace_id, display_name)
    values ('20000000-0000-0000-0000-000000000001', 'Fixture Customer A1 One')$$,
  'same workspace allows duplicate customer display names'
);
select lives_ok(
  $$update public.services set default_price = 9999
    where id = '40000000-0000-0000-0000-000000000001'$$,
  'current service price may change'
);
select is(
  (select quoted_price_snapshot from public.appointment_services
   where id = '51000000-0000-0000-0000-000000000001'),
  3000::bigint, 'historical appointment snapshot is not recalculated'
);

select * from finish();
rollback;
