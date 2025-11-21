import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CardHeader from '../CardHeader.vue'

describe('CardHeader', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(CardHeader, {
        slots: { default: 'Header content' }
      })

      expect(wrapper.text()).toBe('Header content')
      expect(wrapper.find('div').exists()).toBe(true)
    })

    it('should render slot content', () => {
      const wrapper = mount(CardHeader, {
        slots: {
          default: '<h2>Card Title</h2>'
        }
      })

      expect(wrapper.html()).toContain('<h2>Card Title</h2>')
    })
  })

  describe('Styling', () => {
    it('should apply base padding classes', () => {
      const wrapper = mount(CardHeader)

      expect(wrapper.classes()).toContain('px-6')
      expect(wrapper.classes()).toContain('py-4')
    })

    it('should apply border by default', () => {
      const wrapper = mount(CardHeader)

      expect(wrapper.classes()).toContain('border-b')
      expect(wrapper.classes()).toContain('border-border')
    })
  })

  describe('No Border', () => {
    it('should not apply border when noBorder is true', () => {
      const wrapper = mount(CardHeader, {
        props: { noBorder: true }
      })

      expect(wrapper.classes()).not.toContain('border-b')
      expect(wrapper.classes()).not.toContain('border-border')
    })

    it('should apply border when noBorder is false', () => {
      const wrapper = mount(CardHeader, {
        props: { noBorder: false }
      })

      expect(wrapper.classes()).toContain('border-b')
      expect(wrapper.classes()).toContain('border-border')
    })
  })
})
