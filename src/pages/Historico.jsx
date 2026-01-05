import { useEffect, useState } from 'react'
import { useTheme } from '../contexts/ThemeContext'
import { supabase } from '../supabaseClient'
import { 
  Calendar, Droplets, Zap, Trash2, X, Search, Filter, 
  Building, MapPin, ChevronLeft, ChevronRight, BarChart3, 
  MessageSquare 
} from 'lucide-react'
import CustomSelect from '../components/CustomSelect'

const ITENS_POR_PAGINA = 20

export default function Historico() {
  const { tipoAtivo, setTipoAtivo } = useTheme()
  
  // Estados de Dados
  const [leituras, setLeituras] = useState([])
  const [loading, setLoading] = useState(true)
  const [totalRegistros, setTotalRegistros] = useState(0)
  const [paginaAtual, setPaginaAtual] = useState(1)

  // Estados de Filtro
  const [termoBusca, setTermoBusca] = useState('')
  const [filtroUnidade, setFiltroUnidade] = useState('')
  const [filtroAndar, setFiltroAndar] = useState('')
  
  // Filtros de Data
  const [dataInicio, setDataInicio] = useState('')
  const [dataFim, setDataFim] = useState('')

  // Listas para os Selects
  const [opcoesUnidades, setOpcoesUnidades] = useState([])
  const [opcoesAndares, setOpcoesAndares] = useState([])

  // Modal de Justificativa
  const [justificativaModal, setJustificativaModal] = useState(null)

  // Carregar Dados
  useEffect(() => {
    fetchLeituras()
  }, [tipoAtivo, paginaAtual, filtroUnidade, filtroAndar, termoBusca, dataInicio, dataFim])

  async function fetchLeituras() {
    setLoading(true)
    
    const tabela = tipoAtivo === 'agua' ? 'med_hidrometros' : 'med_energia'

    let query = supabase
      .from(tabela)
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false, nullsFirst: false })

    // Filtros de Texto e Select
    if (filtroUnidade) query = query.eq('unidade', filtroUnidade)
    if (filtroAndar) query = query.eq('andar', filtroAndar)
    if (termoBusca) query = query.ilike('identificador_relogio', `%${termoBusca}%`)

    // --- FILTRO DE DATA (usando apenas_data no formato YYYY-MM-DD) ---
    if (dataInicio) {
      query = query.gte('apenas_data', dataInicio)
    }
    
    if (dataFim) {
      query = query.lte('apenas_data', dataFim)
    }

    // Paginação
    const de = (paginaAtual - 1) * ITENS_POR_PAGINA
    const ate = de + ITENS_POR_PAGINA - 1
    query = query.range(de, ate)

    const { data, count, error } = await query

    if (error) {
      console.error('Erro ao buscar:', error)
    } else {
      setLeituras(data)
      setTotalRegistros(count)
      
      if (opcoesUnidades.length === 0 && data.length > 0) {
        const unidades = [...new Set(data.map(i => i.unidade).filter(Boolean))].sort()
        setOpcoesUnidades(unidades.map(u => ({ value: u, label: u })))
        
        const andares = [...new Set(data.map(i => i.andar).filter(Boolean))].sort()
        setOpcoesAndares(andares.map(a => ({ value: a, label: a })))
      }
    }
    setLoading(false)
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Tem certeza que deseja excluir este registro?')) return
    const tabela = tipoAtivo === 'agua' ? 'med_hidrometros' : 'med_energia'
    const { error } = await supabase.from(tabela).delete().eq('id_registro', id)
    if (!error) fetchLeituras()
  }

  const limparFiltros = () => {
    setFiltroUnidade('')
    setFiltroAndar('')
    setTermoBusca('')
    setDataInicio('')
    setDataFim('')
  }

  return (
    <div className="min-h-screen bg-gray-50/50 p-4 md:p-8">
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* CABEÇALHO */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <BarChart3 className="w-6 h-6 text-gray-400" />
              Histórico de Medições
            </h1>
            <p className="text-sm text-gray-500">
              Visualizando registros de <span className="font-bold uppercase">{tipoAtivo}</span>
            </p>
          </div>

          <div className="inline-flex bg-white rounded-xl p-1 shadow-sm border border-gray-200">
            <button
              onClick={() => setTipoAtivo('agua')}
              className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                tipoAtivo === 'agua' ? 'bg-blue-500 text-white shadow' : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              Água
            </button>
            <button
              onClick={() => setTipoAtivo('energia')}
              className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                tipoAtivo === 'energia' ? 'bg-yellow-400 text-white shadow' : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              Energia
            </button>
          </div>
        </div>

        {/* BARRA DE FILTROS */}
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-200 flex flex-col lg:flex-row gap-4 items-end lg:items-center">
          
          <div className="flex-1 w-full relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input 
              type="text" 
              placeholder="Buscar relógio..." 
              value={termoBusca}
              onChange={(e) => setTermoBusca(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-all"
            />
          </div>

          {/* Filtros de Data */}
          <div className="flex gap-2 w-full lg:w-auto">
            <div className="flex-1">
              <label className="block text-[10px] uppercase font-bold text-gray-400 mb-1 ml-1">De</label>
              <input 
                type="date" 
                value={dataInicio}
                onChange={(e) => setDataInicio(e.target.value)}
                className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-blue-500"
              />
            </div>
            <div className="flex-1">
              <label className="block text-[10px] uppercase font-bold text-gray-400 mb-1 ml-1">Até</label>
              <input 
                type="date" 
                value={dataFim}
                onChange={(e) => setDataFim(e.target.value)}
                className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>

          {/* Selects */}
          <div className="w-full lg:w-40">
            <label className="block text-[10px] uppercase font-bold text-gray-400 mb-1 ml-1">Unidade</label>
            <CustomSelect 
              options={opcoesUnidades} 
              value={filtroUnidade} 
              onChange={setFiltroUnidade} 
              placeholder="Todas"
              icon={Building}
            />
          </div>
          <div className="w-full lg:w-40">
            <label className="block text-[10px] uppercase font-bold text-gray-400 mb-1 ml-1">Andar</label>
            <CustomSelect 
              options={opcoesAndares} 
              value={filtroAndar} 
              onChange={setFiltroAndar} 
              placeholder="Todos"
              icon={MapPin}
            />
          </div>

          {(filtroUnidade || filtroAndar || termoBusca || dataInicio || dataFim) && (
            <button 
              onClick={limparFiltros}
              className="px-4 py-3 text-red-600 bg-red-50 hover:bg-red-100 rounded-xl text-sm font-semibold transition-colors h-[46px] mt-auto"
            >
              Limpar
            </button>
          )}
        </div>

        {/* TABELA DE DADOS */}
        <div className="bg-white rounded-2xl shadow-lg border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Data</th>
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Medidor</th>
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Anterior</th>
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Atual</th>
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Consumo</th>
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Foto</th>
                  <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Ações</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {loading ? (
                  <tr>
                    <td colSpan="7" className="p-8 text-center text-gray-400">Carregando dados...</td>
                  </tr>
                ) : leituras.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="p-8 text-center text-gray-400">Nenhum registro encontrado com estes filtros.</td>
                  </tr>
                ) : (
                  leituras.map((item) => {
                    const unidadeMedida = tipoAtivo === 'agua' ? 'm³' : 'kWh'
                    
                    // Parser para dados concatenados do Forms legado
                    // Formato: "unidade,andar,nome,leitura,data1,data2,[{foto JSON}],usuario,id1,num,id2,...,leitura_anterior,consumo"
                    const parseDadosConcatenados = () => {
                      const str = item.identificador_relogio || ''
                      
                      // Detecta se é dado concatenado (tem vírgula + data ou JSON)
                      if (!str.includes(',') || (!str.includes('202') && !str.includes('[{'))) {
                        return { isParsed: false }
                      }
                      
                      try {
                        // 1. Extrai JSON da foto (está entre [{ e }])
                        let fotoUrl = null
                        const jsonRegex = /\[\{.*?\}\]/gs
                        const jsonMatch = str.match(jsonRegex)
                        if (jsonMatch) {
                          try {
                            // Remove as aspas duplas escapadas
                            const jsonStr = jsonMatch[0].replace(/""/g, '"')
                            const parsed = JSON.parse(jsonStr)
                            const obj = Array.isArray(parsed) ? parsed[0] : parsed
                            fotoUrl = obj?.link || obj?.url || null
                          } catch {}
                        }
                        
                        // 2. Remove o JSON para parsear o resto
                        const strSemJson = str.replace(/,"\[\{.*?\}\]"/gs, ',FOTO,').replace(/\[\{.*?\}\]/gs, 'FOTO')
                        const partes = strSemJson.split(',')
                        
                        // 3. Estrutura conhecida:
                        // [0] = unidade (ex: "Ministro")
                        // [1] = andar (ex: "Térreo")  
                        // [2] = nome medidor (ex: "MinistroTérreo")
                        // [3] = leitura atual (ex: "3283")
                        // [4] = data (ex: "2025-12-03")
                        // [5] = data2
                        // [6] = FOTO (placeholder)
                        // [7] = usuario/email
                        // [...] = identificadores antigos
                        // [-2] = leitura anterior (ex: "3280")
                        // [-1] = consumo (ex: "3")
                        
                        const nomeMedidor = partes[2] || (partes[0] + partes[1]) || str.split(',')[0]
                        const leituraAtual = partes[3] && /^\d+$/.test(partes[3]) ? partes[3] : null
                        const dataMatch = partes.find(p => /^\d{4}-\d{2}-\d{2}$/.test(p))
                        
                        // Últimos dois campos são leitura anterior e consumo
                        const ultimoItem = partes[partes.length - 1]?.trim()
                        const penultimoItem = partes[partes.length - 2]?.trim()
                        
                        // Consumo é o último (geralmente número pequeno)
                        const consumo = /^\d+$/.test(ultimoItem) ? ultimoItem : null
                        // Leitura anterior é o penúltimo
                        const leituraAnterior = /^\d+$/.test(penultimoItem) ? penultimoItem : null
                        
                        return {
                          nomeMedidor: nomeMedidor?.trim(),
                          leituraAtual,
                          leituraAnterior,
                          consumo,
                          data: dataMatch,
                          fotoUrl,
                          isParsed: true
                        }
                      } catch (e) {
                        console.warn('Erro ao parsear:', e)
                        return { isParsed: false }
                      }
                    }
                    
                    const dadosParsed = parseDadosConcatenados()
                    
                    // Usa dados parseados se disponíveis, senão usa campos normais
                    const nomeMedidor = dadosParsed.isParsed ? dadosParsed.nomeMedidor : item.identificador_relogio
                    const consumo = dadosParsed.isParsed ? dadosParsed.consumo : (tipoAtivo === 'agua' ? item.gasto_diario : item.variacao)
                    const leituraAtual = dadosParsed.isParsed ? dadosParsed.leituraAtual : (tipoAtivo === 'agua' ? item.leitura_hidrometro : item.leitura_energia)
                    const leituraAnterior = dadosParsed.isParsed ? dadosParsed.leituraAnterior : (tipoAtivo === 'agua' ? item.hidrometro_anterior : item.energia_anterior)
                    const isAlerta = item.observacao?.includes('ALERTA') || item.justificativa

                    // Função para parsear data (pode vir em vários formatos)
                    const parseData = () => {
                      // Se veio do parser, usa a data extraída
                      if (dadosParsed.isParsed && dadosParsed.data) {
                        const [ano, mes, dia] = dadosParsed.data.split('-')
                        return new Date(ano, mes - 1, dia)
                      }
                      // Tenta usar apenas_data primeiro (formato YYYY-MM-DD)
                      if (item.apenas_data && /^\d{4}-\d{2}-\d{2}$/.test(item.apenas_data)) {
                        const [ano, mes, dia] = item.apenas_data.split('-')
                        return new Date(ano, mes - 1, dia)
                      }
                      // Tenta usar created_at (timestamp real)
                      if (item.created_at) {
                        const d = new Date(item.created_at)
                        if (!isNaN(d.getTime()) && d.getFullYear() > 2000) return d
                      }
                      // Tenta usar data_hora
                      if (item.data_hora) {
                        if (/^\d{4}-\d{2}-\d{2}/.test(item.data_hora)) {
                          const d = new Date(item.data_hora)
                          if (!isNaN(d.getTime()) && d.getFullYear() > 2000) return d
                        }
                        if (/^\d{2}\/\d{2}\/\d{4}/.test(item.data_hora)) {
                          const [dia, mes, ano] = item.data_hora.split(/[\/\s]/)
                          return new Date(ano, mes - 1, dia)
                        }
                      }
                      return null
                    }
                    
                    const dataFormatada = parseData()
                    
                    // Função para extrair URL da foto
                    const getFotoUrl = () => {
                      // Se veio do parser, usa a URL extraída
                      if (dadosParsed.isParsed && dadosParsed.fotoUrl) {
                        return dadosParsed.fotoUrl
                      }
                      if (!item.foto_url) return null
                      if (item.foto_url.startsWith('http')) return item.foto_url
                      if (item.foto_url.startsWith('[{') || item.foto_url.startsWith('{')) {
                        try {
                          const parsed = JSON.parse(item.foto_url)
                          const obj = Array.isArray(parsed) ? parsed[0] : parsed
                          return obj?.link || obj?.url || obj?.foto_url || null
                        } catch {
                          return null
                        }
                      }
                      return null
                    }
                    
                    const fotoUrl = getFotoUrl()
                    
                    // Formata número ou retorna "-"
                    const formatNum = (val) => {
                      if (!val || val === 'NÃO HÁ REGISTRO ANTERIOR' || val === 'NÃO HÁ REGISTRO PARA PARÂMETRO') return '-'
                      const num = Number(val)
                      return !isNaN(num) ? num.toLocaleString('pt-BR') : '-'
                    }

                    return (
                      <tr key={item.id_registro} className={`hover:bg-gray-50 transition-colors ${isAlerta ? 'bg-red-50/30' : ''}`}>
                        {/* Data */}
                        <td className="p-4 text-sm text-gray-600 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <Calendar className="w-4 h-4 text-gray-400" />
                            {dataFormatada ? (
                              <span>{dataFormatada.toLocaleDateString('pt-BR')}</span>
                            ) : (
                              <span className="text-gray-400">-</span>
                            )}
                          </div>
                        </td>
                        
                        {/* Medidor */}
                        <td className="p-4">
                          <div className="font-medium text-gray-900">{nomeMedidor || '-'}</div>
                          <div className="text-xs text-gray-500">
                            {item.unidade && !dadosParsed.isParsed && <span>{item.unidade}</span>}
                            {item.unidade && item.andar && !dadosParsed.isParsed && <span> • </span>}
                            {item.andar && !dadosParsed.isParsed && <span>{item.andar}</span>}
                          </div>
                        </td>
                        
                        {/* Leitura Anterior */}
                        <td className="p-4 text-right">
                          <span className="font-mono text-gray-500">{formatNum(leituraAnterior)}</span>
                          {leituraAnterior && leituraAnterior !== '-' && !isNaN(Number(leituraAnterior)) && (
                            <span className="text-[10px] text-gray-400 ml-1">{unidadeMedida}</span>
                          )}
                        </td>
                        
                        {/* Leitura Atual */}
                        <td className="p-4 text-right">
                          <span className="font-mono font-semibold text-gray-900">{formatNum(leituraAtual)}</span>
                          {leituraAtual && !isNaN(Number(leituraAtual)) && (
                            <span className="text-[10px] text-gray-400 ml-1">{unidadeMedida}</span>
                          )}
                        </td>
                        
                        {/* Consumo */}
                        <td className="p-4 text-right">
                          <span className={`font-mono font-bold ${isAlerta ? 'text-red-600' : 'text-emerald-600'}`}>
                            {formatNum(consumo)}
                          </span>
                          {consumo && !isNaN(Number(consumo)) && (
                            <span className="text-[10px] text-gray-400 ml-1">{unidadeMedida}</span>
                          )}
                        </td>
                        
                        {/* Foto */}
                        <td className="p-4 text-center">
                          {fotoUrl ? (
                            <a 
                              href={fotoUrl} 
                              target="_blank" 
                              rel="noopener noreferrer" 
                              className="inline-flex items-center gap-1 text-blue-600 hover:text-blue-800 text-xs font-medium bg-blue-50 hover:bg-blue-100 px-3 py-1.5 rounded-lg transition-colors"
                            >
                              📷 Ver
                            </a>
                          ) : (
                            <span className="text-gray-300 text-xs">-</span>
                          )}
                        </td>
                        <td className="p-4 text-center">
                          <div className="flex items-center justify-center gap-2">
                            {(item.justificativa || item.observacao) && (
                              <button 
                                onClick={() => setJustificativaModal({
                                  texto: item.justificativa,
                                  obs: item.observacao,
                                  autor: item.usuario
                                })}
                                className={`p-2 rounded-full transition-all ${
                                  item.justificativa 
                                    ? 'text-red-600 bg-red-100 hover:bg-red-200 animate-pulse' 
                                    : 'text-gray-400 hover:bg-gray-100'
                                }`}
                                title="Ler Observação"
                              >
                                <MessageSquare className="w-4 h-4" />
                              </button>
                            )}
                            <button 
                              onClick={() => handleDelete(item.id_registro)}
                              className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-full transition-all"
                              title="Excluir"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>

          <div className="bg-gray-50 px-4 py-3 border-t border-gray-200 flex items-center justify-between">
            <span className="text-xs text-gray-500">
              Mostrando página {paginaAtual} de {Math.max(1, Math.ceil(totalRegistros / ITENS_POR_PAGINA))}
            </span>
            <div className="flex gap-2">
              <button 
                onClick={() => setPaginaAtual(p => Math.max(1, p - 1))}
                disabled={paginaAtual === 1}
                className="p-2 bg-white border border-gray-300 rounded-lg disabled:opacity-50 hover:bg-gray-50"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button 
                onClick={() => setPaginaAtual(p => p + 1)}
                disabled={leituras.length < ITENS_POR_PAGINA}
                className="p-2 bg-white border border-gray-300 rounded-lg disabled:opacity-50 hover:bg-gray-50"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

      </div>

      {justificativaModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 animate-in fade-in">
          <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl p-6 animate-in zoom-in-95">
            <div className="flex justify-between items-start mb-4">
              <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <MessageSquare className="w-5 h-5 text-blue-500" />
                Detalhes do Registro
              </h3>
              <button onClick={() => setJustificativaModal(null)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-4">
              {justificativaModal.obs && (
                <div className="bg-gray-50 p-3 rounded-xl border border-gray-100">
                  <p className="text-xs font-bold text-gray-500 uppercase mb-1">Observação do Sistema</p>
                  <p className="text-sm text-gray-800">{justificativaModal.obs}</p>
                </div>
              )}
              {justificativaModal.texto ? (
                <div className="bg-red-50 p-4 rounded-xl border border-red-100">
                  <p className="text-xs font-bold text-red-600 uppercase mb-1">Justificativa do Operador</p>
                  <p className="text-sm text-gray-800 italic">"{justificativaModal.texto}"</p>
                </div>
              ) : (
                <p className="text-sm text-gray-400 italic">Nenhuma justificativa manual foi inserida.</p>
              )}
              <div className="pt-4 border-t border-gray-100 flex justify-between text-xs text-gray-500">
                <span>Registrado por: <strong>{justificativaModal.autor || 'Sistema'}</strong></span>
              </div>
            </div>
            <button 
              onClick={() => setJustificativaModal(null)}
              className="mt-6 w-full py-3 bg-gray-900 text-white rounded-xl font-semibold hover:bg-gray-800 transition-colors"
            >
              Fechar
            </button>
          </div>
        </div>
      )}
    </div>
  )
}