<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useProfileStore } from '../stores/profile'
import { getErrorMessage } from '../utils/error'
import { formatRole, getInitials } from '../utils/format'

const MAX_SIZE = 5 * 1024 * 1024
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp']

const profile = useProfileStore()

const input = ref<HTMLInputElement>()
const pending = ref<File | null>(null)
const previewUrl = ref<string | null>(null)
const saving = ref(false)
const errorMessage = ref('')
const imageFailed = ref(false)

const displayName = computed(() => profile.profile?.nama ?? profile.profile?.username ?? '')
const initials = computed(() => getInitials(displayName.value))
const image = computed(() => previewUrl.value ?? (imageFailed.value ? null : profile.photoUrl))

watch(
  () => profile.photoUrl,
  () => {
    imageFailed.value = false
  },
)

function clearPending() {
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  previewUrl.value = null
  pending.value = null
  if (input.value) input.value.value = ''
}

function onSelect(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return

  clearPending()
  errorMessage.value = ''

  if (!ALLOWED_TYPES.includes(file.type)) {
    errorMessage.value = 'Format harus JPG, PNG, atau WEBP'
    return
  }
  if (file.size > MAX_SIZE) {
    errorMessage.value = 'Ukuran file maksimal 5 MB'
    return
  }

  pending.value = file
  previewUrl.value = URL.createObjectURL(file)
}

async function save() {
  if (!pending.value) return

  saving.value = true
  errorMessage.value = ''

  try {
    await profile.changePhoto(pending.value)
    clearPending()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal mengunggah foto')
  } finally {
    saving.value = false
  }
}

onBeforeUnmount(clearPending)
</script>

<template>
  <section class="flex flex-col items-center gap-4 rounded-xl border border-line bg-card p-6 text-center">
    <Avatar
      :image="image ?? undefined"
      :label="image ? undefined : initials || undefined"
      :icon="!image && !initials ? 'pi pi-user' : undefined"
      shape="circle"
      class="size-28 bg-brand/10 text-3xl font-semibold text-brand"
      @error="imageFailed = true"
    />

    <div>
      <p class="text-lg font-semibold">{{ displayName || '-' }}</p>
      <p class="mt-0.5 text-sm text-fg-muted">{{ formatRole(profile.profile?.role ?? '') || '-' }}</p>
    </div>

    <input
      ref="input"
      type="file"
      accept="image/jpeg,image/png,image/webp"
      class="hidden"
      @change="onSelect"
    />

    <Button
      v-if="!pending"
      label="Ganti foto"
      icon="pi pi-camera"
      variant="outlined"
      severity="secondary"
      @click="input?.click()"
    />
    <div v-else class="flex gap-2">
      <Button label="Simpan" icon="pi pi-check" :loading="saving" @click="save" />
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="clearPending" />
    </div>

    <Message v-if="errorMessage" severity="error" size="small" variant="simple">{{ errorMessage }}</Message>

    <p class="text-xs text-fg-muted">JPG, PNG, atau WEBP. Maksimal 5 MB.</p>
  </section>
</template>