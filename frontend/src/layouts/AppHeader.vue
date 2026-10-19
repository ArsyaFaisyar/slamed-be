<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import Button from 'primevue/button'
import ThemeToggle from '../components/ThemeToggle.vue'
import NotificationBell from '../components/NotificationBell.vue'
import UserMenu from '../components/UserMenu.vue'

defineEmits<{ menu: [] }>()

const route = useRoute()
const router = useRouter()

function logout() {
  router.push({ name: 'login' })
}
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

    <div class="flex items-center gap-3">
      <ThemeToggle />
      <NotificationBell />
      <UserMenu name="Nama Pengguna" role="Role" @logout="logout" />
    </div>
  </header>
</template>