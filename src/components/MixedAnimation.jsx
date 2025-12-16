import { Droplet, Zap } from 'lucide-react'

export default function MixedAnimation() {
  // Cria 10 colunas de gotas caindo
  const rainColumns = Array.from({ length: 10 }, (_, i) => i)

  // Cria 8 colunas de raios caindo
  const lightningColumns = Array.from({ length: 8 }, (_, i) => i)

  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {/* Gotas de Chuva */}
      {rainColumns.map((col) => (
        <div
          key={`rain-${col}`}
          className="absolute top-0 animate-fall opacity-50"
          style={{
            left: `${(col / 10) * 100}%`,
            animationDelay: `${Math.random() * 3}s`,
            animationDuration: `${4 + Math.random() * 2}s`
          }}
        >
          <Droplet
            size={24}
            className="text-cyan-300"
            fill="currentColor"
          />
        </div>
      ))}

      {/* Raios */}
      {lightningColumns.map((col) => (
        <div
          key={`lightning-${col}`}
          className="absolute top-0 animate-fall-lightning opacity-60"
          style={{
            left: `${(col / 8) * 100 + 5}%`, // Offset para não sobrepor gotas
            animationDelay: `${Math.random() * 2.5}s`,
            animationDuration: `${3 + Math.random() * 1.5}s`
          }}
        >
          <Zap
            size={24}
            className="text-yellow-300"
            fill="currentColor"
          />
        </div>
      ))}

      <style jsx>{`
        @keyframes fall {
          0% {
            transform: translateY(-20px);
            opacity: 0;
          }
          10% {
            opacity: 0.5;
          }
          90% {
            opacity: 0.2;
          }
          100% {
            transform: translateY(100vh);
            opacity: 0;
          }
        }

        @keyframes fall-lightning {
          0% {
            transform: translateY(-20px);
            opacity: 0;
          }
          10% {
            opacity: 0.7;
          }
          50% {
            opacity: 0.3;
          }
          60% {
            opacity: 0.7;
          }
          90% {
            opacity: 0.2;
          }
          100% {
            transform: translateY(100vh);
            opacity: 0;
          }
        }

        .animate-fall {
          animation: fall 5s linear infinite;
        }

        .animate-fall-lightning {
          animation: fall-lightning 4s linear infinite;
        }
      `}</style>
    </div>
  )
}