<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import InputNumber from "primevue/inputnumber";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import { createArea } from "../../api/areas";
import { getErrorMessage, getFieldErrors } from "../../utils/error";

export interface SpvOption {
  label: string;
  value: number;
}

const visible = defineModel<boolean>("visible", { default: false });

defineProps<{
  spvOptions: SpvOption[];
}>();

const emit = defineEmits<{ created: [] }>();

const fields = ["nama", "spv_id", "target"] as const;
type Field = (typeof fields)[number];

function emptyForm() {
  return { nama: "", spv_id: null as number | null, target: 0 as number | null };
}

const form = reactive(emptyForm());
const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const clientErrors = computed<Record<Field, string>>(() => ({
  nama: form.nama.trim() ? "" : "Nama area wajib diisi",
  spv_id: form.spv_id ? "" : "SPV wajib dipilih",
  target: form.target === null ? "Target wajib diisi" : form.target < 0 ? "Target tidak boleh negatif" : "",
}));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function reset() {
  Object.assign(form, emptyForm());
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
    await createArea({
      nama: form.nama.trim(),
      spv_id: form.spv_id as number,
      target: form.target as number,
    });
    visible.value = false;
    emit("created");
  } catch (error) {
    const errors = getFieldErrors(error);
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => fields.includes(key as Field)));
    serverErrors.value = known;
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, "Gagal menambahkan area");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Tambah area" class="w-[calc(100vw-2rem)] max-w-md" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="create-area-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="flex flex-col gap-1.5">
        <label for="area-nama" class="text-sm font-medium">Nama area</label>
        <InputText id="area-nama" v-model="form.nama" autocomplete="off" fluid :invalid="!!fieldError('nama')" />
        <Message v-if="fieldError('nama')" severity="error" size="small" variant="simple">
          {{ fieldError("nama") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="area-spv" class="text-sm font-medium">SPV</label>
        <Select v-model="form.spv_id" input-id="area-spv" :options="spvOptions" option-label="label" option-value="value" placeholder="Pilih SPV" filter fluid :invalid="!!fieldError('spv_id')" />
        <Message v-if="fieldError('spv_id')" severity="error" size="small" variant="simple">
          {{ fieldError("spv_id") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="area-target" class="text-sm font-medium">Target</label>
        <InputNumber v-model="form.target" input-id="area-target" :min="0" :max-fraction-digits="0" locale="id-ID" fluid :invalid="!!fieldError('target')" />
        <Message v-if="fieldError('target')" severity="error" size="small" variant="simple">
          {{ fieldError("target") }}
        </Message>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="create-area-form" label="Simpan" :loading="saving" />
    </template>
  </Dialog>
</template>