<script setup lang="ts">
const bars = [
  { x: 30, h: 80, o: 0.22 },
  { x: 92, h: 115, o: 0.32 },
  { x: 154, h: 100, o: 0.42 },
  { x: 216, h: 155, o: 0.55 },
  { x: 278, h: 180, o: 0.7 },
  { x: 340, h: 225, o: 0.85 },
  { x: 402, h: 275, o: 1 },
]
</script>

<template>
  <svg viewBox="0 0 470 340" fill="none" role="img" aria-label="Grafik penjualan naik">
    <g class="grid">
      <line x1="10" x2="460" y1="100" y2="100" />
      <line x1="10" x2="460" y1="180" y2="180" />
      <line x1="10" x2="460" y1="260" y2="260" />
    </g>

    <rect
      v-for="(bar, i) in bars"
      :key="bar.x"
      class="bar"
      :x="bar.x"
      :y="320 - bar.h"
      width="38"
      :height="bar.h"
      rx="10"
      :style="{ '--i': i, fillOpacity: bar.o }"
    />

    <line class="base" x1="10" x2="460" y1="324" y2="324" />

    <path
      class="trend"
      pathLength="1"
      d="M49 216 C80 216 80 181 111 181 C142 181 142 196 173 196 C204 196 204 141 235 141 C266 141 266 116 297 116 C328 116 328 71 359 71 C390 71 390 21 421 21"
    />

    <circle class="pulse" cx="421" cy="21" r="7" />
    <circle class="dot" cx="421" cy="21" r="7" />
  </svg>
</template>

<style scoped>
.grid line {
  stroke: var(--app-line);
  stroke-dasharray: 4 6;
}

.base {
  stroke: var(--app-line);
  stroke-width: 2;
}

.bar {
  fill: var(--app-brand);
  transform-box: fill-box;
  transform-origin: bottom;
  animation: rise 0.8s cubic-bezier(0.22, 1, 0.36, 1) both;
  animation-delay: calc(var(--i) * 90ms);
}

.trend {
  stroke: var(--app-accent);
  stroke-width: 4;
  stroke-linecap: round;
  stroke-dasharray: 1;
  animation: draw 1.6s ease-in-out 0.5s both;
}

.dot {
  fill: var(--app-accent);
  animation: fade 0.4s ease-out 2s both;
}

.pulse {
  fill: var(--app-accent);
  transform-box: fill-box;
  transform-origin: center;
  animation: pulse 2.4s ease-out 2.2s infinite;
}

@keyframes rise {
  from {
    transform: scaleY(0);
  }
}

@keyframes draw {
  from {
    stroke-dashoffset: 1;
  }
  to {
    stroke-dashoffset: 0;
  }
}

@keyframes fade {
  from {
    opacity: 0;
  }
}

@keyframes pulse {
  from {
    opacity: 0.45;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(3);
  }
}

@media (prefers-reduced-motion: reduce) {
  .bar,
  .trend,
  .dot,
  .pulse {
    animation: none;
  }

  .pulse {
    display: none;
  }
}
</style>