-- 012_messaging.sql
create table conversations (
  id uuid primary key default uuid_generate_v4(),
  is_group boolean not null default false,
  name text,
  created_by uuid references profiles(id) on delete cascade,
  created_at timestamptz default now()
);

create table conversation_participants (
  conversation_id uuid references conversations(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'rejected')) default 'accepted',
  joined_at timestamptz default now(),
  primary key (conversation_id, user_id)
);

create table messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id uuid references conversations(id) on delete cascade,
  sender_id uuid references profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz default now()
);

alter table conversations enable row level security;
alter table conversation_participants enable row level security;
alter table messages enable row level security;

create policy conversations_select on conversations for select
  using (exists (
    select 1 from conversation_participants cp
    where cp.conversation_id = conversations.id and cp.user_id = auth.uid()
  ));

create policy conversations_insert on conversations for insert
  with check (created_by = auth.uid());

create policy participants_select on conversation_participants for select
  using (exists (
    select 1 from conversation_participants cp2
    where cp2.conversation_id = conversation_participants.conversation_id and cp2.user_id = auth.uid()
  ));

create policy participants_insert on conversation_participants for insert
  with check (exists (
    select 1 from conversations c
    where c.id = conversation_participants.conversation_id and c.created_by = auth.uid()
  ) or user_id = auth.uid());

create policy participants_update_own on conversation_participants for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy messages_select on messages for select
  using (exists (
    select 1 from conversation_participants cp
    where cp.conversation_id = messages.conversation_id and cp.user_id = auth.uid()
  ));

create policy messages_insert on messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from conversation_participants cp
      where cp.conversation_id = messages.conversation_id
        and cp.user_id = auth.uid()
        and cp.status = 'accepted'
    )
  );
