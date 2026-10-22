<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from "vue";
import { onBeforeRouteLeave, useRoute, useRouter } from "vue-router";
import DatePicker from "primevue/datepicker";
import InputText from "primevue/inputtext";
import Textarea from "primevue/textarea";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import { useConfirm } from "primevue/useconfirm";
import {
  createLkh,
  getAttachments,
  getLkh,
  isLkhDone,
  LKH_DONE,
  updateLkh,
  uploadAttachment,
  type Lkh,
  type LkhAttachment,
} from "../api/lkh";
import { getRkhById, type Rkh } from "../api/rkh";
import { getCustomers, type Customer } from "../api/customers";
import { getProjects, updateProject, type Project } from "../api/projects";
import { getProjectStatuses, type ProjectStatus } from "../api/projectStatuses";
import { useAuthStore } from "../stores/auth";
import { getErrorMessage, getFieldErrors } from "../utils/error";
import { formatDate, parseDateString, toDateString } from "../utils/date";
import { readableTextColor } from "../utils/color";
import LkhFormField from "../components/LkhPage/LkhFormField.vue";
import LkhLocationField from "../components/LkhPage/LkhLocationField.vue";
import LkhFotoField from "../components/LkhPage/LkhFotoField.vue";
import LkhLampiranField from "../components/LkhPage/LkhLampiranField.vue";

const LIST_PATH = "/aktivitas/lkh";

type Field =
  | "tanggal_kunjungan"
  | "hasil_kunjungan"
  | "nama_pic"
  | "nomor_pic"
  | "foto"
  | "file_lampiran"
  | "tindak_lanjut"
  | "tanggal_follow_up"
  | "project_status"
  | "location";

const serverKeys: Field[] = [
  "tanggal_kunjungan",
  "hasil_kunjungan",
  "nama_pic",
  "nomor_pic",
  "foto",
  "file_lampiran",
  "tindak_lanjut",
  "tanggal_follow_up",
];

const route = useRoute();
const router = useRouter();
const confirm = useConfirm();
const auth = useAuthStore();

const rkhId = computed(() => Number(route.params.rkhId));

const rkh = ref<Rkh | null>(null);
const lkh = ref<Lkh | null>(null);
const customers = ref<Customer[]>([]);
const projects = ref<Project[]>([]);
const projectStatuses = ref<ProjectStatus[]>([]);
const attachments = ref<LkhAttachment[]>([]);

const loading = ref(false);
const loadError = ref("");

const form = reactive({
  tanggal_kunjungan: null as Date | null,
  hasil_kunjungan: "",
  nama_pic: "",
  nomor_pic: "",
  tindak_lanjut: "",
  tanggal_follow_up: null as Date | null,
  latitude: null as number | null,
  longitude: null as number | null,
});

const projectStatusId = ref<number | null>(null);
const foto = ref<File | null>(null);
const fotoError = ref("");
const lampiran = ref<File | null>(null);
const lampiranError = ref("");

const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});
const createdId = ref<number | null>(null);
const initialSnapshot = ref("");
const allowLeave = ref(false);

const isEdit = computed(() => lkh.value !== null);
const readonly = computed(() => isLkhDone(lkh.value));
const pageTitle = computed(() => (readonly.value ? "Detail LKH" : isEdit.value ? "Edit LKH" : "Isi LKH"));
const existingFoto = computed(() => attachments.value.find((item) => item.jenis === "FOTO") ?? null);
const existingLampiran = computed(() => attachments.value.find((item) => item.jenis === "LAMPIRAN") ?? null);

const customerName = computed(() => {
  if (!rkh.value) return "";
  const customer = customers.value.find((item) => item.id === rkh.value?.customer_id);
  return customer?.nama_instansi ?? `ID ${rkh.value.customer_id}`;
});

const project = computed(() => {
  if (!rkh.value) return null;
  return projects.value.find((item) => item.id === rkh.value?.project_id) ?? null;
});

