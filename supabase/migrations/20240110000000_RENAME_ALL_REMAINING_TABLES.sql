-- ============================================
-- RENOMEAR TODAS AS TABELAS SEM PREFIXO RESTANTES
-- Data: 2024-01-10
-- Descrição: Renomeia TODAS as tabelas sem prefixo que ainda existem
-- ============================================

DO $$
DECLARE
  r RECORD;
  novo_nome TEXT;
  renomeadas INT := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RENOMEANDO TODAS AS TABELAS SEM PREFIXO';
  RAISE NOTICE '========================================';
  
  -- Lista TODAS as tabelas sem prefixo
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND table_name NOT LIKE 'med_%'
      AND table_name NOT LIKE 'rh_%'
      AND table_name NOT IN ('profiles', 'tokens_acesso')
    ORDER BY table_name
  ) LOOP
    BEGIN
      -- Mapeamento direto de TODAS as tabelas conhecidas
      CASE r.table_name
        -- Tabelas de RH com nomes antigos
        WHEN 'ANEXOS' THEN novo_nome := 'rh_anexos';
        WHEN 'Apoios' THEN novo_nome := 'rh_apoios';
        WHEN 'CELULARES' THEN novo_nome := 'rh_celulares';
        WHEN 'Comentários' THEN novo_nome := 'rh_comentarios';
        WHEN 'Etapas' THEN novo_nome := 'rh_etapas';
        WHEN 'Itens' THEN novo_nome := 'rh_itens';
        WHEN 'LINHAS' THEN novo_nome := 'rh_linhas_telefonicas';
        WHEN 'NOTEBOOK' THEN novo_nome := 'rh_notebooks';
        WHEN 'REGISTROS LINHAS' THEN novo_nome := 'rh_registros_linhas';
        WHEN 'REGISTROS NOTEBOOKS' THEN novo_nome := 'rh_registros_notebooks';
        WHEN 'RGISTROS CELULARES' THEN novo_nome := 'rh_registros_celulares';
        WHEN 'Registros' THEN novo_nome := 'rh_registros_acesso';
        WHEN 'calendario_alertas' THEN novo_nome := 'rh_calendario_alertas';
        WHEN 'calendario_eventos' THEN novo_nome := 'rh_calendario_eventos';
        WHEN 'configuracoes' THEN novo_nome := 'rh_configuracoes';
        WHEN 'documentos_gerados' THEN novo_nome := 'rh_documentos_gerados';
        WHEN 'documentos_templates' THEN novo_nome := 'rh_documentos_templates';
        WHEN 'documentos_temporarios' THEN novo_nome := 'rh_documentos_templates';
        WHEN 'notificacoes' THEN novo_nome := 'rh_notificacoes';
        WHEN 'relatorios_config' THEN novo_nome := 'rh_relatorios_config';
        WHEN 'relatorios_gerados' THEN novo_nome := 'rh_relatorios_gerados';
        WHEN 'painel_metricas' THEN novo_nome := 'rh_painel_metricas';
        WHEN 'acoes_rapidas' THEN novo_nome := 'rh_acoes_rapidas';
        WHEN 'kanban_cartoes' THEN novo_nome := 'rh_kanban_cartoes';
        WHEN 'kanban_comentarios' THEN novo_nome := 'rh_kanban_comentarios';
        WHEN 'kanban_historico' THEN novo_nome := 'rh_kanban_historico';
        WHEN 'Colaboradores' THEN novo_nome := 'rh_colaboradores';
        WHEN 'CCs' THEN novo_nome := 'rh_departamentos';
        WHEN 'Users' THEN novo_nome := 'rh_users_legacy';
        -- Tabelas de medições
        WHEN 'hidrometros' THEN novo_nome := 'med_hidrometros';
        WHEN 'energia' THEN novo_nome := 'med_energia';
        WHEN 'medidores' THEN novo_nome := 'med_medidores';
        ELSE
          -- Tenta identificar automaticamente
          IF r.table_name ILIKE '%colaborador%' OR 
             r.table_name ILIKE '%celular%' OR 
             r.table_name ILIKE '%notebook%' OR
             r.table_name ILIKE '%linha%' OR
             r.table_name ILIKE '%departamento%' OR
             r.table_name ILIKE '%etapa%' OR
             r.table_name ILIKE '%comentario%' OR
             r.table_name ILIKE '%anexo%' OR
             r.table_name ILIKE '%apoio%' OR
             r.table_name ILIKE '%kanban%' OR
             r.table_name ILIKE '%documento%' OR
             r.table_name ILIKE '%calendario%' OR
             r.table_name ILIKE '%notificacao%' OR
             r.table_name ILIKE '%relatorio%' OR
             r.table_name ILIKE '%configuracao%' OR
             r.table_name ILIKE '%metrica%' OR
             r.table_name ILIKE '%acao%' OR
             r.table_name ILIKE '%registro%' THEN
            novo_nome := 'rh_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
          ELSIF r.table_name ILIKE '%hidrometro%' OR 
                r.table_name ILIKE '%energia%' OR 
                r.table_name ILIKE '%medidor%' THEN
            novo_nome := 'med_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
          ELSE
            novo_nome := NULL;
          END IF;
      END CASE;
      
      -- Se encontrou um novo nome
      IF novo_nome IS NOT NULL THEN
        -- Verifica se a tabela com prefixo já existe
        IF EXISTS (
          SELECT 1 FROM information_schema.tables 
          WHERE table_name = novo_nome AND table_schema = 'public'
        ) THEN
          -- Tabela com prefixo já existe, remove a sem prefixo
          EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.table_name);
          RAISE NOTICE '✓ REMOVIDA duplicata: % (existe % com prefixo)', r.table_name, novo_nome;
        ELSE
          -- Renomeia para ter prefixo
          EXECUTE format('ALTER TABLE %I RENAME TO %I', r.table_name, novo_nome);
          renomeadas := renomeadas + 1;
          RAISE NOTICE '✓ RENOMEADA: % -> %', r.table_name, novo_nome;
        END IF;
      ELSE
        RAISE NOTICE '⚠ TABELA DESCONHECIDA (não renomeada): %', r.table_name;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '❌ ERRO ao processar %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de tabelas renomeadas: %', renomeadas;
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- REMOVER TODAS AS VIEWS RESTANTES
-- ============================================

