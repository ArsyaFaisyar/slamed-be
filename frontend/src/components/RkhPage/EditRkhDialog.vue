<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import InputNumber from "primevue/inputnumber";
import Textarea from "primevue/textarea";
import DatePicker from "primevue/datepicker";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import { updateRkh, type Rkh } from "../../api/rkh";
import { tipeAktivitasOptions, tipeAktivitasSetelahRequestOptions } from "../../constant/rkh";
import { getErrorMessage, getFieldErrors } from "../../utils/error";
import { parseDateString, toDateString } from "../../utils/date";
import { getProjectIdsWithRequest } from "../../utils/projectRequest";
import type { Option, ProjectOption } from "./Types";

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  rkh: Rkh | null;
  customerOptions: Option[];
  projectOptions: ProjectOption[];
}>();

const emit = defineEmits<{
  updated: [];
}>();

type Field =
  | "customer_id"
  | "project_id"
  | "tanggal_rencana"
  | "tanggal_pelaksanaan"
  | "judul_kegiatan"
  | "rencana_kegiatan"
  | "tipe_aktivitas"
  | "estimasi_biaya_harian";

const form = reactive({
  customer_id: null as number | null,
  project_id: null as number | null,
  tanggal_rencana: null as Date | null,
  tanggal_pelaksanaan: null as Date | null,
  judul_kegiatan: "",
  rencana_kegiatan: "",
  tipe_aktivitas: null as string | null,
  estimasi_biaya_harian: 0 as number | null,
});

const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

// Project yang sudah punya request penawaran dari RKH lain: tipe aktivitas dibatasi.
const projectIdsWithRequest = ref<Set<number>>(new Set());

const isRestricted = computed(() => form.project_id !== null && projectIdsWithRequest.value.has(form.project_id));

const tipeOptions = computed(() => {
  if (!isRestricted.value) return tipeAktivitasOptions;

  // Data lama tetap valid: tipe asli RKH ini tidak dibuang selama project-nya tidak diganti.
  const original = props.rkh && form.project_id === props.rkh.project_id ? props.rkh.tipe_aktivitas : null;
  const extra = original && !tipeAktivitasSetelahRequestOptions.some((option) => option.value === original) ? [{ label: original, value: original }] : [];

  return [...tipeAktivitasSetelahRequestOptions, ...extra];
});

const filteredProjects = computed(() =>
  props.projectOptions.filter((project) => project.customer_id === form.customer_id),
);

watch(
  () => form.customer_id,
  () => {
    if (!filteredProjects.value.some((project) => project.value === form.project_id)) {
      form.project_id = null;
    }
  },
);

// Tipe yang sudah dipilih tapi tidak lagi diizinkan (project berganti): kosongkan.
watch(tipeOptions, (options) => {
  if (form.tipe_aktivitas && !options.some((option) => option.value === form.tipe_aktivitas)) {
    form.tipe_aktivitas = null;
  }
});

