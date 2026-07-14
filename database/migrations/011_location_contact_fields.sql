-- Migration 011: Add venue contact/messaging fields to locations table

alter table locations
  add column if not exists whatsapp text,
  add column if not exists default_message text;
