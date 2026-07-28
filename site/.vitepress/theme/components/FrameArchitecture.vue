<script setup lang="ts">
import { ArrowDown, ArrowRight, Box, Cable, Cpu, GitMerge, ScanLine } from '@lucide/vue'

defineProps<{ compact?: boolean }>()
</script>

<template>
  <section class="frame-architecture" :class="{ compact }" aria-label="FrameTop 信号结构">
    <div class="architecture-header">
      <div>
        <span class="eyebrow">FRAME SIGNAL PATH</span>
        <h2>一个物理 IO 边界，多个隔离设计</h2>
      </div>
      <code>user_io[72:0]</code>
    </div>

    <div class="architecture-flow">
      <div class="arch-node external">
        <Cable :size="22" />
        <span><strong>73 × bidirectional pad</strong><small>芯片外部连接</small></span>
      </div>
      <ArrowRight class="flow-arrow desktop-arrow" :size="22" />
      <ArrowDown class="flow-arrow mobile-arrow" :size="22" />
      <div class="arch-split">
        <div class="arch-node select">
          <ScanLine :size="20" />
          <span><strong>user_io[6:0]</strong><small>复位期间锁存 design ID</small></span>
        </div>
        <div class="arch-node payload">
          <GitMerge :size="20" />
          <span><strong>user_io[72:7]</strong><small>66 位双向 payload</small></span>
        </div>
      </div>
      <ArrowRight class="flow-arrow desktop-arrow" :size="22" />
      <ArrowDown class="flow-arrow mobile-arrow" :size="22" />
      <div class="arch-node frame-top">
        <Cpu :size="22" />
        <span><strong>FrameTop</strong><small>选择 · 时钟门控 · reset · IO mux</small></span>
      </div>
      <ArrowRight class="flow-arrow desktop-arrow" :size="22" />
      <ArrowDown class="flow-arrow mobile-arrow" :size="22" />
      <div class="design-stack">
        <div class="arch-node active"><Box :size="18" /><span><strong>selected design</strong><small>clock on · reset off</small></span></div>
        <div class="arch-node inactive"><Box :size="18" /><span><strong>other 127 slots</strong><small>clock off · reset on · high-Z</small></span></div>
      </div>
    </div>

    <div class="signal-legend">
      <span><i class="select-dot"></i> control</span>
      <span><i class="payload-dot"></i> payload</span>
      <span><i class="inactive-dot"></i> isolated</span>
    </div>
  </section>
</template>
