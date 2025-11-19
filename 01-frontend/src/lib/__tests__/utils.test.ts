import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  cn,
  formatCurrency,
  formatPercentage,
  formatPhoneNumber,
  maskPhoneNumber,
  getInitials,
  formatDate,
  formatDateTime,
  timeAgo,
  sleep,
  debounce,
  truncate,
  validateCPF,
  formatCPF
} from '../utils'

describe('Utility Functions', () => {
  describe('cn()', () => {
    it('should merge class names', () => {
      const result = cn('px-4', 'py-2', 'bg-primary')
      expect(result).toContain('px-4')
      expect(result).toContain('py-2')
      expect(result).toContain('bg-primary')
    })

    it('should merge conflicting Tailwind classes', () => {
      const result = cn('px-4', 'px-6')
      // tailwind-merge should keep only the last one
      expect(result).toBe('px-6')
    })

    it('should handle conditional classes', () => {
      const result = cn('base', true && 'conditional', false && 'hidden')
      expect(result).toContain('base')
      expect(result).toContain('conditional')
      expect(result).not.toContain('hidden')
    })

    it('should handle arrays and objects', () => {
      const result = cn(['px-4', 'py-2'], { 'bg-primary': true, 'bg-secondary': false })
      expect(result).toContain('px-4')
      expect(result).toContain('py-2')
      expect(result).toContain('bg-primary')
      expect(result).not.toContain('bg-secondary')
    })
  })

  describe('formatCurrency()', () => {
    it('should format positive values', () => {
      const result = formatCurrency(100)
      expect(result).toContain('100,00')
      expect(result).toContain('R$')
    })

    it('should format negative values', () => {
      const result = formatCurrency(-50.5)
      expect(result).toContain('50,50')
      expect(result).toContain('-')
    })

    it('should format zero', () => {
      const result = formatCurrency(0)
      expect(result).toContain('0,00')
      expect(result).toContain('R$')
    })

    it('should format large numbers', () => {
      const result = formatCurrency(1000000)
      expect(result).toContain('1.000.000,00')
      expect(result).toContain('R$')
    })

    it('should format decimals', () => {
      const result = formatCurrency(49.99)
      expect(result).toContain('49,99')
      expect(result).toContain('R$')
    })
  })

  describe('formatPercentage()', () => {
    it('should format positive percentage', () => {
      expect(formatPercentage(5.5)).toBe('+5.50%')
    })

    it('should format negative percentage', () => {
      expect(formatPercentage(-3.2)).toBe('-3.20%')
    })

    it('should format zero', () => {
      expect(formatPercentage(0)).toBe('+0.00%')
    })

    it('should respect decimals parameter', () => {
      expect(formatPercentage(5.123, 1)).toBe('+5.1%')
      expect(formatPercentage(5.123, 3)).toBe('+5.123%')
    })

    it('should add plus sign for positive', () => {
      expect(formatPercentage(10)).toBe('+10.00%')
    })

    it('should not add plus sign for negative', () => {
      expect(formatPercentage(-10)).toBe('-10.00%')
    })
  })

  describe('formatPhoneNumber()', () => {
    it('should format Brazilian mobile number', () => {
      expect(formatPhoneNumber('+55', '11987654321')).toBe('+55 11 98765-4321')
    })

    it('should format generic phone number', () => {
      expect(formatPhoneNumber('+1', '5551234')).toBe('+1 5551234')
    })

    it('should handle short numbers', () => {
      expect(formatPhoneNumber('+55', '123')).toBe('+55 123')
    })
  })

  describe('maskPhoneNumber()', () => {
    it('should mask phone number', () => {
      expect(maskPhoneNumber('+55', '11987654321')).toBe('+55 ** ****-4321')
    })

    it('should handle short numbers', () => {
      expect(maskPhoneNumber('+55', '123')).toBe('+55 123')
    })

    it('should show only last 4 digits', () => {
      const result = maskPhoneNumber('+1', '5551234567')
      expect(result).toContain('4567')
      expect(result).not.toContain('555123')
    })
  })

  describe('getInitials()', () => {
    it('should get initials from full name', () => {
      // "da" is counted as a word, so we get J from João and D from da
      expect(getInitials('João Silva')).toBe('JS')
    })

    it('should get initials from single name', () => {
      expect(getInitials('João')).toBe('J')
    })

    it('should get only first two initials', () => {
      expect(getInitials('João Pedro da Silva Santos')).toBe('JP')
    })

    it('should handle extra spaces', () => {
      expect(getInitials('João  Silva')).toBe('JS')
    })

    it('should uppercase initials', () => {
      expect(getInitials('joão silva')).toBe('JS')
    })

    it('should handle empty string', () => {
      expect(getInitials('')).toBe('')
    })
  })

  describe('formatDate()', () => {
    it('should format ISO date to Brazilian format', () => {
      const result = formatDate('2025-01-15T00:00:00Z')
      // Result depends on timezone, but should contain dd/mm/yyyy format
      expect(result).toMatch(/\d{2}\/\d{2}\/\d{4}/)
    })
  })

  describe('formatDateTime()', () => {
    it('should format ISO datetime to Brazilian format', () => {
      const result = formatDateTime('2025-01-15T14:30:00Z')
      // Result depends on timezone, but should contain date and time
      expect(result).toMatch(/\d{2}\/\d{2}\/\d{4}/)
      expect(result).toMatch(/\d{2}:\d{2}/)
    })
  })

  describe('timeAgo()', () => {
    beforeEach(() => {
      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('should return "agora" for recent time', () => {
      const now = new Date()
      vi.setSystemTime(now)

      const thirtySecondsAgo = new Date(now.getTime() - 30000)
      expect(timeAgo(thirtySecondsAgo.toISOString())).toBe('agora')
    })

    it('should return minutes ago', () => {
      const now = new Date()
      vi.setSystemTime(now)

      const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000)
      expect(timeAgo(fiveMinutesAgo.toISOString())).toBe('há 5 minutos')
    })

    it('should return hours ago', () => {
      const now = new Date()
      vi.setSystemTime(now)

      const threeHoursAgo = new Date(now.getTime() - 3 * 60 * 60 * 1000)
      expect(timeAgo(threeHoursAgo.toISOString())).toBe('há 3 horas')
    })

    it('should return days ago', () => {
      const now = new Date()
      vi.setSystemTime(now)

      const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000)
      expect(timeAgo(twoDaysAgo.toISOString())).toBe('há 2 dias')
    })

    it('should return singular for 1 unit', () => {
      const now = new Date()
      vi.setSystemTime(now)

      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000)
      expect(timeAgo(oneHourAgo.toISOString())).toBe('há 1 hora')
    })
  })

  describe('sleep()', () => {
    it('should resolve after specified time', async () => {
      vi.useFakeTimers()

      const promise = sleep(1000)
      vi.advanceTimersByTime(1000)

      await expect(promise).resolves.toBeUndefined()

      vi.useRealTimers()
    })
  })

  describe('debounce()', () => {
    beforeEach(() => {
      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('should debounce function calls', () => {
      const fn = vi.fn()
      const debounced = debounce(fn, 300)

      debounced()
      debounced()
      debounced()

      expect(fn).not.toHaveBeenCalled()

      vi.advanceTimersByTime(300)

      expect(fn).toHaveBeenCalledTimes(1)
    })

    it('should pass arguments to debounced function', () => {
      const fn = vi.fn()
      const debounced = debounce(fn, 300)

      debounced('arg1', 'arg2')
      vi.advanceTimersByTime(300)

      expect(fn).toHaveBeenCalledWith('arg1', 'arg2')
    })

    it('should reset timer on new call', () => {
      const fn = vi.fn()
      const debounced = debounce(fn, 300)

      debounced()
      vi.advanceTimersByTime(100)

      debounced()
      vi.advanceTimersByTime(100)

      expect(fn).not.toHaveBeenCalled()

      vi.advanceTimersByTime(200)

      expect(fn).toHaveBeenCalledTimes(1)
    })
  })

  describe('truncate()', () => {
    it('should truncate long text', () => {
      expect(truncate('This is a long text', 10)).toBe('This is a ...')
    })

    it('should not truncate short text', () => {
      expect(truncate('Short', 10)).toBe('Short')
    })

    it('should handle exact length', () => {
      expect(truncate('Exactly10!', 10)).toBe('Exactly10!')
    })

    it('should add ellipsis', () => {
      const result = truncate('This is a long text', 5)
      expect(result).toContain('...')
      expect(result.length).toBe(8) // 5 chars + '...'
    })
  })

  describe('validateCPF()', () => {
    it('should validate correct CPF', () => {
      expect(validateCPF('12345678909')).toBe(true)
      expect(validateCPF('111.444.777-35')).toBe(true)
    })

    it('should reject invalid CPF', () => {
      expect(validateCPF('12345678900')).toBe(false)
    })

    it('should reject CPF with less than 11 digits', () => {
      expect(validateCPF('123456789')).toBe(false)
    })

    it('should reject CPF with all same digits', () => {
      expect(validateCPF('11111111111')).toBe(false)
      expect(validateCPF('00000000000')).toBe(false)
    })

    it('should handle CPF with formatting', () => {
      expect(validateCPF('123.456.789-09')).toBe(true)
    })

    it('should reject empty CPF', () => {
      expect(validateCPF('')).toBe(false)
    })
  })

  describe('formatCPF()', () => {
    it('should format CPF with dots and dash', () => {
      expect(formatCPF('12345678909')).toBe('123.456.789-09')
    })

    it('should format already formatted CPF', () => {
      expect(formatCPF('123.456.789-09')).toBe('123.456.789-09')
    })

    it('should remove non-digit characters', () => {
      expect(formatCPF('123abc456def789ghi09')).toBe('123.456.789-09')
    })
  })
})
