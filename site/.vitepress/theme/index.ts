import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import FrameArchitecture from './components/FrameArchitecture.vue'
import DocsDashboard from './components/DocsDashboard.vue'
import SelectionTimeline from './components/SelectionTimeline.vue'
import './style.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('FrameArchitecture', FrameArchitecture)
    app.component('DocsDashboard', DocsDashboard)
    app.component('SelectionTimeline', SelectionTimeline)
  }
} satisfies Theme
