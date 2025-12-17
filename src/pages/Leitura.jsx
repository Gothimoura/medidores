import { useState, useEffect, useRef } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useTheme } from '../contexts/ThemeContext'
import { supabase } from '../supabaseClient'
import { Scanner } from '@yudiel/react-qr-scanner'
import { 
  Camera, CheckCircle, Trash2, AlertTriangle, TrendingUp, 
  Droplets, Zap, Building, MapPin, ArrowRight, Info, 
  BarChart3, History, QrCode, X, Search 
} from 'lucide-react'
import CustomSelect from '../components/CustomSelect'

// CONFIGURAÇÕES
const N8N_WEBHOOK_URL = '' // Se tiver webhook, coloque aqui
const PORCENTAGEM_ALERTA = 0.60 
const VALOR_SEM_ANDAR = '___SEM_ANDAR___'

export default function Leitura() {
  const { tipoAtivo, setTipoAtivo } = useTheme()
  const [todosMedidores, setTodosMedidores] = useState([])
  
  // Estados de Seleção
  const [predioSelecionado, setPredioSelecionado] = useState('')
  const [andarSelecionado, setAndarSelecionado] = useState('')
  const [medidorSelecionado, setMedidorSelecionado] = useState('')
  
  // Estados de Leitura e Comparação
  const [leituraAnterior, setLeituraAnterior] = useState(null)
  const [leituraAtual, setLeituraAtual] = useState('')
  const [mediaHistorica, setMediaHistorica] = useState(null)
  
  // Estados de UI
  const [foto, setFoto] = useState(null)
  const [previewUrl, setPreviewUrl] = useState(null)
  const [loading, setLoading] = useState(false)
  const [mensagem, setMensagem] = useState(null)
  const [motivoValidacao, setMotivoValidacao] = useState('')
  
  // Estado do Scanner
  const [mostrarScanner, setMostrarScanner] = useState(false)
  
  const fileInputRef = useRef(null)
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    if (params.get('scan') === 'true') {
      setMostrarScanner(true);
    }
  }, [location]);

  // 1. CARREGA LISTA DE MEDIDORES DO TIPO ATUAL
  useEffect(() => {
    async function fetchMedidores() {
      // Se já temos um medidor selecionado (via QR Code), mantemos o filtro visualmente
      if (!medidorSelecionado) {
        setPredioSelecionado('')
        setAndarSelecionado('')
      }
      
      const { data } = await supabase
        .from('medidores')
        .select('*')
        .eq('tipo', tipoAtivo)
        .order('nome')
      
      if (data) setTodosMedidores(data)
    }
    fetchMedidores()
  }, [tipoAtivo])

  // 2. FUNÇÃO PRINCIPAL: Processar o UUID do Scanner
  const handleMedidorScan = async (result) => {
    if (!result || result.length === 0) return
    
    // O Scanner lê o UUID direto (ex: "da81ac95-6306-4f6c...")
    const tokenLido = result[0].rawValue 
    
    setMostrarScanner(false)
    setLoading(true)

    try {
      // BUSCA EXATA PELO TOKEN (UUID)
      // Aqui acontece a validação que você pediu
      const { data: medidor, error } = await supabase
        .from('medidores')
        .select('*')
        .eq('token', tokenLido) 
        .single()

      if (error || !medidor) {
        throw new Error('QR Code não cadastrado ou medidor não encontrado.')
      }

      // SUCESSO! PREENCHE O SISTEMA SOZINHO:
      
      // 1. Se o medidor for de outro tipo (ex: leu Energia estando na tela de Água), troca sozinho
      if (medidor.tipo !== tipoAtivo) {
        setTipoAtivo(medidor.tipo)
        // Pequena pausa para o React atualizar o estado do tema e recarregar a lista 'todosMedidores'
        await new Promise(r => setTimeout(r, 200)) 
      }

      // 2. Preenche os filtros visuais
      setPredioSelecionado(medidor.local_unidade)
      setAndarSelecionado(medidor.andar || VALOR_SEM_ANDAR)
      
      // 3. Seleciona o medidor (Isso vai disparar a busca do histórico automaticamente)
      setMedidorSelecionado(medidor.id)
      
      setMensagem(`Identificado: ${medidor.nome}`)
      setTimeout(() => setMensagem(null), 3000)

    } catch (err) {
      alert(err.message) // Mostra erro se o QR não for válido
    } finally {
      setLoading(false)
    }
  }

  // Lógica de Filtros para os Selects Manuais (Caso não use o QR)
  const prediosUnicos = [...new Set(todosMedidores.map(m => m.local_unidade).filter(Boolean))].sort()
  
  let andaresOpcoes = []
  if (predioSelecionado) {
    const medidoresDoPredio = todosMedidores.filter(m => m.local_unidade === predioSelecionado)
    const andaresReais = [...new Set(medidoresDoPredio.map(m => m.andar).filter(Boolean))].sort()
    const temSemAndar = medidoresDoPredio.some(m => !m.andar)
    andaresOpcoes = andaresReais.map(a => ({ valor: a, label: a }))
    if (temSemAndar) {
      andaresOpcoes.unshift({ valor: VALOR_SEM_ANDAR, label: 'Geral / Sem Andar' })
    }
  }

  const medidoresFinais = todosMedidores.filter(m => {
    if (m.local_unidade !== predioSelecionado) return false
    if (andarSelecionado === VALOR_SEM_ANDAR) return !m.andar
    return m.andar === andarSelecionado
  })

  // 3. BUSCA HISTÓRICO E MÉDIA QUANDO UM MEDIDOR É SELECIONADO
  useEffect(() => {
    if (!medidorSelecionado) return

    async function fetchDadosMedidor() {
      // Tenta achar o nome na lista carregada
      let nomeMedidor = todosMedidores.find(m => m.id == medidorSelecionado)?.nome
      
      // Fallback: Se a lista 'todosMedidores' ainda não atualizou após a troca de QR Code, busca direto no banco
      if (!nomeMedidor) {
         const { data } = await supabase.from('medidores').select('nome').eq('id', medidorSelecionado).single()
         if(data) nomeMedidor = data.nome
      }

      if (!nomeMedidor) return

      const viewAlvo = tipoAtivo === 'agua' ? 'view_hidrometros_calculada' : 'view_energia_calculada'

      const tenDaysAgo = new Date()
      tenDaysAgo.setDate(tenDaysAgo.getDate() - 10)

      // Prioriza busca nos últimos 10 dias
      let { data: historico } = await supabase
        .from(viewAlvo)
        .select('leitura_num, consumo_calculado')
        .eq('identificador_relogio', nomeMedidor)
        .gte('data_real', tenDaysAgo.toISOString())
        .order('data_real', { ascending: false })

      // Se não houver dados recentes, busca os últimos 10 registros como fallback
      if (!historico || historico.length === 0) {
        const { data: fallbackHistorico } = await supabase
          .from(viewAlvo)
          .select('leitura_num, consumo_calculado')
          .eq('identificador_relogio', nomeMedidor)
          .order('data_real', { ascending: false })
          .limit(10)
        historico = fallbackHistorico
      }

      if (historico && historico.length > 0) {
        setLeituraAnterior(historico[0].leitura_num || 0)
        
        // Calcula média histórica ignorando nulos e negativos
        const consumosValidos = historico.map(h => h.consumo_calculado).filter(c => c !== null && c >= 0)
        if (consumosValidos.length > 0) {
          const soma = consumosValidos.reduce((a, b) => a + b, 0)
          setMediaHistorica(soma / consumosValidos.length)
        } else {
          setMediaHistorica(null)
        }
      } else {
        setLeituraAnterior(0)
        setMediaHistorica(null)
      }
    }
    fetchDadosMedidor()
  }, [medidorSelecionado, todosMedidores, tipoAtivo])

  const handleFileSelect = (e) => {
    const file = e.target.files[0]
    if (file) {
      setFoto(file)
      setPreviewUrl(URL.createObjectURL(file))
    }
  }

  // Cálculos de Validação
  const valorAtualNum = Number(leituraAtual)
  const valorAnteriorNum = Number(leituraAnterior)
  const consumo = leituraAtual ? valorAtualNum - valorAnteriorNum : 0
  const isMenorQueAnterior = leituraAtual && leituraAnterior !== null && valorAtualNum < valorAnteriorNum
  const isConsumoAlto = !isMenorQueAnterior && mediaHistorica && consumo > (mediaHistorica * (1 + PORCENTAGEM_ALERTA))
  const podeEnviar = leituraAtual && foto && (!isMenorQueAnterior || motivoValidacao !== '')

  // 4. ENVIO DOS DADOS (SUBMIT)
  async function handleSubmit(e) {
    e.preventDefault()
    if (!podeEnviar) return
    setLoading(true)
    
    try {
      // Upload da Foto
      const fileExt = foto.name.split('.').pop()
      const fileName = `${Date.now()}_${Math.random()}.${fileExt}`
      const { error: uploadError } = await supabase.storage.from('evidencias').upload(fileName, foto)
      if (uploadError) throw uploadError
      const { data: urlData } = supabase.storage.from('evidencias').getPublicUrl(fileName)
      
      // Garante que temos os dados do medidor (mesmo se veio via QR e a lista não carregou)
      let medidorObj = todosMedidores.find(m => m.id == medidorSelecionado)
      if(!medidorObj) {
         const { data } = await supabase.from('medidores').select('*').eq('id', medidorSelecionado).single()
         medidorObj = data
      }
      
      // Monta Observação Automática
      let obsFinal = isConsumoAlto ? `ALERTA: Consumo Alto (+${Math.round((consumo/mediaHistorica - 1)*100)}%)` : ''
      if (isMenorQueAnterior) obsFinal = motivoValidacao === 'virada' ? 'Virada de Relógio' : 'Ajuste Manual'

      const dadosComuns = {
        identificador_relogio: medidorObj.nome,
        unidade: medidorObj.local_unidade,
        andar: medidorObj.andar,
        data_hora: new Date().toISOString(),
        apenas_data: new Date().toISOString().split('T')[0],
        foto_url: urlData.publicUrl,
        usuario: 'App Web', // Futuramente: pegar do AuthContext
        observacao: obsFinal
      }

      // Salva na tabela correta
      if (tipoAtivo === 'agua') {
        await supabase.from('hidrometros').insert({ ...dadosComuns, leitura_hidrometro: leituraAtual.toString() })
      } else {
        await supabase.from('energia').insert({ ...dadosComuns, leitura_energia: leituraAtual.toString() })
      }
      
      // Integração N8N (Opcional)
      if (N8N_WEBHOOK_URL) {
        fetch(N8N_WEBHOOK_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            tipo: tipoAtivo,
            medidor: medidorObj.nome,
            unidade: medidorObj.local_unidade,
            leitura_atual: valorAtualNum,
            consumo: consumo,
            alerta: isConsumoAlto || isMenorQueAnterior,
            foto: urlData.publicUrl
          })
        }).catch(err => console.error(err))
      }

      setMensagem(isConsumoAlto ? 'Salvo! Alerta enviado.' : 'Leitura salva com sucesso!')
      
      // Limpa formulário para a próxima
      setLeituraAtual('')
      setFoto(null)
      setPreviewUrl(null)
      setMotivoValidacao('')
      setMedidorSelecionado('') // Limpa seleção para forçar novo scan ou escolha
      setPredioSelecionado('')
      setAndarSelecionado('')
      
      setTimeout(() => setMensagem(null), 3000)

    } catch (error) {
      alert('Erro ao salvar: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const currentStep = !predioSelecionado ? 1 : !andarSelecionado ? 2 : !medidorSelecionado ? 3 : !leituraAtual ? 4 : !foto ? 5 : 6

  const handleCancelScan = () => {
    setMostrarScanner(false);
    const params = new URLSearchParams(location.search);
    if (params.get('scan') === 'true') {
      navigate('/');
    }
  };

  return (
    <div className="min-h-screen bg-transparent py-6 px-4 sm:py-12">
      <div className="max-w-5xl mx-auto px-2 sm:px-6 lg:px-8">
        
        {/* HEADER E BOTÕES DE AÇÃO */}
        <div className="mb-6 sm:mb-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
            <div className="flex items-center justify-between w-full md:w-auto">
              <div>
                <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">Nova Leitura</h1>
                <p className="text-sm text-gray-600 mt-1">Identificação via QR Code ou Manual</p>
              </div>
              
              {/* Botão Scanner Mobile */}
              <button 
                onClick={() => setMostrarScanner(true)}
                className="md:hidden p-3 bg-gray-900 text-white rounded-xl shadow-lg active:scale-95 flex flex-col items-center gap-1"
              >
                <QrCode className="w-6 h-6" />
                <span className="text-[10px] font-bold">SCAN</span>
              </button>
            </div>
            
            <div className="flex flex-col sm:flex-row gap-3 items-center justify-end">
               {/* Botão Scanner Desktop */}
               <button 
                onClick={() => setMostrarScanner(true)}
                className="hidden md:flex items-center gap-2 px-4 py-3 bg-gray-800 text-white rounded-xl font-semibold hover:bg-gray-900 shadow-lg transition-transform hover:scale-105 mr-2"
              >
                <QrCode className="w-5 h-5" />
                Escanear Relógio
              </button>

              {/* Seletor de Tipo (Água/Energia) */}
              <div className="inline-flex bg-white rounded-2xl p-1.5 shadow-lg border border-gray-200">
                <button
                  onClick={() => setTipoAtivo('agua')}
                  className={`flex items-center gap-2 px-6 py-3 rounded-xl font-semibold transition-all duration-300 ${
                    tipoAtivo === 'agua'
                      ? 'bg-gradient-to-r from-blue-500 to-cyan-500 text-white shadow-lg'
                      : 'text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  <Droplets className="w-5 h-5" />
                  <span className="hidden sm:inline">Água</span>
                </button>
                <button
                  onClick={() => setTipoAtivo('energia')}
                  className={`flex items-center gap-2 px-6 py-3 rounded-xl font-semibold transition-all duration-300 ${
                    tipoAtivo === 'energia'
                      ? 'bg-gradient-to-r from-yellow-300 to-yellow-300 text-white shadow-lg'
                      : 'text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  <Zap className="w-5 h-5" />
                  <span className="hidden sm:inline">Energia</span>
                </button>
              </div>
            </div>
          </div>

          {/* Steps Desktop */}
          <div className="hidden md:flex items-center justify-between gap-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            {[
              { num: 1, title: 'Unidade', icon: Building, done: !!predioSelecionado },
              { num: 2, title: 'Andar', icon: MapPin, done: !!andarSelecionado },
              { num: 3, title: 'Relógio', icon: Info, done: !!medidorSelecionado },
              { num: 4, title: 'Leitura', icon: TrendingUp, done: leituraAtual !== '' },
              { num: 5, title: 'Foto', icon: Camera, done: !!foto }
            ].map((step, idx, arr) => (
              <div key={step.num} className="flex items-center flex-1">
                <div className={`flex items-center gap-3 ${currentStep === step.num ? 'scale-105' : ''} transition-transform`}>
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center font-bold transition-all ${
                    step.done
                      ? (tipoAtivo === 'agua' ? 'bg-blue-500 text-white' : 'bg-yellow-300 text-white')
                      : currentStep === step.num
                      ? 'bg-white border-2 border-gray-300 text-gray-700'
                      : 'bg-gray-100 text-gray-400'
                  }`}>
                    {step.done ? <CheckCircle className="w-6 h-6" /> : <step.icon className="w-5 h-5" />}
                  </div>
                  <div>
                    <div className="text-xs text-gray-500 font-medium">Passo {step.num}</div>
                    <div className="text-sm font-semibold text-gray-900">{step.title}</div>
                  </div>
                </div>
                {idx < arr.length - 1 && <ArrowRight className="mx-2 text-gray-300" />}
              </div>
            ))}
          </div>
        </div>

        {/* MODAL DO SCANNER */}
        {mostrarScanner && (
          <div className="fixed inset-0 z-50 bg-black flex flex-col items-center justify-center p-4 animate-in fade-in">
            <div className="w-full max-w-sm relative">
              <h3 className="text-white text-center text-lg font-bold mb-4">Aponte para o QR Code (UUID)</h3>
              <div className="rounded-2xl overflow-hidden border-2 border-white shadow-2xl">
                <Scanner 
                  onScan={handleMedidorScan} 
                  scanDelay={500} 
                  allowMultiple={false} 
                />
              </div>
              <button 
                onClick={handleCancelScan}
                className="mt-6 w-full py-3 bg-white/20 border border-white/30 text-white rounded-xl font-bold backdrop-blur-sm"
              >
                Cancelar
              </button>
            </div>
          </div>
        )}

        {/* MENSAGEM DE SUCESSO/ALERTA */}
        {mensagem && (
          <div className={`mb-6 p-4 rounded-2xl flex items-center gap-3 animate-in slide-in-from-top ${
            mensagem.includes('Alerta') 
              ? 'bg-yellow-50 border border-yellow-200 text-yellow-800' 
              : 'bg-green-50 border border-green-200 text-emerald-900'
          }`}>
            <CheckCircle className="w-6 h-6 flex-shrink-0" />
            <span className="font-semibold">{mensagem}</span>
          </div>
        )}

        {/* FORMULÁRIO */}
        <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-3 gap-8">
          
          <div className="md:col-span-2 space-y-6">
            {/* 1. SELEÇÃO */}
            <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                <Search className="w-5 h-5 text-gray-500" /> Identificação
              </h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <label className="block text-sm font-semibold text-gray-700">Unidade</label>
                  <CustomSelect 
                    value={predioSelecionado} 
                    onChange={(val) => { setPredioSelecionado(val); setAndarSelecionado(''); setMedidorSelecionado('') }} 
                    options={prediosUnicos.map(p => ({ value: p, label: p }))} 
                    placeholder="Selecione..." 
                    icon={Building} 
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-sm font-semibold text-gray-700">Andar</label>
                  <CustomSelect 
                    value={andarSelecionado} 
                    onChange={(val) => { setAndarSelecionado(val); setMedidorSelecionado('') }} 
                    options={andaresOpcoes.map(a => ({ value: a.valor, label: a.label }))} 
                    placeholder="Selecione..." 
                    disabled={!predioSelecionado} 
                    icon={MapPin} 
                  />
                </div>
                <div className="space-y-2 sm:col-span-2 md:col-span-1">
                  <label className="block text-sm font-semibold text-gray-700">Medidor</label>
                  <CustomSelect 
                    value={medidorSelecionado} 
                    onChange={(val) => setMedidorSelecionado(val)} 
                    options={medidoresFinais.map(m => ({ value: m.id, label: m.nome }))} 
                    placeholder="Qual medidor?" 
                    disabled={!andarSelecionado} 
                  />
                </div>
              </div>
            </div>

            {/* 2. LEITURA */}
            <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
               <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-gray-500" /> Valor ({tipoAtivo === 'agua' ? 'm³' : 'kWh'})
              </h2>
              <input 
                type="number" 
                step="0.01" 
                className={`w-full px-6 py-5 text-3xl font-black tracking-wider rounded-xl focus:outline-none transition-all ${
                  !medidorSelecionado 
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed' 
                    : isMenorQueAnterior || isConsumoAlto 
                    ? 'bg-red-50 border-2 border-red-400 text-red-600' 
                    : 'bg-gray-50 border-2 border-gray-300 text-gray-900'
                }`} 
                placeholder="00000" 
                value={leituraAtual} 
                onChange={(e) => { 
                  setLeituraAtual(e.target.value); 
                  if (Number(e.target.value) >= leituraAnterior) setMotivoValidacao('') 
                }} 
                disabled={!medidorSelecionado} 
              />
               
               {isMenorQueAnterior && (
                  <div className="mt-4 bg-red-50 border border-red-200 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-red-800 font-bold mb-2">
                      <AlertTriangle className="w-5 h-5" /> Valor Menor que Anterior
                    </div>
                    <div className="flex gap-4">
                       <label className="flex items-center gap-2 cursor-pointer">
                         <input type="radio" name="motivo" onChange={() => setMotivoValidacao('virada')} className="accent-red-600 w-5 h-5" />
                         <span className="text-sm">Relógio Virou</span>
                       </label>
                       <label className="flex items-center gap-2 cursor-pointer">
                         <input type="radio" name="motivo" onChange={() => setMotivoValidacao('ajuste')} className="accent-red-600 w-5 h-5" />
                         <span className="text-sm">Correção Manual</span>
                       </label>
                    </div>
                  </div>
                )}
            </div>

            {/* 3. FOTO */}
            <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                <Camera className="w-5 h-5 text-gray-500" /> Evidência
              </h2>
              <input 
                ref={fileInputRef} 
                type="file" 
                accept="image/*" 
                capture="environment" 
                onChange={handleFileSelect} 
                className="hidden" 
              />
              {!previewUrl ? (
                <button 
                  type="button" 
                  onClick={() => fileInputRef.current?.click()} 
                  disabled={!leituraAtual} 
                  className={`w-full py-12 border-3 border-dashed rounded-xl transition-all flex flex-col items-center justify-center gap-3 ${
                    !leituraAtual 
                      ? 'border-gray-200 bg-gray-50 text-gray-400 cursor-not-allowed' 
                      : 'border-gray-300 bg-gray-50 hover:bg-gray-100 text-gray-600'
                  }`}
                >
                  <Camera className="w-10 h-10 mb-1 opacity-50" />
                  <span className="font-bold">Tirar Foto</span>
                </button>
              ) : (
                <div className="relative rounded-xl overflow-hidden border border-gray-200 h-64">
                  <img src={previewUrl} className="w-full h-full object-cover" alt="Evidência" />
                  <button 
                    onClick={() => {setFoto(null); setPreviewUrl(null)}} 
                    className="absolute top-2 right-2 p-2 bg-red-600 text-white rounded-full shadow-lg"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              )}
            </div>
            
            {/* BOTÃO MOBILE */}
            <button 
              type="submit" 
              disabled={loading || !podeEnviar} 
              className={`md:hidden w-full py-5 rounded-xl font-bold text-lg shadow-xl text-white mb-20 ${
                !podeEnviar 
                  ? 'bg-gray-300' 
                  : tipoAtivo === 'agua' ? 'bg-blue-600' : 'bg-yellow-500'
              }`}
            >
              {loading ? 'Salvando...' : 'Confirmar Leitura'}
            </button>
          </div>

          {/* SIDEBAR RESUMO (DESKTOP) */}
          <div className="hidden md:block col-span-1 space-y-6">
            <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6 sticky top-8">
              <h3 className="font-bold text-gray-900 mb-4">Resumo</h3>
              <div className="space-y-4">
                 <div className="p-4 bg-gray-50 rounded-xl">
                   <p className="text-xs text-gray-500 uppercase">Leitura Anterior</p>
                   <p className="text-2xl font-bold text-gray-800">{leituraAnterior}</p>
                 </div>
                 {leituraAtual && (
                   <div className={`p-4 rounded-xl border ${isMenorQueAnterior || isConsumoAlto ? 'bg-red-50 border-red-200' : 'bg-green-50 border-green-200'}`}>
                     <p className={`text-xs uppercase ${isMenorQueAnterior || isConsumoAlto ? 'text-red-600' : 'text-green-600'}`}>Consumo</p>
                     <p className={`text-3xl font-black ${isMenorQueAnterior || isConsumoAlto ? 'text-red-700' : 'text-green-700'}`}>{consumo}</p>
                   </div>
                 )}
                 <button 
                  type="submit" 
                  disabled={loading || !podeEnviar} 
                  className={`w-full py-4 rounded-xl font-bold text-white shadow-lg transition-transform hover:scale-105 ${
                    !podeEnviar 
                      ? 'bg-gray-300 cursor-not-allowed' 
                      : tipoAtivo === 'agua' ? 'bg-blue-600 hover:bg-blue-700' : 'bg-yellow-500 hover:bg-yellow-600'
                  }`}
                >
                  {loading ? 'Salvando...' : 'Confirmar'}
                </button>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}