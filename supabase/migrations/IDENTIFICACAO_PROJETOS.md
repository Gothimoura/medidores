# Identificação de Tabelas por Projeto

Este documento identifica quais tabelas pertencem a cada projeto no banco de dados compartilhado.

## 📊 PROJETO DE MEDIÇÕES (Água e Energia)

Este projeto é o sistema atual (`sistema-medicao`) que gerencia leituras de medidores de água e energia.

### Tabelas Principais:
- **`hidrometros`** - Registros de leituras de hidrômetros
  - Campos: `id_registro`, `unidade`, `andar`, `identificador_relogio`, `leitura_hidrometro`, `data_hora`, `foto_url`, `usuario`, `gasto_diario`, `hidrometro_anterior`, `observacao`, `justificativa`, etc.

- **`energia`** - Registros de leituras de energia elétrica
  - Campos: `id_registro`, `unidade`, `andar`, `identificador_relogio`, `leitura_energia`, `data_hora`, `foto_url`, `usuario`, `variacao`, `energia_anterior`, `observacao`, `justificativa`, etc.

- **`medidores`** - Cadastro de medidores (água e energia)
  - Campos: `id`, `nome`, `tipo` ('agua' ou 'energia'), `unidade`, `local_unidade`, `andar`, `token` (UUID para QR Code), `created_at`

### Tabelas de Suporte:
- **`tokens_acesso`** - Tokens para acesso via QR Code (usado tanto no sistema de medições quanto no RH)
  - Campos: `id`, `token` (UUID), `descricao`, `ativo`, `created_at`

### Views Relacionadas (mencionadas no código):
- `view_hidrometros_calculada` - View calculada para hidrômetros
- `view_energia_calculada` - View calculada para energia

### Storage Buckets:
- **`evidencias`** - Armazenamento de fotos dos medidores

---

## 👥 PROJETO DE RH (Recursos Humanos)

Este projeto gerencia colaboradores, equipamentos, processos e documentação de RH.

### Tabelas de Colaboradores:
- **`Colaboradores`** - Cadastro principal de colaboradores
  - Campos: `ID`, `Nome`, `Cargo`, `Departamento`, `Data Entrada`, `Etapa id`, `Foto`
  - FK: `Departamento` → `CCs.Departamento`, `Etapa id` → `Etapas.ID`

- **`Comentários`** - Comentários sobre colaboradores
  - Campos: `Usuário id`, `Colaborador id`, `Data`, `Comentário`
  - FK: `Usuário id` → `Users.Row ID`, `Colaborador id` → `Colaboradores.ID`

### Tabelas de Usuários e Perfis:
- **`Users`** (legado) / **`profiles`** (nova) - Usuários do sistema
  - Campos: `Row ID`/`id`, `Name`/`name`, `Email`/`email`, `Photo`/`photo`, `Role`/`role`, `Export`, `View`

### Tabelas de Estrutura Organizacional:
- **`CCs`** - Centros de Custo / Departamentos
  - Campos: `Row ID`, `Departamento` (UNIQUE)

- **`Etapas`** - Etapas de processos
  - Campos: `ID`, `Tipo`, `Etapa`

- **`Itens`** - Itens/Plataformas do sistema
  - Campos: `ID`, `Plataforma`, `Responsável`, `Icone`

- **`Registros`** - Registros de acesso a plataformas
  - Campos: `ID Colaborador`, `Plataforma`, `Status Acesso`
  - FK: `ID Colaborador` → `Colaboradores.ID`, `Plataforma` → `Itens.ID`

### Tabelas de Gestão de Equipamentos:
- **`CELULARES`** - Gestão de celulares corporativos
  - Campos: `Row ID`, `Usuário atual`, `Nº Matricula`, `NºCHIP`, `CELULAR`, `Modelo`, `IMEI`, `ACESSORIOS`, `DPTO`, `Status`, `OBS`, `Útimo usuário`
  - FK: `DPTO` → `CCs.Departamento`

- **`NOTEBOOK`** - Gestão de notebooks corporativos
  - Campos: `Row ID`, `Usuário atual`, `Nº Matricula`, `Departamento`, `Marca`, `Modelo`, `Status`, `Motivo`, `OBS`, `Último usuário`
  - FK: `Departamento` → `CCs.Departamento`

- **`LINHAS`** - Gestão de linhas telefônicas
  - Campos: `Row ID`, `NTC` (UNIQUE), `Usuário atual`, `Empresa`, `Cód Emp`, `Centro de custo`, `Status`, `Local`, `OBS`
  - FK: `Centro de custo` → `CCs.Departamento`

### Tabelas de Histórico de Equipamentos:
- **`REGISTROS LINHAS`** - Histórico de alterações em linhas
  - Campos: `Row ID`, `ID`, `DATA E HORA`, `USUÁRIO`, `COMENTÁRIO`
  - FK: `ID` → `LINHAS.NTC`

- **`REGISTROS NOTEBOOKS`** - Histórico de alterações em notebooks
  - Campos: `Row ID`, `ID`, `DATA E HORA`, `USUÁRIO`, `COMENTÁRIO`
  - FK: `ID` → `NOTEBOOK.Row ID`

