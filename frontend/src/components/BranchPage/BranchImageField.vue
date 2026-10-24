<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import Button from 'primevue/button'
import Message from 'primevue/message'
import BranchImage from './BranchImage.vue'

const MAX_SIZE = 5 * 1024 * 1024
const TYPES = ['image/jpeg', 'image/png', 'image/webp']

withDefaults(
  defineProps<{
    label: string
    inputLabel?: string
    current?: string | null
    fit?: 'cover' | 'contain'
    boxClass?: string
    disabled?: boolean
  }>(),
  { fit: 'cover', boxClass: 'h-28 w-full', inputLabel: 'Pilih gambar' },
)

const file = defineModel<File | null>('file', { default: null })
const error = defineModel<string>('error', { default: '' })

const input = ref<HTMLInputElement>()
const preview = ref<string | null>(null)

function clear() {
  if (preview.value) URL.revokeObjectURL(preview.value)
  preview.value = null
  file.value = null
  if (input.value) input.value.value = ''
}

function onSelect(event: Event) {
  const selected = (event.target as HTMLInputElement).files?.[0]
  if (!selected) return

  clear()
  error.value = ''

  if (!TYPES.includes(selected.type)) {
    error.value = 'Format harus JPG, PNG, atau WEBP'
    return
  }
  if (selected.size > MAX_SIZE) {
    error.value = 'Ukuran file maksimal 5 MB'
    return
  }

  file.value = selected
  preview.value = URL.createObjectURL(selected)
}

defineExpose({ clear })
onBeforeUnmount(clear)
</script>

<template>
  <div class="flex flex-col gap-2">
    <span class="text-sm font-medium">{{ label }}</span>

    <div
      class="overflow-hidden rounded-lg border border-dashed border-line bg-sidebar/40"
      :class="boxClass"
    >
      <BranchImage :src="current" :preview="preview" :alt="label" :fit="fit">
        <div class="flex size-full items-center justify-center text-fg-muted">
          <i class="pi pi-image text-2xl" />
        </div>
      </BranchImage>
    </div>

    <input ref="input" type="file" accept="image/jpeg,image/png,image/webp" class="hidden" @change="onSelect" />

    <div class="flex flex-wrap items-center gap-2">
      <Button
        type="button"
        :label="file ? 'Ganti pilihan' : inputLabel"
        icon="pi pi-upload"
        size="small"
        variant="outlined"
        severity="secondary"
        :disabled="disabled"
        @click="input?.click()"
      />
      <Button
        v-if="file"
        type="button"
        label="Batalkan"
        size="small"
        variant="text"
        severity="secondary"
        :disabled="disabled"
        @click="clear"
      />
    </div>

    <p class="text-xs text-fg-muted">JPG, PNG, atau WEBP. Maksimal 5 MB.</p>
    <Message v-if="error" severity="error" size="small" variant="simple">{{ error }}</Message>
  </div>
</template>