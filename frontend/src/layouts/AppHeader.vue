<script setup lang="ts">
import { useRoute } from 'vue-router'
import Button from 'primevue/button'
import ThemeToggle from '../components/ThemeToggle.vue'

defineEmits<{ menu: [] }>()

const route = useRoute()
</script>

<template>
  <header
    class="sticky top-0 z-20 flex h-16 shrink-0 items-center justify-between border-b border-line bg-page px-4 sm:px-6"
  >
    <div class="flex items-center gap-3">
      <Button
        class="lg:hidden"
        icon="pi pi-bars"
        variant="text"
        severity="secondary"
        aria-label="Buka menu"
        @click="$emit('menu')"
      />
      <h1 class="text-lg font-semibold">{{ route.meta.title }}</h1>
    </div>
    <ThemeToggle />
  </header>
</template>