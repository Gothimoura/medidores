# 🔧 Solução para Erro PGRST204 - Campo 'ativo' não encontrado

## ❌ Erro
```
PGRST204: Could not find the 'ativo' column of 'med_medidores' in the schema cache
```

## ✅ Solução Passo a Passo

### 1. Execute o Script SQL no Supabase

1. Acesse o **Supabase Dashboard**: https://app.supabase.com
2. Selecione seu projeto
3. No menu lateral, clique em **SQL Editor**
4. Clique em **New Query** (ou use o editor existente)
5. Copie e cole o conteúdo completo do arquivo `sql/adicionar_campo_ativo.sql`:

```sql
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
```

6. Clique em **Run** (ou pressione `Ctrl+Enter` / `Cmd+Enter`)
7. Verifique se a mensagem de sucesso aparece: "Success. No rows returned"

### 2. Aguarde a Atualização do Cache

O Supabase PostgREST precisa atualizar seu cache de schema. Isso geralmente leva:
- **10-30 segundos** após executar o script SQL
- Pode levar até **1-2 minutos** em alguns casos

### 3. Recarregue a Aplicação

1. Recarregue a página da aplicação (F5 ou Ctrl+R)
2. Aguarde a página carregar completamente
3. Tente desativar um medidor novamente

### 4. Verificação (Opcional)

Se quiser verificar se o campo foi criado corretamente:

1. No Supabase Dashboard, vá em **Table Editor**
2. Selecione a tabela `med_medidores`
3. Verifique se a coluna `ativo` aparece na lista de colunas
4. Verifique se todos os registros têm `ativo = true` (ou `t`)

## 🐛 Se o Erro Persistir

### Verifique se o script foi executado:
- No SQL Editor, verifique o histórico de queries executadas
- Procure por mensagens de erro na execução do script

### Verifique permissões:
- Certifique-se de que você tem permissão para alterar a estrutura da tabela
- O usuário precisa ter privilégios de `ALTER TABLE`

### Tente forçar atualização do cache:
1. No Supabase Dashboard, vá em **Settings** > **API**
2. Role até **PostgREST**
3. Clique em **Reload Schema** (se disponível)
4. Ou aguarde alguns minutos e tente novamente

### Verifique a estrutura da tabela:
Execute esta query no SQL Editor para verificar se a coluna existe:

```sql
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'med_medidores' 
  AND column_name = 'ativo';
```

Se retornar uma linha, a coluna existe. Se não retornar nada, execute o script novamente.

## 📝 Notas Importantes

- O campo `ativo` será criado com valor padrão `true` para todos os registros existentes
- Novos medidores serão criados automaticamente com `ativo = true`
- Medidores desativados (`ativo = false`) não aparecerão nas leituras
- O histórico de leituras dos medidores desativados será preservado

## ✅ Após Resolver

Após executar o script e aguardar a atualização do cache:
- ✅ Você poderá desativar medidores
- ✅ Você poderá reativar medidores desativados
- ✅ Os medidores desativados não aparecerão nas leituras
- ✅ O histórico será preservado
