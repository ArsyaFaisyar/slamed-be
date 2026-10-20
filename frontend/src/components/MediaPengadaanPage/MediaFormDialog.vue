<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import Button from "primevue/button";
import Message from "primevue/message";
import { createMediaPengadaan } from "../../api/mediaPengadaan";
import { getErrorMessage, getFieldErrors } from "../../utils/error";

const visible = defineModel<boolean>("visible", { default: false });
const emit = defineEmits<{ created: [] }>();

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

function reset() {
  form.nama = "";
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

watch(visible, (value) => {
  if (value) reset();
});

async function onSubmit() {
  submitted.value = true;
  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    await createMediaPengadaan({ nama: form.nama.trim() });
    visible.value = false;
    emit("created");
  } catch (error) {
    const errors = getFieldErrors(error);
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => key === "nama"));
    serverErrors.value = known;
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, "Gagal menambahkan media pengadaan");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Tambah media pengadaan" class="w-[calc(100vw-2rem)] max-w-md" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="create-media-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="flex flex-col gap-1.5">
        <label for="media-nama" class="text-sm font-medium">Nama media</label>
        <InputText id="media-nama" v-model="form.nama" autocomplete="off" fluid :invalid="!!fieldError('nama')" />
        <Message v-if="fieldError('nama')" severity="error" size="small" variant="simple">
          {{ fieldError("nama") }}
        </Message>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="create-media-form" label="Simpan" :loading="saving" />
    </template>
  </Dialog>
</template>