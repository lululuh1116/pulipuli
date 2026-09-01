begin;
select plan(18);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated","email":"account-a@pulipuli.example.invalid"}';

select is((select count(*)::integer from public.workspaces), 2, 'Account A reads both active workspaces');
select is((select count(*)::integer from public.customers), 3, 'Account A reads only A1 and A2 customers');

select lives_ok(
  $$insert into public.customers (id, workspace_id, display_name)
    values ('30000000-0000-0000-0000-000000000011', '20000000-0000-0000-0000-000000000001', 'Fixture Positive A')$$,
  'Account A inserts an A1 customer'
);
select lives_ok(
  $$update public.customers set notes = 'fixture update'
    where id = '30000000-0000-0000-0000-000000000011'$$,
  'Account A updates an A1 customer'
);
select lives_ok(
  $$update public.customers set deleted_at = now()
    where id = '30000000-0000-0000-0000-000000000011'$$,
  'Account A soft-deletes an A1 customer'
);

select lives_ok(
  $$insert into public.appointments (
      id, workspace_id, customer_id, business_date, start_time, status, deposit_amount
    ) values (
      '50000000-0000-0000-0000-000000000011',
      '20000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000002',
      date '2026-09-10', time '15:00', 'BOOKED', 0
    )$$,
  'Account A creates an A1 appointment'
);
select lives_ok(
  $$insert into public.transactions (
      id, workspace_id, transaction_type, business_date, customer_id, amount, note
    ) values (
      '60000000-0000-0000-0000-000000000011',
      '20000000-0000-0000-0000-000000000001',
      'INCOME', date '2026-09-10',
      '30000000-0000-0000-0000-000000000002', 1200, 'Fixture positive transaction'
    )$$,
  'Account A creates an A1 transaction'
);

select is((select count(*)::integer from public.account_workspace_financials), 2, 'Account A aggregate has two workspace rows');
select is((select revenue from public.account_workspace_financials where workspace_id = '20000000-0000-0000-0000-000000000001'), 4200::bigint, 'Account A1 revenue aggregates current visible transactions');
select is((select expense from public.account_workspace_financials where workspace_id = '20000000-0000-0000-0000-000000000001'), 1000::bigint, 'Account A1 expense aggregates correctly');
select is((select net from public.account_workspace_financials where workspace_id = '20000000-0000-0000-0000-000000000001'), 3200::bigint, 'Account A1 net aggregates correctly');
select is((select count(*)::integer from public.customers where workspace_id = '20000000-0000-0000-0000-000000000003'), 0, 'Account A cannot read B1 customers');

set local "request.jwt.claims" = '{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated","email":"account-b@pulipuli.example.invalid"}';

select is((select count(*)::integer from public.workspaces), 1, 'Account B reads B1');
select is((select count(*)::integer from public.customers), 1, 'Account B reads the B1 customer');
select lives_ok(
  $$insert into public.customers (id, workspace_id, display_name)
    values ('30000000-0000-0000-0000-000000000012', '20000000-0000-0000-0000-000000000003', 'Fixture Positive B')$$,
  'Account B inserts a B1 customer'
);
select lives_ok(
  $$update public.customers set notes = 'fixture B update'
    where id = '30000000-0000-0000-0000-000000000012'$$,
  'Account B updates a B1 customer'
);
select lives_ok(
  $$delete from public.customers
    where id = '30000000-0000-0000-0000-000000000012'$$,
  'Account B deletes its own fixture customer'
);
select is((select count(*)::integer from public.profiles), 1, 'Account B reads only its own profile');

select * from finish();
rollback;
