import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Label from '../Label.vue'

describe('Label', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(Label, {
        slots: { default: 'Email' }
      })

      expect(wrapper.find('label').exists()).toBe(true)
      expect(wrapper.text()).toContain('Email')
    })

    it('should render slot content', () => {
      const wrapper = mount(Label, {
        slots: { default: 'Custom Label' }
      })

      expect(wrapper.text()).toContain('Custom Label')
    })
  })

  describe('For Attribute', () => {
    it('should set for attribute with htmlFor prop', () => {
      const wrapper = mount(Label, {
        props: { htmlFor: 'email-input' },
        slots: { default: 'Email' }
      })

      expect(wrapper.find('label').attributes('for')).toBe('email-input')
    })

    it('should not set for attribute when htmlFor is not provided', () => {
      const wrapper = mount(Label, {
        slots: { default: 'Email' }
      })

      expect(wrapper.find('label').attributes('for')).toBeUndefined()
    })
  })

  describe('Required Indicator', () => {
    it('should show asterisk when required is true', () => {
      const wrapper = mount(Label, {
        props: { required: true },
        slots: { default: 'Email' }
      })

      const asterisk = wrapper.find('span[aria-label="required"]')
      expect(asterisk.exists()).toBe(true)
      expect(asterisk.text()).toBe('*')
      expect(asterisk.classes()).toContain('text-danger')
    })

    it('should not show asterisk when required is false', () => {
      const wrapper = mount(Label, {
        props: { required: false },
        slots: { default: 'Email' }
      })

      expect(wrapper.find('span[aria-label="required"]').exists()).toBe(false)
    })
  })

  describe('Styling', () => {
    it('should apply correct CSS classes', () => {
      const wrapper = mount(Label, {
        slots: { default: 'Label' }
      })

      const label = wrapper.find('label')
      expect(label.classes()).toContain('block')
      expect(label.classes()).toContain('text-sm')
      expect(label.classes()).toContain('font-medium')
      expect(label.classes()).toContain('text-text-primary')
      expect(label.classes()).toContain('mb-1')
    })
  })

  describe('Accessibility', () => {
    it('should have aria-label on required asterisk', () => {
      const wrapper = mount(Label, {
        props: { required: true },
        slots: { default: 'Email' }
      })

      const asterisk = wrapper.find('span')
      expect(asterisk.attributes('aria-label')).toBe('required')
    })
  })
})
