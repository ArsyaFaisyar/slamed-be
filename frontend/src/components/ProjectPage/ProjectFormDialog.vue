<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import InputNumber from "primevue/inputnumber";
import DatePicker from "primevue/datepicker";
import Textarea from "primevue/textarea";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import { createProject, updateProject, type Project, type ProjectInput } from "../../api/projects";
import { getProjectStatuses, type ProjectStatus } from "../../api/projectStatuses";
import { getErrorMessage, getFieldErrors } from "../../utils/error";
import { parseDateString, toDateString } from "../../utils/date";

export interface CustomerOption {
  value: number;
  label: string;
}

export interface SalesOption {
  value: number;
  label: string;
}

interface StatusOption {
  value: number;
  label: string;
  color: string | null;
}

const props = defineProps<{
  project?: Project | null;
  customerOptions: CustomerOption[];
  salesOptions: SalesOption[];
}>();
const visible = defineModel<boolean>("visible", { default: false });
const emit = defineEmits<{ saved: [] }>();

type TextKey = "nama_project" | "deskripsi";
type Field = TextKey | "status_id" | "customer_id" | "sales_id" | "nilai_proyek" | "estimasi_closing";

const textKeys: TextKey[] = ["nama_project", "deskripsi"];
const allKeys: Field[] = [...textKeys, "status_id", "customer_id", "sales_id", "nilai_proyek", "estimasi_closing"];

const form = reactive({
  nama_project: "",
  status_id: null as number | null,
  deskripsi: "",
  customer_id: null as number | null,
  sales_id: null as number | null,
  nilai_proyek: null as number | null,
  estimasi_closing: null as Date | null,
});

const statuses = ref<ProjectStatus[]>([]);
const loadingStatuses = ref(false);

const statusOptions = computed<StatusOption[]>(() => {
  const options = statuses.value
    .filter((status) => status.is_active)
    .sort((a, b) => a.urutan - b.urutan)
    .map((status) => ({ value: status.id, label: status.nama, color: status.warna }));

  const current = props.project?.status_id;
  if (current != null && !options.some((option) => option.value === current)) {
    const known = statuses.value.find((status) => status.id === current);
    options.unshift({
      value: current,
      label: known ? `${known.nama} (nonaktif)` : `ID ${current}`,
      color: known?.warna ?? null,
    });
  }

  return options;
});

const salesSelectOptions = computed<SalesOption[]>(() => {
  const options = [...props.salesOptions];
  const current = props.project?.sales_id;
  if (current != null && !options.some((option) => option.value === current)) {
    options.unshift({ value: current, label: `ID ${current}` });
  }
  return options;
});

const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const isEdit = computed(() => !!props.project);

const clientErrors = computed<Partial<Record<Field, string>>>(() => ({
  nama_project: form.nama_project.trim() ? "" : "Nama project wajib diisi",
  customer_id: form.customer_id === null ? "Customer wajib dipilih" : "",
  sales_id: form.sales_id === null ? "Sales wajib dipilih" : "",
  nilai_proyek: form.nilai_proyek !== null && form.nilai_proyek < 0 ? "Nilai proyek tidak boleh negatif" : "",
}));

const hasClientErrors = computed(() => Object.values(clientErrors.value).some(Boolean));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "") || "";
}

function originalNilai() {
  const value = props.project?.nilai_proyek;
  if (value === null || value === undefined || value === "") return null;
  const amount = Number(value);
  return Number.isNaN(amount) ? null : amount;
}

function originalClosing() {
  return props.project?.estimasi_closing?.slice(0, 10) ?? null;
}

