<script setup lang="ts">
import { computed, onMounted } from 'vue'
import Button from 'primevue/button'
import Message from 'primevue/message'
import ProfilePhotoCard from '../components/ProfilePhotoCard.vue'
import ChangePasswordForm from '../components/ChangePasswordForm.vue'
import { useProfileStore } from '../stores/profile'
import { formatRole } from '../utils/format'

const profile = useProfileStore()

const info = computed(() => [
  { label: 'Nama', value: profile.profile?.nama },
  { label: 'Username', value: profile.profile?.username },
  { label: 'Email', value: profile.profile?.email },
  { label: 'Role', value: formatRole(profile.profile?.role ?? '') },
])

onMounted(() => {
  if (!profile.profile) profile.load()
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <Message v-if="profile.loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ profile.loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="profile.load()" />
      </div>
    </Message>

    <div class="grid gap-6 lg:grid-cols-3">
      <ProfilePhotoCard />

      <div class="flex flex-col gap-6 lg:col-span-2">
        <section class="rounded-xl border border-line bg-card p-6">
          <h2 class="font-semibold">Informasi akun</h2>

          <div v-if="profile.loading && !profile.profile" class="flex items-center gap-3 py-8 text-sm text-fg-muted">
            <i class="pi pi-spin pi-spinner" />
            Memuat profil...
          </div>

          <dl v-else class="mt-4 grid gap-5 sm:grid-cols-2">
            <div v-for="item in info" :key="item.label">
              <dt class="text-xs text-fg-muted">{{ item.label }}</dt>
              <dd class="mt-1 break-words text-sm font-medium">{{ item.value || '-' }}</dd>
            </div>
          </dl>
        </section>

        <section class="rounded-xl border border-line bg-card p-6">
          <h2 class="font-semibold">Ubah kata sandi</h2>
          <ChangePasswordForm class="mt-4" />
        </section>
      </div>
    </div>
  </div>
</template>