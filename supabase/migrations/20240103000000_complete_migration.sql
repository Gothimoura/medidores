-- ============================================
-- MIGRATION COMPLETA: Profiles + Renomeação de Tabelas
-- Data: 2024-01-03
-- Descrição: Cria tabela profiles, renomeia tabelas com prefixos,
--            atualiza foreign keys e aplica RLS
-- ============================================

-- ============================================
-- PARTE 1: CRIAR TABELA PROFILES
-- ============================================

-- Cria tabela profiles ligada ao auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  email text,
  photo text,
  role text DEFAULT 'user',
  export text,
  view text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS profiles_email_idx ON public.profiles(email);
CREATE INDEX IF NOT EXISTS profiles_role_idx ON public.profiles(role);

-- ============================================
-- PARTE 2: MIGRAR DADOS DE Users PARA profiles
-- ============================================

-- Insere dados existentes da tabela Users para profiles (se a tabela Users existir)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Users' AND table_schema = 'public') THEN
    INSERT INTO public.profiles (id, name, email, photo, role, export, view)
    SELECT 
      u."Row ID"::uuid as id,
      u."Name" as name,
      u."Email" as email,
      u."Photo" as photo,
      COALESCE(u."Role", 'user') as role,
      u."Export" as export,
      u."View" as view
    FROM public."Users" u
    WHERE u."Row ID" IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM auth.users au WHERE au.id::text = u."Row ID"
      )
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      email = EXCLUDED.email,
      photo = EXCLUDED.photo,
      role = EXCLUDED.role,
      export = EXCLUDED.export,
      view = EXCLUDED.view,
      updated_at = timezone('utc'::text, now());
  END IF;
END $$;

-- ============================================
-- PARTE 3: RENOMEAR TABELAS DO PROJETO DE MEDIÇÕES
-- ============================================

-- Renomear tabelas de medições com prefixo 'med_'
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hidrometros' AND table_schema = 'public') THEN
    ALTER TABLE public.hidrometros RENAME TO med_hidrometros;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'energia' AND table_schema = 'public') THEN
    ALTER TABLE public.energia RENAME TO med_energia;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'medidores' AND table_schema = 'public') THEN
    ALTER TABLE public.medidores RENAME TO med_medidores;
  END IF;
END $$;

-- ============================================
-- PARTE 4: RENOMEAR TABELAS DO PROJETO DE RH
-- ============================================

-- Renomear tabelas principais do RH
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Colaboradores' AND table_schema = 'public') THEN
    ALTER TABLE public."Colaboradores" RENAME TO rh_colaboradores;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Users' AND table_schema = 'public') THEN
    ALTER TABLE public."Users" RENAME TO rh_users_legacy;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'CCs' AND table_schema = 'public') THEN
    ALTER TABLE public."CCs" RENAME TO rh_departamentos;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Etapas' AND table_schema = 'public') THEN
    ALTER TABLE public."Etapas" RENAME TO rh_etapas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Itens' AND table_schema = 'public') THEN
    ALTER TABLE public."Itens" RENAME TO rh_itens;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Registros' AND table_schema = 'public') THEN
    ALTER TABLE public."Registros" RENAME TO rh_registros_acesso;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'CELULARES' AND table_schema = 'public') THEN
    ALTER TABLE public."CELULARES" RENAME TO rh_celulares;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'NOTEBOOK' AND table_schema = 'public') THEN
    ALTER TABLE public."NOTEBOOK" RENAME TO rh_notebooks;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'LINHAS' AND table_schema = 'public') THEN
    ALTER TABLE public."LINHAS" RENAME TO rh_linhas_telefonicas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'REGISTROS LINHAS' AND table_schema = 'public') THEN
    ALTER TABLE public."REGISTROS LINHAS" RENAME TO rh_registros_linhas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'REGISTROS NOTEBOOKS' AND table_schema = 'public') THEN
    ALTER TABLE public."REGISTROS NOTEBOOKS" RENAME TO rh_registros_notebooks;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'RGISTROS CELULARES' AND table_schema = 'public') THEN
    ALTER TABLE public."RGISTROS CELULARES" RENAME TO rh_registros_celulares;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Comentários' AND table_schema = 'public') THEN
    ALTER TABLE public."Comentários" RENAME TO rh_comentarios;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ANEXOS' AND table_schema = 'public') THEN
    ALTER TABLE public."ANEXOS" RENAME TO rh_anexos;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Apoios' AND table_schema = 'public') THEN
    ALTER TABLE public."Apoios" RENAME TO rh_apoios;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kanban_cartoes' AND table_schema = 'public') THEN
    ALTER TABLE public.kanban_cartoes RENAME TO rh_kanban_cartoes;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kanban_comentarios' AND table_schema = 'public') THEN
    ALTER TABLE public.kanban_comentarios RENAME TO rh_kanban_comentarios;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kanban_historico' AND table_schema = 'public') THEN
    ALTER TABLE public.kanban_historico RENAME TO rh_kanban_historico;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'acoes_rapidas' AND table_schema = 'public') THEN
    ALTER TABLE public.acoes_rapidas RENAME TO rh_acoes_rapidas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documentos_templates' AND table_schema = 'public') THEN
    ALTER TABLE public.documentos_templates RENAME TO rh_documentos_templates;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documentos_gerados' AND table_schema = 'public') THEN
    ALTER TABLE public.documentos_gerados RENAME TO rh_documentos_gerados;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendario_eventos' AND table_schema = 'public') THEN
    ALTER TABLE public.calendario_eventos RENAME TO rh_calendario_eventos;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendario_alertas' AND table_schema = 'public') THEN
    ALTER TABLE public.calendario_alertas RENAME TO rh_calendario_alertas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notificacoes' AND table_schema = 'public') THEN
    ALTER TABLE public.notificacoes RENAME TO rh_notificacoes;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'relatorios_config' AND table_schema = 'public') THEN
    ALTER TABLE public.relatorios_config RENAME TO rh_relatorios_config;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'relatorios_gerados' AND table_schema = 'public') THEN
    ALTER TABLE public.relatorios_gerados RENAME TO rh_relatorios_gerados;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'configuracoes' AND table_schema = 'public') THEN
    ALTER TABLE public.configuracoes RENAME TO rh_configuracoes;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'painel_metricas' AND table_schema = 'public') THEN
    ALTER TABLE public.painel_metricas RENAME TO rh_painel_metricas;
  END IF;
