-- ============================================
-- MIGRATION FORÇADA: Renomear TODAS as tabelas sem prefixo
-- Data: 2024-01-05
-- Descrição: FORÇA renomeação de TODAS as tabelas que não têm prefixo
-- ============================================

DO $$
DECLARE
  r RECORD;
  new_name TEXT;
BEGIN
  -- Lista TODAS as tabelas do schema public que não começam com med_ ou rh_
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND table_name NOT LIKE 'med_%'
      AND table_name NOT LIKE 'rh_%'
      AND table_name NOT IN ('profiles', 'tokens_acesso') -- Tabelas compartilhadas que não precisam prefixo
  ) LOOP
    BEGIN
      -- Determina o prefixo baseado no nome da tabela
      -- Tabelas de medições conhecidas
      IF r.table_name IN ('hidrometros', 'energia', 'medidores') THEN
        new_name := 'med_' || r.table_name;
      -- Tabelas de RH conhecidas (sem aspas no nome)
      ELSIF r.table_name IN (
        'kanban_cartoes', 'kanban_comentarios', 'kanban_historico',
        'acoes_rapidas', 'documentos_templates', 'documentos_gerados',
        'calendario_eventos', 'calendario_alertas',
        'notificacoes', 'relatorios_config', 'relatorios_gerados',
        'configuracoes', 'painel_metricas'
      ) THEN
        new_name := 'rh_' || r.table_name;
      -- Tabelas com nomes com espaços ou caracteres especiais (já renomeadas mas pode ter falhado)
      ELSIF r.table_name LIKE '% %' OR r.table_name ~ '[A-Z]' THEN
        -- Tenta identificar se é RH ou Medições baseado em palavras-chave
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
          -- Converte para nome sem espaços e adiciona prefixo rh_
          new_name := 'rh_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
        ELSE
          -- Assume que é de medições se não identificar como RH
          new_name := 'med_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
        END IF;
      ELSE
        -- Para outras tabelas, tenta identificar pelo contexto
        -- Se não conseguir identificar, pula (não renomeia)
        CONTINUE;
      END IF;
      
      -- Verifica se a nova tabela já existe
      IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = new_name AND table_schema = 'public') THEN
        RAISE NOTICE 'Tabela % já existe, pulando renomeação de %', new_name, r.table_name;
        CONTINUE;
      END IF;
      
      -- Renomeia a tabela
      EXECUTE format('ALTER TABLE %I RENAME TO %I', r.table_name, new_name);
      RAISE NOTICE 'Tabela % renomeada para %', r.table_name, new_name;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Erro ao renomear tabela %: %', r.table_name, SQLERRM;
      -- Continua com a próxima tabela mesmo se der erro
    END;
  END LOOP;
END $$;

-- ============================================
-- VERIFICAR E RENOMEAR TABELAS COM NOMES COM ASPAS (case sensitive)
-- ============================================

DO $$
DECLARE
  r RECORD;
  new_name TEXT;
