import { defineConfig } from 'vitepress'

const cnSidebar = [
  {
    text: 'Frame 模式',
    items: [
      { text: '模式介绍', link: '/frame-mode' },
      { text: 'IO 映射', link: '/io-map' },
      { text: '选择、时钟与复位', link: '/design-control' }
    ]
  },
  {
    text: '用户接入',
    items: [
      { text: '获取 User Kit', link: '/user-kit' },
      { text: '接入指南', link: '/user-guide' },
      { text: '三路非门示例', link: '/examples/three-inverter' },
      { text: '32 位计数器示例', link: '/examples/counter-32bit' },
      { text: '仿真与回归', link: '/simulation-regression' }
    ]
  }
]

const enSidebar = [
  {
    text: 'Frame mode',
    items: [
      { text: 'Overview', link: '/en/frame-mode' },
      { text: 'IO mapping', link: '/en/io-map' },
      { text: 'Selection, clock, and reset', link: '/en/design-control' }
    ]
  },
  {
    text: 'User workflow',
    items: [
      { text: 'Get the User Kit', link: '/en/user-kit' },
      { text: 'Integration guide', link: '/en/user-guide' },
      { text: 'Three-inverter example', link: '/en/examples/three-inverter' },
      { text: '32-bit counter example', link: '/en/examples/counter-32bit' },
      { text: 'Simulation and regression', link: '/en/simulation-regression' }
    ]
  }
]

export default defineConfig({
  title: 'mpc-frame',
  description: 'RTL integration frame for multi-project chips',
  base: '/mpc-frame/',
  cleanUrls: true,
  lastUpdated: true,
  locales: {
    root: { label: '中文', lang: 'zh-CN' },
    en: { label: 'English', lang: 'en-US', link: '/en/' }
  },
  head: [
    ['meta', { name: 'theme-color', content: '#0a8f7a' }],
    ['meta', { name: 'color-scheme', content: 'light dark' }]
  ],
  markdown: {
    lineNumbers: true,
    languages: ['system-verilog'],
    languageAlias: { systemverilog: 'system-verilog' }
  },
  themeConfig: {
    logo: { src: '/mark.svg', alt: 'mpc-frame' },
    siteTitle: 'mpc-frame',
    socialLinks: [
      { icon: 'github', link: 'https://github.com/openecos-projects/mpc-frame' }
    ],
    locales: {
      root: {
        nav: [
          { text: '首页', link: '/' },
          { text: '获取 User Kit', link: '/user-kit' },
          { text: '用户指南', link: '/user-guide' },
          { text: 'English', link: '/en/' }
        ],
        sidebar: cnSidebar,
        outline: { level: [2, 3], label: '本页内容' },
        docFooter: { prev: '上一页', next: '下一页' },
        lastUpdated: { text: '最后更新' },
        returnToTopLabel: '返回顶部',
        sidebarMenuLabel: '目录',
        darkModeSwitchLabel: '外观'
      },
      en: {
        nav: [
          { text: 'Home', link: '/en/' },
          { text: 'Get User Kit', link: '/en/user-kit' },
          { text: 'User guide', link: '/en/user-guide' },
          { text: '中文', link: '/' }
        ],
        sidebar: { '/en/': enSidebar },
        outline: { level: [2, 3], label: 'On this page' }
      }
    },
    search: { provider: 'local' },
    footer: {
      message: 'Documentation is maintained from one bilingual source tree.',
      copyright: 'mpc-frame'
    }
  }
})