END $$;

-- ============================================
-- PARTE 5: FUNÇÃO PARA CRIAR PROFILE AUTOMATICAMENTE
-- ============================================

-- Função para criar profile automaticamente quando um usuário é criado no auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para criar profile automaticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- PARTE 6: FUNÇÃO PARA ATUALIZAR updated_at
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at automaticamente
DROP TRIGGER IF EXISTS set_updated_at ON public.profiles;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- PARTE 7: REMOVER TODAS AS FOREIGN KEYS ANTIGAS PRIMEIRO
-- ============================================

-- Remove TODAS as foreign keys que referenciam Users ou outras tabelas antigas
-- Isso é necessário antes de converter tipos
DO $$
DECLARE
  r RECORD;
BEGIN
  -- rh_comentarios - Remove TODAS as foreign keys
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_comentarios' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_comentarios' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_comentarios DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_kanban_cartoes - Remove TODAS as foreign keys
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_kanban_cartoes' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_kanban_cartoes DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_kanban_comentarios - Remove TODAS as foreign keys primeiro
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_comentarios' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_kanban_comentarios' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_kanban_comentarios DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_kanban_historico - Remove TODAS as foreign keys primeiro
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_historico' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_kanban_historico' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_kanban_historico DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_acoes_rapidas - Remove TODAS as foreign keys primeiro
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_acoes_rapidas' AND table_schema = 'public') THEN
    -- Remove todas as foreign keys desta tabela
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_acoes_rapidas' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_acoes_rapidas DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        -- Continua mesmo se der erro
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_documentos_gerados - Remove TODAS as foreign keys primeiro
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_gerados' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_documentos_gerados' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_documentos_gerados DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_notificacoes - Remove TODAS as foreign keys primeiro
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notificacoes' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_notificacoes' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_notificacoes DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;

  -- rh_relatorios_gerados - Remove TODAS as foreign keys primeiro
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_gerados' AND table_schema = 'public') THEN
    FOR r IN (
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'rh_relatorios_gerados' 
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_schema = 'public'
    ) LOOP
      BEGIN
        EXECUTE 'ALTER TABLE rh_relatorios_gerados DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END IF;
END $$;

-- ============================================
-- PARTE 8: CONVERTER TIPOS DE COLUNAS PARA UUID
-- ============================================