BEGIN
  -- Tabelas conhecidas do RH que podem ter nomes com aspas
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND (
        table_name IN (
          'Colaboradores', 'CCs', 'Etapas', 'Itens', 'Registros',
          'CELULARES', 'NOTEBOOK', 'LINHAS',
          'REGISTROS LINHAS', 'REGISTROS NOTEBOOKS', 'RGISTROS CELULARES',
          'Comentários', 'ANEXOS', 'Apoios', 'Users'
        )
        OR table_name ~ '[A-Z]' -- Tem letras maiúsculas
        OR table_name LIKE '% %' -- Tem espaços
      )
      AND table_name NOT LIKE 'med_%'
      AND table_name NOT LIKE 'rh_%'
      AND table_name NOT IN ('profiles', 'tokens_acesso')
  ) LOOP
    BEGIN
      -- Mapeamento direto das tabelas conhecidas
      CASE r.table_name
        WHEN 'Colaboradores' THEN new_name := 'rh_colaboradores';
        WHEN 'CCs' THEN new_name := 'rh_departamentos';
        WHEN 'Etapas' THEN new_name := 'rh_etapas';
        WHEN 'Itens' THEN new_name := 'rh_itens';
        WHEN 'Registros' THEN new_name := 'rh_registros_acesso';
        WHEN 'CELULARES' THEN new_name := 'rh_celulares';
        WHEN 'NOTEBOOK' THEN new_name := 'rh_notebooks';
        WHEN 'LINHAS' THEN new_name := 'rh_linhas_telefonicas';
        WHEN 'REGISTROS LINHAS' THEN new_name := 'rh_registros_linhas';
        WHEN 'REGISTROS NOTEBOOKS' THEN new_name := 'rh_registros_notebooks';
        WHEN 'RGISTROS CELULARES' THEN new_name := 'rh_registros_celulares';
        WHEN 'Comentários' THEN new_name := 'rh_comentarios';
        WHEN 'ANEXOS' THEN new_name := 'rh_anexos';
        WHEN 'Apoios' THEN new_name := 'rh_apoios';
        WHEN 'Users' THEN new_name := 'rh_users_legacy';
        ELSE
          -- Converte para lowercase e substitui espaços/caracteres especiais
          new_name := 'rh_' || lower(regexp_replace(r.table_name, '[^a-zA-Z0-9]', '_', 'g'));
      END CASE;
      
      -- Verifica se já existe
      IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = new_name AND table_schema = 'public') THEN
        RAISE NOTICE 'Tabela % já existe, pulando renomeação de %', new_name, r.table_name;
        -- Se já existe, pode tentar dropar a antiga se estiver vazia
        BEGIN
          EXECUTE format('SELECT COUNT(*) FROM %I', r.table_name) INTO r;
          IF r = 0 THEN
            EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.table_name);
            RAISE NOTICE 'Tabela vazia % removida', r.table_name;
          END IF;
        EXCEPTION WHEN OTHERS THEN
          NULL;
        END;
        CONTINUE;
      END IF;
      
      -- Renomeia usando formato com aspas para nomes case-sensitive
      EXECUTE format('ALTER TABLE %I RENAME TO %I', r.table_name, new_name);
      RAISE NOTICE 'Tabela % renomeada para %', r.table_name, new_name;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Erro ao renomear tabela %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- ============================================
-- RECRIAR VIEWS DE COMPATIBILIDADE
-- ============================================

DO $$
BEGIN
  -- Views para medições
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_hidrometros') THEN
    DROP VIEW IF EXISTS public.hidrometros CASCADE;
    CREATE VIEW public.hidrometros AS SELECT * FROM public.med_hidrometros;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_energia') THEN
    DROP VIEW IF EXISTS public.energia CASCADE;
    CREATE VIEW public.energia AS SELECT * FROM public.med_energia;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_medidores') THEN
    DROP VIEW IF EXISTS public.medidores CASCADE;
    CREATE VIEW public.medidores AS SELECT * FROM public.med_medidores;
  END IF;
  
  -- Views para RH (se necessário para compatibilidade)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores') THEN
    DROP VIEW IF EXISTS public."Colaboradores" CASCADE;
    CREATE VIEW public."Colaboradores" AS SELECT * FROM public.rh_colaboradores;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos') THEN
    DROP VIEW IF EXISTS public."CCs" CASCADE;
    CREATE VIEW public."CCs" AS SELECT * FROM public.rh_departamentos;
  END IF;
END $$;

-- ============================================
-- LISTAR TODAS AS TABELAS PARA VERIFICAÇÃO
-- ============================================

DO $$
DECLARE
  r RECORD;
  sem_prefixo TEXT[] := ARRAY[]::TEXT[];
BEGIN
  RAISE NOTICE '=== VERIFICAÇÃO DE TABELAS ===';
  
  FOR r IN (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name
  ) LOOP
    IF r.table_name NOT LIKE 'med_%' 
       AND r.table_name NOT LIKE 'rh_%'
       AND r.table_name NOT IN ('profiles', 'tokens_acesso') THEN
      sem_prefixo := array_append(sem_prefixo, r.table_name);
      RAISE NOTICE 'TABELA SEM PREFIXO: %', r.table_name;
    ELSE
      RAISE NOTICE 'Tabela OK: %', r.table_name;
    END IF;
  END LOOP;
  
  IF array_length(sem_prefixo, 1) > 0 THEN
    RAISE NOTICE 'ATENÇÃO: % tabelas ainda sem prefixo!', array_length(sem_prefixo, 1);
  ELSE
    RAISE NOTICE 'SUCESSO: Todas as tabelas têm prefixos!';
  END IF;
END $$;

