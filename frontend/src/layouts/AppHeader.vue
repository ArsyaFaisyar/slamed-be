<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Button from 'primevue/button'
import ThemeToggle from '../components/ThemeToggle.vue'
import NotificationBell from '../components/NotificationBell.vue'
import UserMenu from '../components/UserMenu.vue'
import { useAuthStore } from '../stores/auth'
import { useProfileStore } from '../stores/profile'
import { formatRole } from '../utils/format'

defineEmits<{ menu: [] }>()

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const profile = useProfileStore()

const userName = computed(() => profile.profile?.nama ?? profile.profile?.username ?? 'Pengguna')
const userRole = computed(() => formatRole(profile.profile?.role ?? ''))

onMounted(() => {
  if (!profile.profile) profile.load()
})

function logout() {
  auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <header
    class="sticky top-0 z-20 flex h-16 shrink-0 items-center justify-between border-b border-line bg-sidebar px-4 sm:px-6"
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
      <UserMenu
        :name="userName"
        :role="userRole"
        :image="profile.photoUrl ?? undefined"
        @profile="router.push('/profile')"
        @logout="logout"
      />
    </div>
  </header>
</template>