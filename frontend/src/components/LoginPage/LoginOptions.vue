<script setup lang="ts">
import Button from 'primevue/button'

defineProps<{ loading?: boolean }>()

defineEmits<{
  oneid: []
  admin: []
}>()
</script>


<template>
  <div class="flex w-full flex-col gap-4">
    <Button
      label="Masuk dengan OneID"
      icon="pi pi-id-card"
      size="large"
      fluid
      :loading="loading"
      class="min-h-13.5 justify-center rounded-xl! font-semibold transition-all duration-200 hover:shadow-md active:scale-[0.99]"
      @click="$emit('oneid')"
    />
    <Button
      label="Masuk sebagai administrator"
      fluid
      variant="text"
      severity="secondary"
      class="min-h-12 justify-center rounded-xl border-surface-200 font-medium transition-all duration-200 hover:border-surface-300 hover:bg-surface-100 hover:text-surface-900 dark:hover:bg-surface-800 dark:hover:text-surface-0"
      @click="$emit('admin')"
    />
  </div>
</template>