DO $$
DECLARE
  r RECORD;
  total_views INT := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'REMOVENDO TODAS AS VIEWS RESTANTES';
  RAISE NOTICE '========================================';
  
  -- Remove TODAS as views do schema public
  FOR r IN (
    SELECT schemaname, viewname
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

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  r RECORD;
  total_tabelas INT := 0;
  com_prefixo INT := 0;
  sem_prefixo INT := 0;
  total_views INT := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICAÇÃO FINAL';
  RAISE NOTICE '========================================';
  
  -- Conta tabelas
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
  ) LOOP
    total_tabelas := total_tabelas + 1;
    IF r.table_name LIKE 'med_%' OR r.table_name LIKE 'rh_%' OR r.table_name IN ('profiles', 'tokens_acesso') THEN
      com_prefixo := com_prefixo + 1;
    ELSE
      sem_prefixo := sem_prefixo + 1;
      RAISE NOTICE '❌ TABELA SEM PREFIXO: %', r.table_name;
    END IF;
  END LOOP;
  
  -- Conta views
  SELECT COUNT(*) INTO total_views
  FROM pg_views
  WHERE schemaname = 'public';
  
  RAISE NOTICE 'Total de tabelas: %', total_tabelas;
  RAISE NOTICE 'Com prefixo: %', com_prefixo;
  RAISE NOTICE 'Sem prefixo: %', sem_prefixo;
  RAISE NOTICE 'Total de views: %', total_views;
  
  IF sem_prefixo = 0 AND total_views = 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ SUCESSO! Todas as tabelas têm prefixos e não há views!';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;


