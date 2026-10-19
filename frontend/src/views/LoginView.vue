<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import Button from 'primevue/button'
import { TrendingUp } from '@lucide/vue'
import GrowthChart from '../components/LoginPage/GrowthChart.vue'
import LoginOptions from '../components/LoginPage/LoginOptions.vue'
import LoginForm from '../components/LoginPage/LoginForm.vue'
import ThemeToggle from '../components/ThemeToggle.vue'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage } from '../utils/error'
import type { LoginPayload } from '../api/auth'

const router = useRouter()
const auth = useAuthStore()

const mode = ref<'options' | 'admin'>('options')
const submitting = ref(false)
const errorMessage = ref('')
const loginForm = ref<InstanceType<typeof LoginForm>>()

const title = computed(() => (mode.value === 'options' ? 'Masuk' : 'Masuk administrator'))
const subtitle = computed(() =>
  mode.value === 'options' ? 'Gunakan akun OneID perusahaan.' : 'Masukkan username dan kata sandi.',
)

function showOptions() {
  errorMessage.value = ''
  mode.value = 'options'
}

async function handleLogin(payload: LoginPayload) {
  submitting.value = true
  errorMessage.value = ''
  try {
    await auth.login(payload)
    await router.push('/dashboard')
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Login gagal')
    loginForm.value?.refreshCaptcha()
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <main class="relative grid min-h-dvh bg-page lg:grid-cols-2">
    <div class="absolute right-4 top-4 z-10 sm:right-6 sm:top-6">
      <ThemeToggle />
    </div>

    <aside class="hidden flex-col justify-between border-r border-line bg-sidebar p-12 lg:flex xl:p-16">
      <div>
        <div class="mb-8 grid size-12 place-items-center rounded-xl bg-brand text-white">
          <TrendingUp :size="24" />
        </div>
        <h1 class="text-6xl font-bold tracking-tight">SLAMED</h1>
        <p class="mt-3 text-fg-muted">Pantau target dan aktivitas penjualan.</p>
      </div>

      <GrowthChart class="mx-auto w-full max-w-xl" />
    </aside>

    <section class="flex items-center justify-center px-6 py-20">
      <div class="w-full max-w-sm">
        <div class="mb-8 flex items-center gap-3 lg:hidden">
          <div class="grid size-10 place-items-center rounded-xl bg-brand text-white">
            <TrendingUp :size="20" />
          </div>
          <span class="font-heading text-xl font-bold">SLAMED</span>
        </div>

        <h2 class="text-2xl font-semibold">{{ title }}</h2>
        <p class="mt-1 text-sm text-fg-muted">{{ subtitle }}</p>

        <LoginOptions v-if="mode === 'options'" class="mt-8" @admin="mode = 'admin'" />
        <div v-else class="mt-8 flex flex-col gap-4">
          <LoginForm ref="loginForm" :loading="submitting" :error="errorMessage" @submit="handleLogin" />
          <Button
            label="Kembali"
            icon="pi pi-arrow-left"
            variant="text"
            severity="secondary"
            fluid
            @click="showOptions"
          />
        </div>
      </div>
    </section>
  </main>
</template>