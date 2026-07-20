-- 013_fix_participants_select_recursion.sql
-- participants_select's USING clause queried conversation_participants from
-- within a policy defined on conversation_participants itself, which
-- Postgres re-evaluates recursively on every row check ("infinite recursion
-- detected in policy for relation conversation_participants", 42P17).
-- Move the same membership check into a security definer function so the
-- inner lookup runs without re-triggering RLS on the same table (same
-- pattern already used by is_conversation_creator in 012_messaging.sql).

drop policy if exists participants_select on conversation_participants;

create or replace function is_conversation_participant(target_conversation_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from conversation_participants cp
    where cp.conversation_id = target_conversation_id and cp.user_id = auth.uid()
  );
$$;

create policy participants_select on conversation_participants for select
  using (is_conversation_participant(conversation_participants.conversation_id));
