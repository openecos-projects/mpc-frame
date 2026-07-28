<script setup lang="ts">
import {
  ArrowRight,
  BookOpen,
  Boxes,
  Cable,
  CheckCircle2,
  Cpu,
  FlaskConical,
  TerminalSquare
} from '@lucide/vue'

const base = '/mpc-frame'

const docs = [
  { icon: Cable, label: 'Frame 模式', detail: '选择、隔离与 66 位 payload', to: `${base}/docs/frame-mode` },
  { icon: Cpu, label: '用户设计接入', detail: '从创建 package 到完整检查', to: `${base}/docs/user-guide` },
  { icon: FlaskConical, label: '仿真与回归', detail: 'unit、FrameTop 与波形定位', to: `${base}/docs/simulation-regression` },
  { icon: Boxes, label: '参考 SoC', detail: '架构、启动、存储与外设 IP', to: `${base}/reference/sim/README` }
]
</script>

<template>
  <main class="docs-dashboard">
    <section class="dashboard-heading">
      <div>
        <div class="dashboard-kicker"><Cpu :size="15" /> RTL integration workspace</div>
        <h1>mpc-frame</h1>
        <p>多设计共享一个芯片顶层的集成框架。选择一个槽位，把 66 位 payload 连接到你的 RTL，然后在同一套仿真边界内验证。</p>
      </div>
      <a class="primary-action" :href="`${base}/docs/user-guide`">
        开始接入 <ArrowRight :size="17" />
      </a>
    </section>

    <section class="metric-strip" aria-label="FrameTop 关键参数">
      <div><span>TOP</span><strong>FrameTop</strong></div>
      <div><span>SLOTS</span><strong>128</strong></div>
      <div><span>USER IO</span><strong>73</strong></div>
      <div><span>PAYLOAD</span><strong>66 bit</strong></div>
      <div class="metric-state"><CheckCircle2 :size="16" /><strong>design 0 ready</strong></div>
    </section>

    <FrameArchitecture compact />

    <section class="dashboard-grid">
      <div class="doc-directory">
        <div class="section-label"><BookOpen :size="16" /> 文档目录</div>
        <div class="doc-links">
          <a v-for="item in docs" :key="item.label" :href="item.to" class="doc-link">
            <component :is="item.icon" :size="20" />
            <span><strong>{{ item.label }}</strong><small>{{ item.detail }}</small></span>
            <ArrowRight :size="16" />
          </a>
        </div>
      </div>

      <div class="quick-terminal">
        <div class="section-label"><TerminalSquare :size="16" /> 快速开始</div>
        <div class="terminal-window" aria-label="创建并检查用户设计的命令">
          <div class="terminal-title"><span></span><span></span><span></span><code>mpc-frame</code></div>
          <pre><span class="prompt">$</span> make create-design DESIGN_NAME=counter32
<span class="prompt">$</span> make user-check
<span class="result">USER DESIGN CHECK PASS</span></pre>
        </div>
        <p>用户阶段不需要填写 design ID。FrameTop 测试会自动使用临时槽位，最终 ID 由维护者合并时分配。</p>
      </div>
    </section>
  </main>
</template>
