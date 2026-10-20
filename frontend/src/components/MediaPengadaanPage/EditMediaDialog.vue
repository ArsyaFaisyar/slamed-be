<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import Button from "primevue/button";
import Message from "primevue/message";
import { updateMediaPengadaan, type MediaPengadaan } from "../../api/mediaPengadaan";
import { getErrorMessage, getFieldErrors } from "../../utils/error";

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  media: MediaPengadaan | null;
}>();

const emit = defineEmits<{
  updated: [];
}>();

const form = reactive({ nama: "" });
const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const clientErrors = computed(() => ({
  nama: form.nama.trim() ? "" : "Nama media wajib diisi",
}));

function fieldError(field: "nama") {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function resetForm() {
  form.nama = props.media?.nama ?? "";
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

watch(
  () => [visible.value, props.media] as const,
  ([isVisible]) => {
    if (isVisible) resetForm();
  },
  { immediate: true },
);

async function onSubmit() {
  submitted.value = true;

  if (!props.media) return;
  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    await updateMediaPengadaan(props.media.id, { nama: form.nama.trim() });
    visible.value = false;
    emit("updated");
  } catch (error) {
    const errors = getFieldErrors(error);
    serverErrors.value = errors;

    if (Object.keys(errors).length === 0) {
      formError.value = getErrorMessage(error, "Gagal memperbarui media pengadaan");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Edit media pengadaan" class="w-[calc(100vw-2rem)] max-w-md" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="edit-media-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>

      <div class="flex flex-col gap-1.5">
        <label for="edit-media-nama" class="text-sm font-medium">Nama media</label>
        <InputText id="edit-media-nama" v-model="form.nama" autocomplete="off" fluid :invalid="!!fieldError('nama')" />
        <Message v-if="fieldError('nama')" severity="error" size="small" variant="simple">
          {{ fieldError("nama") }}
        </Message>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="edit-media-form" label="Simpan perubahan" :loading="saving" />
    </template>
  </Dialog>
</template>