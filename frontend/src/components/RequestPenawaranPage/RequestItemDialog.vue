<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Button from 'primevue/button'
import Message from 'primevue/message'
import Select from 'primevue/select'

import {
  createRequestItem,
  updateRequestItem,
  type RequestItem,
  type RequestItemInput,
  type RequestItemUpdate,
} from '../../api/requestPenawaran'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

const props = defineProps<{
  requestId: number
  /** Diisi = mode edit data barang. Kosong = mode tambah barang. */
  item?: RequestItem | null
  /** Tidak dipakai lagi di dialog ini (harga diatur lewat tabel), dibiarkan agar parent tidak error. */
  canEditCost?: boolean
}>()

const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

type Field =
  | 'nama_barang'
  | 'merk'
  | 'tkdn'
  | 'tkdn_persen'
  | 'spesifikasi'
  | 'catatan_sales'
  | 'jumlah'
  | 'satuan'

const form = reactive({
  nama_barang: '',
  merk: '',
  tkdn: '',
  tkdn_persen: null as number | null,
  spesifikasi: '',
  catatan_sales: '',
  jumlah: 1 as number | null,
  satuan: 'Unit',
})

const tkdnOptions = [
  { label: 'TKDN', value: 'TKDN' },
  { label: 'NON TKDN', value: 'NON TKDN' },
]

const isTkdn = computed(() => form.tkdn === 'TKDN')
const isEdit = computed(() => !!props.item)

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const clientErrors = computed<Partial<Record<Field, string>>>(() => ({
  nama_barang: form.nama_barang.trim() ? '' : 'Nama barang wajib diisi',
  jumlah: form.jumlah !== null && form.jumlah > 0 ? '' : 'Jumlah minimal 1',
  satuan: form.satuan.trim() ? '' : 'Satuan wajib diisi',
  tkdn_persen:
    isTkdn.value && form.tkdn_persen !== null && (form.tkdn_persen < 0 || form.tkdn_persen > 100)
      ? 'Persentase TKDN harus antara 0 sampai 100'
      : '',
}))

const hasClientErrors = computed(() => Object.values(clientErrors.value).some(Boolean))

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '') || ''
}

function toNumber(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === '') return null

  const number = Number(value)
  return Number.isNaN(number) ? null : number
}

// Jika status bukan TKDN, persentase harus dikosongkan.
watch(
  () => form.tkdn,
  (value) => {
    if (value !== 'TKDN') {
      form.tkdn_persen = null
      delete serverErrors.value.tkdn_persen
    }
  },
)

watch(visible, (value) => {
  if (!value) return

  form.nama_barang = props.item?.nama_barang ?? ''
  form.merk = props.item?.merk ?? ''
  form.tkdn = props.item?.tkdn ?? ''
  form.tkdn_persen = toNumber(props.item?.tkdn_persen)
  form.spesifikasi = props.item?.spesifikasi ?? ''
  form.catatan_sales = props.item?.catatan_sales ?? ''
  form.jumlah = props.item ? toNumber(props.item.jumlah) : 1
  form.satuan = props.item?.satuan ?? 'Unit'

  // Hindari mempertahankan persentase jika status bukan TKDN.
  if (form.tkdn !== 'TKDN') {
    form.tkdn_persen = null
  }

  submitted.value = false
  formError.value = ''
  serverErrors.value = {}
})

function buildCreatePayload(): RequestItemInput {
  const payload: RequestItemInput = {
    nama_barang: form.nama_barang.trim(),
    jumlah: form.jumlah as number,
    satuan: form.satuan.trim(),
  }

  if (form.merk.trim()) payload.merk = form.merk.trim()
  if (form.tkdn.trim()) payload.tkdn = form.tkdn.trim()

  // Kirim persentase hanya jika statusnya TKDN.
  if (isTkdn.value && form.tkdn_persen !== null) payload.tkdn_persen = form.tkdn_persen

  if (form.spesifikasi.trim()) payload.spesifikasi = form.spesifikasi.trim()
  if (form.catatan_sales.trim()) payload.catatan_sales = form.catatan_sales.trim()

  return payload
}

// Hanya kirim field yang berubah. Field teks yang dikosongkan dikirim sebagai null.
function buildUpdatePayload(item: RequestItem): RequestItemUpdate {
  const payload: RequestItemUpdate = {}

  const nama = form.nama_barang.trim()
  if (nama !== item.nama_barang) payload.nama_barang = nama

  const merk = form.merk.trim() || null
  if (merk !== (item.merk || null)) payload.merk = merk

  const tkdn = form.tkdn.trim() || null
  if (tkdn !== (item.tkdn || null)) payload.tkdn = tkdn

  const persen = isTkdn.value ? form.tkdn_persen : null
  if (persen !== toNumber(item.tkdn_persen)) payload.tkdn_persen = persen

  const spesifikasi = form.spesifikasi.trim() || null
  if (spesifikasi !== (item.spesifikasi || null)) payload.spesifikasi = spesifikasi

  const catatan = form.catatan_sales.trim() || null
  if (catatan !== (item.catatan_sales || null)) payload.catatan_sales = catatan

  if (form.jumlah !== toNumber(item.jumlah)) payload.jumlah = form.jumlah as number

  const satuan = form.satuan.trim()
  if (satuan !== item.satuan) payload.satuan = satuan

  return payload
}

