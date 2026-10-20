<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Avatar from 'primevue/avatar'
import { getInitials } from '../../utils/format'
import { resolveMediaUrl } from '../../utils/media'

const props = defineProps<{ name: string; logo?: string | null; preview?: string | null }>()

const failed = ref(false)

const image = computed(() => props.preview ?? (failed.value ? undefined : resolveMediaUrl(props.logo)))
const initials = computed(() => getInitials(props.name ?? ''))

watch(
  () => props.logo,
  () => {
    failed.value = false
  },
)
</script>

<template>
  <Avatar
    :image="image"
    :label="image ? undefined : initials"
    shape="square"
    class="shrink-0 rounded-lg bg-brand/10 font-semibold text-brand"
    @error="failed = true"
  />
</template>