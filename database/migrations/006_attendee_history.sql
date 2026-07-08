-- 006: attendee history feature — flag system + opt-outs
alter table locations add column city text;

create table feature_flags (
  feature_name text primary key,
  default_enabled boolean not null default false,
  description text
);
alter table feature_flags enable row level security;
create policy "feature_flags_select" on feature_flags for select to authenticated using (true);

create table feature_flag_overrides (
  id uuid primary key default uuid_generate_v4(),
  feature_name text references feature_flags(feature_name) not null,
  scope_type text check (scope_type in ('city', 'location', 'user')) not null,
  scope_value text not null,
  enabled boolean not null,
  set_by uuid references profiles(id),
  set_at timestamptz default now(),
  unique(feature_name, scope_type, scope_value)
);
alter table feature_flag_overrides enable row level security;
create policy "feature_flag_overrides_select" on feature_flag_overrides for select to authenticated using (true);

create table attendee_history_opt_outs (
  user_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, location_id)
);
alter table attendee_history_opt_outs enable row level security;
create policy "opt_outs_select" on attendee_history_opt_outs for select to authenticated using (true);
create policy "opt_outs_insert" on attendee_history_opt_outs for insert to authenticated with check (user_id = auth.uid());
create policy "opt_outs_delete" on attendee_history_opt_outs for delete to authenticated using (user_id = auth.uid());

insert into feature_flags (feature_name, default_enabled, description) values
  ('attendee_history_view', false, 'View a venue''s all-time attendee roster'),
  ('attendee_history_hide_self', true, 'Allow a user to opt out of a venue''s attendee roster');
