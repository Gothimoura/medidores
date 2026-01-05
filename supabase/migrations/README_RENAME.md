# Migration de Renomeação de Tabelas

## Objetivo

Esta migration padroniza os nomes das tabelas adicionando prefixos identificadores:
- **`med_`** - Para tabelas do projeto de Medições (água e energia)
- **`rh_`** - Para tabelas do projeto de RH (Recursos Humanos)

## Mudanças Realizadas

### Projeto de Medições (`med_`)

| Nome Antigo | Nome Novo |
|------------|-----------|
| `hidrometros` | `med_hidrometros` |
| `energia` | `med_energia` |
| `medidores` | `med_medidores` |

### Projeto de RH (`rh_`)

| Nome Antigo | Nome Novo |
|------------|-----------|
| `Colaboradores` | `rh_colaboradores` |
| `CCs` | `rh_departamentos` |
| `Etapas` | `rh_etapas` |
| `Itens` | `rh_itens` |
| `Registros` | `rh_registros_acesso` |
| `CELULARES` | `rh_celulares` |
| `NOTEBOOK` | `rh_notebooks` |
| `LINHAS` | `rh_linhas_telefonicas` |
| `REGISTROS LINHAS` | `rh_registros_linhas` |
| `REGISTROS NOTEBOOKS` | `rh_registros_notebooks` |
| `RGISTROS CELULARES` | `rh_registros_celulares` |
| `Comentários` | `rh_comentarios` |
| `ANEXOS` | `rh_anexos` |
| `Apoios` | `rh_apoios` |
| `kanban_cartoes` | `rh_kanban_cartoes` |
| `kanban_comentarios` | `rh_kanban_comentarios` |
| `kanban_historico` | `rh_kanban_historico` |
| `acoes_rapidas` | `rh_acoes_rapidas` |
| `documentos_templates` | `rh_documentos_templates` |
| `documentos_gerados` | `rh_documentos_gerados` |
| `calendario_eventos` | `rh_calendario_eventos` |
| `calendario_alertas` | `rh_calendario_alertas` |
| `notificacoes` | `rh_notificacoes` |
| `relatorios_config` | `rh_relatorios_config` |
| `relatorios_gerados` | `rh_relatorios_gerados` |
| `configuracoes` | `rh_configuracoes` |
| `painel_metricas` | `rh_painel_metricas` |

## Compatibilidade

A migration cria **views de compatibilidade** que mantêm os nomes antigos funcionando temporariamente. Isso permite:

1. ✅ Aplicar a migration sem quebrar código existente
2. ✅ Atualizar o código gradualmente
3. ✅ Remover as views quando tudo estiver atualizado

## Próximos Passos

1. **Aplicar a migration** no banco de dados
2. **Atualizar o código** para usar os novos nomes
3. **Testar** todas as funcionalidades
4. **Remover as views** de compatibilidade após confirmação

## Importante

⚠️ **As views são apenas para leitura/compatibilidade temporária.**
- Para INSERT/UPDATE/DELETE, use os novos nomes de tabelas diretamente
- As views podem ter limitações em operações complexas

## Ordem de Aplicação

1. Primeiro: `20240101000000_create_profiles_and_update_references.sql`
2. Depois: `20240102000000_rename_tables_with_prefixes.sql`


