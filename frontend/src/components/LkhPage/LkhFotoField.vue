<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import Button from "primevue/button";
import Dialog from "primevue/dialog";
import LkhFormField from "./LkhFormField.vue";
import { fetchAttachmentBlob, type LkhAttachment } from "../../api/lkh";

const MAX_SIZE = 2 * 1024 * 1024;
const TYPES = ["image/jpeg", "image/png", "image/gif"];

const file = defineModel<File | null>({ default: null });
const fileError = defineModel<string>("fileError", { default: "" });

const props = defineProps<{
  disabled?: boolean;
  readonly?: boolean;
  error?: string;
  attachment?: LkhAttachment | null;
}>();

const input = ref<HTMLInputElement | null>(null);
const preview = ref("");
const existingSrc = ref("");
const previewOpen = ref(false);
let loadToken = 0;

const imageSrc = computed(() => preview.value || existingSrc.value);

function revokePreview() {
  if (preview.value) URL.revokeObjectURL(preview.value);
  preview.value = "";
}

function revokeExisting() {
  if (existingSrc.value) URL.revokeObjectURL(existingSrc.value);
  existingSrc.value = "";
}

watch(
  file,
  (value) => {
    revokePreview();
    if (value) preview.value = URL.createObjectURL(value);
    else if (input.value) input.value.value = "";
  },
  { immediate: true },
);

watch(
  () => props.attachment?.id,
  async (id) => {
    const token = ++loadToken;
    revokeExisting();
    if (!id) return;

    try {
      const blob = await fetchAttachmentBlob(id);
      if (token !== loadToken) return;
      existingSrc.value = URL.createObjectURL(blob);
    } catch {
      existingSrc.value = "";
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  loadToken++;
  revokePreview();
  revokeExisting();
});

function onSelected(event: Event) {
  const el = event.target as HTMLInputElement;
  const selected = el.files?.[0];
  fileError.value = "";
  if (!selected) return;

  if (!TYPES.includes(selected.type)) {
    fileError.value = "Foto harus JPG, PNG, atau GIF";
    el.value = "";
    return;
  }

  if (selected.size > MAX_SIZE) {
    fileError.value = "Foto melebihi 2 MB";
    el.value = "";
    return;
  }

  file.value = selected;
}
</script>

<template>
  <LkhFormField
    label="Foto kunjungan"
    :required="!readonly"
    :hint="readonly ? undefined : 'JPG, PNG, atau GIF, maksimal 2 MB.'"
    :error="fileError || error"
  >
    <div class="flex items-center gap-3">
      <img
        v-if="imageSrc"
        :src="imageSrc"
        alt="Foto kunjungan"
        class="size-16 shrink-0 rounded-lg border border-line object-cover"
      />

      <input ref="input" type="file" :accept="TYPES.join(',')" class="hidden" @change="onSelected" />

      <Button
        v-if="imageSrc"
        type="button"
        icon="pi pi-eye"
        size="small"
        rounded
        variant="text"
        severity="secondary"
        aria-label="Lihat foto"
        @click="previewOpen = true"
      />

      <Button
        v-if="!readonly"
        type="button"
        :label="imageSrc || attachment ? 'Ganti foto' : 'Pilih foto'"
        icon="pi pi-camera"
        size="small"
        severity="secondary"
        :disabled="disabled"
        @click="input?.click()"
      />

      <span v-if="file" class="truncate text-sm text-fg-muted">{{ file.name }}</span>
      <span v-else-if="attachment && !imageSrc" class="text-sm text-fg-muted">Memuat foto...</span>
      <span v-else-if="readonly && !attachment" class="text-sm text-fg-muted">Tidak ada foto</span>
    </div>

    <Dialog v-model:visible="previewOpen" modal header="Foto kunjungan" class="w-[calc(100vw-2rem)] max-w-2xl" :draggable="false">
      <img :src="imageSrc" alt="Foto kunjungan" class="mx-auto max-h-[70vh] w-auto rounded-lg object-contain" />
    </Dialog>
  </LkhFormField>
</template>