-- Converter colunas de text para uuid antes de criar foreign keys
DO $$
BEGIN
  -- rh_comentarios."Usuário id"
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_comentarios' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_comentarios' 
      AND column_name = 'Usuário id' 
      AND data_type = 'text'
    ) THEN
      -- Converte text para uuid (trata NULL e valores inválidos)
      ALTER TABLE rh_comentarios 
      ALTER COLUMN "Usuário id" TYPE uuid USING 
        CASE 
          WHEN "Usuário id" IS NULL OR "Usuário id" = '' THEN NULL
          WHEN "Usuário id" ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN "Usuário id"::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_kanban_cartoes.responsavel_id
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_kanban_cartoes' 
      AND column_name = 'responsavel_id' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_kanban_cartoes 
      ALTER COLUMN responsavel_id TYPE uuid USING 
        CASE 
          WHEN responsavel_id IS NULL OR responsavel_id = '' THEN NULL
          WHEN responsavel_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN responsavel_id::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_kanban_comentarios.usuario_id
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_comentarios' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_kanban_comentarios' 
      AND column_name = 'usuario_id' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_kanban_comentarios 
      ALTER COLUMN usuario_id TYPE uuid USING 
        CASE 
          WHEN usuario_id IS NULL OR usuario_id = '' THEN NULL
          WHEN usuario_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN usuario_id::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_kanban_historico.movido_por
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_historico' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_kanban_historico' 
      AND column_name = 'movido_por' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_kanban_historico 
      ALTER COLUMN movido_por TYPE uuid USING 
        CASE 
          WHEN movido_por IS NULL OR movido_por = '' THEN NULL
          WHEN movido_por ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN movido_por::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_acoes_rapidas.executado_por
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_acoes_rapidas' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_acoes_rapidas' 
      AND column_name = 'executado_por' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_acoes_rapidas 
      ALTER COLUMN executado_por TYPE uuid USING 
        CASE 
          WHEN executado_por IS NULL OR executado_por = '' THEN NULL
          WHEN executado_por ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN executado_por::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_documentos_gerados.gerado_por
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_gerados' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_documentos_gerados' 
      AND column_name = 'gerado_por' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_documentos_gerados 
      ALTER COLUMN gerado_por TYPE uuid USING 
        CASE 
          WHEN gerado_por IS NULL OR gerado_por = '' THEN NULL
          WHEN gerado_por ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN gerado_por::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_notificacoes.usuario_id
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notificacoes' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_notificacoes' 
      AND column_name = 'usuario_id' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_notificacoes 
      ALTER COLUMN usuario_id TYPE uuid USING 
        CASE 
          WHEN usuario_id IS NULL OR usuario_id = '' THEN NULL
          WHEN usuario_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN usuario_id::uuid
          ELSE NULL
        END;
    END IF;
  END IF;

  -- rh_relatorios_gerados.gerado_por
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_gerados' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rh_relatorios_gerados' 
      AND column_name = 'gerado_por' 
      AND data_type = 'text'
    ) THEN
      ALTER TABLE rh_relatorios_gerados 
      ALTER COLUMN gerado_por TYPE uuid USING 
        CASE 
          WHEN gerado_por IS NULL OR gerado_por = '' THEN NULL
          WHEN gerado_por ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN gerado_por::uuid
          ELSE NULL
        END;
    END IF;
  END IF;
END $$;

-- ============================================
-- PARTE 9: ATUALIZAR FOREIGN KEYS - PROJETO RH
-- ============================================

-- Atualizar FKs da tabela rh_colaboradores
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
    -- Remove constraint antiga se existir
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'Colaboradores_Departamento_fkey'
      AND table_name = 'rh_colaboradores'
    ) THEN
      ALTER TABLE rh_colaboradores DROP CONSTRAINT "Colaboradores_Departamento_fkey";
    END IF;
    
    -- Adiciona nova constraint
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_colaboradores_departamento_fkey'
      ) THEN
        ALTER TABLE rh_colaboradores
        ADD CONSTRAINT rh_colaboradores_departamento_fkey 
        FOREIGN KEY ("Departamento") REFERENCES rh_departamentos("Departamento");
      END IF;
    END IF;

    -- Atualizar FK de Etapa id
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'Colaboradores_Etapa id_fkey'
    ) THEN
      ALTER TABLE rh_colaboradores DROP CONSTRAINT "Colaboradores_Etapa id_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_etapas' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_colaboradores_etapa_id_fkey'
      ) THEN
        ALTER TABLE rh_colaboradores
        ADD CONSTRAINT rh_colaboradores_etapa_id_fkey 
        FOREIGN KEY ("Etapa id") REFERENCES rh_etapas("ID");
      END IF;
    END IF;
  END IF;
END $$;

