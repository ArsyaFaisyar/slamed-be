<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Dropdown from 'primevue/dropdown'
import Textarea from 'primevue/textarea'
import Button from 'primevue/button'
import Message from 'primevue/message'
import {
  createRequestItem,
  resolveGambarUrl,
  updateLinkMarketplace,
  updateRequestItem,
  uploadGambarItem,
  type RequestItem,
  type RequestItemInput,
  type RequestItemUpdate,
} from '../../api/requestPenawaran'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

const props = defineProps<{
  requestId: number
  item?: RequestItem | null
  /** true untuk PPIC: barang dari sales sebagian dikunci, harga diisi di tabel */
  restricted?: boolean
  /** true saat menambah barang tambahan (tidak masuk pagu/RAB) */
  extra?: boolean
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
  | 'link_marketplace'
  | 'gambar'

const MAX_GAMBAR_MB = 5
const TEXT_FIELDS = ['merk', 'tkdn', 'spesifikasi', 'catatan_sales'] as const
const TKDN_OPTIONS = [
  { label: 'TKDN', value: 'TKDN' },
  { label: 'NON TKDN', value: 'NON TKDN' },
]

function isNonTkdn(value: string | null | undefined) {
  return /^(non|tidak)/i.test((value ?? '').trim())
}

const form = reactive({
  nama_barang: '',
  merk: '',
  tkdn: '' as string | null,
  tkdn_persen: null as number | null,
  spesifikasi: '',
  catatan_sales: '',
  jumlah: 1 as number | null,
  satuan: 'Unit',
  link_marketplace: '',
})

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const gambarInput = ref<HTMLInputElement | null>(null)
const gambarFile = ref<File | null>(null)
const gambarPreview = ref('')
const createdItemId = ref<number | null>(null)

const showTkdnPersen = computed(() => form.tkdn === 'TKDN')

watch(
  () => form.tkdn,
  (val) => {
    if (val !== 'TKDN') {
      form.tkdn_persen = null
    }
  },
)

const isEdit = computed(() => !!props.item)
// Barang dari sales dikunci untuk PPIC; barang tambahan milik PPIC tidak dikunci
const lockExtra = computed(() => !!props.restricted && !!props.item && !props.item.is_tambahan)
const currentGambar = computed(() => gambarPreview.value || resolveGambarUrl(props.item?.gambar_path))

function isValidUrl(value: string) {
  try {
    const url = new URL(value)
    return url.protocol === 'http:' || url.protocol === 'https:'
  } catch {
    return false
  }
}

const clientErrors = computed<Partial<Record<Field, string>>>(() => ({
  nama_barang: form.nama_barang.trim() ? '' : 'Nama barang wajib diisi',
  jumlah: form.jumlah !== null && form.jumlah > 0 ? '' : 'Jumlah minimal 1',
  satuan: form.satuan.trim() ? '' : 'Satuan wajib diisi',
  tkdn_persen:
    showTkdnPersen.value && form.tkdn_persen !== null && (form.tkdn_persen < 0 || form.tkdn_persen > 100)
      ? 'Persentase 0 sampai 100'
      : '',
  link_marketplace:
    form.link_marketplace.trim() && !isValidUrl(form.link_marketplace.trim())
      ? 'Link harus diawali http:// atau https://'
      : '',
  gambar: !gambarFile.value
    ? ''
    : !gambarFile.value.type.startsWith('image/')
      ? 'File harus berupa gambar'
      : gambarFile.value.size > MAX_GAMBAR_MB * 1024 * 1024
        ? `Ukuran gambar maksimal ${MAX_GAMBAR_MB} MB`
        : '',
}))

const hasClientErrors = computed(() => Object.values(clientErrors.value).some(Boolean))

function limitPersen(event: { value?: number | string | null; originalEvent: Event }) {
  const value = typeof event.value === 'number' ? event.value : null
  if (value === null || value <= 100) return
  form.tkdn_persen = 100
  const target = event.originalEvent?.target as HTMLInputElement | null
  if (target) target.value = '100%'
}

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '') || ''
}

function toNumber(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === '') return null
  const number = Number(value)
  return Number.isNaN(number) ? null : number
}

function clearPreview() {
  if (gambarPreview.value) URL.revokeObjectURL(gambarPreview.value)
  gambarPreview.value = ''
}

function pickGambar() {
  gambarInput.value?.click()
}

function onGambarChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0] ?? null
  input.value = ''
  if (!file) return

  clearPreview()
  gambarFile.value = file
  gambarPreview.value = URL.createObjectURL(file)
  delete serverErrors.value.gambar
}

