-- ============================================
-- MIGRATION DEFINITIVA: Remover duplicatas e corrigir nomes
-- Data: 2024-01-08
-- Descrição: REMOVE tabelas duplicadas sem prefixo e renomeia as restantes
-- ============================================

-- ============================================
-- PARTE 1: REMOVER TABELAS DUPLICADAS SEM PREFIXO
-- ============================================

DO $$
DECLARE
  r RECORD;
  tabela_com_prefixo TEXT;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'REMOVENDO TABELAS DUPLICADAS';
  RAISE NOTICE '========================================';
  
  -- Lista todas as tabelas sem prefixo
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
      -- Determina qual seria o nome com prefixo
      CASE r.table_name
        WHEN 'hidrometros' THEN tabela_com_prefixo := 'med_hidrometros';
        WHEN 'energia' THEN tabela_com_prefixo := 'med_energia';
        WHEN 'medidores' THEN tabela_com_prefixo := 'med_medidores';
        WHEN 'Colaboradores' THEN tabela_com_prefixo := 'rh_colaboradores';
        WHEN 'CCs' THEN tabela_com_prefixo := 'rh_departamentos';
        WHEN 'Etapas' THEN tabela_com_prefixo := 'rh_etapas';
        WHEN 'Itens' THEN tabela_com_prefixo := 'rh_itens';
        WHEN 'Registros' THEN tabela_com_prefixo := 'rh_registros_acesso';
        WHEN 'CELULARES' THEN tabela_com_prefixo := 'rh_celulares';
        WHEN 'NOTEBOOK' THEN tabela_com_prefixo := 'rh_notebooks';
        WHEN 'LINHAS' THEN tabela_com_prefixo := 'rh_linhas_telefonicas';
        WHEN 'REGISTROS LINHAS' THEN tabela_com_prefixo := 'rh_registros_linhas';
        WHEN 'REGISTROS NOTEBOOKS' THEN tabela_com_prefixo := 'rh_registros_notebooks';
        WHEN 'RGISTROS CELULARES' THEN tabela_com_prefixo := 'rh_registros_celulares';
        WHEN 'Comentários' THEN tabela_com_prefixo := 'rh_comentarios';
        WHEN 'ANEXOS' THEN tabela_com_prefixo := 'rh_anexos';
        WHEN 'Apoios' THEN tabela_com_prefixo := 'rh_apoios';
        WHEN 'Users' THEN tabela_com_prefixo := 'rh_users_legacy';
        WHEN 'kanban_cartoes' THEN tabela_com_prefixo := 'rh_kanban_cartoes';
        WHEN 'kanban_comentarios' THEN tabela_com_prefixo := 'rh_kanban_comentarios';
        WHEN 'kanban_historico' THEN tabela_com_prefixo := 'rh_kanban_historico';
        WHEN 'acoes_rapidas' THEN tabela_com_prefixo := 'rh_acoes_rapidas';
        WHEN 'documentos_templates' THEN tabela_com_prefixo := 'rh_documentos_templates';
        WHEN 'documentos_gerados' THEN tabela_com_prefixo := 'rh_documentos_gerados';
        WHEN 'calendario_eventos' THEN tabela_com_prefixo := 'rh_calendario_eventos';
        WHEN 'calendario_alertas' THEN tabela_com_prefixo := 'rh_calendario_alertas';
        WHEN 'notificacoes' THEN tabela_com_prefixo := 'rh_notificacoes';
        WHEN 'relatorios_config' THEN tabela_com_prefixo := 'rh_relatorios_config';
        WHEN 'relatorios_gerados' THEN tabela_com_prefixo := 'rh_relatorios_gerados';
        WHEN 'configuracoes' THEN tabela_com_prefixo := 'rh_configuracoes';
        WHEN 'painel_metricas' THEN tabela_com_prefixo := 'rh_painel_metricas';
        ELSE
          tabela_com_prefixo := NULL;
      END CASE;
      
      -- Se encontrou correspondente com prefixo
      IF tabela_com_prefixo IS NOT NULL THEN
        -- Verifica se a tabela com prefixo existe
        IF EXISTS (
          SELECT 1 FROM information_schema.tables 
          WHERE table_name = tabela_com_prefixo AND table_schema = 'public'
        ) THEN
          -- REMOVE a tabela sem prefixo (é duplicata)
          EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.table_name);
          RAISE NOTICE '✓ REMOVIDA duplicata: % (existe % com prefixo)', r.table_name, tabela_com_prefixo;
        ELSE
          -- Tabela com prefixo não existe, então renomeia a sem prefixo
          EXECUTE format('ALTER TABLE %I RENAME TO %I', r.table_name, tabela_com_prefixo);
          RAISE NOTICE '✓ RENOMEADA: % -> %', r.table_name, tabela_com_prefixo;
        END IF;
      ELSE
        -- Não tem mapeamento conhecido - tenta identificar pelo nome
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
           r.table_name ILIKE '%metricas%' OR
           r.table_name ILIKE '%acao%' THEN
          -- É do RH, adiciona prefixo rh_
          tabela_com_prefixo := 'rh_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
          IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = tabela_com_prefixo AND table_schema = 'public'
          ) THEN
            EXECUTE format('ALTER TABLE %I RENAME TO %I', r.table_name, tabela_com_prefixo);
            RAISE NOTICE '✓ RENOMEADA (RH): % -> %', r.table_name, tabela_com_prefixo;
          ELSE
            EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.table_name);
            RAISE NOTICE '✓ REMOVIDA duplicata (RH): %', r.table_name;
          END IF;
        ELSIF r.table_name ILIKE '%hidrometro%' OR 
              r.table_name ILIKE '%energia%' OR 
              r.table_name ILIKE '%medidor%' THEN
          -- É de medições, adiciona prefixo med_
          tabela_com_prefixo := 'med_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
          IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = tabela_com_prefixo AND table_schema = 'public'
          ) THEN
            EXECUTE format('ALTER TABLE %I RENAME TO %I', r.table_name, tabela_com_prefixo);
            RAISE NOTICE '✓ RENOMEADA (MED): % -> %', r.table_name, tabela_com_prefixo;
          ELSE
            EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.table_name);
            RAISE NOTICE '✓ REMOVIDA duplicata (MED): %', r.table_name;
          END IF;
        ELSE
          RAISE NOTICE '⚠ TABELA DESCONHECIDA (não renomeada): %', r.table_name;
        END IF;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '❌ ERRO ao processar %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- ============================================