-- Atualizar FKs da tabela rh_comentarios
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_comentarios' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'Comentários_Usuário id_fkey'
    ) THEN
      ALTER TABLE rh_comentarios DROP CONSTRAINT "Comentários_Usuário id_fkey";
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_comentarios_usuario_id_fkey'
    ) THEN
      ALTER TABLE rh_comentarios
      ADD CONSTRAINT rh_comentarios_usuario_id_fkey 
      FOREIGN KEY ("Usuário id") REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'Comentários_Colaborador id_fkey'
    ) THEN
      ALTER TABLE rh_comentarios DROP CONSTRAINT "Comentários_Colaborador id_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_comentarios_colaborador_id_fkey'
      ) THEN
        ALTER TABLE rh_comentarios
        ADD CONSTRAINT rh_comentarios_colaborador_id_fkey 
        FOREIGN KEY ("Colaborador id") REFERENCES rh_colaboradores("ID");
      END IF;
    END IF;
  END IF;
END $$;

-- Atualizar FKs da tabela rh_registros_acesso
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_acesso' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'Registros_ID Colaborador_fkey'
    ) THEN
      ALTER TABLE rh_registros_acesso DROP CONSTRAINT "Registros_ID Colaborador_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_registros_acesso_colaborador_id_fkey'
      ) THEN
        ALTER TABLE rh_registros_acesso
        ADD CONSTRAINT rh_registros_acesso_colaborador_id_fkey 
        FOREIGN KEY ("ID Colaborador") REFERENCES rh_colaboradores("ID");
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'Registros_Plataforma_fkey'
    ) THEN
      ALTER TABLE rh_registros_acesso DROP CONSTRAINT "Registros_Plataforma_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_itens' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_registros_acesso_plataforma_fkey'
      ) THEN
        ALTER TABLE rh_registros_acesso
        ADD CONSTRAINT rh_registros_acesso_plataforma_fkey 
        FOREIGN KEY ("Plataforma") REFERENCES rh_itens("ID");
      END IF;
    END IF;
  END IF;
END $$;

-- Atualizar FKs de equipamentos
DO $$
BEGIN
  -- CELULARES
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_celulares' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'CELULARES_DPTO_fkey'
    ) THEN
      ALTER TABLE rh_celulares DROP CONSTRAINT "CELULARES_DPTO_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_celulares_dpto_fkey'
      ) THEN
        ALTER TABLE rh_celulares
        ADD CONSTRAINT rh_celulares_dpto_fkey 
        FOREIGN KEY ("DPTO") REFERENCES rh_departamentos("Departamento");
      END IF;
    END IF;
  END IF;

  -- NOTEBOOK
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notebooks' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'NOTEBOOK_Departamento_fkey'
    ) THEN
      ALTER TABLE rh_notebooks DROP CONSTRAINT "NOTEBOOK_Departamento_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_notebooks_departamento_fkey'
      ) THEN
        ALTER TABLE rh_notebooks
        ADD CONSTRAINT rh_notebooks_departamento_fkey 
        FOREIGN KEY ("Departamento") REFERENCES rh_departamentos("Departamento");
      END IF;
    END IF;
  END IF;

  -- LINHAS
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_linhas_telefonicas' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'LINHAS_Centro de custo_fkey'
    ) THEN
      ALTER TABLE rh_linhas_telefonicas DROP CONSTRAINT "LINHAS_Centro de custo_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_linhas_centro_custo_fkey'
      ) THEN
        ALTER TABLE rh_linhas_telefonicas
        ADD CONSTRAINT rh_linhas_centro_custo_fkey 
        FOREIGN KEY ("Centro de custo") REFERENCES rh_departamentos("Departamento");
      END IF;
    END IF;
  END IF;
END $$;

-- Atualizar FKs de registros de equipamentos
DO $$
BEGIN
  -- REGISTROS LINHAS
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_linhas' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'REGISTROS LINHAS_ID_fkey'
    ) THEN
      ALTER TABLE rh_registros_linhas DROP CONSTRAINT "REGISTROS LINHAS_ID_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_linhas_telefonicas' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_registros_linhas_id_fkey'
      ) THEN
        ALTER TABLE rh_registros_linhas
        ADD CONSTRAINT rh_registros_linhas_id_fkey 
        FOREIGN KEY ("ID") REFERENCES rh_linhas_telefonicas("NTC");
      END IF;
    END IF;
  END IF;

  -- REGISTROS NOTEBOOKS
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_notebooks' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'REGISTROS NOTEBOOKS_ID_fkey'
    ) THEN
      ALTER TABLE rh_registros_notebooks DROP CONSTRAINT "REGISTROS NOTEBOOKS_ID_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notebooks' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_registros_notebooks_id_fkey'
      ) THEN
        ALTER TABLE rh_registros_notebooks
        ADD CONSTRAINT rh_registros_notebooks_id_fkey 
        FOREIGN KEY ("ID") REFERENCES rh_notebooks("Row ID");
      END IF;
    END IF;
  END IF;

  -- REGISTROS CELULARES
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_celulares' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'RGISTROS CELULARES_ID_fkey'
    ) THEN
      ALTER TABLE rh_registros_celulares DROP CONSTRAINT "RGISTROS CELULARES_ID_fkey";
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_celulares' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_registros_celulares_id_fkey'
      ) THEN
        ALTER TABLE rh_registros_celulares
        ADD CONSTRAINT rh_registros_celulares_id_fkey 
        FOREIGN KEY ("ID") REFERENCES rh_celulares("Row ID");
      END IF;
    END IF;
  END IF;
