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
import { createRkh } from "../../api/rkh";
import { tipeAktivitasOptions, tipeAktivitasSetelahRequestOptions } from "../../constant/rkh";
import { getErrorMessage, getFieldErrors } from "../../utils/error";
import { toDateString } from "../../utils/date";
import { getProjectIdsWithRequest } from "../../utils/projectRequest";
import type { Option, ProjectOption } from "./Types";

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  customerOptions: Option[];
  projectOptions: ProjectOption[];
}>();

const emit = defineEmits<{ created: [] }>();

// Kedua tanggal hanya boleh diisi dari hari ini sampai 7 hari ke depan.
const MAX_DAYS_AHEAD = 7;

function startOfToday() {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  return date;
}

// Diperbarui setiap dialog dibuka, supaya tidak basi kalau halaman dibiarkan terbuka lewat tengah malam.
const today = ref(startOfToday());

const maxDate = computed(() => {
  const max = new Date(today.value);
  max.setDate(max.getDate() + MAX_DAYS_AHEAD);
  return max;
});

function isOutOfRange(date: Date) {
  const day = new Date(date);
  day.setHours(0, 0, 0, 0);
  return day < today.value || day > maxDate.value;
}

const fields = ["customer_id", "project_id", "tanggal_rencana", "tanggal_pelaksanaan", "judul_kegiatan", "rencana_kegiatan", "tipe_aktivitas", "estimasi_biaya_harian"] as const;
type Field = (typeof fields)[number];

function emptyForm() {
  return {
    customer_id: null as number | null,
    project_id: null as number | null,
    tanggal_rencana: null as Date | null,
    tanggal_pelaksanaan: null as Date | null,
    judul_kegiatan: "",
    rencana_kegiatan: "",
    tipe_aktivitas: null as string | null,
    estimasi_biaya_harian: 0 as number | null,
  };
}

const form = reactive(emptyForm());
const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

// Project yang sudah punya request penawaran: tipe aktivitas RKH berikutnya dibatasi.
const projectIdsWithRequest = ref<Set<number>>(new Set());

const isRestricted = computed(() => form.project_id !== null && projectIdsWithRequest.value.has(form.project_id));

const tipeOptions = computed(() => (isRestricted.value ? tipeAktivitasSetelahRequestOptions : tipeAktivitasOptions));

const safeCustomerOptions = computed<Option[]>(() =>
  (Array.isArray(props.customerOptions) ? props.customerOptions : [])
    .filter((option) => option && option.value != null && typeof option.label === "string")
    .map((option) => ({
      ...option,
      value: Number(option.value),
    })),
);

const safeProjectOptions = computed<ProjectOption[]>(() =>
  (Array.isArray(props.projectOptions) ? props.projectOptions : [])
    .filter((project) => project && project.value != null && typeof project.label === "string")
    .map((project) => ({
      ...project,
      value: Number(project.value),
      customer_id: Number(project.customer_id),
    })),
);

const filteredProjects = computed(() => safeProjectOptions.value.filter((project) => project.customer_id === form.customer_id));

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

// Tanggal pelaksanaan tidak boleh lebih awal dari tanggal rencana.
watch(
  () => form.tanggal_rencana,
  (rencana) => {
    if (rencana && form.tanggal_pelaksanaan && form.tanggal_pelaksanaan < rencana) {
      form.tanggal_pelaksanaan = null;
    }
  },
);

const rangeHint = computed(() => `Hanya bisa diisi sampai ${MAX_DAYS_AHEAD} hari ke depan dari hari ini`);

