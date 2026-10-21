<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import DatePicker from "primevue/datepicker";
import Textarea from "primevue/textarea";
import Button from "primevue/button";
import Message from "primevue/message";
import {
  attachmentName,
  createLkh,
  getLkhAttachmentBlob,
  getLkhAttachments,
  updateLkh,
  uploadLkhAttachment,
  type Lkh,
} from "../../api/lkh";
import { getErrorMessage, getFieldErrors } from "../../utils/error";
import { parseDateString, toDateString } from "../../utils/date";

const MAX_FILE_SIZE = 10 * 1024 * 1024;
const ACCEPT = "image/*,application/pdf";

interface PendingFile {
  key: string;
  file: File;
  previewUrl: string | null;
  status: "pending" | "uploading" | "done" | "failed";
  error: string;
}

interface ExistingFile {
  id: number;
  name: string;
  url: string | null;
  isImage: boolean;
  failed: boolean;
}

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  rkhId: number | null;
  lkh: Lkh | null;
  contextTitle: string;
  contextDetail: string;
}>();

const emit = defineEmits<{ saved: [] }>();

type Field = "tanggal_kunjungan" | "hasil_kunjungan" | "tindak_lanjut" | "location";

const form = reactive({
  tanggal_kunjungan: null as Date | null,
  hasil_kunjungan: "",
  tindak_lanjut: "",
  latitude: null as number | null,
  longitude: null as number | null,
});

const submitted = ref(false);
const saving = ref(false);
const locating = ref(false);
const locationError = ref("");
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const workingLkhId = ref<number | null>(null);
const pending = ref<PendingFile[]>([]);
const existing = ref<ExistingFile[]>([]);
const loadingExisting = ref(false);
const attachmentError = ref("");
const fileError = ref("");
const fileInput = ref<HTMLInputElement | null>(null);
let fileCounter = 0;

const isEdit = computed(() => workingLkhId.value !== null);
const hasLocation = computed(() => form.latitude !== null && form.longitude !== null);
const mapsUrl = computed(() => `https://www.google.com/maps?q=${form.latitude},${form.longitude}`);

const clientErrors = computed<Record<Field, string>>(() => ({
  tanggal_kunjungan: form.tanggal_kunjungan ? "" : "Tanggal kunjungan wajib diisi",
  hasil_kunjungan: form.hasil_kunjungan.trim() ? "" : "Hasil kunjungan wajib diisi",
  tindak_lanjut: form.tindak_lanjut.trim() ? "" : "Tindak lanjut wajib diisi",
  location: hasLocation.value ? "" : "Lokasi wajib diambil",
}));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function revokeAll() {
  for (const item of existing.value) {
    if (item.url) URL.revokeObjectURL(item.url);
  }
  for (const item of pending.value) {
    if (item.previewUrl) URL.revokeObjectURL(item.previewUrl);
  }
  existing.value = [];
  pending.value = [];
}

async function loadExisting(lkhId: number) {
  loadingExisting.value = true;
  attachmentError.value = "";

  try {
    const list = await getLkhAttachments(lkhId);

    existing.value = await Promise.all(
      list.map(async (attachment): Promise<ExistingFile> => {
        const name = attachmentName(attachment);
        try {
          const blob = await getLkhAttachmentBlob(attachment.id);
          return {
            id: attachment.id,
            name,
            url: URL.createObjectURL(blob),
            isImage: blob.type.startsWith("image/"),
            failed: false,
          };
        } catch {
          return { id: attachment.id, name, url: null, isImage: false, failed: true };
        }
      }),
    );
  } catch (error) {
    attachmentError.value = getErrorMessage(error, "Gagal memuat lampiran");
  } finally {
    loadingExisting.value = false;
  }
}

function resetForm() {
  revokeAll();
  form.tanggal_kunjungan = parseDateString(props.lkh?.tanggal_kunjungan) ?? new Date();
  form.hasil_kunjungan = props.lkh?.hasil_kunjungan ?? "";
  form.tindak_lanjut = props.lkh?.tindak_lanjut ?? "";
  form.latitude = props.lkh?.latitude ?? null;
  form.longitude = props.lkh?.longitude ?? null;
  workingLkhId.value = props.lkh?.id ?? null;
  submitted.value = false;
  locationError.value = "";
  formError.value = "";
  attachmentError.value = "";
  fileError.value = "";
  serverErrors.value = {};

  if (props.lkh) loadExisting(props.lkh.id);
}

watch(
  () => [visible.value, props.lkh, props.rkhId] as const,
  ([isVisible]) => {
    if (isVisible) resetForm();
    else revokeAll();
  },
  { immediate: true },
);

onBeforeUnmount(revokeAll);

function openPicker() {
  fileInput.value?.click();
}

function onFilesSelected(event: Event) {
  const input = event.target as HTMLInputElement;
  const files = Array.from(input.files ?? []);
  input.value = "";
  fileError.value = "";

  const rejected: string[] = [];

  for (const file of files) {
    if (file.size > MAX_FILE_SIZE) {
      rejected.push(file.name);
      continue;
    }

    pending.value.push({
      key: String(++fileCounter),
      file,
      previewUrl: file.type.startsWith("image/") ? URL.createObjectURL(file) : null,
      status: "pending",
      error: "",
    });
  }

  if (rejected.length > 0) {
    fileError.value = `File melebihi 10 MB: ${rejected.join(", ")}`;
  }
}

