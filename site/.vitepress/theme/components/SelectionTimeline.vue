<script setup lang="ts">
import { Check, LockKeyhole, Power, RotateCcw } from '@lucide/vue'

const steps = [
  { icon: RotateCcw, time: 'T0', title: '保持复位', text: 'reset = 1，所有用户槽位保持隔离。' },
  { icon: LockKeyhole, time: 'T1', title: '提供编号', text: '在 user_io[6:0] 放置目标 design ID。' },
  { icon: Check, time: 'T2', title: '锁存选择', text: 'FrameTop 同步并确认有效槽位。' },
  { icon: Power, time: 'T3', title: '释放复位', text: '仅选中设计获得时钟、复位释放和 payload。' }
]
</script>

<template>
  <div class="selection-timeline" aria-label="设计选择时序">
    <div v-for="step in steps" :key="step.time" class="timeline-step">
      <div class="timeline-marker"><component :is="step.icon" :size="17" /></div>
      <code>{{ step.time }}</code>
      <strong>{{ step.title }}</strong>
      <span>{{ step.text }}</span>
    </div>
  </div>
</template>
