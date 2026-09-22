-- Ads table: banner + html body used by the businesses screen carousel.
create table if not exists public.ads (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete cascade,
  title text not null,
  banner_image_url text not null,
  html_content text not null,
  link_url text,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ads_active_idx on public.ads (is_active, sort_order);
create index if not exists ads_business_idx on public.ads (business_id);

alter table public.ads enable row level security;

-- Public: read active ads within their active window.
drop policy if exists "ads_public_read" on public.ads;
create policy "ads_public_read"
  on public.ads
  for select
  using (
    is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

-- Owner: read all of their own ads (including inactive/scheduled).
drop policy if exists "ads_owner_read" on public.ads;
create policy "ads_owner_read"
  on public.ads
  for select
  using (
    business_id in (
      select id from public.businesses where owner_id = auth.uid()
    )
  );

-- Owner: insert ads for businesses they own.
drop policy if exists "ads_owner_insert" on public.ads;
create policy "ads_owner_insert"
  on public.ads
  for insert
  with check (
    business_id in (
      select id from public.businesses where owner_id = auth.uid()
    )
  );

-- Owner: update their own ads.
drop policy if exists "ads_owner_update" on public.ads;
create policy "ads_owner_update"
  on public.ads
  for update
  using (
    business_id in (
      select id from public.businesses where owner_id = auth.uid()
    )
  )
  with check (
    business_id in (
      select id from public.businesses where owner_id = auth.uid()
    )
  );

-- Owner: delete their own ads.
drop policy if exists "ads_owner_delete" on public.ads;
create policy "ads_owner_delete"
  on public.ads
  for delete
  using (
    business_id in (
      select id from public.businesses where owner_id = auth.uid()
    )
  );

-- Storage bucket for ad banners.
insert into storage.buckets (id, name, public)
values ('ad-banners', 'ad-banners', true)
on conflict (id) do nothing;

drop policy if exists "ad_banners_public_read" on storage.objects;
create policy "ad_banners_public_read"
  on storage.objects
  for select
  using (bucket_id = 'ad-banners');

drop policy if exists "ad_banners_owner_write" on storage.objects;
create policy "ad_banners_owner_write"
  on storage.objects
  for insert
  with check (
    bucket_id = 'ad-banners'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "ad_banners_owner_update" on storage.objects;
create policy "ad_banners_owner_update"
  on storage.objects
  for update
  using (
    bucket_id = 'ad-banners'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "ad_banners_owner_delete" on storage.objects;
create policy "ad_banners_owner_delete"
  on storage.objects
  for delete
  using (
    bucket_id = 'ad-banners'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
