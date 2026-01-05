import { useAuth } from '../contexts/AuthContext'
import { Clock, Mail, LogOut, ShieldAlert } from 'lucide-react'

export default function AguardandoAprovacao() {
  const { user, logout } = useAuth()

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center p-4">
      <div className="bg-white/10 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/20 p-8 max-w-md w-full text-center">
        
        {/* Ícone */}
        <div className="w-20 h-20 bg-amber-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
          <Clock className="w-10 h-10 text-amber-400" />
        </div>

        {/* Título */}
        <h1 className="text-2xl font-bold text-white mb-2">
          Aguardando Aprovação
        </h1>
        
        <p className="text-slate-300 mb-6">
          Sua conta foi criada com sucesso, mas você ainda não possui acesso ao sistema.
        </p>

        {/* Info do usuário */}
        <div className="bg-white/5 rounded-xl p-4 mb-6">
          <div className="flex items-center justify-center gap-2 text-slate-400 mb-2">
            <Mail className="w-4 h-4" />
            <span className="text-sm">{user?.email}</span>
          </div>
          <div className="flex items-center justify-center gap-2 text-slate-500">
            <ShieldAlert className="w-4 h-4" />
            <span className="text-xs">Acesso pendente de liberação</span>
          </div>
        </div>

        {/* Instruções */}
        <div className="bg-amber-500/10 border border-amber-500/30 rounded-xl p-4 mb-6 text-left">
          <h3 className="text-amber-400 font-semibold text-sm mb-2">O que fazer?</h3>
          <ul className="text-slate-300 text-sm space-y-2">
            <li className="flex items-start gap-2">
              <span className="text-amber-400">1.</span>
              Entre em contato com o administrador do sistema
            </li>
            <li className="flex items-start gap-2">
              <span className="text-amber-400">2.</span>
              Solicite a liberação do seu acesso
            </li>
            <li className="flex items-start gap-2">
              <span className="text-amber-400">3.</span>
              Após aprovado, faça login novamente
            </li>
          </ul>
        </div>

        {/* Botão de logout */}
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-white/10 hover:bg-white/20 text-white rounded-xl font-semibold transition-all"
        >
          <LogOut className="w-5 h-5" />
          Sair e tentar novamente
        </button>

      </div>
    </div>
  )
}

