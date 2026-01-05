# Migrations do Supabase

## Como aplicar as migrations

### Opção 1: Via Supabase Dashboard (Recomendado)

1. Acesse o Supabase Dashboard
2. Vá em **SQL Editor**
3. Copie o conteúdo do arquivo `20240101000000_create_profiles_and_update_references.sql`
4. Cole no editor SQL
5. Execute a query

### Opção 2: Via Supabase CLI

```bash
# Se você tiver o Supabase CLI instalado
supabase db push
```

### Opção 3: Via psql

```bash
psql -h [seu-host] -U postgres -d postgres -f supabase/migrations/20240101000000_create_profiles_and_update_references.sql
```

## O que esta migration faz:

1. **Cria tabela `profiles`**: Tabela ligada ao `auth.users` do Supabase
2. **Migra dados**: Copia dados existentes de `Users` para `profiles`
3. **Atualiza foreign keys**: Atualiza todas as referências de `Users` para `profiles`
4. **Aplica RLS**: Configura Row Level Security em todas as tabelas relevantes
5. **Cria triggers**: Automatiza criação de profiles quando usuários são criados
6. **Cria view de compatibilidade**: Mantém view `Users` para código legado

## Tabelas atualizadas:

- `Comentários` → `usuario_id` referencia `profiles.id`
- `acoes_rapidas` → `executado_por` referencia `profiles.id`
- `documentos_gerados` → `gerado_por` referencia `profiles.id`
- `kanban_comentarios` → `usuario_id` referencia `profiles.id`
- `kanban_historico` → `movido_por` referencia `profiles.id`
- `notificacoes` → `usuario_id` referencia `profiles.id`
- `relatorios_gerados` → `gerado_por` referencia `profiles.id`

## RLS Aplicado:

- `profiles`: Usuários veem/atualizam próprio perfil
- `energia`: Usuários podem inserir/ver registros
- `hidrometros`: Usuários podem inserir/ver registros
- `tokens_acesso`: Apenas admins gerenciam
- `notificacoes`: Usuários veem apenas suas notificações
- `kanban_comentarios`: Usuários autenticados podem ver/comentar
- E outras tabelas relacionadas

## Após aplicar a migration:

1. Atualize o código para usar `profiles` em vez de `Users`
2. Teste todas as funcionalidades
3. Após confirmar que tudo funciona, você pode remover a view `Users` se desejar


