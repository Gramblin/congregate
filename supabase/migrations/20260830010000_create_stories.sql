-- Stories: ephemeral posts (default 24h TTL) authored by a community (group) or business.
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  author_type text not null check (author_type in ('community', 'business')),
  group_id uuid references public.groups(id) on delete cascade,
  business_id uuid references public.businesses(id) on delete cascade,
  author_name text not null,
  media_url text not null,
  caption text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  constraint stories_author_ref check (
    (author_type = 'community' and group_id is not null and business_id is null)
    or (author_type = 'business' and business_id is not null and group_id is null)
  ),
  constraint stories_ttl_max check (expires_at <= created_at + interval '24 hours')
);

create index if not exists stories_active_idx on public.stories (expires_at);
create index if not exists stories_group_idx on public.stories (group_id);
create index if not exists stories_business_idx on public.stories (business_id);

alter table public.stories enable row level security;

-- Public: read stories that have not yet expired.
drop policy if exists "stories_public_read" on public.stories;
create policy "stories_public_read"
  on public.stories
  for select
  using (expires_at > now());

-- Owner insert: community stories require group ownership; business stories require business ownership.
drop policy if exists "stories_owner_insert" on public.stories;
create policy "stories_owner_insert"
  on public.stories
  for insert
  with check (
    (author_type = 'community' and group_id in (
      select id from public.groups where created_by = auth.uid()
    ))
    or (author_type = 'business' and business_id in (
      select id from public.businesses where owner_id = auth.uid()
    ))
  );

-- Owner delete.
drop policy if exists "stories_owner_delete" on public.stories;
create policy "stories_owner_delete"
  on public.stories
  for delete
  using (
    (author_type = 'community' and group_id in (
      select id from public.groups where created_by = auth.uid()
    ))
    or (author_type = 'business' and business_id in (
      select id from public.businesses where owner_id = auth.uid()
    ))
  );

-- Storage bucket for story media.
insert into storage.buckets (id, name, public)
values ('story-media', 'story-media', true)
on conflict (id) do nothing;

drop policy if exists "story_media_public_read" on storage.objects;
create policy "story_media_public_read"
  on storage.objects
  for select
  using (bucket_id = 'story-media');

drop policy if exists "story_media_owner_write" on storage.objects;
create policy "story_media_owner_write"
  on storage.objects
  for insert
  with check (
    bucket_id = 'story-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "story_media_owner_delete" on storage.objects;
create policy "story_media_owner_delete"
  on storage.objects
  for delete
  using (
    bucket_id = 'story-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

notify pgrst, 'reload schema';
