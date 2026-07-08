-- 008: user_feature_access has RLS enabled (001) but no SELECT policy was
-- ever added, so WAPData.hasFeatureAccess() would silently always return
-- false once Phase 5 calls it. Found during Phase 1's final review.

drop policy if exists "user_feature_access_select" on user_feature_access;
create policy "user_feature_access_select" on user_feature_access for select to authenticated using (user_id = auth.uid());
