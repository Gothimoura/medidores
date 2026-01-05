-- Migration: Criar tabela profiles e atualizar referências
-- Data: 2024-01-01
-- Descrição: Cria tabela profiles ligada ao auth.users, migra dados de Users,
--            atualiza foreign keys e aplica RLS

-- ============================================
-- 1. CRIAR TABELA PROFILES
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
-- 2. MIGRAR DADOS DE Users PARA profiles
-- ============================================

-- Insere dados existentes da tabela Users para profiles
-- Apenas para registros que têm correspondência no auth.users
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

-- ============================================
-- 3. ATUALIZAR FOREIGN KEYS DAS TABELAS RELACIONADAS
-- ============================================

-- Atualizar tabela Comentários
-- Verifica se a constraint existe antes de tentar alterar
DO $$
BEGIN
  -- Remove constraint antiga se existir
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'Comentários_Usuário id_fkey'
    AND table_name = 'Comentários'
  ) THEN
    ALTER TABLE public."Comentários" 
    DROP CONSTRAINT IF EXISTS "Comentários_Usuário id_fkey";
  END IF;
  
  -- Adiciona nova constraint apontando para profiles
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'comentarios_usuario_id_fkey'
    AND table_name = 'Comentários'
  ) THEN
    ALTER TABLE public."Comentários"
    ADD CONSTRAINT comentarios_usuario_id_fkey 
    FOREIGN KEY ("Usuário id") REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Atualizar tabela acoes_rapidas
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'acoes_rapidas_executado_por_fkey'
  ) THEN
    ALTER TABLE public.acoes_rapidas 
    DROP CONSTRAINT IF EXISTS acoes_rapidas_executado_por_fkey;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'acoes_rapidas_executado_por_fkey_new'
  ) THEN
    ALTER TABLE public.acoes_rapidas
    ADD CONSTRAINT acoes_rapidas_executado_por_fkey_new 
    FOREIGN KEY (executado_por) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Atualizar tabela documentos_gerados
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'documentos_gerados_gerado_por_fkey'
  ) THEN
    ALTER TABLE public.documentos_gerados 
    DROP CONSTRAINT IF EXISTS documentos_gerados_gerado_por_fkey;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'documentos_gerados_gerado_por_fkey_new'
  ) THEN
    ALTER TABLE public.documentos_gerados
    ADD CONSTRAINT documentos_gerados_gerado_por_fkey_new 
    FOREIGN KEY (gerado_por) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Atualizar tabela kanban_comentarios
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'kanban_comentarios_usuario_id_fkey'
  ) THEN
    ALTER TABLE public.kanban_comentarios 
    DROP CONSTRAINT IF EXISTS kanban_comentarios_usuario_id_fkey;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'kanban_comentarios_usuario_id_fkey_new'
  ) THEN
    ALTER TABLE public.kanban_comentarios
    ADD CONSTRAINT kanban_comentarios_usuario_id_fkey_new 
    FOREIGN KEY (usuario_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Atualizar tabela kanban_historico
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'kanban_historico_movido_por_fkey'
  ) THEN
    ALTER TABLE public.kanban_historico 
    DROP CONSTRAINT IF EXISTS kanban_historico_movido_por_fkey;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'kanban_historico_movido_por_fkey_new'
  ) THEN
    ALTER TABLE public.kanban_historico
    ADD CONSTRAINT kanban_historico_movido_por_fkey_new 
    FOREIGN KEY (movido_por) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Atualizar tabela notificacoes
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'notificacoes_usuario_id_fkey'
  ) THEN
    ALTER TABLE public.notificacoes 
    DROP CONSTRAINT IF EXISTS notificacoes_usuario_id_fkey;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'notificacoes_usuario_id_fkey_new'
  ) THEN
    ALTER TABLE public.notificacoes
    ADD CONSTRAINT notificacoes_usuario_id_fkey_new 
    FOREIGN KEY (usuario_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Atualizar tabela relatorios_gerados
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'relatorios_gerados_gerado_por_fkey'
  ) THEN
    ALTER TABLE public.relatorios_gerados 
    DROP CONSTRAINT IF EXISTS relatorios_gerados_gerado_por_fkey;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'relatorios_gerados_gerado_por_fkey_new'
  ) THEN
    ALTER TABLE public.relatorios_gerados
    ADD CONSTRAINT relatorios_gerados_gerado_por_fkey_new 
    FOREIGN KEY (gerado_por) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================