function removeGambar() {
  clearPreview()
  gambarFile.value = null
}

onBeforeUnmount(clearPreview)

watch(visible, (value) => {
  if (!value) return

  form.nama_barang = props.item?.nama_barang ?? ''
  form.merk = props.item?.merk ?? ''
  const rawTkdn = props.item?.tkdn?.trim() ?? ''
  if (rawTkdn) {
    form.tkdn = isNonTkdn(rawTkdn) ? 'NON TKDN' : 'TKDN'
  } else if (props.item?.tkdn_persen != null) {
    form.tkdn = 'TKDN'
  } else {
    form.tkdn = ''
  }
  form.tkdn_persen = form.tkdn === 'TKDN' ? toNumber(props.item?.tkdn_persen) : null
  form.spesifikasi = props.item?.spesifikasi ?? ''
  form.catatan_sales = props.item?.catatan_sales ?? ''
  form.jumlah = props.item ? toNumber(props.item.jumlah) : 1
  form.satuan = props.item?.satuan ?? 'Unit'
  form.link_marketplace = props.item?.link_marketplace ?? ''
  removeGambar()
  createdItemId.value = null
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
  if (form.tkdn?.trim()) payload.tkdn = form.tkdn.trim()
  if (form.tkdn === 'TKDN' && form.tkdn_persen !== null) payload.tkdn_persen = form.tkdn_persen
  if (form.spesifikasi.trim()) payload.spesifikasi = form.spesifikasi.trim()
  if (form.catatan_sales.trim()) payload.catatan_sales = form.catatan_sales.trim()
  if (props.extra) payload.is_tambahan = true

  return payload
}

// Dialog ini hanya mengubah data barang. Harga pagu, modal, dan jual
// hanya diubah lewat tabel di halaman detail, jadi tidak pernah dikirim dari sini.
function buildUpdatePayload(item: RequestItem): RequestItemUpdate {
  const payload: RequestItemUpdate = {}

  const nama = form.nama_barang.trim()
  if (nama !== item.nama_barang) payload.nama_barang = nama

  const satuan = form.satuan.trim()
  if (!lockExtra.value && satuan !== item.satuan) payload.satuan = satuan

  if (!lockExtra.value && form.jumlah !== toNumber(item.jumlah)) payload.jumlah = form.jumlah as number
  const nextPersen = form.tkdn === 'TKDN' ? form.tkdn_persen : null
  if (nextPersen !== toNumber(item.tkdn_persen)) payload.tkdn_persen = nextPersen

  for (const key of TEXT_FIELDS) {
    if (lockExtra.value && key === 'catatan_sales') continue
    const next = (form[key] ?? '').trim() || null
    const previous = item[key]?.trim() || null
    if (next !== previous) payload[key] = next
  }

  return payload
}

async function onSubmit() {
  submitted.value = true
  if (hasClientErrors.value) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    let itemId = props.item?.id ?? createdItemId.value

    if (props.item) {
      const payload = buildUpdatePayload(props.item)
      if (Object.keys(payload).length > 0) await updateRequestItem(props.requestId, props.item.id, payload)
    } else if (itemId === null) {
      const created = await createRequestItem(props.requestId, buildCreatePayload())
      itemId = created.id
      createdItemId.value = created.id
    }

    if (itemId !== null) {
      const link = form.link_marketplace.trim()
      const currentLink = props.item?.link_marketplace ?? ''
      if (!lockExtra.value && link !== currentLink) {
        await updateLinkMarketplace(props.requestId, itemId, link || null)
      }
      if (gambarFile.value) {
        await uploadGambarItem(props.requestId, itemId, gambarFile.value)
      }
    }

    visible.value = false
    emit('saved')
  } catch (error) {
    if (createdItemId.value !== null) emit('saved')

    const errors = getFieldErrors(error)
    serverErrors.value = errors
    if (Object.keys(errors).length === 0) {
      formError.value =
        createdItemId.value !== null
          ? 'Barang sudah tersimpan, tetapi gambar atau link marketplace gagal disimpan. Coba simpan lagi.'
          : getErrorMessage(error, 'Gagal menyimpan barang')
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
    :header="isEdit ? 'Ubah barang' : extra ? 'Tambah barang tambahan' : 'Tambah barang'"
    class="w-[calc(100vw-2rem)] max-w-2xl"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="request-item-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="item-nama" class="text-sm font-medium">
            Nama barang <span class="text-red-500">*</span>
          </label>
          <InputText id="item-nama" v-model="form.nama_barang" autocomplete="off" fluid :invalid="!!fieldError('nama_barang')" />
          <Message v-if="fieldError('nama_barang')" severity="error" size="small" variant="simple">
            {{ fieldError('nama_barang') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="item-merk" class="text-sm font-medium">Merk</label>
          <InputText id="item-merk" v-model="form.merk" autocomplete="off" fluid :invalid="!!fieldError('merk')" />
          <Message v-if="fieldError('merk')" severity="error" size="small" variant="simple">
            {{ fieldError('merk') }}
          </Message>
        </div>

        <div :class="['grid gap-4', showTkdnPersen ? 'grid-cols-2' : 'grid-cols-1']">
          <div class="flex flex-col gap-1.5">
            <label for="item-tkdn" class="text-sm font-medium">TKDN</label>
            <Dropdown
              id="item-tkdn"
              v-model="form.tkdn"
              input-id="item-tkdn"
              :options="TKDN_OPTIONS"
              option-label="label"
              option-value="value"
              placeholder="Pilih TKDN"
              show-clear
              fluid
              :invalid="!!fieldError('tkdn')"
            />
            <Message v-if="fieldError('tkdn')" severity="error" size="small" variant="simple">
              {{ fieldError('tkdn') }}
            </Message>
          </div>

          <div v-if="showTkdnPersen" class="flex flex-col gap-1.5">
            <label for="item-tkdn-persen" class="text-sm font-medium">TKDN (%)</label>
            <InputNumber
              v-model="form.tkdn_persen"
              input-id="item-tkdn-persen"
              suffix="%"
              :min="0"
              :max="100"
              :max-fraction-digits="2"
              :use-grouping="false"
              :maxlength="8"
              fluid
              :invalid="!!fieldError('tkdn_persen')"
              @input="limitPersen"
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
            :disabled="lockExtra"
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
          <InputText id="item-satuan" v-model="form.satuan" autocomplete="off" fluid :disabled="lockExtra" :invalid="!!fieldError('satuan')" />
          <Message v-if="fieldError('satuan')" severity="error" size="small" variant="simple">
            {{ fieldError('satuan') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="item-spesifikasi" class="text-sm font-medium">Spesifikasi</label>
          <Textarea id="item-spesifikasi" v-model="form.spesifikasi" rows="3" auto-resize fluid :invalid="!!fieldError('spesifikasi')" />
          <Message v-if="fieldError('spesifikasi')" severity="error" size="small" variant="simple">
            {{ fieldError('spesifikasi') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="item-catatan" class="text-sm font-medium">Catatan sales</label>
          <Textarea id="item-catatan" v-model="form.catatan_sales" rows="2" auto-resize fluid :disabled="lockExtra" :invalid="!!fieldError('catatan_sales')" />
          <Message v-if="fieldError('catatan_sales')" severity="error" size="small" variant="simple">
            {{ fieldError('catatan_sales') }}
          </Message>
        </div>
      </div>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label class="text-sm font-medium">Gambar barang</label>
          <input ref="gambarInput" type="file" accept="image/*" class="hidden" @change="onGambarChange" />

          <div
            v-if="currentGambar"
            class="flex h-40 w-full items-center justify-center overflow-hidden rounded-lg border border-line bg-sidebar/50"
          >
            <img :src="currentGambar" alt="Gambar barang" class="max-h-full max-w-full object-contain" />
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <Button
              type="button"
              :label="currentGambar ? 'Ganti gambar' : 'Pilih gambar'"
              icon="pi pi-image"
              size="small"
              variant="outlined"
              :disabled="saving"
              @click="pickGambar"
            />
            <Button
              v-if="gambarFile"
              type="button"
              label="Batal pilih"
              size="small"
              variant="text"
              severity="secondary"
              :disabled="saving"
              @click="removeGambar"
            />
          </div>

          <p v-if="gambarFile" class="truncate text-xs text-fg-muted">{{ gambarFile.name }}</p>
          <Message v-if="fieldError('gambar')" severity="error" size="small" variant="simple">
            {{ fieldError('gambar') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="item-marketplace" class="text-sm font-medium">Link marketplace</label>
          <InputText
            id="item-marketplace"
            v-model="form.link_marketplace"
            type="url"
            placeholder="https://..."
            autocomplete="off"
            fluid
            :disabled="lockExtra"
            :invalid="!!fieldError('link_marketplace')"
          />
          <Message v-if="fieldError('link_marketplace')" severity="error" size="small" variant="simple">
            {{ fieldError('link_marketplace') }}
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