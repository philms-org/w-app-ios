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

-- Runs with the privileges of its owner (the migration-running role) rather
-- than the calling role's, so this lookup isn't itself gated by
-- conversations_select below it — otherwise participants_insert could never
-- see a conversation the caller just created (no conversation_participants
-- row exists yet for them at that exact point, which is precisely what this
-- insert is trying to create) and every startConversation call would fail.
create or replace function is_conversation_creator(target_conversation_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from conversations c
    where c.id = target_conversation_id and c.created_by = auth.uid()
  );
$$;

-- Only the conversation's creator may insert participant rows (matches
-- WAPData.startConversation, which always inserts the full participant
-- batch — creator plus every recipient — as the creator, in one call).
-- The prior "or user_id = auth.uid()" branch let any authenticated user
-- self-insert a participant row into ANY conversation_id, invited or not.
create policy participants_insert on conversation_participants for insert
  with check (is_conversation_creator(conversation_participants.conversation_id));

create policy participants_update_own on conversation_participants for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- participants_update_own's WITH CHECK only re-validates the NEW row's
-- user_id; it never confirms conversation_id is unchanged, so a user could
-- UPDATE their own existing participant row's conversation_id to any other
-- conversation's UUID and self-grant membership somewhere they were never
-- invited (bounded only by UUID unguessability, not by RLS). Lock both key
-- columns immutable on update — respondToConversationRequest only ever
-- updates status, so this changes nothing for the real app.
create or replace function conversation_participants_lock_identity()
returns trigger
language plpgsql
as $$
begin
  if new.conversation_id <> old.conversation_id or new.user_id <> old.user_id then
    raise exception 'conversation_participants: conversation_id and user_id cannot be changed';
  end if;
  return new;
end;
$$;

create trigger conversation_participants_lock_identity_trigger
  before update on conversation_participants
  for each row execute function conversation_participants_lock_identity();

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
