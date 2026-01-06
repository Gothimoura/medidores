import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { useAuth } from '../contexts/AuthContext'
import { 
  Users, Search, Edit2, Save, X, Shield, ShieldCheck, ShieldX,
  Mail, User, AlertCircle, CheckCircle2, Loader2
} from 'lucide-react'

export default function GerenciarUsuarios() {
  const { user } = useAuth()
  const [usuarios, setUsuarios] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [editingId, setEditingId] = useState(null)
  const [editForm, setEditForm] = useState({})
  const [mensagem, setMensagem] = useState(null)

  // Verifica se o usuário tem permissão (admin ou role específica)
  const isAdmin = user?.role === 'admin' || user?.role === 'super_admin'

  const roleDisplayMap = {
    user: 'Operacional',
    admin: 'Admin',
    super_admin: 'Master',
  }

  useEffect(() => {
    if (!isAdmin) {
      setMensagem({ tipo: 'erro', texto: 'Você não tem permissão para acessar esta página.' })
      return
    }
    fetchUsuarios()
  }, [isAdmin])

  async function fetchUsuarios() {
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .order('name', { ascending: true })

      if (error) throw error
      setUsuarios(data || [])
    } catch (error) {
      console.error('Erro ao buscar usuários:', error)
      setMensagem({ tipo: 'erro', texto: 'Erro ao carregar usuários' })
    } finally {
      setLoading(false)
    }
  }

  function handleEdit(usuario) {
    setEditingId(usuario.id)
    setEditForm({
      name: usuario.name || '',
      email: usuario.email || '',
      role: usuario.role || 'user',
      access_medicoes: usuario.access_medicoes ?? true,
      access_dp_rh: usuario.access_dp_rh ?? false
    })
  }

  function handleCancelEdit() {
    setEditingId(null)
    setEditForm({})
  }

  async function handleSave(usuarioId) {
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          name: editForm.name,
          email: editForm.email,
          role: editForm.role,
          access_medicoes: editForm.access_medicoes,
          access_dp_rh: editForm.access_dp_rh
        })
        .eq('id', usuarioId)

      if (error) throw error

      setMensagem({ tipo: 'sucesso', texto: 'Usuário atualizado com sucesso!' })
      setEditingId(null)
      setEditForm({})
      fetchUsuarios()
      
      setTimeout(() => setMensagem(null), 3000)
    } catch (error) {
      console.error('Erro ao atualizar usuário:', error)
      setMensagem({ tipo: 'erro', texto: 'Erro ao atualizar usuário' })
      setTimeout(() => setMensagem(null), 3000)
    }
  }

  const usuariosFiltrados = usuarios.filter(u => {
    const termo = searchTerm.toLowerCase()
    return (
      u.name?.toLowerCase().includes(termo) ||
      u.email?.toLowerCase().includes(termo) ||
      u.role?.toLowerCase().includes(termo)
    )
  })

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-gray-50/50 p-4 md:p-8 flex items-center justify-center">
        <div className="bg-white rounded-2xl shadow-lg border border-red-200 p-8 max-w-md text-center">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Acesso Negado</h2>
          <p className="text-gray-600">Você não tem permissão para acessar esta página.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50/50 p-4 md:p-8">
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* HEADER */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <Users className="w-6 h-6 text-gray-400" />
              Gerenciar Usuários
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              Controle de acesso e permissões dos usuários
            </p>
          </div>
        </div>

        {/* MENSAGEM */}
        {mensagem && (
          <div className={`p-4 rounded-xl flex items-center gap-3 animate-in slide-in-from-top ${
            mensagem.tipo === 'sucesso'
              ? 'bg-green-50 border border-green-200 text-green-900'
              : 'bg-red-50 border border-red-200 text-red-900'
          }`}>
            {mensagem.tipo === 'sucesso' ? (
              <CheckCircle2 className="w-5 h-5" />
            ) : (
              <AlertCircle className="w-5 h-5" />
            )}
            <span className="font-semibold">{mensagem.texto}</span>
          </div>
        )}

        {/* BARRA DE BUSCA */}
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-200">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Buscar por nome, email ou role..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-all"
            />
          </div>
        </div>

        {/* TABELA DE USUÁRIOS */}
        <div className="bg-white rounded-2xl shadow-lg border border-gray-200 overflow-hidden">
          {loading ? (
            <div className="p-12 text-center">
              <Loader2 className="w-8 h-8 text-gray-400 animate-spin mx-auto mb-4" />
              <p className="text-gray-500">Carregando usuários...</p>
            </div>
          ) : usuariosFiltrados.length === 0 ? (
            <div className="p-12 text-center text-gray-400">
              <Users className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p>Nenhum usuário encontrado</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Usuário</th>
                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Role</th>
                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Medições</th>
                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">RH</th>
                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Ações</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {usuariosFiltrados.map((usuario) => (
                    <tr key={usuario.id} className="hover:bg-gray-50 transition-colors">
                      {editingId === usuario.id ? (
                        <>
                          {/* MODO EDIÇÃO */}
                          <td className="p-4">
                            <div className="space-y-2">
                              <input
                                type="text"
                                value={editForm.name}
                                onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                                placeholder="Nome"
                              />
                              <input
                                type="email"
                                value={editForm.email}
                                onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                                placeholder="Email"
                              />
                            </div>
                          </td>
                          <td className="p-4">
                            <select
                              value={editForm.role}
                              onChange={(e) => setEditForm({ ...editForm, role: e.target.value })}
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                            >
                              <option value="user">Operacional</option>
                              <option value="admin">Admin</option>
                              <option value="super_admin">Master</option>
                            </select>
                          </td>
                          <td className="p-4 text-center">
                            <label className="flex items-center justify-center gap-2 cursor-pointer">
                              <input
                                type="checkbox"
                                checked={editForm.access_medicoes}
                                onChange={(e) => setEditForm({ ...editForm, access_medicoes: e.target.checked })}
                                className="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                              />
                            </label>
                          </td>
                          <td className="p-4 text-center">
                            <label className="flex items-center justify-center gap-2 cursor-pointer">
                              <input
                                type="checkbox"
                                checked={editForm.access_dp_rh}
                                onChange={(e) => setEditForm({ ...editForm, access_dp_rh: e.target.checked })}
                                className="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                              />
                            </label>
                          </td>
                          <td className="p-4">
                            <div className="flex items-center justify-center gap-2">
                              <button
                                onClick={() => handleSave(usuario.id)}
                                className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                                title="Salvar"
                              >
                                <Save className="w-5 h-5" />
                              </button>
                              <button
                                onClick={handleCancelEdit}
                                className="p-2 text-gray-400 hover:bg-gray-100 rounded-lg transition-colors"
                                title="Cancelar"
                              >
                                <X className="w-5 h-5" />
                              </button>
                            </div>
                          </td>
                        </>
                      ) : (
                        <>
                          {/* MODO VISUALIZAÇÃO */}
                          <td className="p-4">
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                                <User className="w-5 h-5 text-blue-600" />
                              </div>
                              <div>
                                <div className="font-medium text-gray-900">{usuario.name || 'Sem nome'}</div>
                                <div className="text-sm text-gray-500 flex items-center gap-1">
                                  <Mail className="w-3 h-3" />
                                  {usuario.email}
                                </div>
                              </div>
                            </div>
                          </td>
                          <td className="p-4">
                            <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                              usuario.role === 'admin' || usuario.role === 'super_admin' 
                                ? 'bg-purple-100 text-purple-700'
                                : 'bg-gray-100 text-gray-700'
                            }`}>
                              {roleDisplayMap[usuario.role] || 'Usuário'}
                            </span>
                          </td>
                          <td className="p-4 text-center">
                            {usuario.access_medicoes ? (
                              <div className="flex items-center justify-center gap-1 text-green-600">
                                <ShieldCheck className="w-5 h-5" />
                                <span className="text-xs font-medium">Sim</span>
                              </div>
                            ) : (
                              <div className="flex items-center justify-center gap-1 text-red-600">
                                <ShieldX className="w-5 h-5" />
                                <span className="text-xs font-medium">Não</span>
                              </div>
                            )}
                          </td>
                          <td className="p-4 text-center">
                            {usuario.access_dp_rh ? (
                              <div className="flex items-center justify-center gap-1 text-green-600">
                                <ShieldCheck className="w-5 h-5" />
                                <span className="text-xs font-medium">Sim</span>
                              </div>
                            ) : (
                              <div className="flex items-center justify-center gap-1 text-red-600">
                                <ShieldX className="w-5 h-5" />
                                <span className="text-xs font-medium">Não</span>
                              </div>
                            )}
                          </td>
                          <td className="p-4">
                            <div className="flex items-center justify-center gap-2">
                              <button
                                onClick={() => handleEdit(usuario)}
                                className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                title="Editar"
                              >
                                <Edit2 className="w-5 h-5" />
                              </button>
                            </div>
                          </td>
                        </>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* LEGENDA */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <h3 className="text-sm font-bold text-gray-700 mb-4 flex items-center gap-2">
            <Shield className="w-4 h-4" />
            Legenda de Acessos
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-green-600" />
              <span className="text-gray-700">
                <strong>Medições:</strong> Acesso ao sistema de medições de água e energia
              </span>
            </div>
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-green-600" />
              <span className="text-gray-700">
                <strong>RH:</strong> Acesso ao sistema de RH (Departamento Pessoal)
              </span>
            </div>
          </div>
        </div>

      </div>
    </div>
  )
}
