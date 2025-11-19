/**
 * Utility Functions
 */

import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

/**
 * Merge Tailwind CSS classes (clsx + tailwind-merge)
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Format currency to Brazilian Real (R$)
 */
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value)
}

/**
 * Format percentage with + or - sign
 */
export function formatPercentage(value: number, decimals: number = 2): string {
  const sign = value >= 0 ? '+' : ''
  return `${sign}${value.toFixed(decimals)}%`
}

/**
 * Format phone number to international format
 * Example: formatPhoneNumber('+55', '11987654321') => '+55 11 98765-4321'
 */
export function formatPhoneNumber(countryCode: string, number: string): string {
  // Brazilian format
  if (countryCode === '+55' && number.length === 11) {
    return `${countryCode} ${number.slice(0, 2)} ${number.slice(2, 7)}-${number.slice(7)}`
  }

  // Generic format
  return `${countryCode} ${number}`
}

/**
 * Mask phone number for security (show only last 4 digits)
 * Example: maskPhoneNumber('+55', '11987654321') => '+55 ** ****-4321'
 */
export function maskPhoneNumber(countryCode: string, number: string): string {
  if (number.length < 4) return `${countryCode} ${number}`
  const lastFour = number.slice(-4)
  return `${countryCode} ** ****-${lastFour}`
}

/**
 * Get initials from name
 * Example: getInitials('João da Silva') => 'JS'
 */
export function getInitials(name: string): string {
  return name
    .split(' ')
    .filter((word) => word.length > 0)
    .map((word) => word[0]!.toUpperCase())
    .slice(0, 2)
    .join('')
}

/**
 * Format date to Brazilian format (dd/mm/yyyy)
 */
export function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('pt-BR').format(date)
}

/**
 * Format date and time to Brazilian format (dd/mm/yyyy HH:mm)
 */
export function formatDateTime(dateString: string): string {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short'
  }).format(date)
}

/**
 * Calculate time ago from ISO date string
 * Example: timeAgo('2025-11-13T10:00:00Z') => 'há 1 dia'
 */
export function timeAgo(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  const intervals: { [key: string]: number } = {
    ano: 31536000,
    mês: 2592000,
    semana: 604800,
    dia: 86400,
    hora: 3600,
    minuto: 60
  }

  for (const [label, secondsInInterval] of Object.entries(intervals)) {
    const interval = Math.floor(seconds / secondsInInterval)
    if (interval >= 1) {
      return interval === 1 ? `há 1 ${label}` : `há ${interval} ${label}s`
    }
  }

  return 'agora'
}

/**
 * Sleep utility (for demos/testing)
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/**
 * Debounce utility
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: ReturnType<typeof setTimeout> | null = null

  return function executedFunction(...args: Parameters<T>) {
    const later = () => {
      if (timeout) clearTimeout(timeout)
      func(...args)
    }

    if (timeout) clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

/**
 * Truncate text with ellipsis
 */
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + '...'
}

/**
 * Validate CPF (Brazilian tax ID)
 */
export function validateCPF(cpf: string): boolean {
  cpf = cpf.replace(/\D/g, '')

  if (cpf.length !== 11) return false
  if (/^(\d)\1+$/.test(cpf)) return false

  let sum = 0
  let remainder: number

  for (let i = 1; i <= 9; i++) {
    sum += parseInt(cpf.substring(i - 1, i)) * (11 - i)
  }

  remainder = (sum * 10) % 11
  if (remainder === 10 || remainder === 11) remainder = 0
  if (remainder !== parseInt(cpf.substring(9, 10))) return false

  sum = 0
  for (let i = 1; i <= 10; i++) {
    sum += parseInt(cpf.substring(i - 1, i)) * (12 - i)
  }

  remainder = (sum * 10) % 11
  if (remainder === 10 || remainder === 11) remainder = 0
  if (remainder !== parseInt(cpf.substring(10, 11))) return false

  return true
}

/**
 * Format CPF (000.000.000-00)
 */
export function formatCPF(cpf: string): string {
  cpf = cpf.replace(/\D/g, '')
  return cpf.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
}
