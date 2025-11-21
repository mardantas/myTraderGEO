import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Card from '../Card.vue'

describe('Card', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(Card, {
        slots: { default: 'Card content' }
      })

      expect(wrapper.text()).toBe('Card content')
      expect(wrapper.find('div').exists()).toBe(true)
    })

    it('should render slot content', () => {
      const wrapper = mount(Card, {
        slots: {
          default: '<p>Custom content</p>'
        }
      })

      expect(wrapper.html()).toContain('<p>Custom content</p>')
    })
  })

  describe('Styling', () => {
    it('should apply base styling classes', () => {
      const wrapper = mount(Card)

      expect(wrapper.classes()).toContain('bg-white')
      expect(wrapper.classes()).toContain('border')
      expect(wrapper.classes()).toContain('border-border')
      expect(wrapper.classes()).toContain('rounded-lg')
      expect(wrapper.classes()).toContain('shadow-md')
      expect(wrapper.classes()).toContain('transition-shadow')
    })

    it('should apply padding by default', () => {
      const wrapper = mount(Card)

      expect(wrapper.classes()).toContain('p-6')
    })
  })

  describe('Hoverable', () => {
    it('should apply hover classes when hoverable is true', () => {
      const wrapper = mount(Card, {
        props: { hoverable: true }
      })

      expect(wrapper.classes()).toContain('hover:shadow-lg')
      expect(wrapper.classes()).toContain('cursor-pointer')
    })

    it('should not apply hover classes when hoverable is false', () => {
      const wrapper = mount(Card, {
        props: { hoverable: false }
      })

      expect(wrapper.classes()).not.toContain('hover:shadow-lg')
      expect(wrapper.classes()).not.toContain('cursor-pointer')
    })
  })

  describe('No Padding', () => {
    it('should not apply padding when noPadding is true', () => {
      const wrapper = mount(Card, {
        props: { noPadding: true }
      })

      expect(wrapper.classes()).not.toContain('p-6')
    })

    it('should apply padding when noPadding is false', () => {
      const wrapper = mount(Card, {
        props: { noPadding: false }
      })

      expect(wrapper.classes()).toContain('p-6')
    })
  })

  describe('Combined Props', () => {
    it('should apply all props correctly', () => {
      const wrapper = mount(Card, {
        props: {
          hoverable: true,
          noPadding: true
        }
      })

      expect(wrapper.classes()).toContain('hover:shadow-lg')
      expect(wrapper.classes()).toContain('cursor-pointer')
      expect(wrapper.classes()).not.toContain('p-6')
    })
  })
})
