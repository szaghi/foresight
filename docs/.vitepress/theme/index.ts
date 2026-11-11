// foresight docs theme: the default VitePress theme, the Sumi family identity (Fugaku in Kurenai), and <Plot> for live foresight pages.
import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import Plot from './Plot.vue'
import './style.css'
import './custom.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('Plot', Plot)
  },
} satisfies Theme