const projectName = computed(() => {
  if (!rkh.value) return "";
  return project.value?.nama_project ?? `ID ${rkh.value.project_id}`;
});

const projectStatus = computed(() => project.value?.status_rel ?? null);

interface ProjectStatusOption {
  value: number;
  label: string;
  color: string | null;
}

const projectStatusOptions = computed<ProjectStatusOption[]>(() => {
  const options = projectStatuses.value
    .filter((status) => status.is_active)
    .sort((a, b) => a.urutan - b.urutan)
    .map((status) => ({ value: status.id, label: status.nama, color: status.warna }));

  const current = project.value?.status_id;
  if (current != null && !options.some((option) => option.value === current)) {
    options.unshift({
      value: current,
      label: projectStatus.value?.nama ?? "Status nonaktif",
      color: projectStatus.value?.warna ?? null,
    });
  }

  return options;
});

const clientErrors = computed<Record<Field, string>>(() => ({
  tanggal_kunjungan: form.tanggal_kunjungan ? "" : "Tanggal kunjungan wajib diisi",
  hasil_kunjungan: form.hasil_kunjungan.trim() ? "" : "Hasil kunjungan wajib diisi",
  nama_pic: form.nama_pic.trim() ? "" : "Nama PIC wajib diisi",
  nomor_pic: !form.nomor_pic.trim()
    ? "Nomor PIC wajib diisi"
    : /^\d+$/.test(form.nomor_pic.trim())
      ? ""
      : "Nomor PIC hanya boleh berisi angka",
  foto: foto.value || existingFoto.value ? "" : "Foto wajib diunggah",
  file_lampiran: "",
  tindak_lanjut: "",
  tanggal_follow_up: "",
  project_status: "",
  location: "",
}));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function snapshot() {
  return JSON.stringify([
    form.tanggal_kunjungan ? toDateString(form.tanggal_kunjungan) : null,
    form.hasil_kunjungan,
    form.nama_pic,
    form.nomor_pic,
    form.tindak_lanjut,
    form.tanggal_follow_up ? toDateString(form.tanggal_follow_up) : null,
    form.latitude,
    form.longitude,
    projectStatusId.value,
    foto.value?.name ?? null,
    lampiran.value?.name ?? null,
  ]);
}

const dirty = computed(
  () =>
    rkh.value !== null &&
    !loading.value &&
    !readonly.value &&
    !allowLeave.value &&
    snapshot() !== initialSnapshot.value,
);

function resetForm() {
  foto.value = null;
  fotoError.value = "";
  lampiran.value = null;
  lampiranError.value = "";
  createdId.value = null;
  form.tanggal_kunjungan = parseDateString(lkh.value?.tanggal_kunjungan) ?? new Date();
  form.hasil_kunjungan = lkh.value?.hasil_kunjungan ?? "";
  form.nama_pic = lkh.value?.nama_pic ?? "";
  form.nomor_pic = lkh.value?.nomor_pic ?? "";
  form.tindak_lanjut = lkh.value?.tindak_lanjut ?? "";
  form.tanggal_follow_up = parseDateString(lkh.value?.tanggal_follow_up ?? undefined) ?? null;
  form.latitude = lkh.value?.latitude ?? null;
  form.longitude = lkh.value?.longitude ?? null;
  projectStatusId.value = project.value?.status_id ?? null;
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
  initialSnapshot.value = snapshot();
}

async function loadAttachments() {
  attachments.value = [];
  if (!lkh.value) return;

  try {
    attachments.value = await getAttachments(lkh.value.id);
  } catch {
    attachments.value = [];
  }
}

