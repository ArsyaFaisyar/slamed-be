<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { resolveMediaUrl } from '../../utils/media'

const props = withDefaults(
  defineProps<{
    src?: string | null
    preview?: string | null
    alt?: string
    fit?: 'cover' | 'contain'
  }>(),
  { fit: 'cover', alt: '' },
)

const failed = ref(false)

const url = computed(() => props.preview ?? (failed.value ? undefined : resolveMediaUrl(props.src)))

watch(
  () => props.src,
  () => {
    failed.value = false
  },
)
</script>

<template>
  <img
    v-if="url"
    :src="url"
    :alt="alt"
    class="size-full"
    :class="fit === 'cover' ? 'object-cover' : 'object-contain'"
    @error="failed = true"
  />
  <slot v-else />
</template>