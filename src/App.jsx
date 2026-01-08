import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { ThemeProvider } from './contexts/ThemeContext'
import { AuthProvider, useAuth } from './contexts/AuthContext'

import Layout from './components/Layout'
import Leitura from './pages/Leitura'
import Historico from './pages/Historico'
import Dashboard from './pages/Dashboard'
import Login from './pages/login'
import OpcaoEntrada from './pages/OpcaoEntrada'
import GerenciarUsuarios from './pages/GerenciarUsuarios'
import GerenciarMedidores from './pages/GerenciarMedidores'
import AguardandoAprovacao from './pages/AguardandoAprovacao'

// Componente para proteger rotas
function RotaPrivada({ children }) {
  const { user, loading } = useAuth()
  const [timeoutReached, setTimeoutReached] = useState(false)
  const [forceRedirect, setForceRedirect] = useState(false)
  
  useEffect(() => {
    console.log('[App] Estado da rota privada - loading:', loading, 'user:', user ? 'SIM' : 'NÃO')
  }, [loading, user])
  
  useEffect(() => {
    // Timeout de aviso após 3 segundos
    const timer = setTimeout(() => {
      if (loading) {
        console.warn('[App] Loading demorando mais que 3 segundos')
        setTimeoutReached(true)
      }
    }, 3000)
    return () => clearTimeout(timer)
  }, [loading])
  
  useEffect(() => {
    // Timeout absoluto após 10 segundos - força redirecionamento (aumentado para mobile)
    const forceTimeout = setTimeout(() => {
      if (loading) {
        console.error('[App] Timeout absoluto de autenticação: redirecionando para login')
        setForceRedirect(true)
      }
    }, 10000)
    return () => clearTimeout(forceTimeout)
  }, [loading])

  // Se o timeout absoluto foi atingido, redireciona imediatamente
  if (forceRedirect) {
    console.error('[App] Forçando redirecionamento para login')
    return <Navigate to="/login" replace />
  }
  
  // Se está carregando, mostra loading
  if (loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 gap-4">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <p className="text-gray-600 font-medium">Verificando autenticação...</p>
        {timeoutReached && (
          <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg max-w-md text-center">
            <p className="text-sm text-yellow-800">
              O carregamento está demorando mais que o esperado. 
              <br />
              <button 
                onClick={() => {
                  try {
                    localStorage.clear()
                    sessionStorage.clear()
                  } catch (e) {
                    console.warn('[App] Erro ao limpar storage:', e)
                  }
                  window.location.href = '/login'
                }} 
                className="mt-2 text-blue-600 hover:underline font-semibold"
              >
                Ir para Login
              </button>
            </p>
          </div>
        )}
      </div>
    )
  }
  
  // Se não há usuário após o loading terminar, redireciona para login
  if (!user) {
    console.log('[App] Nenhum usuário encontrado, redirecionando para login')
    return <Navigate to="/login" replace />
  }
  
  console.log('[App] Usuário autenticado:', user.tipo, user.nome)

  // Verifica se o usuário tem acesso ao sistema de medições
  // Admins sempre têm acesso, QR Code (n1) sempre tem acesso
  const isAdmin = user.role === 'admin' || user.role === 'super_admin'
  const isQrCode = user.tipo === 'qr_code'
  const temAcessoMedicoes = user.access_medicoes === true
  
  if (!isAdmin && !isQrCode && !temAcessoMedicoes) {
    return <Navigate to="/aguardando-aprovacao" replace />
  }

  return children
}

function App() {
  return (
    <AuthProvider>
      <ThemeProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/aguardando-aprovacao" element={<AguardandoAprovacao />} />
            
            <Route path="/" element={
              <RotaPrivada>
                <Layout />
              </RotaPrivada>
            }>
              <Route index element={<OpcaoEntrada />} />
              <Route path="leitura" element={<Leitura />} />
              <Route path="historico" element={<Historico />} />
              <Route path="dashboard" element={<Dashboard />} />
              <Route path="usuarios" element={<GerenciarUsuarios />} />
              <Route path="medidores" element={<GerenciarMedidores />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ThemeProvider>
    </AuthProvider>
  )
}

export default App