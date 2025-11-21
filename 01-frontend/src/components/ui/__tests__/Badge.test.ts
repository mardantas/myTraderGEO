import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Badge from '../Badge.vue'

describe('Badge', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(Badge, {
        slots: { default: 'Badge' }
      })

      expect(wrapper.text()).toBe('Badge')
      expect(wrapper.classes()).toContain('bg-surface')
      expect(wrapper.classes()).toContain('px-2.5') // md size
    })

    it('should render slot content', () => {
      const wrapper = mount(Badge, {
        slots: { default: 'Active' }
      })

      expect(wrapper.text()).toBe('Active')
    })

    it('should render icon slot', () => {
      const wrapper = mount(Badge, {
        slots: {
          default: 'Badge',
          icon: '<svg data-testid="icon"></svg>'
        }
      })

      expect(wrapper.find('[data-testid="icon"]').exists()).toBe(true)
    })
  })

  describe('Sizes', () => {
    it('should apply small size classes', () => {
      const wrapper = mount(Badge, {
        props: { size: 'sm' }
      })

      expect(wrapper.classes()).toContain('px-2')
      expect(wrapper.classes()).toContain('py-0.5')
      expect(wrapper.classes()).toContain('text-xs')
    })

    it('should apply medium size classes', () => {
      const wrapper = mount(Badge, {
        props: { size: 'md' }
      })

      expect(wrapper.classes()).toContain('px-2.5')
      expect(wrapper.classes()).toContain('py-1')
      expect(wrapper.classes()).toContain('text-sm')
    })
  })

  describe('Variants', () => {
    it('should apply default variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'default' }
      })

      expect(wrapper.classes()).toContain('bg-surface')
      expect(wrapper.classes()).toContain('text-text-primary')
    })

    it('should apply primary variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'primary' }
      })

      expect(wrapper.classes()).toContain('bg-primary/10')
      expect(wrapper.classes()).toContain('text-primary')
    })

    it('should apply success variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'success' }
      })

      expect(wrapper.classes()).toContain('bg-success/10')
      expect(wrapper.classes()).toContain('text-success')
    })

    it('should apply danger variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'danger' }
      })

      expect(wrapper.classes()).toContain('bg-danger/10')
      expect(wrapper.classes()).toContain('text-danger')
    })

    it('should apply warning variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'warning' }
      })

      expect(wrapper.classes()).toContain('bg-warning/10')
      expect(wrapper.classes()).toContain('text-warning')
    })

    it('should apply info variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'info' }
      })

      expect(wrapper.classes()).toContain('bg-info/10')
      expect(wrapper.classes()).toContain('text-info')
    })
  })

  describe('Status Variants', () => {
    it('should apply active variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'active' }
      })

      expect(wrapper.classes()).toContain('bg-success/10')
      expect(wrapper.classes()).toContain('text-success')
    })

    it('should apply inactive variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'inactive' }
      })

      expect(wrapper.classes()).toContain('bg-neutral/10')
      expect(wrapper.classes()).toContain('text-neutral')
    })

    it('should apply suspended variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'suspended' }
      })

      expect(wrapper.classes()).toContain('bg-danger/10')
      expect(wrapper.classes()).toContain('text-danger')
    })

    it('should apply pending variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'pending' }
      })

      expect(wrapper.classes()).toContain('bg-warning/10')
      expect(wrapper.classes()).toContain('text-warning')
    })
  })

  describe('P&L Variants', () => {
    it('should apply profit variant with monospace font', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'profit' }
      })

      expect(wrapper.classes()).toContain('bg-profit/10')
      expect(wrapper.classes()).toContain('text-profit')
      expect(wrapper.classes()).toContain('font-mono')
    })

    it('should apply loss variant with monospace font', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'loss' }
      })

      expect(wrapper.classes()).toContain('bg-loss/10')
      expect(wrapper.classes()).toContain('text-loss')
      expect(wrapper.classes()).toContain('font-mono')
    })

    it('should apply neutral variant with monospace font', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'neutral' }
      })

      expect(wrapper.classes()).toContain('bg-neutral/10')
      expect(wrapper.classes()).toContain('text-neutral')
      expect(wrapper.classes()).toContain('font-mono')
    })
  })

  describe('Role Variants', () => {
    it('should apply premium variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'premium' }
      })

      expect(wrapper.classes()).toContain('bg-purple-100')
      expect(wrapper.classes()).toContain('text-purple-700')
    })

    it('should apply trader variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'trader' }
      })

      expect(wrapper.classes()).toContain('bg-blue-100')
      expect(wrapper.classes()).toContain('text-blue-700')
    })

    it('should apply consultant variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'consultant' }
      })

      expect(wrapper.classes()).toContain('bg-purple-100')
      expect(wrapper.classes()).toContain('text-purple-700')
    })
  })

  describe('Risk Variants', () => {
    it('should apply riskLow variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'riskLow' }
      })

      expect(wrapper.classes()).toContain('bg-success/10')
      expect(wrapper.classes()).toContain('text-success')
    })

    it('should apply riskMedium variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'riskMedium' }
      })

      expect(wrapper.classes()).toContain('bg-warning/10')
      expect(wrapper.classes()).toContain('text-warning')
    })

    it('should apply riskHigh variant', () => {
      const wrapper = mount(Badge, {
        props: { variant: 'riskHigh' }
      })

      expect(wrapper.classes()).toContain('bg-danger/10')
      expect(wrapper.classes()).toContain('text-danger')
    })
  })
})
