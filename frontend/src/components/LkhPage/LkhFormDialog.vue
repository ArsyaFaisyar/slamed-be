<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import DatePicker from "primevue/datepicker";
import InputText from "primevue/inputtext";
import Textarea from "primevue/textarea";
import Button from "primevue/button";
import Message from "primevue/message";
import {
  createLkh,
  updateLkh,
  uploadAttachment,
  getAttachments,
  isLkhDone,
  LKH_DONE,
  type Lkh,
  type LkhAttachment,
} from "../../api/lkh";
import { getErrorMessage, getFieldErrors } from "../../utils/error";
import { parseDateString, toDateString } from "../../utils/date";
import LkhFormField from "./LkhFormField.vue";
import LkhLocationField from "./LkhLocationField.vue";
import LkhFotoField from "./LkhFotoField.vue";
import LkhLampiranField from "./LkhLampiranField.vue";

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  rkhId: number | null;
  lkh: Lkh | null;
  contextTitle: string;
  contextDetail: string;
}>();

const emit = defineEmits<{ saved: [] }>();

type Field =
  | "tanggal_kunjungan"
  | "hasil_kunjungan"
  | "nama_pic"
  | "nomor_pic"
  | "foto"
  | "file_lampiran"
  | "tindak_lanjut"
  | "tanggal_follow_up"
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

const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const foto = ref<File | null>(null);
const fotoError = ref("");
const lampiran = ref<File | null>(null);
const lampiranError = ref("");

const attachments = ref<LkhAttachment[]>([]);
// Menyimpan id LKH yang sudah terbuat jika unggah file gagal, agar submit ulang tidak membuat LKH ganda.
const createdId = ref<number | null>(null);

const isEdit = computed(() => props.lkh !== null);
const readonly = computed(() => isLkhDone(props.lkh));
const existingFoto = computed(() => attachments.value.find((item) => item.jenis === "FOTO") ?? null);
const existingLampiran = computed(() => attachments.value.find((item) => item.jenis === "LAMPIRAN") ?? null);

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
  location: "",
}));

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function clearFiles() {
  foto.value = null;
  fotoError.value = "";
  lampiran.value = null;
  lampiranError.value = "";
}

async function loadAttachments() {
  attachments.value = [];
  if (!props.lkh) return;

  const lkhId = props.lkh.id;
  try {
    const items = await getAttachments(lkhId);
    if (props.lkh?.id === lkhId) attachments.value = items;
  } catch {
    attachments.value = [];
  }
}

function resetForm() {
  clearFiles();
  createdId.value = null;
  form.tanggal_kunjungan = parseDateString(props.lkh?.tanggal_kunjungan) ?? new Date();
  form.hasil_kunjungan = props.lkh?.hasil_kunjungan ?? "";
  form.nama_pic = props.lkh?.nama_pic ?? "";
  form.nomor_pic = props.lkh?.nomor_pic ?? "";
  form.tindak_lanjut = props.lkh?.tindak_lanjut ?? "";
  form.tanggal_follow_up = parseDateString(props.lkh?.tanggal_follow_up ?? undefined) ?? null;
  form.latitude = props.lkh?.latitude ?? null;
  form.longitude = props.lkh?.longitude ?? null;
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

watch(
  () => [visible.value, props.lkh, props.rkhId] as const,
  ([isVisible]) => {
    if (isVisible) {
      resetForm();
      loadAttachments();
    } else {
      clearFiles();
      attachments.value = [];
    }
  },
  { immediate: true },
);

// Blokir karakter non-angka sebelum masuk ke input (termasuk saat paste).
function onNomorPicBeforeInput(event: Event) {
  const data = (event as InputEvent).data;
  if (data && /\D/.test(data)) event.preventDefault();
}

async function onSubmit() {
  if (readonly.value) return;
  submitted.value = true;

  if (!props.lkh && props.rkhId === null) return;
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

    let id = props.lkh?.id ?? createdId.value;

    if (id === null) {
      const created = await createLkh({ rkh_id: props.rkhId as number, ...payload });
      id = created.id;
      createdId.value = id;
    } else {
      await updateLkh(id, payload);
    }

    if (foto.value) await uploadAttachment(id, foto.value, "FOTO");
    if (lampiran.value) await uploadAttachment(id, lampiran.value, "LAMPIRAN");

    await updateLkh(id, { status_lkh: LKH_DONE });

    emit("saved");
    visible.value = false;
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
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    :header="readonly ? 'Detail LKH' : isEdit ? 'Edit LKH' : 'Isi LKH'"
    class="w-[calc(100vw-2rem)] max-w-lg"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="lkh-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <Message v-if="readonly" severity="info" size="small">
        LKH sudah Done dan tidak bisa diedit. Kembalikan status dari tabel untuk mengubahnya.
      </Message>

      <div class="rounded-lg border border-line bg-sidebar/50 p-3">
        <p class="text-xs text-fg-muted">Kegiatan RKH</p>
        <p class="mt-0.5 text-sm font-medium">{{ contextTitle }}</p>
        <p class="mt-0.5 text-xs text-fg-muted">{{ contextDetail }}</p>
      </div>

      <LkhFormField label="Tanggal kunjungan" for-id="lkh-tanggal" :error="fieldError('tanggal_kunjungan')">
        <DatePicker v-model="form.tanggal_kunjungan" input-id="lkh-tanggal" date-format="dd/mm/yy" show-icon fluid :disabled="readonly" :invalid="!!fieldError('tanggal_kunjungan')" />
      </LkhFormField>

      <div class="grid gap-4 sm:grid-cols-2">
        <LkhFormField label="Nama PIC" for-id="lkh-nama-pic" :error="fieldError('nama_pic')">
          <InputText id="lkh-nama-pic" v-model="form.nama_pic" autocomplete="off" fluid :readonly="readonly" :invalid="!!fieldError('nama_pic')" />
        </LkhFormField>

        <LkhFormField label="Nomor PIC" for-id="lkh-nomor-pic" :error="fieldError('nomor_pic')">
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
      </div>

      <LkhFormField label="Hasil kunjungan" for-id="lkh-hasil" :error="fieldError('hasil_kunjungan')">
        <Textarea id="lkh-hasil" v-model="form.hasil_kunjungan" rows="3" auto-resize fluid :readonly="readonly" :invalid="!!fieldError('hasil_kunjungan')" />
      </LkhFormField>

      <LkhFormField label="Tindak lanjut" for-id="lkh-tindak-lanjut" optional :error="fieldError('tindak_lanjut')">
        <Textarea id="lkh-tindak-lanjut" v-model="form.tindak_lanjut" rows="3" auto-resize fluid :readonly="readonly" :invalid="!!fieldError('tindak_lanjut')" />
      </LkhFormField>

      <LkhFormField label="Tanggal follow up" for-id="lkh-follow-up" optional :error="fieldError('tanggal_follow_up')">
        <DatePicker v-model="form.tanggal_follow_up" input-id="lkh-follow-up" date-format="dd/mm/yy" show-icon :show-button-bar="!readonly" fluid :disabled="readonly" :invalid="!!fieldError('tanggal_follow_up')" />
      </LkhFormField>

      <LkhLocationField
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

    <template #footer>
      <Button :label="readonly ? 'Tutup' : 'Batal'" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button v-if="!readonly" type="submit" form="lkh-form" :label="isEdit ? 'Simpan perubahan' : 'Simpan'" :loading="saving" />
    </template>
  </Dialog>
</template>