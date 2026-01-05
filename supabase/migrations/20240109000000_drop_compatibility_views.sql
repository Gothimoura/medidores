-- ============================================
-- REMOVER TODAS AS VIEWS
-- Data: 2024-01-09
-- Descrição: Remove TODAS as views do schema public
-- ============================================

DO $$
DECLARE
  r RECORD;
  total_views INT := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'REMOVENDO TODAS AS VIEWS';
  RAISE NOTICE '========================================';
  
  -- Remove TODAS as views do schema public
  FOR r IN (
    SELECT viewname
    FROM pg_views
    WHERE schemaname = 'public'
  ) LOOP
    BEGIN
      EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', r.schemaname, r.viewname);
      total_views := total_views + 1;
      RAISE NOTICE '✓ View removida: %', r.viewname;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '❌ Erro ao remover view %: %', r.viewname, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de views removidas: %', total_views;
  RAISE NOTICE '========================================';
END $$;

