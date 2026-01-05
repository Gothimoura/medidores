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
  
  useEffect(() => {
    const timer = setTimeout(() => {
      if (loading) {
        setTimeoutReached(true)
      }
    }, 3000)
    return () => clearTimeout(timer)
  }, [loading])
  
  useEffect(() => {
    const forceTimeout = setTimeout(() => {
      if (loading) {
        console.error('Timeout absoluto: redirecionando para login')
        window.location.href = '/login'
      }
    }, 8000)
    return () => clearTimeout(forceTimeout)
  }, [loading])
  
  if (loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 gap-4">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <p className="text-gray-600 font-medium">Carregando...</p>
        {timeoutReached && (
          <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg max-w-md text-center">
            <p className="text-sm text-yellow-800">
              O carregamento está demorando mais que o esperado. 
              <br />
              <button 
                onClick={() => window.location.href = '/login'} 
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
  
  if (!user) {
    return <Navigate to="/login" />
  }

  // Verifica se o usuário tem acesso ao sistema de medições
  // Admins sempre têm acesso, QR Code (n1) sempre tem acesso
  const isAdmin = user.role === 'admin' || user.role === 'super_admin'
  const isQrCode = user.tipo === 'qr_code'
  const temAcessoMedicoes = user.access_medicoes === true
  
  if (!isAdmin && !isQrCode && !temAcessoMedicoes) {
    return <Navigate to="/aguardando-aprovacao" />
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