<script setup lang="ts">
import { computed, ref } from "vue";
import Button from "primevue/button";
import LkhFormField from "./LkhFormField.vue";

const latitude = defineModel<number | null>("latitude", { default: null });
const longitude = defineModel<number | null>("longitude", { default: null });

defineProps<{
  disabled?: boolean;
  error?: string;
}>();

const locating = ref(false);
const locationError = ref("");

const hasLocation = computed(() => latitude.value !== null && longitude.value !== null);
const mapsUrl = computed(() => `https://www.google.com/maps?q=${latitude.value},${longitude.value}`);

function captureLocation() {
  locationError.value = "";

  if (!("geolocation" in navigator)) {
    locationError.value = "Browser tidak mendukung pengambilan lokasi";
    return;
  }

  locating.value = true;

  navigator.geolocation.getCurrentPosition(
    (position) => {
      latitude.value = Number(position.coords.latitude.toFixed(6));
      longitude.value = Number(position.coords.longitude.toFixed(6));
      locating.value = false;
    },
    (err) => {
      locating.value = false;
      if (err.code === err.PERMISSION_DENIED) {
        locationError.value = "Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan browser.";
      } else if (err.code === err.TIMEOUT) {
        locationError.value = "Pengambilan lokasi terlalu lama. Coba lagi.";
      } else {
        locationError.value = "Lokasi tidak tersedia. Coba lagi.";
      }
    },
    { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 },
  );
}

function clearLocation() {
  latitude.value = null;
  longitude.value = null;
  locationError.value = "";
}
</script>

<template>
  <LkhFormField label="Lokasi" optional :error="locationError || error">
    <div
      class="flex flex-wrap items-center gap-3 rounded-lg border p-3"
      :class="error || locationError ? 'border-red-500' : 'border-line'"
    >
      <Button
        type="button"
        :label="hasLocation ? 'Perbarui lokasi' : 'Ambil lokasi saat ini'"
        icon="pi pi-map-marker"
        size="small"
        severity="secondary"
        :loading="locating"
        :disabled="disabled"
        @click="captureLocation"
      />

      <div v-if="hasLocation" class="flex items-center gap-3 text-sm">
        <div>
          <p class="tabular-nums">{{ latitude }}, {{ longitude }}</p>
          <a :href="mapsUrl" target="_blank" rel="noopener" class="text-xs text-primary underline">Lihat di peta</a>
        </div>
        <Button type="button" label="Hapus" size="small" variant="text" severity="secondary" :disabled="disabled" @click="clearLocation" />
      </div>
      <span v-else class="text-sm text-fg-muted">Belum diambil</span>
    </div>
  </LkhFormField>
</template>