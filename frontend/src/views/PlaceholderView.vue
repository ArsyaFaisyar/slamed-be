<script setup lang="ts">
import { useRoute } from 'vue-router'

const route = useRoute()
</script>

<template>
  <div class="rounded-xl border border-dashed border-line bg-card p-10 text-center text-fg-muted">
    Halaman {{ route.meta.title }} belum diimplementasikan.
  </div>
</template>