const clientErrors = computed<Record<Field, string>>(() => ({
  customer_id: form.customer_id ? "" : "Customer wajib dipilih",
  project_id: form.project_id ? "" : "Project wajib dipilih",
  tanggal_rencana: form.tanggal_rencana ? "" : "Tanggal rencana wajib diisi",
  tanggal_pelaksanaan: "",
  judul_kegiatan: form.judul_kegiatan.trim() ? "" : "Judul kegiatan wajib diisi",
  rencana_kegiatan: form.rencana_kegiatan.trim() ? "" : "Rencana kegiatan wajib diisi",
  tipe_aktivitas: !form.tipe_aktivitas
    ? "Tipe aktivitas wajib dipilih"
    : !tipeOptions.value.some((option) => option.value === form.tipe_aktivitas)
      ? "Tipe aktivitas tidak diizinkan untuk project ini"
      : "",
  estimasi_biaya_harian:
    form.estimasi_biaya_harian === null
      ? "Estimasi biaya wajib diisi"
      : form.estimasi_biaya_harian < 0
        ? "Estimasi biaya tidak boleh negatif"
        : "",
}));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function resetForm() {
  form.customer_id = props.rkh?.customer_id ?? null;
  form.project_id = props.rkh?.project_id ?? null;
  form.tanggal_rencana = parseDateString(props.rkh?.tanggal_rencana);
  form.tanggal_pelaksanaan = parseDateString(props.rkh?.tanggal_pelaksanaan);
  form.judul_kegiatan = props.rkh?.judul_kegiatan ?? "";
  form.rencana_kegiatan = props.rkh?.rencana_kegiatan ?? "";
  form.tipe_aktivitas = props.rkh?.tipe_aktivitas ?? null;
  form.estimasi_biaya_harian = props.rkh ? Number(props.rkh.estimasi_biaya_harian) : 0;
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

async function loadRestriction() {
  projectIdsWithRequest.value = await getProjectIdsWithRequest(props.rkh?.id);
}

watch(
  () => [visible.value, props.rkh] as const,
  ([isVisible]) => {
    if (!isVisible) return;
    resetForm();
    loadRestriction();
  },
  { immediate: true },
);

async function onSubmit() {
  submitted.value = true;

  if (!props.rkh) return;
  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    await updateRkh(props.rkh.id, {
      customer_id: form.customer_id as number,
      project_id: form.project_id as number,
      tanggal_rencana: toDateString(form.tanggal_rencana as Date),
      ...(form.tanggal_pelaksanaan ? { tanggal_pelaksanaan: toDateString(form.tanggal_pelaksanaan) } : {}),
      judul_kegiatan: form.judul_kegiatan.trim(),
      rencana_kegiatan: form.rencana_kegiatan.trim(),
      tipe_aktivitas: form.tipe_aktivitas as string,
      estimasi_biaya_harian: form.estimasi_biaya_harian as number,
    });

    visible.value = false;
    emit("updated");
  } catch (error) {
    const errors = getFieldErrors(error);
    serverErrors.value = errors;

    if (Object.keys(errors).length === 0) {
      formError.value = getErrorMessage(error, "Gagal memperbarui RKH");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Edit RKH" class="w-[calc(100vw-2rem)] max-w-lg" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="edit-rkh-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="edit-rkh-customer" class="text-sm font-medium">Customer</label>
          <Select v-model="form.customer_id" input-id="edit-rkh-customer" :options="customerOptions" option-label="label" option-value="value" placeholder="Pilih customer" filter fluid :invalid="!!fieldError('customer_id')" />
          <Message v-if="fieldError('customer_id')" severity="error" size="small" variant="simple">
            {{ fieldError("customer_id") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="edit-rkh-project" class="text-sm font-medium">Project</label>
          <Select v-model="form.project_id" input-id="edit-rkh-project" :options="filteredProjects" option-label="label" option-value="value" :placeholder="form.customer_id ? 'Pilih project' : 'Pilih customer dulu'" :disabled="!form.customer_id" filter fluid :invalid="!!fieldError('project_id')" />
          <Message v-if="fieldError('project_id')" severity="error" size="small" variant="simple">
            {{ fieldError("project_id") }}
          </Message>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="edit-rkh-tanggal-rencana" class="text-sm font-medium">Tanggal rencana</label>
          <DatePicker v-model="form.tanggal_rencana" input-id="edit-rkh-tanggal-rencana" date-format="dd/mm/yy" show-icon fluid :invalid="!!fieldError('tanggal_rencana')" />
          <Message v-if="fieldError('tanggal_rencana')" severity="error" size="small" variant="simple">
            {{ fieldError("tanggal_rencana") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="edit-rkh-tanggal-pelaksanaan" class="text-sm font-medium">Tanggal pelaksanaan</label>
          <DatePicker v-model="form.tanggal_pelaksanaan" input-id="edit-rkh-tanggal-pelaksanaan" date-format="dd/mm/yy" show-icon show-button-bar fluid :invalid="!!fieldError('tanggal_pelaksanaan')" />
          <Message v-if="fieldError('tanggal_pelaksanaan')" severity="error" size="small" variant="simple">
            {{ fieldError("tanggal_pelaksanaan") }}
          </Message>
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-rkh-judul" class="text-sm font-medium">Judul kegiatan</label>
        <InputText id="edit-rkh-judul" v-model="form.judul_kegiatan" autocomplete="off" fluid :invalid="!!fieldError('judul_kegiatan')" />
        <Message v-if="fieldError('judul_kegiatan')" severity="error" size="small" variant="simple">
          {{ fieldError("judul_kegiatan") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-rkh-rencana" class="text-sm font-medium">Rencana kegiatan</label>
        <Textarea id="edit-rkh-rencana" v-model="form.rencana_kegiatan" rows="3" auto-resize fluid :invalid="!!fieldError('rencana_kegiatan')" />
        <Message v-if="fieldError('rencana_kegiatan')" severity="error" size="small" variant="simple">
          {{ fieldError("rencana_kegiatan") }}
        </Message>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="edit-rkh-tipe" class="text-sm font-medium">Tipe aktivitas</label>
          <Select v-model="form.tipe_aktivitas" input-id="edit-rkh-tipe" :options="tipeOptions" option-label="label" option-value="value" placeholder="Pilih tipe" fluid :invalid="!!fieldError('tipe_aktivitas')" />
          <p v-if="isRestricted" class="text-xs text-fg-muted">
            Project ini sudah punya request penawaran, jadi pilihan dibatasi ke tahap lanjutan.
          </p>
          <Message v-if="fieldError('tipe_aktivitas')" severity="error" size="small" variant="simple">
            {{ fieldError("tipe_aktivitas") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="edit-rkh-biaya" class="text-sm font-medium">Estimasi biaya harian</label>
          <InputNumber v-model="form.estimasi_biaya_harian" input-id="edit-rkh-biaya" mode="currency" currency="IDR" locale="id-ID" :min="0" :max-fraction-digits="0" fluid :invalid="!!fieldError('estimasi_biaya_harian')" />
          <Message v-if="fieldError('estimasi_biaya_harian')" severity="error" size="small" variant="simple">
            {{ fieldError("estimasi_biaya_harian") }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="edit-rkh-form" label="Simpan perubahan" :loading="saving" />
    </template>
  </Dialog>
</template>