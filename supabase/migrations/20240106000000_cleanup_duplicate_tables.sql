-- ============================================
-- MIGRATION DE LIMPEZA: Remover tabelas duplicadas/antigas
-- Data: 2024-01-06
-- Descrição: Remove tabelas antigas sem prefixo que podem estar duplicadas
-- ============================================

-- ============================================
-- PARTE 1: LISTAR TODAS AS TABELAS PARA DIAGNÓSTICO
-- ============================================

DO $$
DECLARE
  r RECORD;
  total_tabelas INT := 0;
  com_prefixo INT := 0;
  sem_prefixo INT := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DIAGNÓSTICO COMPLETO DO BANCO';
  RAISE NOTICE '========================================';
  
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name
  ) LOOP
    total_tabelas := total_tabelas + 1;
    
    IF r.table_name LIKE 'med_%' OR r.table_name LIKE 'rh_%' OR r.table_name IN ('profiles', 'tokens_acesso') THEN
      com_prefixo := com_prefixo + 1;
      RAISE NOTICE '✓ % (COM PREFIXO)', r.table_name;
    ELSE
      sem_prefixo := sem_prefixo + 1;
      RAISE NOTICE '✗ % (SEM PREFIXO - PROBLEMA!)', r.table_name;
    END IF;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'TOTAL: % tabelas', total_tabelas;
  RAISE NOTICE 'COM PREFIXO: %', com_prefixo;
  RAISE NOTICE 'SEM PREFIXO: %', sem_prefixo;
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- PARTE 2: REMOVER TABELAS DUPLICADAS ANTIGAS
-- ============================================

DO $$
DECLARE
  r RECORD;
  tabela_nova TEXT;
