import { createContext, useState, useContext, useEffect } from 'react'
import { supabase } from '../supabaseClient'

const AuthContext = createContext()

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // BOAS PRÁTICAS SUPABASE - onAuthStateChange já dispara INITIAL_SESSION na inicialização
    // Não precisa de getSession() separado - isso causa race conditions
    // Ref: https://supabase.com/docs/reference/javascript/auth-onauthstatechange
    
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('[Auth] Evento:', event)
        
        if (session?.user) {
          // Busca dados do profile
          // Usando Promise com timeout para evitar travamento em mobile
          const buscarProfile = async () => {
            try {
              const { data: profileData, error } = await supabase
                .from('profiles')
                .select('name, role, email, photo, export, view, access_medicoes, access_dp_rh')
                .eq('id', session.user.id)
                .single()

              if (error && error.code !== 'PGRST116') {
                console.warn('[Auth] Erro ao buscar profile:', error.message)
              }
              
              setUser({
                id: session.user.id,
                email: profileData?.email || session.user.email,
                nome: profileData?.name || session.user.email,
                role: profileData?.role || 'user',
                // Adicionando novos campos do profile
                photo: profileData?.photo,
                export: profileData?.export,
                view: profileData?.view,
                // Mantendo a lógica de fallback para os campos de acesso
                access_medicoes: profileData?.access_medicoes ?? true,
                access_dp_rh: profileData?.access_dp_rh ?? false,
                tipo: 'email_senha'
              })
            } catch (err) {
              console.error('[Auth] Erro ao processar profile:', err)
              // Mesmo com erro, seta o user básico
              setUser({
                id: session.user.id,
                email: session.user.email,
                nome: session.user.email,
                role: 'user',
                photo: null,
                export: null,
                view: null,
                access_medicoes: true,
                access_dp_rh: false,
                tipo: 'email_senha'
              })
            } finally {
              setLoading(false)
            }
          }
          
          // Executa a busca do profile com um pequeno delay para evitar deadlock
          // Usa requestAnimationFrame quando disponível (melhor para mobile)
          if (typeof requestAnimationFrame !== 'undefined') {
            requestAnimationFrame(() => {
              buscarProfile()
            })
          } else {
            // Fallback para setTimeout
            setTimeout(buscarProfile, 10)
          }
        } else {
          // Sem sessão Supabase - verifica token QR Code
          const tokenSalvo = sessionStorage.getItem('gowork_token_n1')
          if (tokenSalvo) {
            await validarTokenN1(tokenSalvo)
          } else {
            setUser(null)
            setLoading(false)
          }
        }
      }
    )

    return () => {
      subscription.unsubscribe()
    }
  }, [])

  // Função para validar o token QR Code salvo
  async function validarTokenN1(token) {
    try {
      const { data, error } = await supabase
        .from('tokens_acesso')
        .select('*')
        .eq('token', token)
        .eq('ativo', true)
        .single()

      if (error || !data) {
        sessionStorage.removeItem('gowork_token_n1')
        setUser(null)
        setLoading(false)
        return
      }

      setUser({ 
        id: data.id, 
        role: 'n1', 
        nome: data.descricao,
        tipo: 'qr_code' 
      })
      setLoading(false)
    } catch (error) {
      console.error('[Auth] Erro ao validar token:', error)
      sessionStorage.removeItem('gowork_token_n1')
      setUser(null)
      setLoading(false)
    }
  }

  // Função para criar conta com email e senha
  async function criarConta(nome, email, senha) {
    try {
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password: senha,
        options: {
          data: { name: nome }
        }
      })

      if (authError) throw new Error(authError.message)
      if (!authData.user) throw new Error('Erro ao criar conta')

      // Cria profile com acesso NEGADO por padrão
      // O admin deve liberar o acesso manualmente depois
      await supabase
        .from('profiles')
        .upsert({
          id: authData.user.id,
          name: nome,
          email: email,
          role: 'user',
          access_medicoes: false,  // Sem acesso por padrão
          access_dp_rh: false      // Sem acesso por padrão
        }, { onConflict: 'id' })

      return { success: true, message: 'Conta criada! Aguarde liberação de acesso pelo administrador.' }
    } catch (error) {
      console.error('[Auth] Erro criarConta:', error)
      return { success: false, message: error.message }
    }
  }

  // Função para login com email e senha
  async function loginComEmailSenha(email, senha) {
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password: senha
      })

      if (error) throw new Error(error.message)
      
      // onAuthStateChange vai tratar o resto
      return { success: true }
    } catch (error) {
      console.error('[Auth] Erro loginComEmailSenha:', error)
      return { success: false, message: error.message }
    }
  }

  // Função para validar o QR Code
  async function loginViaQrCode(tokenLido) {
    try {
      const { data, error } = await supabase
        .from('tokens_acesso')
        .select('*')
        .eq('token', tokenLido)
        .eq('ativo', true)
        .single()

      if (error || !data) {
        throw new Error('QR Code inválido ou inativo.')
      }

      setUser({ 
        id: data.id, 
        role: 'n1', 
        nome: data.descricao,
        tipo: 'qr_code' 
      })
      sessionStorage.setItem('gowork_token_n1', tokenLido)
      return { success: true }
    } catch (error) {
      console.error('[Auth] Erro loginViaQrCode:', error)
      return { success: false, message: error.message }
    }
  }

  async function logout() {
    await supabase.auth.signOut()
    setUser(null)
    sessionStorage.removeItem('gowork_token_n1')
  }

  // Nova função para salvar leituras de água ou energia
  async function salvarLeitura(dadosLeitura) {
    const { medidor_id, tipo, leitura, foto_url, observacao, justificativa } = dadosLeitura

    if (!user) {
      return { success: false, message: 'Usuário não autenticado.' }
    }

    const tabela = tipo === 'agua' ? 'med_hidrometros' : 'med_energia'

    const dadosParaSalvar = {
      medidor_id,
      leitura,
      foto_url,
      observacao,
      justificativa,
      usuario: user.nome || user.email, // Usa o nome do usuário logado
      // data_hora e created_at usarão o default do banco de dados
    }

    try {
      const { error } = await supabase.from(tabela).insert(dadosParaSalvar)

      if (error) throw error

      return { success: true, message: 'Leitura salva com sucesso!' }
    } catch (error) {
      console.error(`[Auth] Erro ao salvar leitura em ${tabela}:`, error)
      return { success: false, message: `Erro ao salvar leitura: ${error.message}` }
    }
  }

  return (
    <AuthContext.Provider value={{ user, criarConta, loginComEmailSenha, loginViaQrCode, logout, loading, salvarLeitura }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
