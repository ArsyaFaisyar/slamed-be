<script setup lang="ts">
import { ref } from 'vue'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'

const mobileOpen = ref(false)
</script>

<template>
  <div class="min-h-dvh bg-page">
    <AppSidebar v-model:open="mobileOpen" />

    <div class="flex min-h-dvh flex-col lg:pl-[4.5rem]">
      <AppHeader @menu="mobileOpen = true" />
      <main class="flex-1 p-4 sm:p-6">
        <RouterView />
      </main>
    </div>
  </div>
</template>