const clientErrors = computed<Record<Field, string>>(() => ({
  customer_id: form.customer_id ? "" : "Customer wajib dipilih",
  project_id: form.project_id ? "" : "Project wajib dipilih",
  tanggal_rencana: !form.tanggal_rencana
    ? "Tanggal rencana wajib diisi"
    : isOutOfRange(form.tanggal_rencana)
      ? rangeHint.value
      : "",
  tanggal_pelaksanaan: !form.tanggal_pelaksanaan
    ? ""
    : isOutOfRange(form.tanggal_pelaksanaan)
      ? rangeHint.value
      : form.tanggal_rencana && form.tanggal_pelaksanaan < form.tanggal_rencana
        ? "Tanggal pelaksanaan tidak boleh sebelum tanggal rencana"
        : "",
  judul_kegiatan: form.judul_kegiatan.trim() ? "" : "Judul kegiatan wajib diisi",
  rencana_kegiatan: form.rencana_kegiatan.trim() ? "" : "Rencana kegiatan wajib diisi",
  tipe_aktivitas: !form.tipe_aktivitas
    ? "Tipe aktivitas wajib dipilih"
    : !tipeOptions.value.some((option) => option.value === form.tipe_aktivitas)
      ? "Tipe aktivitas tidak diizinkan untuk project ini"
      : "",
  estimasi_biaya_harian: form.estimasi_biaya_harian === null ? "Estimasi biaya wajib diisi" : form.estimasi_biaya_harian < 0 ? "Estimasi biaya tidak boleh negatif" : "",
}));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function reset() {
  today.value = startOfToday();
  Object.assign(form, emptyForm());
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

watch(visible, async (value) => {
  if (!value) return;
  reset();
  projectIdsWithRequest.value = await getProjectIdsWithRequest();
});

async function onSubmit() {
  submitted.value = true;
  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    await createRkh({
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
    emit("created");
  } catch (error) {
    const errors = getFieldErrors(error);
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => fields.includes(key as Field)));
    serverErrors.value = known;
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, "Gagal menambahkan RKH");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Tambah RKH" class="w-[calc(100vw-2rem)] max-w-lg" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="create-rkh-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="rkh-customer" class="text-sm font-medium">Customer</label>
          <Select v-model="form.customer_id" input-id="rkh-customer" :options="safeCustomerOptions" option-label="label" option-value="value" placeholder="Pilih customer" filter fluid :invalid="!!fieldError('customer_id')" />
          <Message v-if="fieldError('customer_id')" severity="error" size="small" variant="simple">
            {{ fieldError("customer_id") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rkh-project" class="text-sm font-medium">Project</label>
          <Select
            v-model="form.project_id"
            input-id="rkh-project"
            :options="filteredProjects"
            option-label="label"
            option-value="value"
            :placeholder="form.customer_id ? 'Pilih project' : 'Pilih customer dulu'"
            :disabled="!form.customer_id"
            filter
            fluid
            :invalid="!!fieldError('project_id')" />
          <Message v-if="fieldError('project_id')" severity="error" size="small" variant="simple">
            {{ fieldError("project_id") }}
          </Message>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="rkh-tanggal-rencana" class="text-sm font-medium">Tanggal rencana</label>
          <DatePicker
            v-model="form.tanggal_rencana"
            input-id="rkh-tanggal-rencana"
            date-format="dd/mm/yy"
            show-icon
            fluid
            :min-date="today"
            :max-date="maxDate"
            :invalid="!!fieldError('tanggal_rencana')"
          />
          <Message v-if="fieldError('tanggal_rencana')" severity="error" size="small" variant="simple">
            {{ fieldError("tanggal_rencana") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rkh-tanggal-pelaksanaan" class="text-sm font-medium">Tanggal pelaksanaan</label>
          <DatePicker
            v-model="form.tanggal_pelaksanaan"
            input-id="rkh-tanggal-pelaksanaan"
            date-format="dd/mm/yy"
            show-icon
            show-button-bar
            fluid
            :min-date="form.tanggal_rencana || today"
            :max-date="maxDate"
            :invalid="!!fieldError('tanggal_pelaksanaan')"
          />
          <Message v-if="fieldError('tanggal_pelaksanaan')" severity="error" size="small" variant="simple">
            {{ fieldError("tanggal_pelaksanaan") }}
          </Message>
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="rkh-judul" class="text-sm font-medium">Judul kegiatan</label>
        <InputText id="rkh-judul" v-model="form.judul_kegiatan" autocomplete="off" fluid :invalid="!!fieldError('judul_kegiatan')" />
        <Message v-if="fieldError('judul_kegiatan')" severity="error" size="small" variant="simple">
          {{ fieldError("judul_kegiatan") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="rkh-rencana" class="text-sm font-medium">Rencana kegiatan</label>
        <Textarea id="rkh-rencana" v-model="form.rencana_kegiatan" rows="3" auto-resize fluid :invalid="!!fieldError('rencana_kegiatan')" />
        <Message v-if="fieldError('rencana_kegiatan')" severity="error" size="small" variant="simple">
          {{ fieldError("rencana_kegiatan") }}
        </Message>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="rkh-tipe" class="text-sm font-medium">Tipe aktivitas</label>
          <Select v-model="form.tipe_aktivitas" input-id="rkh-tipe" :options="tipeOptions" option-label="label" option-value="value" placeholder="Pilih tipe" fluid :invalid="!!fieldError('tipe_aktivitas')" />
          <p v-if="isRestricted" class="text-xs text-fg-muted">
            Project ini sudah punya request penawaran, jadi pilihan dibatasi ke tahap lanjutan.
          </p>
          <Message v-if="fieldError('tipe_aktivitas')" severity="error" size="small" variant="simple">
            {{ fieldError("tipe_aktivitas") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rkh-biaya" class="text-sm font-medium">Estimasi biaya harian</label>
          <InputNumber v-model="form.estimasi_biaya_harian" input-id="rkh-biaya" mode="currency" currency="IDR" locale="id-ID" :min="0" :max-fraction-digits="0" fluid :invalid="!!fieldError('estimasi_biaya_harian')" />
          <Message v-if="fieldError('estimasi_biaya_harian')" severity="error" size="small" variant="simple">
            {{ fieldError("estimasi_biaya_harian") }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="create-rkh-form" label="Simpan" :loading="saving" />
    </template>
  </Dialog>
</template>