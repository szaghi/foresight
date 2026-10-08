// foresight docs theme: the default VitePress theme, gnuplot palette colours, and <Plot> for live foresight pages.
import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import Plot from './Plot.vue'
import './style.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('Plot', Plot)
  },
} satisfies Theme
