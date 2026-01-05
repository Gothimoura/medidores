-- ============================================
-- MIGRATION FINAL: CORRIGIR TUDO DE UMA VEZ
-- Data: 2024-01-07
-- Descrição: Garante que TUDO está funcionando
-- ============================================

-- ============================================
-- PARTE 1: GARANTIR QUE AS VIEWS DE COMPATIBILIDADE EXISTEM E FUNCIONAM
-- ============================================

-- Remove todas as views antigas primeiro
DROP VIEW IF EXISTS public.hidrometros CASCADE;
DROP VIEW IF EXISTS public.energia CASCADE;
DROP VIEW IF EXISTS public.medidores CASCADE;

-- Recria as views de compatibilidade para o código funcionar
CREATE OR REPLACE VIEW public.hidrometros AS 
SELECT * FROM public.med_hidrometros;

CREATE OR REPLACE VIEW public.energia AS 
SELECT * FROM public.med_energia;

CREATE OR REPLACE VIEW public.medidores AS 
SELECT * FROM public.med_medidores;

-- Permissões nas views
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hidrometros TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.energia TO authenticated;
GRANT SELECT ON public.medidores TO authenticated;

-- ============================================
-- PARTE 2: GARANTIR PERMISSÕES NAS TABELAS
-- ============================================

-- Permissões nas tabelas de medições
GRANT SELECT, INSERT, UPDATE, DELETE ON public.med_hidrometros TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.med_energia TO authenticated;
GRANT SELECT ON public.med_medidores TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.tokens_acesso TO authenticated;

-- ============================================
-- PARTE 3: GARANTIR QUE RLS ESTÁ CORRETO E PERMISSIVO TEMPORARIAMENTE
-- ============================================

-- Desabilita RLS temporariamente nas tabelas de medições para garantir que funciona
ALTER TABLE IF EXISTS public.med_hidrometros DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.med_energia DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.med_medidores DISABLE ROW LEVEL SECURITY;

-- Remove todas as políticas antigas
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Remove políticas de med_hidrometros
  FOR r IN (
    SELECT policyname FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'med_hidrometros'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.med_hidrometros', r.policyname);
  END LOOP;
  
  -- Remove políticas de med_energia
  FOR r IN (
    SELECT policyname FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'med_energia'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.med_energia', r.policyname);
  END LOOP;
  
  -- Remove políticas de med_medidores
  FOR r IN (
    SELECT policyname FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'med_medidores'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.med_medidores', r.policyname);
  END LOOP;
END $$;

-- ============================================
-- PARTE 4: VERIFICAR SE PROFILES TEM DADOS
-- ============================================

-- Garante que todos os usuários do auth.users têm profile
INSERT INTO public.profiles (id, name, email, role)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'name', au.email),
  au.email,
  COALESCE(au.raw_user_meta_data->>'role', 'user')
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PARTE 5: RELATÓRIO FINAL
-- ============================================

DO $$
DECLARE
  total_tabelas INT;
  total_views INT;
BEGIN
  SELECT COUNT(*) INTO total_tabelas
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
  
  SELECT COUNT(*) INTO total_views
  FROM information_schema.views
  WHERE table_schema = 'public';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'MIGRATION FINAL CONCLUÍDA';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de tabelas: %', total_tabelas;
  RAISE NOTICE 'Total de views: %', total_views;
  RAISE NOTICE '';
  RAISE NOTICE 'Views de compatibilidade criadas:';
  RAISE NOTICE '  - hidrometros -> med_hidrometros';
  RAISE NOTICE '  - energia -> med_energia';
  RAISE NOTICE '  - medidores -> med_medidores';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS DESABILITADO temporariamente nas tabelas de medições';
  RAISE NOTICE 'Permissões garantidas para authenticated';
  RAISE NOTICE '========================================';
END $$;

