import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

export default withMermaid({
  title: 'foresight',
  description: 'FORtran Easy Svg Interactive Gnuplot-like Html Tool',
  base: '/foresight/',
  // ford.md is the formal project file, not a page
  srcExclude: ['ford.md'],

  markdown: {
    math: true,
    languages: ['fortran-free-form', 'fortran-fixed-form'],
    languageAlias: {
      fortran: 'fortran-free-form',
      f90: 'fortran-free-form',
      f03: 'fortran-free-form',
      f08: 'fortran-free-form',
    },
  },

  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Guide',
        items: [
          { text: 'About',             link: '/guide/' },
          { text: 'Quick Start',       link: '/guide/quickstart' },
          { text: 'Fortran Library',   link: '/guide/library' },
          { text: 'Command Line',      link: '/guide/cli' },
          { text: 'gnuplot Subset',    link: '/guide/gnuplot-subset' },
          { text: 'Live Monitoring',   link: '/guide/monitoring' },
          { text: 'Changelog',         link: '/guide/changelog' },
        ],
      },
      { text: 'Examples', link: '/guide/examples' },
      { text: 'API', link: '/api/' },
      { text: 'GitHub', link: 'https://github.com/szaghi/foresight' },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'About',      link: '/guide/' },
            { text: 'Features',   link: '/guide/features' },
            { text: 'Comparison', link: '/guide/comparison' },
          ],
        },
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start',  link: '/guide/quickstart' },
            { text: 'Examples',     link: '/guide/examples' },
          ],
        },
        {
          text: 'User Guide',
          items: [
            { text: 'Fortran Library',    link: '/guide/library' },
            { text: 'Command Line',       link: '/guide/cli' },
            { text: 'gnuplot Subset',     link: '/guide/gnuplot-subset' },
            { text: 'Data Files',         link: '/guide/data-files' },
            { text: 'Interactive Viewer', link: '/guide/viewer' },
            { text: 'Live Monitoring',    link: '/guide/monitoring' },
            { text: 'Output Formats',     link: '/guide/output-formats' },
          ],
        },
        {
          text: 'Internals',
          items: [
            { text: 'Architecture', link: '/guide/architecture' },
          ],
        },
        {
          text: 'Project',
          items: [
            { text: 'API Reference', link: '/guide/api-reference' },
            { text: 'Contributing',  link: '/guide/contributing' },
            { text: 'Changelog',     link: '/guide/changelog' },
          ],
        },
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
          ],
        },
        ...apiSidebar,
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/szaghi/foresight' },
    ],

    search: {
      provider: 'local',
    },

    footer: {
      message: 'Released under the <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPL v3 License</a>.',
      copyright: 'Copyright © 2026 Stefano Zaghi',
    },
  },

  mermaid: {},

  vite: {
    // Build with an explicit modern JS target so the docs compile regardless of
    // which mermaid/vitepress/esbuild versions npm resolves. Vite's default
    // es2020 target forces esbuild to down-level modern syntax (e.g. the
    // destructuring mermaid 11.16+ emits), which it refuses to do and the build
    // dies. es2022 needs no lowering and is within VitePress's browser floor.
    build: {
      target: 'es2022',
    },
  },
})
