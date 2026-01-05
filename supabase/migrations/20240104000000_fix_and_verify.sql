-- ============================================
-- MIGRATION DE CORREÇÃO E VERIFICAÇÃO
-- Data: 2024-01-04
-- Descrição: Corrige problemas residuais e verifica integridade
-- ============================================

-- ============================================
-- PARTE 1: VERIFICAR E RECRIAR VIEWS DE COMPATIBILIDADE
-- ============================================

-- Garantir que as views de compatibilidade existem e funcionam
DO $$
BEGIN
  -- Views para projeto de medições
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_hidrometros' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.hidrometros CASCADE;
    CREATE VIEW public.hidrometros AS SELECT * FROM public.med_hidrometros;
    GRANT SELECT ON public.hidrometros TO authenticated;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_energia' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.energia CASCADE;
    CREATE VIEW public.energia AS SELECT * FROM public.med_energia;
    GRANT SELECT ON public.energia TO authenticated;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_medidores' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public.medidores CASCADE;
    CREATE VIEW public.medidores AS SELECT * FROM public.med_medidores;
    GRANT SELECT ON public.medidores TO authenticated;
  END IF;

  -- Views para projeto de RH (se necessário)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_colaboradores' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."Colaboradores" CASCADE;
    CREATE VIEW public."Colaboradores" AS SELECT * FROM public.rh_colaboradores;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_departamentos' AND table_schema = 'public') THEN
    DROP VIEW IF EXISTS public."CCs" CASCADE;
    CREATE VIEW public."CCs" AS SELECT * FROM public.rh_departamentos;
  END IF;
END $$;

-- ============================================
-- PARTE 2: GARANTIR QUE PROFILES TEM DADOS CORRETOS
-- ============================================

-- Sincronizar profiles com auth.users (caso algum usuário tenha sido criado sem profile)
DO $$
BEGIN
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
END $$;

-- ============================================
-- PARTE 3: VERIFICAR E CORRIGIR FOREIGN KEYS QUEBRADAS
-- ============================================

-- Remove foreign keys que referenciam tabelas que não existem mais
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Lista todas as foreign keys e verifica se a tabela referenciada existe
  FOR r IN (
    SELECT 
      tc.table_name,
      tc.constraint_name,
      kcu.column_name,
      ccu.table_name AS foreign_table_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
  ) LOOP
    -- Se a tabela referenciada não existe, remove a constraint
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_name = r.foreign_table_name 
      AND table_schema = 'public'
    ) THEN
      BEGIN
        EXECUTE 'ALTER TABLE ' || quote_ident(r.table_name) || 
                ' DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
        RAISE NOTICE 'Removida FK quebrada: % em %', r.constraint_name, r.table_name;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Erro ao remover FK %: %', r.constraint_name, SQLERRM;
      END;
    END IF;
  END LOOP;
END $$;

-- ============================================
-- PARTE 4: GARANTIR RLS ESTÁ APLICADO CORRETAMENTE
-- ============================================

-- Verificar e aplicar RLS nas tabelas de medições
DO $$
BEGIN
  -- med_hidrometros
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_hidrometros' AND table_schema = 'public') THEN
    ALTER TABLE public.med_hidrometros ENABLE ROW LEVEL SECURITY;
    
    -- Remove políticas antigas se existirem
    DROP POLICY IF EXISTS "Users can view hidrometros records" ON public.med_hidrometros;
    DROP POLICY IF EXISTS "Users can insert hidrometros records" ON public.med_hidrometros;
    DROP POLICY IF EXISTS "Users can update own hidrometros records" ON public.med_hidrometros;
    
    -- Cria políticas novas
    CREATE POLICY "Users can view hidrometros records"
      ON public.med_hidrometros FOR SELECT
      TO authenticated USING (true);
    
    CREATE POLICY "Users can insert hidrometros records"
      ON public.med_hidrometros FOR INSERT
      TO authenticated WITH CHECK (true);
    
    CREATE POLICY "Users can update own hidrometros records"
      ON public.med_hidrometros FOR UPDATE
      TO authenticated
      USING (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()))
      WITH CHECK (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()));
  END IF;

  -- med_energia
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_energia' AND table_schema = 'public') THEN
    ALTER TABLE public.med_energia ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "Users can view energia records" ON public.med_energia;
    DROP POLICY IF EXISTS "Users can insert energia records" ON public.med_energia;
    DROP POLICY IF EXISTS "Users can update own energia records" ON public.med_energia;
    
    CREATE POLICY "Users can view energia records"
      ON public.med_energia FOR SELECT
      TO authenticated USING (true);
    
    CREATE POLICY "Users can insert energia records"
      ON public.med_energia FOR INSERT
      TO authenticated WITH CHECK (true);
    
    CREATE POLICY "Users can update own energia records"
      ON public.med_energia FOR UPDATE
      TO authenticated
      USING (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()))
      WITH CHECK (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()));
  END IF;

  -- med_medidores
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'med_medidores' AND table_schema = 'public') THEN
    ALTER TABLE public.med_medidores ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "Users can view medidores" ON public.med_medidores;
    
    CREATE POLICY "Users can view medidores"
      ON public.med_medidores FOR SELECT
      TO authenticated USING (true);
  END IF;