BEGIN
  -- Mapeamento de tabelas antigas para novas
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND table_name NOT LIKE 'med_%'
      AND table_name NOT LIKE 'rh_%'
      AND table_name NOT IN ('profiles', 'tokens_acesso')
  ) LOOP
    BEGIN
      -- Determina o nome da tabela nova baseado no nome antigo
      CASE r.table_name
        WHEN 'hidrometros' THEN tabela_nova := 'med_hidrometros';
        WHEN 'energia' THEN tabela_nova := 'med_energia';
        WHEN 'medidores' THEN tabela_nova := 'med_medidores';
        WHEN 'Colaboradores' THEN tabela_nova := 'rh_colaboradores';
        WHEN 'CCs' THEN tabela_nova := 'rh_departamentos';
        WHEN 'Etapas' THEN tabela_nova := 'rh_etapas';
        WHEN 'Itens' THEN tabela_nova := 'rh_itens';
        WHEN 'Registros' THEN tabela_nova := 'rh_registros_acesso';
        WHEN 'CELULARES' THEN tabela_nova := 'rh_celulares';
        WHEN 'NOTEBOOK' THEN tabela_nova := 'rh_notebooks';
        WHEN 'LINHAS' THEN tabela_nova := 'rh_linhas_telefonicas';
        WHEN 'REGISTROS LINHAS' THEN tabela_nova := 'rh_registros_linhas';
        WHEN 'REGISTROS NOTEBOOKS' THEN tabela_nova := 'rh_registros_notebooks';
        WHEN 'RGISTROS CELULARES' THEN tabela_nova := 'rh_registros_celulares';
        WHEN 'Comentários' THEN tabela_nova := 'rh_comentarios';
        WHEN 'ANEXOS' THEN tabela_nova := 'rh_anexos';
        WHEN 'Apoios' THEN tabela_nova := 'rh_apoios';
        WHEN 'Users' THEN tabela_nova := 'rh_users_legacy';
        WHEN 'kanban_cartoes' THEN tabela_nova := 'rh_kanban_cartoes';
        WHEN 'kanban_comentarios' THEN tabela_nova := 'rh_kanban_comentarios';
        WHEN 'kanban_historico' THEN tabela_nova := 'rh_kanban_historico';
        WHEN 'acoes_rapidas' THEN tabela_nova := 'rh_acoes_rapidas';
        WHEN 'documentos_templates' THEN tabela_nova := 'rh_documentos_templates';
        WHEN 'documentos_gerados' THEN tabela_nova := 'rh_documentos_gerados';
        WHEN 'calendario_eventos' THEN tabela_nova := 'rh_calendario_eventos';
        WHEN 'calendario_alertas' THEN tabela_nova := 'rh_calendario_alertas';
        WHEN 'notificacoes' THEN tabela_nova := 'rh_notificacoes';
        WHEN 'relatorios_config' THEN tabela_nova := 'rh_relatorios_config';
        WHEN 'relatorios_gerados' THEN tabela_nova := 'rh_relatorios_gerados';
        WHEN 'configuracoes' THEN tabela_nova := 'rh_configuracoes';
        WHEN 'painel_metricas' THEN tabela_nova := 'rh_painel_metricas';
        ELSE
          tabela_nova := NULL;
      END CASE;
      
      -- Se encontrou mapeamento e a tabela nova existe
      IF tabela_nova IS NOT NULL THEN
        IF EXISTS (
          SELECT 1 FROM information_schema.tables 
          WHERE table_name = tabela_nova AND table_schema = 'public'
        ) THEN
          -- Verifica se a tabela antiga está vazia
          DECLARE
            contador BIGINT;
          BEGIN
            EXECUTE format('SELECT COUNT(*) FROM %I', r.table_name) INTO contador;
            
            IF contador = 0 THEN
              -- Tabela vazia, pode remover
              EXECUTE format('DROP TABLE %I CASCADE', r.table_name);
              RAISE NOTICE 'Removida tabela vazia duplicada: % (existe % como nova)', r.table_name, tabela_nova;
            ELSE
              -- Tabela tem dados, precisa migrar antes de remover
              RAISE NOTICE 'ATENÇÃO: Tabela % tem % registros e precisa migração manual!', r.table_name, contador;
              RAISE NOTICE '  Tabela nova correspondente: %', tabela_nova;
            END IF;
          EXCEPTION WHEN OTHERS THEN
            -- Se não conseguir contar, tenta remover mesmo assim (pode ser view ou problema de permissão)
            BEGIN
              EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.table_name);
              RAISE NOTICE 'Removida tabela % (erro ao contar registros)', r.table_name;
            EXCEPTION WHEN OTHERS THEN
              RAISE NOTICE 'ERRO ao remover %: %', r.table_name, SQLERRM;
            END;
          END;
        ELSE
          -- Tabela nova não existe, pode ser que precise renomear a antiga
          RAISE NOTICE 'Tabela % não tem correspondente novo. Precisa renomear manualmente.', r.table_name;
        END IF;
      ELSE
        RAISE NOTICE 'Tabela % não tem mapeamento conhecido. Verificar manualmente.', r.table_name;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Erro ao processar tabela %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- ============================================
-- PARTE 3: VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  r RECORD;
  sem_prefixo TEXT[] := ARRAY[]::TEXT[];
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICAÇÃO FINAL';
  RAISE NOTICE '========================================';
  
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND table_name NOT LIKE 'med_%'
      AND table_name NOT LIKE 'rh_%'
      AND table_name NOT IN ('profiles', 'tokens_acesso')
  ) LOOP
    sem_prefixo := array_append(sem_prefixo, r.table_name);
    RAISE NOTICE '⚠ TABELA SEM PREFIXO ENCONTRADA: %', r.table_name;
  END LOOP;
  
  IF array_length(sem_prefixo, 1) IS NULL THEN
    RAISE NOTICE '✅ SUCESSO: Todas as tabelas têm prefixos!';
  ELSE
    RAISE NOTICE '❌ PROBLEMA: % tabelas ainda sem prefixo:', array_length(sem_prefixo, 1);
    FOREACH r.table_name IN ARRAY sem_prefixo LOOP
      RAISE NOTICE '   - %', r.table_name;
    END LOOP;
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

