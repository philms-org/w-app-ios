-- Migration 010: Add event and description fields to locations table

alter table locations
  add column if not exists description text,
  add column if not exists event_end_date timestamptz,
  add column if not exists event_status text not null default 'Active';
