REVOKE INSERT, UPDATE ON TABLE public.users FROM PUBLIC, anon, authenticated;
REVOKE INSERT (user_type, is_active), UPDATE (user_type, is_active) ON TABLE public.users FROM PUBLIC, anon, authenticated;
DO $$ BEGIN
  IF has_table_privilege('authenticated','public.users','INSERT')
     OR has_table_privilege('authenticated','public.users','UPDATE')
     OR has_column_privilege('authenticated','public.users','user_type','INSERT')
     OR has_column_privilege('authenticated','public.users','user_type','UPDATE')
     OR has_column_privilege('authenticated','public.users','is_active','UPDATE') THEN
    RAISE EXCEPTION 'Profile privileges remain writable';
  END IF;
END $$;
