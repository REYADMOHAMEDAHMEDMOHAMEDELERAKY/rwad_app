-- Quick Fix: Disable RLS for Testing
-- Run this in Supabase SQL Editor for immediate resolution

-- Disable RLS on all tables (TEMPORARY SOLUTION for testing)
ALTER TABLE public.managers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.cars DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_drivers DISABLE ROW LEVEL SECURITY;

-- Check current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('managers', 'cars', 'car_drivers');

-- If you prefer to keep RLS enabled but with permissive policies:
-- Uncomment the following lines and comment out the DISABLE commands above

/*
-- Re-enable RLS with permissive policies
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_drivers ENABLE ROW LEVEL SECURITY;

-- Create very permissive policies for all operations
CREATE POLICY "Allow all operations" ON public.managers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations" ON public.cars FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations" ON public.car_drivers FOR ALL USING (true) WITH CHECK (true);
*/