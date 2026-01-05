import { createClient } from '@supabase/supabase-js'

// Variáveis de ambiente - configure no arquivo .env
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Log para debug (remover em produção)
console.log('[Supabase] URL configurada:', supabaseUrl ? 'SIM' : 'NÃO')
console.log('[Supabase] Key configurada:', supabaseAnonKey ? 'SIM' : 'NÃO')

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('[Supabase] Variáveis de ambiente não configuradas!')
  console.error('Crie um arquivo .env na raiz do projeto com:')
  console.error('VITE_SUPABASE_URL=sua_url')
  console.error('VITE_SUPABASE_ANON_KEY=sua_key')
  throw new Error(
    'Variáveis de ambiente do Supabase não configuradas. ' +
    'Verifique se VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY estão definidas no arquivo .env'
  )
}

// Configuração seguindo as melhores práticas do Supabase
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  }
})