/**
 * Development Helpers
 * Funções para testar a aplicação sem backend
 *
 * ⚠️ APENAS PARA DESENVOLVIMENTO LOCAL - REMOVER EM PRODUÇÃO
 */

import type { User } from '@/types'
import { UserRole, RiskProfile, UserStatus, BillingPeriod } from '@/types'

/**
 * Mock User Data para testes
 */
export const MOCK_USER: User = {
  id: 1,
  fullName: 'João da Silva',
  displayName: 'João',
  email: { value: 'joao@email.com' },
  passwordHash: '',
  phoneNumber: {
    countryCode: '+55',
    number: '11987654321'
  },
  isPhoneVerified: true,
  role: UserRole.Trader,
  riskProfile: RiskProfile.Moderate,
  status: UserStatus.Active,
  subscriptionPlanId: 2,
  subscriptionPlan: {
    id: 2,
    name: 'Pleno',
    price: 49.9,
    billingPeriod: BillingPeriod.Monthly,
    strategyLimit: null,
    hasRealtimeData: true,
    hasAdvancedAlerts: true,
    hasConsultingTools: false,
    hasCommunityAccess: true,
    isActive: true
  },
  billingPeriod: BillingPeriod.Monthly,
  planOverride: null,
  createdAt: '2025-01-01T00:00:00Z',
  lastLoginAt: '2025-11-15T10:00:00Z'
}

/**
 * Simula login com usuário mock
 */
export function mockLogin() {
  try {
    console.log('🚀 Iniciando mock login...')

    const MOCK_TOKEN = 'mock-jwt-token-for-development'

    // Armazena no sessionStorage
    sessionStorage.setItem('auth_token', MOCK_TOKEN)
    sessionStorage.setItem('user', JSON.stringify(MOCK_USER))

    console.log('✅ Mock login realizado com sucesso!')
    console.log('👤 Usuário:', MOCK_USER)
    console.log('🔑 Token:', MOCK_TOKEN)
    console.log('📍 Recarregue a página ou navegue para /dashboard')
    console.log('')
    console.log('💡 Execute: location.href = "/dashboard"')

    return { user: MOCK_USER, token: MOCK_TOKEN }
  } catch (error) {
    console.error('❌ Erro no mock login:', error)
    throw error
  }
}

/**
 * Limpa dados de autenticação mock
 */
export function mockLogout() {
  sessionStorage.removeItem('auth_token')
  sessionStorage.removeItem('user')

  console.log('✅ Mock logout realizado com sucesso!')
  console.log('📍 Navegue para /login')
}

// Expõe funções no window para facilitar testes (apenas em desenvolvimento)
if (import.meta.env.DEV) {
  // Declara as funções no window
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(window as any).mockLogin = mockLogin
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(window as any).mockLogout = mockLogout
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(window as any).MOCK_USER = MOCK_USER

  console.log('🔧 Dev Helpers disponíveis:')
  console.log('  window.mockLogin() - Simula login')
  console.log('  window.mockLogout() - Limpa sessão')
  console.log('  window.MOCK_USER - Dados do usuário mock')
}
