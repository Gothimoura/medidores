-- Script SQL para adicionar o campo 'ativo' na tabela med_medidores
-- Execute este script no Supabase SQL Editor
-- IMPORTANTE: Após executar, aguarde alguns segundos para o cache do PostgREST atualizar

-- Adiciona a coluna 'ativo' do tipo boolean com valor padrão true
-- O DEFAULT true garante que todos os registros existentes serão marcados como ativos
ALTER TABLE med_medidores 
ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT true NOT NULL;

-- Cria um índice para melhorar a performance das consultas filtradas
CREATE INDEX IF NOT EXISTS idx_med_medidores_ativo ON med_medidores(ativo);

-- Comentário na coluna para documentação
COMMENT ON COLUMN med_medidores.ativo IS 'Indica se o medidor está ativo (true) ou desativado (false). Medidores desativados não aparecem nas leituras.';

-- NOTA: Se ainda receber erro PGRST204 após executar este script:
-- 1. Aguarde 10-30 segundos para o cache do PostgREST atualizar
-- 2. Recarregue a página da aplicação
-- 3. Tente novamente desativar o medidor
