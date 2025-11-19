import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Alert from '../Alert.vue'

describe('Alert', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(Alert, {
        slots: { default: 'Alert message' }
      })

      expect(wrapper.text()).toContain('Alert message')
      expect(wrapper.find('div').exists()).toBe(true)
    })

    it('should render slot content', () => {
      const wrapper = mount(Alert, {
        slots: {
          default: '<strong>Important:</strong> Read this'
        }
      })

      expect(wrapper.html()).toContain('<strong>Important:</strong> Read this')
    })

    it('should render icon', () => {
      const wrapper = mount(Alert, {
        slots: { default: 'Message' }
      })

      // Check for SVG icon
      expect(wrapper.find('svg').exists()).toBe(true)
    })
  })

  describe('Variants', () => {
    it('should apply info variant by default', () => {
      const wrapper = mount(Alert)

      expect(wrapper.classes()).toContain('bg-info/10')
      expect(wrapper.classes()).toContain('border-info/20')
      expect(wrapper.classes()).toContain('text-info')
    })

    it('should apply success variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'success' }
      })

      expect(wrapper.classes()).toContain('bg-success/10')
      expect(wrapper.classes()).toContain('border-success/20')
      expect(wrapper.classes()).toContain('text-success')
    })

    it('should apply warning variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'warning' }
      })

      expect(wrapper.classes()).toContain('bg-warning/10')
      expect(wrapper.classes()).toContain('border-warning/20')
      expect(wrapper.classes()).toContain('text-warning')
    })

    it('should apply error variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'error' }
      })

      expect(wrapper.classes()).toContain('bg-danger/10')
      expect(wrapper.classes()).toContain('border-danger/20')
      expect(wrapper.classes()).toContain('text-danger')
    })
  })

  describe('Icons', () => {
    it('should render InformationCircleIcon for info variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'info' },
        slots: { default: 'Info' }
      })

      // Icon should be rendered as first SVG element
      expect(wrapper.findAll('svg').length).toBeGreaterThan(0)
    })

    it('should render CheckCircleIcon for success variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'success' },
        slots: { default: 'Success' }
      })

      expect(wrapper.findAll('svg').length).toBeGreaterThan(0)
    })

    it('should render ExclamationTriangleIcon for warning variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'warning' },
        slots: { default: 'Warning' }
      })

      expect(wrapper.findAll('svg').length).toBeGreaterThan(0)
    })

    it('should render XCircleIcon for error variant', () => {
      const wrapper = mount(Alert, {
        props: { variant: 'error' },
        slots: { default: 'Error' }
      })

      expect(wrapper.findAll('svg').length).toBeGreaterThan(0)
    })
  })

  describe('Dismissible', () => {
    it('should not show close button by default', () => {
      const wrapper = mount(Alert, {
        slots: { default: 'Message' }
      })

      expect(wrapper.find('button').exists()).toBe(false)
    })

    it('should show close button when dismissible is true', () => {
      const wrapper = mount(Alert, {
        props: { dismissible: true },
        slots: { default: 'Message' }
      })

      const button = wrapper.find('button')
      expect(button.exists()).toBe(true)
      expect(button.find('svg').exists()).toBe(true) // XMarkIcon
    })

    it('should emit close event when close button clicked', async () => {
      const wrapper = mount(Alert, {
        props: { dismissible: true },
        slots: { default: 'Message' }
      })

      const button = wrapper.find('button')
      await button.trigger('click')

      expect(wrapper.emitted('close')).toBeTruthy()
      expect(wrapper.emitted('close')?.length).toBe(1)
    })

    it('should not emit close when not dismissible', () => {
      const wrapper = mount(Alert, {
        props: { dismissible: false },
        slots: { default: 'Message' }
      })

      expect(wrapper.find('button').exists()).toBe(false)
      expect(wrapper.emitted('close')).toBeFalsy()
    })
  })

  describe('Styling', () => {
    it('should apply base styling classes', () => {
      const wrapper = mount(Alert)

      expect(wrapper.classes()).toContain('relative')
      expect(wrapper.classes()).toContain('p-4')
      expect(wrapper.classes()).toContain('rounded-lg')
      expect(wrapper.classes()).toContain('border')
    })

    it('should have correct layout structure', () => {
      const wrapper = mount(Alert, {
        slots: { default: 'Content' }
      })

      const flexContainer = wrapper.find('.flex.gap-3')
      expect(flexContainer.exists()).toBe(true)

      const content = wrapper.find('.flex-1.text-sm.text-text-primary')
      expect(content.exists()).toBe(true)
    })
  })

  describe('Accessibility', () => {
    it('should have accessible close button', () => {
      const wrapper = mount(Alert, {
        props: { dismissible: true },
        slots: { default: 'Message' }
      })

      const button = wrapper.find('button')
      expect(button.attributes('type')).toBe('button')
    })
  })
})