END $$;

-- Atualizar FKs das tabelas kanban
DO $$
BEGIN
  -- kanban_cartoes
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'kanban_cartoes_colaborador_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_cartoes DROP CONSTRAINT kanban_cartoes_colaborador_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_kanban_cartoes_colaborador_id_fkey'
      ) THEN
        ALTER TABLE rh_kanban_cartoes
        ADD CONSTRAINT rh_kanban_cartoes_colaborador_id_fkey 
        FOREIGN KEY (colaborador_id) REFERENCES rh_colaboradores("ID");
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'kanban_cartoes_responsavel_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_cartoes DROP CONSTRAINT kanban_cartoes_responsavel_id_fkey;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_kanban_cartoes_responsavel_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_cartoes
      ADD CONSTRAINT rh_kanban_cartoes_responsavel_id_fkey 
      FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id);
    END IF;
  END IF;

  -- kanban_comentarios
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_comentarios' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'kanban_comentarios_cartao_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_comentarios DROP CONSTRAINT kanban_comentarios_cartao_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_kanban_comentarios_cartao_id_fkey'
      ) THEN
        ALTER TABLE rh_kanban_comentarios
        ADD CONSTRAINT rh_kanban_comentarios_cartao_id_fkey 
        FOREIGN KEY (cartao_id) REFERENCES rh_kanban_cartoes(id);
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'kanban_comentarios_usuario_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_comentarios DROP CONSTRAINT kanban_comentarios_usuario_id_fkey;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_kanban_comentarios_usuario_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_comentarios
      ADD CONSTRAINT rh_kanban_comentarios_usuario_id_fkey 
      FOREIGN KEY (usuario_id) REFERENCES public.profiles(id);
    END IF;
  END IF;

  -- kanban_historico
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_historico' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'kanban_historico_cartao_id_fkey'
    ) THEN
      ALTER TABLE rh_kanban_historico DROP CONSTRAINT kanban_historico_cartao_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_kanban_historico_cartao_id_fkey'
      ) THEN
        ALTER TABLE rh_kanban_historico
        ADD CONSTRAINT rh_kanban_historico_cartao_id_fkey 
        FOREIGN KEY (cartao_id) REFERENCES rh_kanban_cartoes(id);
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'kanban_historico_movido_por_fkey'
    ) THEN
      ALTER TABLE rh_kanban_historico DROP CONSTRAINT kanban_historico_movido_por_fkey;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_kanban_historico_movido_por_fkey'
    ) THEN
      ALTER TABLE rh_kanban_historico
      ADD CONSTRAINT rh_kanban_historico_movido_por_fkey 
      FOREIGN KEY (movido_por) REFERENCES public.profiles(id);
    END IF;
  END IF;
END $$;