END $$;

-- ============================================
-- PARTE 5: VERIFICAR INTEGRIDADE DOS DADOS
-- ============================================

-- Limpar referências inválidas em colunas UUID que foram convertidas
DO $$
BEGIN
  -- rh_comentarios - limpar UUIDs inválidos
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_comentarios' AND table_schema = 'public') THEN
    UPDATE rh_comentarios 
    SET "Usuário id" = NULL 
    WHERE "Usuário id" IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_comentarios."Usuário id"
      );
  END IF;

  -- rh_kanban_cartoes
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_cartoes' AND table_schema = 'public') THEN
    UPDATE rh_kanban_cartoes 
    SET responsavel_id = NULL 
    WHERE responsavel_id IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_kanban_cartoes.responsavel_id
      );
  END IF;

  -- rh_kanban_comentarios
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_comentarios' AND table_schema = 'public') THEN
    UPDATE rh_kanban_comentarios 
    SET usuario_id = NULL 
    WHERE usuario_id IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_kanban_comentarios.usuario_id
      );
  END IF;

  -- rh_kanban_historico
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_kanban_historico' AND table_schema = 'public') THEN
    UPDATE rh_kanban_historico 
    SET movido_por = NULL 
    WHERE movido_por IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_kanban_historico.movido_por
      );
  END IF;

  -- rh_acoes_rapidas
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_acoes_rapidas' AND table_schema = 'public') THEN
    UPDATE rh_acoes_rapidas 
    SET executado_por = NULL 
    WHERE executado_por IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_acoes_rapidas.executado_por
      );
  END IF;

  -- rh_documentos_gerados
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_documentos_gerados' AND table_schema = 'public') THEN
    UPDATE rh_documentos_gerados 
    SET gerado_por = NULL 
    WHERE gerado_por IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_documentos_gerados.gerado_por
      );
  END IF;

  -- rh_notificacoes
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_notificacoes' AND table_schema = 'public') THEN
    UPDATE rh_notificacoes 
    SET usuario_id = NULL 
    WHERE usuario_id IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_notificacoes.usuario_id
      );
  END IF;

  -- rh_relatorios_gerados
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rh_relatorios_gerados' AND table_schema = 'public') THEN
    UPDATE rh_relatorios_gerados 
    SET gerado_por = NULL 
    WHERE gerado_por IS NOT NULL 
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = rh_relatorios_gerados.gerado_por
      );
  END IF;
END $$;

-- ============================================
-- PARTE 6: GARANTIR PERMISSÕES CORRETAS
-- ============================================

-- Dar permissões necessárias nas tabelas
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Dar permissões específicas nas tabelas de medições
GRANT SELECT, INSERT, UPDATE, DELETE ON public.med_hidrometros TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.med_energia TO authenticated;
GRANT SELECT ON public.med_medidores TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;

-- ============================================
-- PARTE 7: COMENTÁRIOS FINAIS
-- ============================================

COMMENT ON TABLE public.profiles IS 'Tabela de perfis de usuários ligada ao auth.users - ATUALIZADA';
COMMENT ON TABLE public.med_hidrometros IS 'Tabela de leituras de hidrômetros - Projeto de Medições - ATUALIZADA';
COMMENT ON TABLE public.med_energia IS 'Tabela de leituras de energia elétrica - Projeto de Medições - ATUALIZADA';
COMMENT ON TABLE public.med_medidores IS 'Cadastro de medidores (água e energia) - Projeto de Medições - ATUALIZADA';

COMMENT ON VIEW public.hidrometros IS 'View de compatibilidade - usar med_hidrometros diretamente';
COMMENT ON VIEW public.energia IS 'View de compatibilidade - usar med_energia diretamente';
COMMENT ON VIEW public.medidores IS 'View de compatibilidade - usar med_medidores diretamente';

