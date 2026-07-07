-- RLS Policies for WAP
-- Run in Supabase SQL Editor after 001_initial_schema.sql and 002_seed_data.sql

-- profiles: anyone authenticated can read; only owner can write
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated USING (id = auth.uid());

-- location_checkins
CREATE POLICY "checkins_select" ON location_checkins FOR SELECT TO authenticated USING (true);
CREATE POLICY "checkins_insert" ON location_checkins FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "checkins_delete" ON location_checkins FOR DELETE TO authenticated USING (user_id = auth.uid());

-- feed_posts
CREATE POLICY "posts_select" ON feed_posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "posts_insert" ON feed_posts FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "posts_update" ON feed_posts FOR UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "posts_delete" ON feed_posts FOR DELETE TO authenticated USING (user_id = auth.uid());

-- contacts_shared
CREATE POLICY "contacts_select" ON contacts_shared FOR SELECT TO authenticated USING (from_user_id = auth.uid() OR to_user_id = auth.uid());
CREATE POLICY "contacts_insert" ON contacts_shared FOR INSERT TO authenticated WITH CHECK (from_user_id = auth.uid());

-- peek_invites
CREATE POLICY "peeks_select" ON peek_invites FOR SELECT TO authenticated USING (from_user_id = auth.uid() OR to_user_id = auth.uid());
CREATE POLICY "peeks_insert" ON peek_invites FOR INSERT TO authenticated WITH CHECK (from_user_id = auth.uid());
CREATE POLICY "peeks_update" ON peek_invites FOR UPDATE TO authenticated USING (to_user_id = auth.uid());

-- read-only reference tables
CREATE POLICY "locations_select" ON locations FOR SELECT TO authenticated USING (true);
CREATE POLICY "features_select" ON feature_unlocks FOR SELECT TO authenticated USING (true);
CREATE POLICY "field_defs_select" ON profile_field_definitions FOR SELECT TO authenticated USING (true);

-- user_rewards
CREATE POLICY "rewards_select" ON user_rewards FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "rewards_insert" ON user_rewards FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "rewards_update" ON user_rewards FOR UPDATE TO authenticated USING (user_id = auth.uid());
