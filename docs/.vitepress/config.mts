import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

// one sidebar, in reading order, for the guide and the manual: prev/next links walk the whole documentation
const docs = [
  {
    text: 'Start here',
    items: [
      { text: 'About',        link: '/guide/' },
      { text: 'Installation', link: '/guide/install' },
    ],
  },
  {
    text: 'Tutorial',
    items: [
      { text: 'Overview',                        link: '/manual/' },
      { text: '1. A first plot',                 link: '/manual/tutorial/01-first-plot' },
      { text: '2. Styles and the key',           link: '/manual/tutorial/02-styles' },
      { text: '3. Axes',                         link: '/manual/tutorial/03-axes' },
      { text: '4. From the log, with a script',  link: '/manual/tutorial/04-scripts' },
      { text: '5. CSV and expressions',          link: '/manual/tutorial/05-data' },
      { text: '6. Two axes and a model',         link: '/manual/tutorial/06-two-axes' },
      { text: '7. A dashboard',                  link: '/manual/tutorial/07-dashboard' },
      { text: '8. Watching the run',             link: '/manual/tutorial/08-live' },
    ],
  },
  {
    text: 'Path C: figures for a paper',
    items: [
      { text: 'C1. A first PDF', link: '/manual/paths/c-paper/01-a-first-pdf' },
      { text: 'C2. Fonts that travel', link: '/manual/paths/c-paper/02-fonts-that-travel' },
    ],
  },
  {
    text: 'Recipes',
    items: [
      { text: 'Cookbook', link: '/manual/cookbook' },
    ],
  },
  {
    text: 'Reference',
    items: [
      { text: 'Feature map',        link: '/guide/features' },
      { text: 'Fortran Library',    link: '/guide/library' },
      { text: 'Command Line',       link: '/guide/cli' },
      { text: 'gnuplot Subset',     link: '/guide/gnuplot-subset' },
      { text: 'Data Files',         link: '/guide/data-files' },
      { text: 'Interactive Viewer', link: '/guide/viewer' },
      { text: 'Live Monitoring',    link: '/guide/monitoring' },
      { text: 'Output Formats',     link: '/guide/output-formats' },
      { text: 'Architecture',       link: '/guide/architecture' },
    ],
  },
  {
    text: 'Project',
    items: [
      { text: 'Comparison',    link: '/guide/comparison' },
      { text: 'API Reference', link: '/guide/api-reference' },
      { text: 'Contributing',  link: '/guide/contributing' },
      { text: 'Changelog',     link: '/guide/changelog' },
    ],
  },
]

export default withMermaid({
  title: 'foresight',
  description: 'gnuplot-like interactive plots from pure Fortran',
  base: '/foresight/',
  // VitePress does not add the base to head hrefs, so they carry /foresight/ explicitly
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/foresight/favicon.svg', media: '(prefers-color-scheme: light)' }],
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/foresight/favicon-dark.svg', media: '(prefers-color-scheme: dark)' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/foresight/favicon-32.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/foresight/favicon-16.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/foresight/apple-touch-icon.png' }],
    ['meta', { name: 'theme-color', content: '#f3ede1', media: '(prefers-color-scheme: light)' }],
    ['meta', { name: 'theme-color', content: '#130d0f', media: '(prefers-color-scheme: dark)' }],
  ],
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
      gp: 'gnuplot',
    },
  },

  themeConfig: {
    logo: { light: '/logo-nav.svg', dark: '/logo-nav-dark.svg', alt: 'FORESIGHT' },
    siteTitle: 'FORESIGHT',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Start here', link: '/guide/', activeMatch: '^/guide/(index|install)?$' },
      { text: 'Tutorial', link: '/manual/tutorial/01-first-plot', activeMatch: '^/manual/(index|tutorial/)' },
      { text: 'Cookbook', link: '/manual/cookbook', activeMatch: '^/manual/cookbook' },
      {
        text: 'Reference',
        link: '/guide/features',
        activeMatch: '^/guide/(features|library|cli|gnuplot-subset|data-files|viewer|monitoring|output-formats|architecture)',
      },
      { text: 'API', link: '/api/' },
      {
        text: 'Project',
        items: [
          { text: 'Comparison',   link: '/guide/comparison' },
          { text: 'Contributing', link: '/guide/contributing' },
          { text: 'Changelog',    link: '/guide/changelog' },
        ],
      },
    ],

    sidebar: {
      '/guide/': docs,
      '/manual/': docs,
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

    outline: [2, 3],

    footer: {
      message: 'Released under the <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPL v3</a>, BSD 2-Clause, BSD 3-Clause or MIT License.',
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