async function load() {
  const id = rkhId.value;

  loading.value = true;
  loadError.value = "";
  rkh.value = null;
  lkh.value = null;
  attachments.value = [];

  if (!Number.isInteger(id) || id <= 0) {
    loadError.value = "RKH tidak valid";
    loading.value = false;
    return;
  }

  try {
    const [rkhData, lkhList, customerData, projectData, statusData] = await Promise.all([
      getRkhById(id),
      getLkh(),
      getCustomers(),
      getProjects(),
      getProjectStatuses().catch(() => [] as ProjectStatus[]),
    ]);

    if (auth.user?.role === "SALES" && rkhData.sales_id !== auth.user.id) {
      loadError.value = "Anda tidak memiliki akses ke kegiatan ini";
      return;
    }

    rkh.value = rkhData;
    lkh.value = lkhList.find((item) => item.rkh_id === id) ?? null;
    customers.value = customerData;
    projects.value = projectData;
    projectStatuses.value = statusData;
    resetForm();
    await loadAttachments();
  } catch (error) {
    loadError.value = getErrorMessage(error, "Gagal memuat data LKH");
  } finally {
    loading.value = false;
  }
}

watch(rkhId, load, { immediate: true });

function onNomorPicBeforeInput(event: Event) {
  const data = (event as InputEvent).data;
  if (data && /\D/.test(data)) event.preventDefault();
}

function goBack() {
  router.push(LIST_PATH);
}

async function onSubmit() {
  if (readonly.value || !rkh.value) return;
  submitted.value = true;

  if (Object.values(clientErrors.value).some(Boolean)) return;
  if (fotoError.value || lampiranError.value) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    const payload = {
      tanggal_kunjungan: toDateString(form.tanggal_kunjungan as Date),
      hasil_kunjungan: form.hasil_kunjungan.trim(),
      nama_pic: form.nama_pic.trim(),
      nomor_pic: form.nomor_pic.trim(),
      tindak_lanjut: form.tindak_lanjut.trim() || null,
      tanggal_follow_up: form.tanggal_follow_up ? toDateString(form.tanggal_follow_up) : null,
      latitude: form.latitude,
      longitude: form.longitude,
    };

    let id = lkh.value?.id ?? createdId.value;

    if (id === null) {
      const created = await createLkh({ rkh_id: rkh.value.id, ...payload });
      id = created.id;
      createdId.value = id;
    } else {
      await updateLkh(id, payload);
    }

    if (foto.value) await uploadAttachment(id, foto.value, "FOTO");
    if (lampiran.value) await uploadAttachment(id, lampiran.value, "LAMPIRAN");

    const targetProject = project.value;
    if (targetProject && projectStatusId.value !== (targetProject.status_id ?? null)) {
      try {
        await updateProject(targetProject.id, { status_id: projectStatusId.value });
        projects.value = await getProjects();
      } catch (error) {
        formError.value = `LKH tersimpan, tetapi status project gagal diubah: ${getErrorMessage(error, "terjadi kesalahan")}`;
        return;
      }
    }

    await updateLkh(id, { status_lkh: LKH_DONE });

    allowLeave.value = true;
    await router.push(LIST_PATH);
  } catch (error) {
    const errors = getFieldErrors(error);
    const known: Record<string, string> = {};

    for (const [key, message] of Object.entries(errors)) {
      if (key === "latitude" || key === "longitude") known.location = message;
      else if (serverKeys.includes(key as Field)) known[key] = message;
    }

    serverErrors.value = known;
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, "Gagal menyimpan LKH");
    }
  } finally {
    saving.value = false;
  }
}

onBeforeRouteLeave(() => {
  if (!dirty.value) return true;

  return new Promise<boolean>((resolve) => {
    confirm.require({
      header: "Tinggalkan halaman?",
      message: "Perubahan yang belum disimpan akan hilang.",
      icon: "pi pi-exclamation-triangle",
      rejectProps: {
        label: "Tetap di sini",
        severity: "secondary",
        variant: "text",
      },
      acceptProps: {
        label: "Tinggalkan",
        severity: "danger",
      },
      accept: () => resolve(true),
      reject: () => resolve(false),
      onHide: () => resolve(false),
    });
  });
});

function onBeforeUnload(event: BeforeUnloadEvent) {
  if (!dirty.value) return;
  event.preventDefault();
  event.returnValue = "";
}

