<script setup lang="ts">
import { ref, watch } from "vue";
import Button from "primevue/button";
import LkhFormField from "./LkhFormField.vue";
import { fetchAttachmentBlob, type LkhAttachment } from "../../api/lkh";

const MAX_SIZE = 5 * 1024 * 1024;
const ACCEPT = ".pdf,.doc,.docx,.xls,.xlsx";
const TYPES = [
  "application/pdf",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.ms-excel",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
];

const file = defineModel<File | null>({ default: null });
const fileError = defineModel<string>("fileError", { default: "" });

const props = defineProps<{
  disabled?: boolean;
  readonly?: boolean;
  error?: string;
  attachment?: LkhAttachment | null;
}>();

const input = ref<HTMLInputElement | null>(null);
const opening = ref(false);
const openError = ref("");

watch(file, (value) => {
  if (!value && input.value) input.value.value = "";
});

function onSelected(event: Event) {
  const el = event.target as HTMLInputElement;
  const selected = el.files?.[0];
  fileError.value = "";
  if (!selected) return;

  if (!TYPES.includes(selected.type)) {
    fileError.value = "Lampiran harus PDF, DOC, DOCX, XLS, atau XLSX";
    el.value = "";
    return;
  }

  if (selected.size > MAX_SIZE) {
    fileError.value = "Lampiran melebihi 5 MB";
    el.value = "";
    return;
  }

  file.value = selected;
}

async function openExisting() {
  if (!props.attachment) return;

  opening.value = true;
  openError.value = "";

  try {
    const blob = await fetchAttachmentBlob(props.attachment.id);
    const url = URL.createObjectURL(blob);
    window.open(url, "_blank", "noopener");
    setTimeout(() => URL.revokeObjectURL(url), 60_000);
  } catch {
    openError.value = "Gagal membuka lampiran";
  } finally {
    opening.value = false;
  }
}
</script>

<template>
  <LkhFormField
    label="Lampiran"
    :hint="readonly ? undefined : 'PDF, DOC, DOCX, XLS, atau XLSX, maksimal 5 MB. Opsional.'"
    :error="fileError || openError || error"
  >
    <div class="flex items-center gap-3">
      <input ref="input" type="file" :accept="ACCEPT" class="hidden" @change="onSelected" />

      <Button
        v-if="!readonly"
        type="button"
        :label="file || attachment ? 'Ganti file' : 'Pilih file'"
        icon="pi pi-paperclip"
        size="small"
        severity="secondary"
        :disabled="disabled"
        @click="input?.click()"
      />

      <span v-if="file" class="truncate text-sm text-fg-muted">{{ file.name }}</span>

      <template v-else-if="attachment">
        <span class="truncate text-sm text-fg-muted">{{ attachment.nama_file }}</span>
        <Button
          type="button"
          icon="pi pi-eye"
          size="small"
          rounded
          variant="text"
          severity="secondary"
          aria-label="Lihat lampiran"
          :loading="opening"
          @click="openExisting"
        />
      </template>

      <span v-else-if="readonly" class="text-sm text-fg-muted">Tidak ada lampiran</span>

      <Button
        v-if="file && !readonly"
        type="button"
        icon="pi pi-times"
        size="small"
        rounded
        variant="text"
        severity="secondary"
        aria-label="Batalkan pilihan file"
        :disabled="disabled"
        @click="file = null"
      />
    </div>
  </LkhFormField>
</template>