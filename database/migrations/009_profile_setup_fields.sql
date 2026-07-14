-- Migration 009: Add profile setup wizard fields to profiles table
-- Adds: height, nationality, relationship, dating/socialising/networking preferences

alter table profiles
  add column if not exists height numeric(4,2),
  add column if not exists nationality text,
  add column if not exists relationship text,
  add column if not exists dating_id int,
  add column if not exists socialising_id int,
  add column if not exists networking_id int;