function removePending(key: string) {
  const item = pending.value.find((entry) => entry.key === key);
  if (item?.previewUrl) URL.revokeObjectURL(item.previewUrl);
  pending.value = pending.value.filter((entry) => entry.key !== key);
}

function captureLocation() {
  locationError.value = "";

  if (!("geolocation" in navigator)) {
    locationError.value = "Browser tidak mendukung pengambilan lokasi";
    return;
  }

  locating.value = true;

  navigator.geolocation.getCurrentPosition(
    (position) => {
      form.latitude = Number(position.coords.latitude.toFixed(6));
      form.longitude = Number(position.coords.longitude.toFixed(6));
      locating.value = false;
    },
    (error) => {
      locating.value = false;
      if (error.code === error.PERMISSION_DENIED) {
        locationError.value = "Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan browser.";
      } else if (error.code === error.TIMEOUT) {
        locationError.value = "Pengambilan lokasi terlalu lama. Coba lagi.";
      } else {
        locationError.value = "Lokasi tidak tersedia. Coba lagi.";
      }
    },
    { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 },
  );
}

async function uploadPending(lkhId: number | null) {
  let failed = 0;

  for (const item of [...pending.value]) {
    if (item.status === "done") continue;

    if (lkhId === null) {
      item.status = "failed";
      item.error = "ID LKH tidak diterima dari server";
      failed++;
      continue;
    }

    item.status = "uploading";
    item.error = "";

    try {
      await uploadLkhAttachment(lkhId, item.file);
      item.status = "done";
    } catch (error) {
      item.status = "failed";
      item.error = getErrorMessage(error, "Gagal diunggah");
      failed++;
    }
  }

  return failed;
}

async function onSubmit() {
  submitted.value = true;

  if (workingLkhId.value === null && props.rkhId === null) return;
  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    const payload = {
      tanggal_kunjungan: toDateString(form.tanggal_kunjungan as Date),
      hasil_kunjungan: form.hasil_kunjungan.trim(),
      tindak_lanjut: form.tindak_lanjut.trim(),
      latitude: form.latitude as number,
      longitude: form.longitude as number,
    };

    if (workingLkhId.value !== null) {
      await updateLkh(workingLkhId.value, payload);
    } else {
      const created = await createLkh({ rkh_id: props.rkhId as number, ...payload });
      workingLkhId.value = typeof created?.id === "number" ? created.id : null;
      if (workingLkhId.value === null && pending.value.length === 0) {
        emit("saved");
        visible.value = false;
        return;
      }
    }
  } catch (error) {
    const errors = getFieldErrors(error);
    const known: Record<string, string> = {};

    for (const [key, message] of Object.entries(errors)) {
      if (key === "latitude" || key === "longitude") known.location = message;
      else if (key === "tanggal_kunjungan" || key === "hasil_kunjungan" || key === "tindak_lanjut") known[key] = message;
    }

    serverErrors.value = known;
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, "Gagal menyimpan LKH");
    }
    saving.value = false;
    return;
  }

  const failed = await uploadPending(workingLkhId.value);
  saving.value = false;
  emit("saved");

  if (failed > 0) {
    formError.value = `LKH tersimpan, tetapi ${failed} lampiran gagal diunggah. Periksa file yang bertanda merah lalu coba lagi.`;
    return;
  }

  visible.value = false;
}
</script>