-- 4. FUNÇÃO PARA CRIAR PROFILE AUTOMATICAMENTE
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
-- 5. FUNÇÃO PARA ATUALIZAR updated_at
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
-- 6. APLICAR RLS (ROW LEVEL SECURITY)
-- ============================================

-- Habilitar RLS na tabela profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver seu próprio perfil
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Política: Usuários podem atualizar seu próprio perfil
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Política: Usuários autenticados podem ver outros perfis (ajuste conforme necessário)
CREATE POLICY "Authenticated users can view profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Política: Apenas admins podem inserir perfis (via trigger normalmente)
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

-- Habilitar RLS em outras tabelas relacionadas

-- RLS para tabela energia
ALTER TABLE public.energia ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view energia records"
  ON public.energia
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert energia records"
  ON public.energia
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own energia records"
  ON public.energia
  FOR UPDATE
  TO authenticated
  USING (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()));

-- RLS para tabela hidrometros
ALTER TABLE public.hidrometros ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view hidrometros records"
  ON public.hidrometros
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert hidrometros records"
  ON public.hidrometros
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own hidrometros records"
  ON public.hidrometros
  FOR UPDATE
  TO authenticated
  USING (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (usuario = (SELECT email FROM public.profiles WHERE id = auth.uid()));

-- RLS para tabela tokens_acesso
ALTER TABLE public.tokens_acesso ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view active tokens"
  ON public.tokens_acesso
  FOR SELECT
  TO authenticated
  USING (ativo = true);

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

-- RLS para tabela notificacoes
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON public.notificacoes
  FOR SELECT
  TO authenticated
  USING (usuario_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON public.notificacoes
  FOR UPDATE
  TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- RLS para tabela kanban_comentarios
ALTER TABLE public.kanban_comentarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view kanban comments"
  ON public.kanban_comentarios
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert kanban comments"
  ON public.kanban_comentarios
  FOR INSERT
  TO authenticated
  WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "Users can update own kanban comments"
  ON public.kanban_comentarios
  FOR UPDATE
  TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- RLS para tabela kanban_historico
ALTER TABLE public.kanban_historico ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view kanban history"
  ON public.kanban_historico
  FOR SELECT
  TO authenticated
  USING (true);

-- RLS para tabela acoes_rapidas
ALTER TABLE public.acoes_rapidas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view acoes_rapidas"
  ON public.acoes_rapidas
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert acoes_rapidas"
  ON public.acoes_rapidas
  FOR INSERT
  TO authenticated
  WITH CHECK (executado_por = auth.uid());

-- RLS para tabela documentos_gerados
ALTER TABLE public.documentos_gerados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents"
  ON public.documentos_gerados
  FOR SELECT
  TO authenticated
  USING (
    gerado_por = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- RLS para tabela relatorios_gerados
ALTER TABLE public.relatorios_gerados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reports"
  ON public.relatorios_gerados
  FOR SELECT
  TO authenticated
  USING (
    gerado_por = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- ============================================
-- 7. VIEW DE COMPATIBILIDADE (OPCIONAL)
-- ============================================

-- View para manter compatibilidade com código que ainda usa Users
-- Pode ser removida após atualizar todo o código
CREATE OR REPLACE VIEW public."Users" AS
SELECT 
  id::text as "Row ID",
  name as "Name",
  email as "Email",
  photo as "Photo",
  role as "Role",
  export as "Export",
  view as "View"
FROM public.profiles;

-- Comentário explicativo
COMMENT ON TABLE public.profiles IS 'Tabela de perfis de usuários ligada ao auth.users';
COMMENT ON VIEW public."Users" IS 'View de compatibilidade - usar profiles diretamente';


