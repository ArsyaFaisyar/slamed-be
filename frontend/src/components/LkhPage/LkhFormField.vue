<script setup lang="ts">
import Message from "primevue/message";

defineProps<{
  label: string;
  forId?: string;
  error?: string;
  hint?: string;
  optional?: boolean;
  required?: boolean;
}>();
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <component :is="forId ? 'label' : 'span'" :for="forId" class="text-sm font-medium">
      {{ label }}
      <span v-if="optional" class="font-normal text-fg-muted">(opsional)</span>
      <span v-if="required" class="text-red-500">*</span>
    </component>

    <slot />

    <p v-if="hint" class="text-xs text-fg-muted">{{ hint }}</p>
    <Message v-if="error" severity="error" size="small" variant="simple">{{ error }}</Message>
  </div>
</template>