<template>
  <Dialog v-model:visible="visible" modal :header="isEdit ? 'Edit LKH' : 'Isi LKH'" class="w-[calc(100vw-2rem)] max-w-lg" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="lkh-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="rounded-lg border border-line bg-sidebar/50 p-3">
        <p class="text-xs text-fg-muted">Kegiatan RKH</p>
        <p class="mt-0.5 text-sm font-medium">{{ contextTitle }}</p>
        <p class="mt-0.5 text-xs text-fg-muted">{{ contextDetail }}</p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="lkh-tanggal" class="text-sm font-medium">Tanggal kunjungan</label>
        <DatePicker v-model="form.tanggal_kunjungan" input-id="lkh-tanggal" date-format="dd/mm/yy" show-icon fluid :invalid="!!fieldError('tanggal_kunjungan')" />
        <Message v-if="fieldError('tanggal_kunjungan')" severity="error" size="small" variant="simple">
          {{ fieldError("tanggal_kunjungan") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="lkh-hasil" class="text-sm font-medium">Hasil kunjungan</label>
        <Textarea id="lkh-hasil" v-model="form.hasil_kunjungan" rows="3" auto-resize fluid :invalid="!!fieldError('hasil_kunjungan')" />
        <Message v-if="fieldError('hasil_kunjungan')" severity="error" size="small" variant="simple">
          {{ fieldError("hasil_kunjungan") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="lkh-tindak-lanjut" class="text-sm font-medium">Tindak lanjut</label>
        <Textarea id="lkh-tindak-lanjut" v-model="form.tindak_lanjut" rows="3" auto-resize fluid :invalid="!!fieldError('tindak_lanjut')" />
        <Message v-if="fieldError('tindak_lanjut')" severity="error" size="small" variant="simple">
          {{ fieldError("tindak_lanjut") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <span class="text-sm font-medium">Lokasi</span>
        <div
          class="flex flex-wrap items-center gap-3 rounded-lg border p-3"
          :class="fieldError('location') ? 'border-red-500' : 'border-line'"
        >
          <Button
            type="button"
            :label="hasLocation ? 'Perbarui lokasi' : 'Ambil lokasi saat ini'"
            icon="pi pi-map-marker"
            size="small"
            severity="secondary"
            :loading="locating"
            :disabled="saving"
            @click="captureLocation"
          />

          <div v-if="hasLocation" class="text-sm">
            <p class="tabular-nums">{{ form.latitude }}, {{ form.longitude }}</p>
            <a :href="mapsUrl" target="_blank" rel="noopener" class="text-xs text-primary underline">Lihat di peta</a>
          </div>
          <span v-else class="text-sm text-fg-muted">Belum diambil</span>
        </div>
        <Message v-if="locationError" severity="error" size="small" variant="simple">
          {{ locationError }}
        </Message>
        <Message v-else-if="fieldError('location')" severity="error" size="small" variant="simple">
          {{ fieldError("location") }}
        </Message>
      </div>

      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between gap-3">
          <span class="text-sm font-medium">Lampiran</span>
          <Button
            type="button"
            label="Tambah file"
            icon="pi pi-paperclip"
            size="small"
            severity="secondary"
            :disabled="saving"
            @click="openPicker"
          />
        </div>

        <input ref="fileInput" type="file" class="hidden" multiple :accept="ACCEPT" @change="onFilesSelected" />

        <Message v-if="fileError" severity="error" size="small" variant="simple">{{ fileError }}</Message>
        <Message v-if="attachmentError" severity="error" size="small" variant="simple">{{ attachmentError }}</Message>

        <div v-if="loadingExisting" class="flex items-center gap-2 text-sm text-fg-muted">
          <i class="pi pi-spin pi-spinner" />
          Memuat lampiran...
        </div>

        <ul v-if="existing.length > 0 || pending.length > 0" class="grid grid-cols-2 gap-2 sm:grid-cols-3">
          <li v-for="item in existing" :key="`existing-${item.id}`" class="overflow-hidden rounded-lg border border-line">
            <a v-if="item.url" :href="item.url" target="_blank" rel="noopener" class="block">
              <img v-if="item.isImage" :src="item.url" :alt="item.name" class="aspect-square w-full object-cover" />
              <div v-else class="flex aspect-square w-full items-center justify-center bg-sidebar">
                <i class="pi pi-file text-2xl text-fg-muted" />
              </div>
            </a>
            <div v-else class="flex aspect-square w-full items-center justify-center bg-sidebar">
              <i class="pi pi-exclamation-triangle text-2xl text-red-500" />
            </div>
            <p class="truncate px-2 py-1 text-xs" :title="item.name">{{ item.name }}</p>
            <p v-if="item.failed" class="px-2 pb-1 text-xs text-red-600">Gagal dimuat</p>
          </li>

          <li
            v-for="item in pending"
            :key="item.key"
            class="relative overflow-hidden rounded-lg border"
            :class="item.status === 'failed' ? 'border-red-500' : 'border-line'"
          >
            <img v-if="item.previewUrl" :src="item.previewUrl" :alt="item.file.name" class="aspect-square w-full object-cover" />
            <div v-else class="flex aspect-square w-full items-center justify-center bg-sidebar">
              <i class="pi pi-file text-2xl text-fg-muted" />
            </div>
            <p class="truncate px-2 py-1 text-xs" :title="item.file.name">{{ item.file.name }}</p>
            <p v-if="item.status === 'failed'" class="px-2 pb-1 text-xs text-red-600">{{ item.error }}</p>

            <div v-if="item.status === 'uploading'" class="absolute inset-0 flex items-center justify-center bg-black/40">
              <i class="pi pi-spin pi-spinner text-xl text-white" />
            </div>

            <span v-if="item.status === 'done'" class="absolute left-1 top-1 inline-flex size-6 items-center justify-center rounded-full bg-green-500 text-white">
              <i class="pi pi-check text-xs" />
            </span>

            <Button
              v-if="!saving && item.status !== 'done'"
              type="button"
              icon="pi pi-times"
              size="small"
              rounded
              severity="secondary"
              class="absolute right-1 top-1"
              aria-label="Hapus file"
              @click="removePending(item.key)"
            />
          </li>
        </ul>

        <p v-else-if="!loadingExisting" class="text-xs text-fg-muted">Belum ada lampiran. Foto atau PDF, maksimal 10 MB per file.</p>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="lkh-form" :label="isEdit ? 'Simpan perubahan' : 'Simpan'" :loading="saving" />
    </template>
  </Dialog>
</template>