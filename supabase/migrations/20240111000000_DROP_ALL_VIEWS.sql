-- ============================================
-- REMOVER TODAS AS VIEWS DO BANCO
-- Data: 2024-01-11
-- Descrição: Remove TODAS as views do schema public
-- ============================================

DO $$
DECLARE
  r RECORD;
  total_removidas INT := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'REMOVENDO TODAS AS VIEWS';
  RAISE NOTICE '========================================';
  
  -- Lista e remove TODAS as views do schema public
  FOR r IN (
    SELECT schemaname, viewname
    FROM pg_views
    WHERE schemaname = 'public'
    ORDER BY viewname
  ) LOOP
    BEGIN
      EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', r.schemaname, r.viewname);
      total_removidas := total_removidas + 1;
      RAISE NOTICE '✓ View removida: %', r.viewname;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '❌ Erro ao remover view %: %', r.viewname, SQLERRM;
    END;
  END LOOP;
  
  -- Também remove de information_schema.views (caso tenha alguma)
  FOR r IN (
    SELECT table_schema, table_name
    FROM information_schema.views
    WHERE table_schema = 'public'
  ) LOOP
    BEGIN
      -- Verifica se já foi removida
      IF EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = r.table_schema 
        AND viewname = r.table_name
      ) THEN
        EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', r.table_schema, r.table_name);
        total_removidas := total_removidas + 1;
        RAISE NOTICE '✓ View removida (information_schema): %', r.table_name;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '❌ Erro ao remover view %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de views removidas: %', total_removidas;
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  r RECORD;
  total_views INT;
BEGIN
  SELECT COUNT(*) INTO total_views
  FROM pg_views
  WHERE schemaname = 'public';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICAÇÃO FINAL';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Views restantes no schema public: %', total_views;
  
  IF total_views > 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '⚠ ATENÇÃO: Ainda existem % views!', total_views;
    RAISE NOTICE 'Listando views restantes:';
    FOR r IN (
      SELECT viewname FROM pg_views WHERE schemaname = 'public' ORDER BY viewname
    ) LOOP
      RAISE NOTICE '  - %', r.viewname;
    END LOOP;
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '✅ SUCESSO! Todas as views foram removidas!';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

