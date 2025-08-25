-- RLS Policy Fix for rwaad_app
-- Run this script in Supabase SQL Editor to fix Row Level Security policies

-- Fix for managers table
DROP POLICY IF EXISTS "Allow anonymous insert on managers" ON public.managers;
DROP POLICY IF EXISTS "Allow anonymous read on managers" ON public.managers;
DROP POLICY IF EXISTS "Allow anonymous update on managers" ON public.managers;
DROP POLICY IF EXISTS "Allow authenticated users to manage managers" ON public.managers;

CREATE POLICY "Allow anonymous insert on managers"
ON public.managers
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anonymous read on managers"
ON public.managers
FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anonymous update on managers"
ON public.managers
FOR UPDATE
TO anon
USING (true);

CREATE POLICY "Allow authenticated users to manage managers"
ON public.managers
FOR ALL
TO authenticated
USING (true);

-- Fix for cars table
DROP POLICY IF EXISTS "Allow anonymous read on cars" ON public.cars;
DROP POLICY IF EXISTS "Allow anonymous insert on cars" ON public.cars;
DROP POLICY IF EXISTS "Allow authenticated users to manage cars" ON public.cars;

CREATE POLICY "Allow anonymous read on cars"
ON public.cars
FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anonymous insert on cars"
ON public.cars
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to manage cars"
ON public.cars
FOR ALL
TO authenticated
USING (true);

-- Fix for car_drivers table (THIS IS THE MAIN ISSUE)
DROP POLICY IF EXISTS "Allow anonymous insert on car_drivers" ON public.car_drivers;
DROP POLICY IF EXISTS "Allow anonymous read on car_drivers" ON public.car_drivers;
DROP POLICY IF EXISTS "Allow authenticated users to manage car_drivers" ON public.car_drivers;

CREATE POLICY "Allow anonymous insert on car_drivers"
ON public.car_drivers
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anonymous read on car_drivers"
ON public.car_drivers
FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anonymous update on car_drivers"
ON public.car_drivers
FOR UPDATE
TO anon
USING (true);

CREATE POLICY "Allow anonymous delete on car_drivers"
ON public.car_drivers
FOR DELETE
TO anon
USING (true);

CREATE POLICY "Allow authenticated users to manage car_drivers"
ON public.car_drivers
FOR ALL
TO authenticated
USING (true);

-- Ensure RLS is enabled on all tables
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_drivers ENABLE ROW LEVEL SECURITY;

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('managers', 'cars', 'car_drivers')
ORDER BY tablename, policyname;