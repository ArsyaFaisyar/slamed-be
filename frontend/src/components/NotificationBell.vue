<script setup lang="ts">
import Button from 'primevue/button'

withDefaults(defineProps<{ count?: number }>(), { count: 0 })
</script>

<template>
  <div class="relative">
    <Button
      icon="pi pi-bell"
      rounded
      variant="text"
      severity="secondary"
      aria-label="Notifikasi"
      title="Notifikasi"
    />
    <span
      v-if="count > 0"
      class="pointer-events-none absolute right-2 top-2 size-2 rounded-full bg-red-500 ring-2 ring-page"
    />
  </div>
</template>