-- Atualizar FKs de outras tabelas RH
DO $$
BEGIN
  -- acoes_rapidas
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_acoes_rapidas' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'acoes_rapidas_colaborador_id_fkey'
    ) THEN
      ALTER TABLE rh_acoes_rapidas DROP CONSTRAINT acoes_rapidas_colaborador_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_acoes_rapidas_colaborador_id_fkey'
      ) THEN
        ALTER TABLE rh_acoes_rapidas
        ADD CONSTRAINT rh_acoes_rapidas_colaborador_id_fkey 
        FOREIGN KEY (colaborador_id) REFERENCES rh_colaboradores("ID");
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'acoes_rapidas_executado_por_fkey_new'
    ) THEN
      ALTER TABLE rh_acoes_rapidas DROP CONSTRAINT acoes_rapidas_executado_por_fkey_new;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_acoes_rapidas_executado_por_fkey'
    ) THEN
      ALTER TABLE rh_acoes_rapidas
      ADD CONSTRAINT rh_acoes_rapidas_executado_por_fkey 
      FOREIGN KEY (executado_por) REFERENCES public.profiles(id);
    END IF;
  END IF;

  -- documentos_gerados
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_gerados' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'documentos_gerados_template_id_fkey'
    ) THEN
      ALTER TABLE rh_documentos_gerados DROP CONSTRAINT documentos_gerados_template_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_templates' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_documentos_gerados_template_id_fkey'
      ) THEN
        ALTER TABLE rh_documentos_gerados
        ADD CONSTRAINT rh_documentos_gerados_template_id_fkey 
        FOREIGN KEY (template_id) REFERENCES rh_documentos_templates(id);
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'documentos_gerados_colaborador_id_fkey'
    ) THEN
      ALTER TABLE rh_documentos_gerados DROP CONSTRAINT documentos_gerados_colaborador_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_documentos_gerados_colaborador_id_fkey'
      ) THEN
        ALTER TABLE rh_documentos_gerados
        ADD CONSTRAINT rh_documentos_gerados_colaborador_id_fkey 
        FOREIGN KEY (colaborador_id) REFERENCES rh_colaboradores("ID");
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'documentos_gerados_gerado_por_fkey_new'
    ) THEN
      ALTER TABLE rh_documentos_gerados DROP CONSTRAINT documentos_gerados_gerado_por_fkey_new;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_documentos_gerados_gerado_por_fkey'
    ) THEN
      ALTER TABLE rh_documentos_gerados
      ADD CONSTRAINT rh_documentos_gerados_gerado_por_fkey 
      FOREIGN KEY (gerado_por) REFERENCES public.profiles(id);
    END IF;
  END IF;

  -- calendario_eventos
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_calendario_eventos' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'calendario_eventos_colaborador_id_fkey'
    ) THEN
      ALTER TABLE rh_calendario_eventos DROP CONSTRAINT calendario_eventos_colaborador_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_calendario_eventos_colaborador_id_fkey'
      ) THEN
        ALTER TABLE rh_calendario_eventos
        ADD CONSTRAINT rh_calendario_eventos_colaborador_id_fkey 
        FOREIGN KEY (colaborador_id) REFERENCES rh_colaboradores("ID");
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'calendario_eventos_departamento_id_fkey'
    ) THEN
      ALTER TABLE rh_calendario_eventos DROP CONSTRAINT calendario_eventos_departamento_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_calendario_eventos_departamento_id_fkey'
      ) THEN
        ALTER TABLE rh_calendario_eventos
        ADD CONSTRAINT rh_calendario_eventos_departamento_id_fkey 
        FOREIGN KEY (departamento_id) REFERENCES rh_departamentos("Departamento");
      END IF;
    END IF;
  END IF;

  -- calendario_alertas
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_calendario_alertas' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'calendario_alertas_evento_id_fkey'
    ) THEN
      ALTER TABLE rh_calendario_alertas DROP CONSTRAINT calendario_alertas_evento_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_calendario_eventos' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_calendario_alertas_evento_id_fkey'
      ) THEN
        ALTER TABLE rh_calendario_alertas
        ADD CONSTRAINT rh_calendario_alertas_evento_id_fkey 
        FOREIGN KEY (evento_id) REFERENCES rh_calendario_eventos(id);
      END IF;
    END IF;
  END IF;

  -- notificacoes
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notificacoes' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'notificacoes_usuario_id_fkey_new'
    ) THEN
      ALTER TABLE rh_notificacoes DROP CONSTRAINT notificacoes_usuario_id_fkey_new;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_notificacoes_usuario_id_fkey'
    ) THEN
      ALTER TABLE rh_notificacoes
      ADD CONSTRAINT rh_notificacoes_usuario_id_fkey 
      FOREIGN KEY (usuario_id) REFERENCES public.profiles(id);
    END IF;
  END IF;

  -- relatorios_gerados
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_gerados' AND table_schema = 'public') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'relatorios_gerados_config_id_fkey'
    ) THEN
      ALTER TABLE rh_relatorios_gerados DROP CONSTRAINT relatorios_gerados_config_id_fkey;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_config' AND table_schema = 'public') THEN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'rh_relatorios_gerados_config_id_fkey'
      ) THEN
        ALTER TABLE rh_relatorios_gerados
        ADD CONSTRAINT rh_relatorios_gerados_config_id_fkey 
        FOREIGN KEY (config_id) REFERENCES rh_relatorios_config(id);
      END IF;
    END IF;

    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'relatorios_gerados_gerado_por_fkey_new'
    ) THEN
      ALTER TABLE rh_relatorios_gerados DROP CONSTRAINT relatorios_gerados_gerado_por_fkey_new;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'rh_relatorios_gerados_gerado_por_fkey'
    ) THEN
      ALTER TABLE rh_relatorios_gerados
      ADD CONSTRAINT rh_relatorios_gerados_gerado_por_fkey 
      FOREIGN KEY (gerado_por) REFERENCES public.profiles(id);
    END IF;
  END IF;
