# Scripts SQL para o Banco de Dados

## Adicionar Campo Ativo

O arquivo `adicionar_campo_ativo.sql` adiciona o campo `ativo` na tabela `med_medidores` para permitir desativar medidores sem excluí-los do banco de dados.

### Como executar:

1. Acesse o **Supabase Dashboard**
2. Vá em **SQL Editor** (no menu lateral)
3. Clique em **New Query**
4. Copie e cole o conteúdo do arquivo `adicionar_campo_ativo.sql`
5. Clique em **Run** ou pressione `Ctrl+Enter`

### O que o script faz:

- Adiciona a coluna `ativo` do tipo `BOOLEAN` com valor padrão `true`
- Atualiza todos os registros existentes para `ativo = true`
- Cria um índice para melhorar a performance das consultas
- Adiciona um comentário na coluna para documentação

### Após executar:

Após executar o script, você poderá:
- ✅ Desativar medidores sem excluí-los do banco
- ✅ Reativar medidores desativados
- ✅ Filtrar medidores ativos/desativados
- ✅ Medidores desativados não aparecerão nas leituras