- **`RGISTROS CELULARES`** - Histórico de alterações em celulares
  - Campos: `Row ID`, `ID`, `DATA E HORA`, `USUÁRIO`, `COMENTÁRIO`
  - FK: `ID` → `CELULARES.Row ID`

### Tabelas de Kanban:
- **`kanban_cartoes`** - Cartões do kanban de processos
  - Campos: `id`, `colaborador_id`, `coluna`, `posicao`, `data_inicio`, `data_prevista`, `tem_notebook`, `tem_celular`, `tem_acessos`, `prioridade`, `observacoes`, `responsavel_id`, `criado_em`, `atualizado_em`
  - FK: `colaborador_id` → `Colaboradores.ID`, `responsavel_id` → `Users.Row ID`

- **`kanban_comentarios`** - Comentários nos cartões do kanban
  - Campos: `id`, `cartao_id`, `comentario`, `usuario_id`, `criado_em`, `usuario_nome`
  - FK: `cartao_id` → `kanban_cartoes.id`, `usuario_id` → `Users.Row ID`

- **`kanban_historico`** - Histórico de movimentações no kanban
  - Campos: `id`, `cartao_id`, `de_coluna`, `para_coluna`, `movido_por`, `movido_em`
  - FK: `cartao_id` → `kanban_cartoes.id`, `movido_por` → `Users.Row ID`

### Tabelas de Ações e Documentos:
- **`acoes_rapidas`** - Ações rápidas executadas
  - Campos: `id`, `tipo`, `colaborador_id`, `executado_por`, `dados`, `status`, `observacoes`, `criado_em`
  - FK: `colaborador_id` → `Colaboradores.ID`, `executado_por` → `Users.Row ID`

- **`documentos_templates`** - Templates de documentos
  - Campos: `id`, `codigo`, `nome`, `conteudo`, `variaveis`, `ativo`, `criado_em`

- **`documentos_gerados`** - Documentos gerados
  - Campos: `id`, `template_id`, `colaborador_id`, `numero`, `url_pdf`, `dados_usados`, `gerado_por`, `criado_em`
  - FK: `template_id` → `documentos_templates.id`, `colaborador_id` → `Colaboradores.ID`, `gerado_por` → `Users.Row ID`

### Tabelas de Calendário:
- **`calendario_eventos`** - Eventos do calendário
  - Campos: `id`, `colaborador_id`, `tipo_evento`, `titulo`, `descricao`, `data_evento`, `hora_evento`, `cor`, `departamento_id`, `status`, `criado_em`, `atualizado_em`
  - FK: `colaborador_id` → `Colaboradores.ID`, `departamento_id` → `CCs.Departamento`

- **`calendario_alertas`** - Alertas do calendário
  - Campos: `id`, `evento_id`, `dias_antes`, `mensagem`, `prioridade`, `enviado`, `criado_em`
  - FK: `evento_id` → `calendario_eventos.id`

### Tabelas de Notificações e Relatórios:
- **`notificacoes`** - Notificações do sistema
  - Campos: `id`, `usuario_id`, `tipo`, `titulo`, `mensagem`, `lida`, `criada_em`
  - FK: `usuario_id` → `Users.Row ID`

- **`relatorios_config`** - Configurações de relatórios
  - Campos: `id`, `codigo`, `nome`, `query_sql`, `parametros`, `ativo`

- **`relatorios_gerados`** - Relatórios gerados
  - Campos: `id`, `config_id`, `url_arquivo`, `formato`, `gerado_por`, `criado_em`, `expira_em`
  - FK: `config_id` → `relatorios_config.id`, `gerado_por` → `Users.Row ID`

### Tabelas de Configuração:
- **`configuracoes`** - Configurações gerais do sistema
  - Campos: `chave`, `valor`, `atualizado_em`

- **`painel_metricas`** - Métricas do painel
  - Campos: `id`, `chave`, `valor`, `label`, `icone`, `cor`, `atualizado_em`

### Tabelas Auxiliares:
- **`ANEXOS`** - Anexos diversos
  - Campos: `Row ID`, `DATA E HORA`, `ID`, `ANEXO`, `Usuário`

- **`Apoios`** - Tabela de apoio/views
  - Campos: `View`, `Status colaborador`, `Status acesso`

---

## 🔄 Tabelas Compartilhadas

### `tokens_acesso`
- Usada em ambos os projetos
- No sistema de medições: para acesso operacional via QR Code
- No sistema de RH: provavelmente para outros tipos de acesso

### `profiles` / `Users`
- Usuários do sistema compartilhado
- Usado para autenticação em ambos os projetos

---

## 📝 Observações Importantes

1. **Nomenclatura**: As tabelas do projeto RH usam nomes com espaços e caracteres especiais (ex: `"Users"`, `"Comentários"`), enquanto as do projeto de medições usam nomes em minúsculas sem espaços (ex: `hidrometros`, `energia`).

2. **Foreign Keys**: Muitas tabelas do RH referenciam `Users.Row ID`, que deve ser atualizado para `profiles.id` após a migration.

3. **RLS**: As políticas de RLS devem ser configuradas considerando ambos os projetos e suas necessidades de acesso.

4. **Separação**: Embora compartilhem o mesmo banco, os projetos são funcionalmente independentes e podem ter políticas de acesso diferentes.