-- PARTE 2: VERIFICAÇÃO FINAL E RELATÓRIO
-- ============================================

DO $$
DECLARE
  r RECORD;
  total INT := 0;
  com_prefixo INT := 0;
  sem_prefixo INT := 0;
  sem_prefixo_list TEXT[] := ARRAY[]::TEXT[];
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RELATÓRIO FINAL';
  RAISE NOTICE '========================================';
  
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name
  ) LOOP
    total := total + 1;
    
    IF r.table_name LIKE 'med_%' OR r.table_name LIKE 'rh_%' OR r.table_name IN ('profiles', 'tokens_acesso') THEN
      com_prefixo := com_prefixo + 1;
    ELSE
      sem_prefixo := sem_prefixo + 1;
      sem_prefixo_list := array_append(sem_prefixo_list, r.table_name);
      RAISE NOTICE '❌ SEM PREFIXO: %', r.table_name;
    END IF;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de tabelas: %', total;
  RAISE NOTICE 'Com prefixo: %', com_prefixo;
  RAISE NOTICE 'Sem prefixo: %', sem_prefixo;
  
  IF sem_prefixo > 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE 'TABELAS QUE AINDA PRECISAM CORREÇÃO:';
    FOREACH r.table_name IN ARRAY sem_prefixo_list LOOP
      RAISE NOTICE '  - %', r.table_name;
    END LOOP;
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '✅ SUCESSO! Todas as tabelas têm prefixos!';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- PARTE 3: RECRIAR VIEWS DE COMPATIBILIDADE
-- ============================================

DROP VIEW IF EXISTS public.hidrometros CASCADE;
DROP VIEW IF EXISTS public.energia CASCADE;
DROP VIEW IF EXISTS public.medidores CASCADE;

CREATE OR REPLACE VIEW public.hidrometros AS SELECT * FROM public.med_hidrometros;
CREATE OR REPLACE VIEW public.energia AS SELECT * FROM public.med_energia;
CREATE OR REPLACE VIEW public.medidores AS SELECT * FROM public.med_medidores;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.hidrometros TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.energia TO authenticated;
GRANT SELECT ON public.medidores TO authenticated;

DO $$
BEGIN
  RAISE NOTICE 'Views de compatibilidade recriadas';
END $$;

