import React, { createContext, useState, useContext } from 'react'

const ThemeContext = createContext()

export function ThemeProvider({ children }) {
  const [tipoAtivo, setTipoAtivo] = useState('agua')
  const [dataVersion, setDataVersion] = useState(0)

  // Função para forçar a atualização de componentes que dependem de dados do banco
  const refreshData = () => {
    setDataVersion(v => v + 1)
  }

  return (
    <ThemeContext.Provider value={{ tipoAtivo, setTipoAtivo, dataVersion, refreshData }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider')
  }
  return context
}
