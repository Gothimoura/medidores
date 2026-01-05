-- ============================================
-- ADICIONAR COLUNAS DE ACESSO NA TABELA PROFILES
-- Data: 2024-01-12
-- Descrição: Adiciona colunas para controlar acesso aos sistemas
-- ============================================

-- Adiciona colunas de acesso se não existirem
DO $$
BEGIN
  -- Coluna para acesso ao sistema de medições
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'access_medicoes'
  ) THEN
    ALTER TABLE public.profiles 
    ADD COLUMN access_medicoes boolean DEFAULT true;
    
    RAISE NOTICE 'Coluna access_medicoes adicionada';
  END IF;

  -- Coluna para acesso ao sistema de RH
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'access_dp_rh'
  ) THEN
    ALTER TABLE public.profiles 
    ADD COLUMN access_dp_rh boolean DEFAULT false;
    
    RAISE NOTICE 'Coluna access_dp_rh adicionada';
  END IF;

  -- Atualiza usuários existentes: todos têm acesso a medições por padrão
  UPDATE public.profiles 
  SET access_medicoes = COALESCE(access_medicoes, true),
      access_dp_rh = COALESCE(access_dp_rh, false)
  WHERE access_medicoes IS NULL OR access_dp_rh IS NULL;
  
  RAISE NOTICE 'Valores padrão aplicados aos usuários existentes';
END $$;

-- Comentários nas colunas
COMMENT ON COLUMN public.profiles.access_medicoes IS 'Indica se o usuário tem acesso ao sistema de medições (água e energia)';
COMMENT ON COLUMN public.profiles.access_dp_rh IS 'Indica se o usuário tem acesso ao sistema de RH (Departamento Pessoal)';

