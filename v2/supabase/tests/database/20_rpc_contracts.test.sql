begin;
select plan(11);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated","email":"account-a@pulipuli.example.invalid"}';

select ok(private.is_workspace_member('20000000-0000-0000-0000-000000000001'), 'membership helper accepts A1 for Account A');
select ok(not private.is_workspace_member('20000000-0000-0000-0000-000000000003'), 'membership helper rejects B1 for Account A');
select lives_ok($$select private.create_workspace('Fixture Workspace A3')$$, 'create_workspace atomically creates the third workspace');
select is(
  (select count(*)::integer from public.workspace_members where account_id = '10000000-0000-0000-0000-000000000001' and role = 'OWNER'),
  3, 'Account A owns exactly three workspaces after RPC'
);
select is(
  (select count(*)::integer from public.workspace_settings where workspace_id not in (
    '20000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002'
  )), 1, 'create_workspace creates settings atomically'
);
select throws_ok(
  $$select private.create_workspace('Fixture Workspace A4')$$,
  'P0001', 'Workspace limit reached', 'workspace creation is capped at three'
);

set local "request.jwt.claims" = '{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated","email":"account-b@pulipuli.example.invalid"}';

select is(
  private.accept_invite('fixture-invite-b-to-a1'),
  '20000000-0000-0000-0000-000000000001'::uuid,
  'accept_invite returns the invited workspace'
);
select ok(private.is_workspace_member('20000000-0000-0000-0000-000000000001'), 'accepted invite creates active membership');
select is(
  (select status::text from public.workspace_invites where id = '22000000-0000-0000-0000-000000000001'),
  'ACCEPTED', 'invite is atomically marked accepted'
);
select throws_ok(
  $$select private.accept_invite('fixture-invite-b-to-a1')$$,
  'P0001', 'Invite is invalid, expired, or already accepted', 'invite replay is rejected'
);
select throws_ok(
  $$insert into public.workspace_members (workspace_id, account_id, role)
    values ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'OWNER')$$,
  '42501', null, 'authenticated cannot directly insert membership'
);

select * from finish();
rollback;
