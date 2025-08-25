-- Supabase setup SQL
-- Run this in the Supabase SQL editor (or via psql) to create required tables.

-- 1) Create storage bucket (run in Storage UI) named: driver-photos
-- 2) Create tables

create table if not exists public.checkins (
  id bigserial primary key,
  serial integer not null,
  timestamp timestamptz not null,
  lat text,
  lon text,
  before_path text,
  after_path text
);

create table if not exists public.managers (
  id bigserial primary key,
  username text unique not null,
  password text not null,
  full_name text,
  email text,
  phone text,
  role text default 'driver' check (role in ('driver', 'admin')),
  department text,
  join_date date default CURRENT_DATE,
  last_login timestamptz,
  total_actions integer default 0,
  active_sessions integer default 0,
  profile_image text,
  is_suspended boolean default false,
  created_at timestamptz default now()
);

-- Enable RLS for the managers table
alter table public.managers enable row level security;

-- Allow authenticated users to manage managers
create policy "Allow authenticated users to manage managers"
on public.managers
for all
to authenticated
using (true);

-- Allow anonymous users to insert managers (for user registration)
create policy "Allow anonymous insert on managers"
on public.managers
for insert
to anon
with check (true);

-- Allow anonymous users to read managers (for login)
create policy "Allow anonymous read on managers"
on public.managers
for select
to anon
using (true);

-- Allow anonymous users to update managers (for login tracking)
create policy "Allow anonymous update on managers"
on public.managers
for update
to anon
using (true);

-- Optional: insert admin (you can also let the app insert)
insert into public.managers (username, password)
values ('admin', 'admin123')
on conflict (username) do update set password = excluded.password;

-- Cars table and assignments
create table if not exists public.cars (
  id bigserial primary key,
  plate text not null,
  model text,
  notes text
);

-- Enable RLS for the cars table
alter table public.cars enable row level security;

-- Allow authenticated users to manage cars
create policy "Allow authenticated users to manage cars"
on public.cars
for all
to authenticated
using (true);

-- Allow anonymous users to read cars (for dropdown functionality)
create policy "Allow anonymous read on cars"
on public.cars
for select
to anon
using (true);

-- Allow anonymous users to insert cars (for test data)
create policy "Allow anonymous insert on cars"
on public.cars
for insert
to anon
with check (true);

create table if not exists public.car_drivers (
  id bigserial primary key,
  car_id bigint references public.cars(id) on delete cascade,
  driver_username text not null,
  created_at timestamptz default now()
);

-- Enable RLS for the car_drivers table
alter table public.car_drivers enable row level security;

-- Allow authenticated users to manage car_drivers
create policy "Allow authenticated users to manage car_drivers"
on public.car_drivers
for all
to authenticated
using (true);

-- Allow anonymous users to insert car_drivers (for app functionality)
create policy "Allow anonymous insert on car_drivers"
on public.car_drivers
for insert
to anon
with check (true);

-- Allow anonymous users to read car_drivers
create policy "Allow anonymous read on car_drivers"
on public.car_drivers
for select
to anon
using (true);

-- sample cars
insert into public.cars (plate, model, notes) values
('ABC-123', 'Toyota Hiace', 'حافلة رقم 1'),
('XYZ-999', 'Nissan NV200', 'سيارة صغيرة');

-- sample assignments (map demo drivers to cars)
insert into public.car_drivers (car_id, driver_username) values
(1, 'driver1'),
(1, 'driver2'),
(2, 'driver3')
on conflict do nothing;