END $$;

-- ============================================
-- PARTE 10: CRIAR VIEWS DE COMPATIBILIDADE
-- ============================================

-- Views para projeto de medições (manter compatibilidade temporária)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_hidrometros' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.hidrometros;
    CREATE VIEW public.hidrometros AS SELECT * FROM public.med_hidrometros;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_energia' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.energia;
    CREATE VIEW public.energia AS SELECT * FROM public.med_energia;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_medidores' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.medidores;
    CREATE VIEW public.medidores AS SELECT * FROM public.med_medidores;
  END IF;
END $$;

-- Views para projeto de RH (manter compatibilidade temporária)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Colaboradores";
    CREATE VIEW public."Colaboradores" AS SELECT * FROM public.rh_colaboradores;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."CCs";
    CREATE VIEW public."CCs" AS SELECT * FROM public.rh_departamentos;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_etapas' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Etapas";
    CREATE VIEW public."Etapas" AS SELECT * FROM public.rh_etapas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_itens' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Itens";
    CREATE VIEW public."Itens" AS SELECT * FROM public.rh_itens;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_acesso' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Registros";
    CREATE VIEW public."Registros" AS SELECT * FROM public.rh_registros_acesso;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_celulares' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."CELULARES";
    CREATE VIEW public."CELULARES" AS SELECT * FROM public.rh_celulares;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notebooks' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."NOTEBOOK";
    CREATE VIEW public."NOTEBOOK" AS SELECT * FROM public.rh_notebooks;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_linhas_telefonicas' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."LINHAS";
    CREATE VIEW public."LINHAS" AS SELECT * FROM public.rh_linhas_telefonicas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_linhas' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."REGISTROS LINHAS";
    CREATE VIEW public."REGISTROS LINHAS" AS SELECT * FROM public.rh_registros_linhas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_notebooks' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."REGISTROS NOTEBOOKS";
    CREATE VIEW public."REGISTROS NOTEBOOKS" AS SELECT * FROM public.rh_registros_notebooks;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_registros_celulares' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."RGISTROS CELULARES";
    CREATE VIEW public."RGISTROS CELULARES" AS SELECT * FROM public.rh_registros_celulares;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_comentarios' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Comentários";
    CREATE VIEW public."Comentários" AS SELECT * FROM public.rh_comentarios;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_anexos' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."ANEXOS";
    CREATE VIEW public."ANEXOS" AS SELECT * FROM public.rh_anexos;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_apoios' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Apoios";
    CREATE VIEW public."Apoios" AS SELECT * FROM public.rh_apoios;
  END IF;
  
  -- Views para tabelas que já tinham nomes em minúsculas
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.kanban_cartoes;
    CREATE VIEW public.kanban_cartoes AS SELECT * FROM public.rh_kanban_cartoes;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_comentarios' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.kanban_comentarios;
    CREATE VIEW public.kanban_comentarios AS SELECT * FROM public.rh_kanban_comentarios;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_historico' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.kanban_historico;
    CREATE VIEW public.kanban_historico AS SELECT * FROM public.rh_kanban_historico;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_acoes_rapidas' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.acoes_rapidas;
    CREATE VIEW public.acoes_rapidas AS SELECT * FROM public.rh_acoes_rapidas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_templates' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.documentos_templates;
    CREATE VIEW public.documentos_templates AS SELECT * FROM public.rh_documentos_templates;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_gerados' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.documentos_gerados;
    CREATE VIEW public.documentos_gerados AS SELECT * FROM public.rh_documentos_gerados;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_calendario_eventos' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.calendario_eventos;
    CREATE VIEW public.calendario_eventos AS SELECT * FROM public.rh_calendario_eventos;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_calendario_alertas' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.calendario_alertas;
    CREATE VIEW public.calendario_alertas AS SELECT * FROM public.rh_calendario_alertas;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notificacoes' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.notificacoes;
    CREATE VIEW public.notificacoes AS SELECT * FROM public.rh_notificacoes;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_config' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.relatorios_config;
    CREATE VIEW public.relatorios_config AS SELECT * FROM public.rh_relatorios_config;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_gerados' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.relatorios_gerados;
    CREATE VIEW public.relatorios_gerados AS SELECT * FROM public.rh_relatorios_gerados;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_configuracoes' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.configuracoes;
    CREATE VIEW public.configuracoes AS SELECT * FROM public.rh_configuracoes;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_painel_metricas' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.painel_metricas;
    CREATE VIEW public.painel_metricas AS SELECT * FROM public.rh_painel_metricas;
  END IF;
