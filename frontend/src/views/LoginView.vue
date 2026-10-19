<script setup lang="ts">
import { computed, ref } from 'vue'
import Button from 'primevue/button'
import { TrendingUp } from '@lucide/vue'
import GrowthChart from '../components/LoginPage/GrowthChart.vue'
import LoginOptions from '../components/LoginPage/LoginOptions.vue'
import LoginForm from '../components/LoginPage/LoginForm.vue'
import ThemeToggle from '../components/ThemeToggle.vue'

const mode = ref<'options' | 'admin'>('options')

const title = computed(() => (mode.value === 'options' ? 'Masuk' : 'Masuk administrator'))
const subtitle = computed(() =>
  mode.value === 'options' ? 'Gunakan akun OneID perusahaan, atau masuk sebagai administrator.' : 'Masukkan email dan kata sandi.',
)
</script>

<template>
  <main class="relative grid min-h-dvh bg-page lg:grid-cols-2">
    <div class="absolute right-4 top-4 z-10 sm:right-6 sm:top-6">
      <ThemeToggle />
    </div>

    <aside class="hidden flex-col justify-between border-r border-line bg-sidebar p-12 lg:flex xl:p-16">
      <div>
        <h1 class="text-6xl font-bold tracking-tight">SLAMED</h1>
        <p class="mt-3 text-fg-muted">Sales Activity Management Digitalize</p>
      </div>

      <GrowthChart class="mx-auto w-full max-w-xl" />
    </aside>

    
    <section class="flex min-h-full items-center justify-center px-6 py-12 sm:px-10 lg:px-16">
    <div class="w-full max-w-md">
        <!-- Mobile branding -->
        <div class="mb-10 flex items-center gap-3 lg:hidden">
        <div class="grid size-11 place-items-center rounded-xl bg-brand text-white">
            <TrendingUp :size="21" />
        </div>
        <span class="font-heading text-xl font-bold tracking-tight">
            SLAMED
        </span>
        </div>

        <div class="mb-8 space-y-2 text-left">
        <h2 class="font-heading text-3xl font-bold tracking-tight text-fg">
            {{ title }}
        </h2>
        <p class="text-base leading-relaxed text-fg-muted">
            {{ subtitle }}
        </p>
        </div>

        <LoginOptions
        v-if="mode === 'options'"
        class="w-full"
        @admin="mode = 'admin'"
        />

        <div v-else class="flex flex-col gap-5">
        <LoginForm />

        <Button
            label="Kembali"
            icon="pi pi-arrow-left"
            variant="text"
            severity="secondary"
            fluid
            @click="mode = 'options'"
        />
        </div>
    </div>
    </section>
  </main>
</template>