function reset() {
  for (const key of textKeys) form[key] = props.project?.[key] ?? "";
  form.status_id = props.project?.status_id ?? null;
  form.customer_id = props.project?.customer_id ?? null;
  form.sales_id = props.project?.sales_id ?? null;
  form.nilai_proyek = originalNilai();
  form.estimasi_closing = parseDateString(props.project?.estimasi_closing);
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

async function loadStatuses() {
  loadingStatuses.value = true;

  try {
    statuses.value = await getProjectStatuses();
  } catch (error) {
    statuses.value = [];
    formError.value = getErrorMessage(error, "Gagal memuat daftar status");
  } finally {
    loadingStatuses.value = false;
  }
}

watch(visible, (value) => {
  if (!value) return;

  reset();
  loadStatuses();
});

function buildPayload() {
  const payload: Record<string, string | number | null> = {};

  for (const key of textKeys) {
    const value = form[key].trim();
    if (isEdit.value) {
      if (value !== (props.project?.[key] ?? "")) payload[key] = value || null;
    } else if (value) {
      payload[key] = value;
    }
  }

  if (isEdit.value) {
    if (form.status_id !== (props.project?.status_id ?? null)) payload.status_id = form.status_id;
  } else if (form.status_id !== null) {
    payload.status_id = form.status_id;
  }

  if (isEdit.value) {
    if (form.nilai_proyek !== originalNilai()) payload.nilai_proyek = form.nilai_proyek;
  } else if (form.nilai_proyek !== null) {
    payload.nilai_proyek = form.nilai_proyek;
  }

  const closing = form.estimasi_closing ? toDateString(form.estimasi_closing) : null;
  if (isEdit.value) {
    if (closing !== originalClosing()) payload.estimasi_closing = closing;
  } else if (closing !== null) {
    payload.estimasi_closing = closing;
  }

  if (!isEdit.value || form.customer_id !== props.project?.customer_id) {
    payload.customer_id = form.customer_id;
  }

  if (!isEdit.value || form.sales_id !== props.project?.sales_id) {
    payload.sales_id = form.sales_id;
  }

  return payload;
}

async function onSubmit() {
  submitted.value = true;
  if (hasClientErrors.value) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    const payload = buildPayload();

    if (props.project) {
      if (Object.keys(payload).length > 0) await updateProject(props.project.id, payload);
    } else {
      await createProject(payload as unknown as ProjectInput);
    }

    visible.value = false;
    emit("saved");
  } catch (error) {
    const errors = getFieldErrors(error);
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => allKeys.includes(key as Field)));
    serverErrors.value = known;
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, "Gagal menyimpan project");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal :header="isEdit ? 'Edit project' : 'Tambah project'" class="w-[calc(100vw-2rem)] max-w-2xl" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="project-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="project-nama" class="text-sm font-medium"> Nama project <span class="text-red-500">*</span> </label>
          <InputText id="project-nama" v-model="form.nama_project" autocomplete="off" fluid :invalid="!!fieldError('nama_project')" />
          <Message v-if="fieldError('nama_project')" severity="error" size="small" variant="simple">
            {{ fieldError("nama_project") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="project-customer" class="text-sm font-medium"> Customer <span class="text-red-500">*</span> </label>
          <Select
            v-model="form.customer_id"
            input-id="project-customer"
            :options="customerOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih customer"
            filter
            fluid
            empty-message="Daftar customer tidak tersedia"
            :invalid="!!fieldError('customer_id')" />
          <Message v-if="fieldError('customer_id')" severity="error" size="small" variant="simple">
            {{ fieldError("customer_id") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="project-sales" class="text-sm font-medium"> Sales <span class="text-red-500">*</span> </label>
          <Select
            v-model="form.sales_id"
            input-id="project-sales"
            :options="salesSelectOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih sales"
            filter
            fluid
            empty-message="Daftar sales tidak tersedia"
            :invalid="!!fieldError('sales_id')" />
          <Message v-if="fieldError('sales_id')" severity="error" size="small" variant="simple">
            {{ fieldError("sales_id") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="project-nilai" class="text-sm font-medium">Nilai proyek</label>
          <InputNumber
            v-model="form.nilai_proyek"
            input-id="project-nilai"
            mode="currency"
            currency="IDR"
            locale="id-ID"
            :min="0"
            :max-fraction-digits="0"
            fluid
            :invalid="!!fieldError('nilai_proyek')" />
          <Message v-if="fieldError('nilai_proyek')" severity="error" size="small" variant="simple">
            {{ fieldError("nilai_proyek") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="project-closing" class="text-sm font-medium">Estimasi closing</label>
          <DatePicker
            v-model="form.estimasi_closing"
            input-id="project-closing"
            date-format="dd/mm/yy"
            show-icon
            show-button-bar
            fluid
            :invalid="!!fieldError('estimasi_closing')" />
          <Message v-if="fieldError('estimasi_closing')" severity="error" size="small" variant="simple">
            {{ fieldError("estimasi_closing") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="project-status" class="text-sm font-medium">Status</label>
          <Select
            v-model="form.status_id"
            input-id="project-status"
            :options="statusOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih status"
            :loading="loadingStatuses"
            :disabled="loadingStatuses || statusOptions.length === 0"
            show-clear
            fluid
            empty-message="Daftar status tidak tersedia"
            :invalid="!!fieldError('status_id')">
            <template #option="{ option }">
              <div class="flex items-center gap-2.5">
                <span class="size-3 shrink-0 rounded-full border border-line" :style="{ backgroundColor: option.color ?? 'transparent' }" />
                <span>{{ option.label }}</span>
              </div>
            </template>
            <template #value="{ value, placeholder }">
              <div v-if="value != null" class="flex items-center gap-2.5">
                <span
                  class="size-3 shrink-0 rounded-full border border-line"
                  :style="{
                    backgroundColor: statusOptions.find((option) => option.value === value)?.color ?? 'transparent',
                  }" />
                <span>{{ statusOptions.find((option) => option.value === value)?.label ?? `ID ${value}` }}</span>
              </div>
              <span v-else class="text-fg-muted">{{ placeholder }}</span>
            </template>
          </Select>
          <Message v-if="fieldError('status_id')" severity="error" size="small" variant="simple">
            {{ fieldError("status_id") }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="project-deskripsi" class="text-sm font-medium">Deskripsi</label>
          <Textarea id="project-deskripsi" v-model="form.deskripsi" rows="3" auto-resize fluid :invalid="!!fieldError('deskripsi')" />
          <Message v-if="fieldError('deskripsi')" severity="error" size="small" variant="simple">
            {{ fieldError("deskripsi") }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="project-form" label="Simpan" icon="pi pi-check" :loading="saving" />
    </template>
  </Dialog>
</template>