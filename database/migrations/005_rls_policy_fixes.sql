-- 005: fix RLS policies that referenced nonexistent tables in 003
-- (003 referenced contacts_shared and user_rewards, which don't exist —
--  the real tables are contact_methods and rewards/reward_claims).
-- Every statement below is drop-then-create so this is safe to run
-- regardless of exactly where 003 stopped.

drop policy if exists "contacts_select" on contact_methods;
drop policy if exists "contacts_insert" on contact_methods;
create policy "contacts_select" on contact_methods for select to authenticated using (true);
create policy "contacts_insert" on contact_methods for insert to authenticated with check (user_id = auth.uid());
create policy "contacts_update" on contact_methods for update to authenticated using (user_id = auth.uid());

drop policy if exists "rewards_select" on rewards;
create policy "rewards_select" on rewards for select to authenticated using (true);

drop policy if exists "reward_claims_select" on reward_claims;
drop policy if exists "reward_claims_insert" on reward_claims;
create policy "reward_claims_select" on reward_claims for select to authenticated using (user_id = auth.uid());
create policy "reward_claims_insert" on reward_claims for insert to authenticated with check (user_id = auth.uid());

-- re-assert in case 003 stopped before these
drop policy if exists "peeks_select" on peek_invites;
drop policy if exists "peeks_insert" on peek_invites;
drop policy if exists "peeks_update" on peek_invites;
create policy "peeks_select" on peek_invites for select to authenticated using (sender_id = auth.uid() or peeker_id = auth.uid());
create policy "peeks_insert" on peek_invites for insert to authenticated with check (sender_id = auth.uid());
create policy "peeks_update" on peek_invites for update to authenticated using (peeker_id = auth.uid());

drop policy if exists "locations_select" on locations;
create policy "locations_select" on locations for select to authenticated using (true);

drop policy if exists "features_select" on feature_unlocks;
create policy "features_select" on feature_unlocks for select to authenticated using (true);

drop policy if exists "field_defs_select" on profile_field_definitions;
create policy "field_defs_select" on profile_field_definitions for select to authenticated using (true);
