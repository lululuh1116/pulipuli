-- Local-only anonymized Phase 6B fixtures. No production or legacy customer data.
insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'account-a@pulipuli.example.invalid', extensions.crypt('LocalOnly-A1!', extensions.gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('10000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'account-b@pulipuli.example.invalid', extensions.crypt('LocalOnly-B1!', extensions.gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}', '{}', now(), now())
on conflict (id) do nothing;

insert into public.profiles (id, display_name) values
  ('10000000-0000-0000-0000-000000000001', 'Fixture Account A'),
  ('10000000-0000-0000-0000-000000000002', 'Fixture Account B');
insert into public.account_preferences (account_id) values
  ('10000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000002');

insert into public.workspace_creation_grants (id, account_id, email, max_workspaces) values
  ('11000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'account-a@pulipuli.example.invalid', 3),
  ('11000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'account-b@pulipuli.example.invalid', 3);

insert into public.workspaces (id, name, created_by_account_id) values
  ('20000000-0000-0000-0000-000000000001', 'Fixture Workspace A1', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 'Fixture Workspace A2', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000003', 'Fixture Workspace B1', '10000000-0000-0000-0000-000000000002');
insert into public.workspace_members (id, workspace_id, account_id, role) values
  ('21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'OWNER'),
  ('21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'OWNER'),
  ('21000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 'OWNER');
insert into public.workspace_settings (workspace_id) values
  ('20000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002'),
  ('20000000-0000-0000-0000-000000000003');
insert into public.workspace_themes (workspace_id, theme_key, color_tokens, card_alpha) values
  ('20000000-0000-0000-0000-000000000001', 'fixture-a1', '{"accent":"#6b7280"}', 0.900),
  ('20000000-0000-0000-0000-000000000002', 'fixture-a2', '{"accent":"#64748b"}', 0.900),
  ('20000000-0000-0000-0000-000000000003', 'fixture-b1', '{"accent":"#78716c"}', 0.900);

insert into public.customers (id, workspace_id, display_name, email) values
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Fixture Customer A1 One', 'customer-a1-one@example.invalid'),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'Fixture Customer A1 Two', null),
  ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', 'Fixture Customer A2 One', null),
  ('30000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000003', 'Fixture Customer B1 One', 'customer-b1-one@example.invalid');

insert into public.services (id, workspace_id, name, service_type, default_price, sort_order) values
  ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Fixture Base A1', 'BASE', 3000, 1),
  ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Fixture Addon A2', 'ADDON', 800, 1),
  ('40000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', 'Fixture Base B1', 'BASE', 2500, 1);

insert into public.appointments (
  id, workspace_id, customer_id, business_date, start_time, status, deposit_amount
) values
  ('50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', date '2026-09-01', time '10:00', 'COMPLETED', 500),
  ('50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', date '2026-09-02', time '11:00', 'BOOKED', 0),
  ('50000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000004', date '2026-09-03', time '14:00', 'COMPLETED', 0);
insert into public.appointment_services (
  id, workspace_id, appointment_id, service_id, service_name_snapshot, quoted_price_snapshot
) values
  ('51000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Fixture Base A1 Snapshot', 3000),
  ('51000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000003', '40000000-0000-0000-0000-000000000003', 'Fixture Base B1 Snapshot', 2500);

insert into public.expense_categories (id, workspace_id, name) values
  ('70000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Fixture Supplies A1'),
  ('70000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', 'Fixture Supplies B1');
insert into public.transactions (
  id, workspace_id, transaction_type, business_date, customer_id, appointment_id, amount, category_id, note
) values
  ('60000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'INCOME', date '2026-09-01', '30000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 3000, null, 'Fixture income A1'),
  ('60000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'EXPENSE', date '2026-09-01', null, null, 1000, '70000000-0000-0000-0000-000000000001', 'Fixture expense A1'),
  ('60000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', 'INCOME', date '2026-09-03', '30000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000003', 2500, null, 'Fixture income B1');
insert into public.transaction_items (
  id, workspace_id, transaction_id, service_id, item_type, name_snapshot, unit_amount, quantity, line_amount
) values
  ('61000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'SERVICE', 'Fixture Base A1 Snapshot', 3000, 1, 3000),
  ('61000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000003', '40000000-0000-0000-0000-000000000003', 'SERVICE', 'Fixture Base B1 Snapshot', 2500, 1, 2500);

insert into public.availability_templates (id, workspace_id, weekday, start_time) values
  ('80000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 1, time '10:00'),
  ('80000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', 2, time '14:00');
insert into public.availability_overrides (id, workspace_id, business_date, override_type) values
  ('81000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', date '2026-09-07', 'CLOSED'),
  ('81000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', date '2026-09-08', 'CLOSED');

insert into public.migration_runs (id, workspace_id, source_key, status, started_at, completed_at) values
  ('90000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'fixture-source-v1', 'COMPLETED', now(), now());
insert into public.legacy_id_maps (
  id, workspace_id, migration_run_id, legacy_source_entity, legacy_source_id, v2_entity_type, v2_entity_id
) values
  ('91000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001', 'fixture_customer', 'fixture-legacy-1', 'customer', '30000000-0000-0000-0000-000000000001');

insert into public.workspace_invites (
  id, workspace_id, target_email, token_hash, role, status, expires_at, created_by_account_id
) values (
  '22000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'account-b@pulipuli.example.invalid',
  extensions.digest('fixture-invite-b-to-a1', 'sha256'),
  'OWNER', 'PENDING', now() + interval '7 days',
  '10000000-0000-0000-0000-000000000001'
);