onMounted(() => window.addEventListener("beforeunload", onBeforeUnload));
onBeforeUnmount(() => window.removeEventListener("beforeunload", onBeforeUnload));
</script>

<template>
  <div class="mx-auto flex w-full max-w-4xl flex-col gap-4">
    <div>
      <Button
        icon="pi pi-arrow-left"
        label="Kembali ke daftar LKH"
        variant="text"
        severity="secondary"
        size="small"
        :disabled="saving"
        @click="goBack"
      />
    </div>

    <div
      v-if="loading"
      class="flex items-center justify-center gap-3 rounded-xl border border-line bg-card p-12 text-sm text-fg-muted"
    >
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat data kegiatan...
    </div>

    <Message v-else-if="loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <section v-else-if="rkh" class="rounded-xl border border-line bg-card">
      <div class="border-b border-line p-4 sm:p-5">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 class="font-semibold">{{ pageTitle }}</h2>
            <p class="mt-1 text-sm text-fg-muted">{{ rkh.judul_kegiatan }}</p>
          </div>

          <span
            v-if="lkh"
            class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
            :class="
              readonly
                ? 'bg-green-500/10 text-green-700 dark:text-green-400'
                : 'bg-amber-500/10 text-amber-700 dark:text-amber-400'
            "
          >
            {{ readonly ? "Done" : "Open" }}
          </span>
        </div>

        <dl class="mt-4 grid gap-3 text-sm sm:grid-cols-3">
          <div>
            <dt class="text-xs text-fg-muted">Customer</dt>
            <dd class="mt-0.5 font-medium">{{ customerName }}</dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">Project</dt>
            <dd class="mt-0.5 flex flex-wrap items-center gap-2 font-medium">
              <span>{{ projectName }}</span>
              <span
                v-if="projectStatus"
                class="inline-flex items-center rounded-md border border-line px-2 py-0.5 text-xs font-medium"
                :style="
                  projectStatus.warna
                    ? {
                        backgroundColor: projectStatus.warna,
                        color: readableTextColor(projectStatus.warna),
                        borderColor: projectStatus.warna,
                      }
                    : undefined
                "
              >
                {{ projectStatus.nama }}
              </span>
            </dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">Tanggal rencana</dt>
            <dd class="mt-0.5 font-medium">{{ formatDate(rkh.tanggal_rencana) }}</dd>
          </div>
        </dl>
      </div>

      <form
        id="lkh-form"
        class="grid gap-4 p-4 sm:grid-cols-2 sm:p-5"
        novalidate
        @submit.prevent="onSubmit"
      >
        <Message v-if="formError" class="sm:col-span-2" severity="error" size="small">{{ formError }}</Message>

        <Message v-if="readonly" class="sm:col-span-2" severity="info" size="small">
          LKH sudah Done dan tidak bisa diedit. Kembalikan status dari tabel untuk mengubahnya.
        </Message>

        <LkhFormField label="Tanggal kunjungan" for-id="lkh-tanggal" required :error="fieldError('tanggal_kunjungan')">
          <DatePicker
            v-model="form.tanggal_kunjungan"
            input-id="lkh-tanggal"
            date-format="dd/mm/yy"
            show-icon
            fluid
            :disabled="readonly"
            :invalid="!!fieldError('tanggal_kunjungan')"
          />
        </LkhFormField>

        <LkhFormField label="Tanggal follow up" for-id="lkh-follow-up" optional :error="fieldError('tanggal_follow_up')">
          <DatePicker
            v-model="form.tanggal_follow_up"
            input-id="lkh-follow-up"
            date-format="dd/mm/yy"
            show-icon
            :show-button-bar="!readonly"
            fluid
            :disabled="readonly"
            :invalid="!!fieldError('tanggal_follow_up')"
          />
        </LkhFormField>

        <LkhFormField label="Nama PIC" for-id="lkh-nama-pic" required :error="fieldError('nama_pic')">
          <InputText
            id="lkh-nama-pic"
            v-model="form.nama_pic"
            autocomplete="off"
            fluid
            :readonly="readonly"
            :invalid="!!fieldError('nama_pic')"
          />
        </LkhFormField>

        <LkhFormField label="Nomor PIC" for-id="lkh-nomor-pic" required :error="fieldError('nomor_pic')">
          <InputText
            id="lkh-nomor-pic"
            v-model="form.nomor_pic"
            inputmode="numeric"
            pattern="[0-9]*"
            maxlength="15"
            autocomplete="off"
            fluid
            :readonly="readonly"
            :invalid="!!fieldError('nomor_pic')"
            @beforeinput="onNomorPicBeforeInput"
          />
        </LkhFormField>

        <LkhFormField
          class="sm:col-span-2"
          label="Hasil kunjungan"
          for-id="lkh-hasil"
          required
          :error="fieldError('hasil_kunjungan')"
        >
          <Textarea
            id="lkh-hasil"
            v-model="form.hasil_kunjungan"
            rows="4"
            auto-resize
            fluid
            :readonly="readonly"
            :invalid="!!fieldError('hasil_kunjungan')"
          />
        </LkhFormField>

        <LkhFormField
          class="sm:col-span-2"
          label="Tindak lanjut"
          for-id="lkh-tindak-lanjut"
          optional
          :error="fieldError('tindak_lanjut')"
        >
          <Textarea
            id="lkh-tindak-lanjut"
            v-model="form.tindak_lanjut"
            rows="3"
            auto-resize
            fluid
            :readonly="readonly"
            :invalid="!!fieldError('tindak_lanjut')"
          />
        </LkhFormField>

        <LkhFormField
          class="sm:col-span-2"
          label="Status project"
          for-id="lkh-project-status"
          optional
          :error="fieldError('project_status')"
        >
          <Select
            v-model="projectStatusId"
            input-id="lkh-project-status"
            :options="projectStatusOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih status project"
            show-clear
            fluid
            :disabled="saving || readonly"
            empty-message="Daftar status tidak tersedia"
          >
            <template #option="{ option }">
              <div class="flex items-center gap-2.5">
                <span
                  class="size-3 shrink-0 rounded-full border border-line"
                  :style="{ backgroundColor: option.color ?? 'transparent' }"
                />
                <span>{{ option.label }}</span>
              </div>
            </template>
            <template #value="{ value, placeholder }">
              <div v-if="value != null" class="flex items-center gap-2.5">
                <span
                  class="size-3 shrink-0 rounded-full border border-line"
                  :style="{
                    backgroundColor: projectStatusOptions.find((option) => option.value === value)?.color ?? 'transparent',
                  }"
                />
                <span>{{ projectStatusOptions.find((option) => option.value === value)?.label ?? "-" }}</span>
              </div>
              <span v-else class="text-fg-muted">{{ placeholder }}</span>
            </template>
          </Select>
        </LkhFormField>

        <LkhLocationField
          class="sm:col-span-2"
          v-model:latitude="form.latitude"
          v-model:longitude="form.longitude"
          :disabled="saving || readonly"
          :error="fieldError('location')"
        />

        <LkhFotoField
          v-model="foto"
          v-model:file-error="fotoError"
          :disabled="saving"
          :readonly="readonly"
          :attachment="existingFoto"
          :error="fieldError('foto')"
        />

        <LkhLampiranField
          v-model="lampiran"
          v-model:file-error="lampiranError"
          :disabled="saving"
          :readonly="readonly"
          :attachment="existingLampiran"
          :error="fieldError('file_lampiran')"
        />
      </form>

      <div class="flex justify-end gap-2 border-t border-line p-4 sm:px-5">
        <Button
          :label="readonly ? 'Kembali' : 'Batal'"
          variant="text"
          severity="secondary"
          :disabled="saving"
          @click="goBack"
        />
        <Button
          v-if="!readonly"
          type="submit"
          form="lkh-form"
          :label="isEdit ? 'Simpan perubahan' : 'Simpan'"
          :loading="saving"
        />
      </div>
    </section>
  </div>
</template>