async function onSubmit() {
  submitted.value = true

  if (hasClientErrors.value) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    if (props.item) {
      const payload = buildUpdatePayload(props.item)

      if (Object.keys(payload).length > 0) {
        await updateRequestItem(
          props.requestId,
          props.item.id,
          payload as unknown as Parameters<typeof updateRequestItem>[2],
        )
      }
    } else {
      await createRequestItem(props.requestId, buildCreatePayload())
    }

    visible.value = false
    emit('saved')
  } catch (error) {
    const errors = getFieldErrors(error)
    serverErrors.value = errors

    if (Object.keys(errors).length === 0) {
      formError.value = getErrorMessage(error, 'Gagal menyimpan barang')
    }
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    :header="isEdit ? 'Ubah barang' : 'Tambah barang'"
    class="w-[calc(100vw-2rem)] max-w-2xl"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="request-item-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="item-nama" class="text-sm font-medium">
            Nama barang <span class="text-red-500">*</span>
          </label>
          <InputText
            id="item-nama"
            v-model="form.nama_barang"
            autocomplete="off"
            fluid
            :invalid="!!fieldError('nama_barang')"
          />
          <Message v-if="fieldError('nama_barang')" severity="error" size="small" variant="simple">
            {{ fieldError('nama_barang') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="item-merk" class="text-sm font-medium">Merk</label>
          <InputText
            id="item-merk"
            v-model="form.merk"
            autocomplete="off"
            fluid
            :invalid="!!fieldError('merk')"
          />
          <Message v-if="fieldError('merk')" severity="error" size="small" variant="simple">
            {{ fieldError('merk') }}
          </Message>
        </div>

        <!-- Status TKDN dan persentase -->
        <div class="grid gap-4" :class="isTkdn ? 'sm:grid-cols-2' : 'sm:grid-cols-1'">
          <div class="flex flex-col gap-1.5" :class="!isTkdn ? 'sm:col-span-2' : ''">
            <label for="item-tkdn" class="text-sm font-medium">Status TKDN</label>

            <Select
              id="item-tkdn"
              v-model="form.tkdn"
              :options="tkdnOptions"
              option-label="label"
              option-value="value"
              placeholder="Pilih status TKDN"
              fluid
              :invalid="!!fieldError('tkdn')"
            />

            <Message v-if="fieldError('tkdn')" severity="error" size="small" variant="simple">
              {{ fieldError('tkdn') }}
            </Message>
          </div>

          <div v-if="isTkdn" class="flex flex-col gap-1.5">
            <label for="item-tkdn-persen" class="text-sm font-medium">Nilai TKDN (%)</label>

            <InputNumber
              v-model="form.tkdn_persen"
              input-id="item-tkdn-persen"
              suffix=" %"
              placeholder="Masukkan persentase"
              :min="0"
              :max="100"
              :min-fraction-digits="0"
              :max-fraction-digits="2"
              fluid
              :invalid="!!fieldError('tkdn_persen')"
            />

            <Message v-if="fieldError('tkdn_persen')" severity="error" size="small" variant="simple">
              {{ fieldError('tkdn_persen') }}
            </Message>
          </div>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="item-jumlah" class="text-sm font-medium">
            Jumlah <span class="text-red-500">*</span>
          </label>
          <InputNumber
            v-model="form.jumlah"
            input-id="item-jumlah"
            :min="1"
            :max-fraction-digits="2"
            fluid
            :invalid="!!fieldError('jumlah')"
          />
          <Message v-if="fieldError('jumlah')" severity="error" size="small" variant="simple">
            {{ fieldError('jumlah') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="item-satuan" class="text-sm font-medium">
            Satuan <span class="text-red-500">*</span>
          </label>
          <InputText
            id="item-satuan"
            v-model="form.satuan"
            autocomplete="off"
            fluid
            :invalid="!!fieldError('satuan')"
          />
          <Message v-if="fieldError('satuan')" severity="error" size="small" variant="simple">
            {{ fieldError('satuan') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="item-spesifikasi" class="text-sm font-medium">Spesifikasi</label>
          <Textarea
            id="item-spesifikasi"
            v-model="form.spesifikasi"
            rows="3"
            auto-resize
            fluid
            :invalid="!!fieldError('spesifikasi')"
          />
          <Message v-if="fieldError('spesifikasi')" severity="error" size="small" variant="simple">
            {{ fieldError('spesifikasi') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="item-catatan" class="text-sm font-medium">Catatan sales</label>
          <Textarea
            id="item-catatan"
            v-model="form.catatan_sales"
            rows="2"
            auto-resize
            fluid
            :invalid="!!fieldError('catatan_sales')"
          />
          <Message v-if="fieldError('catatan_sales')" severity="error" size="small" variant="simple">
            {{ fieldError('catatan_sales') }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="request-item-form" label="Simpan" icon="pi pi-check" :loading="saving" />
    </template>
  </Dialog>
</template>