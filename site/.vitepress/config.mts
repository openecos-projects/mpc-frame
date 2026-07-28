import { defineConfig } from 'vitepress'

const zhSidebar = [
  {
    text: 'Frame 模式',
    items: [
      { text: '模式介绍', link: '/docs/frame-mode' },
      { text: 'IO 映射', link: '/docs/io-map' },
      { text: '选择、时钟与复位', link: '/docs/design-control' },
      { text: '参考设计', link: '/docs/reference-design' }
    ]
  },
  {
    text: '用户接入',
    items: [
      { text: '接入指南', link: '/docs/user-guide' },
      { text: '三路非门示例', link: '/docs/examples/three-inverter' },
      { text: '32 位计数器示例', link: '/docs/examples/counter-32bit' },
      { text: '设计注册', link: '/docs/user-design-registration' },
      { text: '仿真与回归', link: '/docs/simulation-regression' },
      { text: '持续集成', link: '/docs/ci' }
    ]
  },
  {
    text: '参考 SoC',
    collapsed: true,
    items: [
      { text: '工程概览', link: '/reference/sim/README' },
      { text: '架构说明', link: '/reference/sim/docs/arch' },
      { text: '启动流程', link: '/reference/sim/docs/boot-flow' },
      { text: '地址空间', link: '/reference/sim/docs/memory-map' },
      { text: '软件 SDK', link: '/reference/sim/docs/ecos-sdk' },
      { text: 'Verilator', link: '/reference/sim/docs/verilator' },
      { text: 'IP 状态', link: '/reference/sim/docs/ip-readiness' },
      { text: 'PSRAM 测试', link: '/reference/sim/docs/testcase-psram' }
    ]
  },
  {
    text: '参考 IP',
    collapsed: true,
    items: [
      { text: '公共 RTL 工具', link: '/reference/sim/hw/common/README' },
      { text: 'CLINT', link: '/reference/sim/hw/ip/clint/README' },
      { text: 'GPIO', link: '/reference/sim/hw/ip/gpio/README' },
      { text: 'PLIC', link: '/reference/sim/hw/ip/plic/README' },
      { text: 'PSRAM', link: '/reference/sim/hw/ip/psram/README' },
      { text: 'RCU', link: '/reference/sim/hw/ip/rcu/README' },
      { text: 'SPI', link: '/reference/sim/hw/ip/spi/README' },
      { text: '软件目录', link: '/reference/sim/sw/README' }
    ]
  }
]

export default defineConfig({
  title: 'mpc-frame',
  description: '面向多项目晶圆拼片的 RTL 集成框架与参考实现',
  lang: 'zh-CN',
  base: '/mpc-frame/',
  cleanUrls: true,
  lastUpdated: true,
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
    nav: [
      { text: 'Frame 模式', link: '/docs/frame-mode' },
      { text: '用户接入', link: '/docs/user-guide' },
      { text: '参考 SoC', link: '/reference/sim/README' },
      { text: 'English', link: '/index.en' }
    ],
    sidebar: {
      '/docs/': zhSidebar,
      '/reference/': zhSidebar
    },
    outline: { level: [2, 3], label: '本页内容' },
    search: {
      provider: 'local',
      options: {
        translations: {
          button: { buttonText: '搜索文档', buttonAriaLabel: '搜索文档' },
          modal: {
            displayDetails: '显示详细列表',
            resetButtonTitle: '清除查询',
            backButtonTitle: '关闭搜索',
            noResultsText: '没有找到相关内容',
            footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' }
          }
        }
      }
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/openecos-projects/mpc-frame' }
    ],
    footer: {
      message: '文档以中文为第一语言，并提供对应英文版本。',
      copyright: 'mpc-frame'
    },
    lastUpdated: { text: '最后更新' },
    docFooter: { prev: '上一页', next: '下一页' },
    returnToTopLabel: '返回顶部',
    sidebarMenuLabel: '目录',
    darkModeSwitchLabel: '外观'
  }
})