END $$;

-- ============================================
-- PARTE 11: APLICAR RLS (ROW LEVEL SECURITY)
-- ============================================

-- Habilitar RLS na tabela profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver seu próprio perfil
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Política: Usuários podem atualizar seu próprio perfil
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Política: Usuários autenticados podem ver outros perfis
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
CREATE POLICY "Authenticated users can view profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Política: Apenas admins podem inserir perfis (via trigger normalmente)
DROP POLICY IF EXISTS "Only admins can insert profiles" ON public.profiles;
CREATE POLICY "Only admins can insert profiles"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS para tabelas de medições
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_energia' AND table_schema = 'public') THEN
    ALTER TABLE public.med_energia ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can view energia records" ON public.med_energia;
    CREATE POLICY "Users can view energia records"
      ON public.med_energia
      FOR SELECT
      TO authenticated
      USING (true);

    DROP POLICY IF EXISTS "Users can insert energia records" ON public.med_energia;
    CREATE POLICY "Users can insert energia records"
      ON public.med_energia
      FOR INSERT
      TO authenticated
      WITH CHECK (true);

    DROP POLICY IF EXISTS "Users can update own energia records" ON public.med_energia;
    CREATE POLICY "Users can update own energia records"
      ON public.med_energia
      FOR UPDATE
      TO authenticated
      USING (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()))
      WITH CHECK (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_hidrometros' AND table_schema = 'public') THEN
    ALTER TABLE public.med_hidrometros ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can view hidrometros records" ON public.med_hidrometros;
    CREATE POLICY "Users can view hidrometros records"
      ON public.med_hidrometros
      FOR SELECT
      TO authenticated
      USING (true);

    DROP POLICY IF EXISTS "Users can insert hidrometros records" ON public.med_hidrometros;
    CREATE POLICY "Users can insert hidrometros records"
      ON public.med_hidrometros
      FOR INSERT
      TO authenticated
      WITH CHECK (true);

    DROP POLICY IF EXISTS "Users can update own hidrometros records" ON public.med_hidrometros;
    CREATE POLICY "Users can update own hidrometros records"
      ON public.med_hidrometros
      FOR UPDATE
      TO authenticated
      USING (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()))
      WITH CHECK (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_medidores' AND table_schema = 'public') THEN
    ALTER TABLE public.med_medidores ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can view medidores" ON public.med_medidores;
    CREATE POLICY "Users can view medidores"
      ON public.med_medidores
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- RLS para tokens_acesso
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tokens_acesso' AND table_schema = 'public') THEN
    ALTER TABLE public.tokens_acesso ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Authenticated users can view active tokens" ON public.tokens_acesso;
    CREATE POLICY "Authenticated users can view active tokens"
      ON public.tokens_acesso
      FOR SELECT
      TO authenticated
      USING (ativo = true);

    DROP POLICY IF EXISTS "Only admins can manage tokens" ON public.tokens_acesso;
    CREATE POLICY "Only admins can manage tokens"
      ON public.tokens_acesso
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
      );
  END IF;
END $$;

-- ============================================
-- PARTE 12: COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================

COMMENT ON TABLE public.profiles IS 'Tabela de perfis de usuários ligada ao auth.users';
COMMENT ON TABLE public.med_hidrometros IS 'Tabela de leituras de hidrômetros - Projeto de Medições';
COMMENT ON TABLE public.med_energia IS 'Tabela de leituras de energia elétrica - Projeto de Medições';
COMMENT ON TABLE public.med_medidores IS 'Cadastro de medidores (água e energia) - Projeto de Medições';
COMMENT ON TABLE public.rh_colaboradores IS 'Cadastro de colaboradores - Projeto de RH';
COMMENT ON TABLE public.rh_departamentos IS 'Centros de custo e departamentos - Projeto de RH';

COMMENT ON VIEW public.hidrometros IS 'View de compatibilidade - usar med_hidrometros';
COMMENT ON VIEW public.energia IS 'View de compatibilidade - usar med_energia';
COMMENT ON VIEW public.medidores IS 'View de compatibilidade - usar med_medidores';

