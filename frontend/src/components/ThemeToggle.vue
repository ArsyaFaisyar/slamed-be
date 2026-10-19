<script setup lang="ts">
import { computed, ref } from "vue";
import ToggleSwitch from "primevue/toggleswitch";
import { DARK_CLASS, toggleThemeMode } from "../theme";

const isDark = ref(document.documentElement.classList.contains(DARK_CLASS));

const label = computed(() => (isDark.value ? "Ganti ke mode terang" : "Ganti ke mode gelap"));

function toggle() {
  isDark.value = toggleThemeMode() === "dark";
}
</script>
<template>
  <ToggleSwitch :model-value="isDark" :aria-label="label" :title="label" class="scale-110" @update:model-value="toggle">
    <template #handle="{ checked }">
      <i :class="checked ? 'pi pi-moon' : 'pi pi-sun'" class="text-xs" />
    </template>
  </ToggleSwitch>
</template>
