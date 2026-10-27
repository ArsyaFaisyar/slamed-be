<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Button from 'primevue/button'
import Message from 'primevue/message'
import {
  createRequestItem,
  updateRequestItem,
  type RequestItem,
  type RequestItemInput,
  type RequestItemPriceUpdate,
} from '../../api/requestPenawaran'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

const props = defineProps<{ requestId: number; item?: RequestItem | null; canEditCost: boolean }>()
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
  | 'harga_pagu'
  | 'harga_modal'
  | 'harga_jual'

const form = reactive({
  nama_barang: '',
  merk: '',
  tkdn: '',
  tkdn_persen: null as number | null,
  spesifikasi: '',
  catatan_sales: '',
  jumlah: 1 as number | null,
  satuan: 'Unit',
  harga_pagu: null as number | null,
  harga_modal: null as number | null,
  harga_jual: null as number | null,
})

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const isPriceMode = computed(() => !!props.item)

const clientErrors = computed<Partial<Record<Field, string>>>(() => ({
  nama_barang: isPriceMode.value || form.nama_barang.trim() ? '' : 'Nama barang wajib diisi',
  jumlah: isPriceMode.value || (form.jumlah !== null && form.jumlah > 0) ? '' : 'Jumlah minimal 1',
  satuan: isPriceMode.value || form.satuan.trim() ? '' : 'Satuan wajib diisi',
  tkdn_persen:
    form.tkdn_persen !== null && (form.tkdn_persen < 0 || form.tkdn_persen > 100) ? 'Persentase 0 sampai 100' : '',
}))

const hasClientErrors = computed(() => Object.values(clientErrors.value).some(Boolean))

function limitPersen(event: { value?: number | string | null; originalEvent: Event }) {
  const value = typeof event.value === 'number' ? event.value : null
  if (value === null || value <= 100) return
  form.tkdn_persen = 100
  const target = event.originalEvent?.target as HTMLInputElement | null
  if (target) target.value = '100'
}

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '') || ''
}

function toNumber(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === '') return null
  const number = Number(value)
  return Number.isNaN(number) ? null : number
}

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
  form.harga_pagu = toNumber(props.item?.harga_pagu)
  form.harga_modal = toNumber(props.item?.harga_modal)
  form.harga_jual = toNumber(props.item?.harga_jual)
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
  if (form.tkdn_persen !== null) payload.tkdn_persen = form.tkdn_persen
  if (form.spesifikasi.trim()) payload.spesifikasi = form.spesifikasi.trim()
  if (form.catatan_sales.trim()) payload.catatan_sales = form.catatan_sales.trim()

  return payload
}

function buildPricePayload(item: RequestItem): RequestItemPriceUpdate {
  const payload: RequestItemPriceUpdate = {}

  if (form.harga_pagu !== toNumber(item.harga_pagu)) payload.harga_pagu = form.harga_pagu
  if (props.canEditCost) {
    if (form.harga_modal !== toNumber(item.harga_modal)) payload.harga_modal = form.harga_modal
    if (form.harga_jual !== toNumber(item.harga_jual)) payload.harga_jual = form.harga_jual
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
    if (props.item) {
      const payload = buildPricePayload(props.item)
      if (Object.keys(payload).length > 0) await updateRequestItem(props.requestId, props.item.id, payload)
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
    :header="isPriceMode ? 'Ubah harga barang' : 'Tambah barang'"
    class="w-[calc(100vw-2rem)] max-w-2xl"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="request-item-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <template v-if="isPriceMode">
        <div class="rounded-lg border border-line bg-sidebar/50 p-3">
          <p class="text-sm font-medium">{{ item?.nama_barang }}</p>
          <p class="mt-0.5 text-xs text-fg-muted">{{ item?.jumlah }} {{ item?.satuan }}</p>
        </div>

        <div class="grid gap-4 sm:grid-cols-3">
          <div class="flex flex-col gap-1.5">
            <label for="item-pagu" class="text-sm font-medium">Harga pagu</label>
            <InputNumber
              v-model="form.harga_pagu"
              input-id="item-pagu"
              mode="currency"
              currency="IDR"
              locale="id-ID"
              :max-fraction-digits="0"
              fluid
              :invalid="!!fieldError('harga_pagu')"
            />
            <Message v-if="fieldError('harga_pagu')" severity="error" size="small" variant="simple">
              {{ fieldError('harga_pagu') }}
            </Message>
          </div>

          <div class="flex flex-col gap-1.5">
            <label for="item-modal" class="text-sm font-medium">Harga modal</label>
            <InputNumber
              v-model="form.harga_modal"
              input-id="item-modal"
              mode="currency"
              currency="IDR"
              locale="id-ID"
              :max-fraction-digits="0"
              fluid
              :disabled="!canEditCost"
              :invalid="!!fieldError('harga_modal')"
            />
            <Message v-if="fieldError('harga_modal')" severity="error" size="small" variant="simple">
              {{ fieldError('harga_modal') }}
            </Message>
          </div>

          <div class="flex flex-col gap-1.5">
            <label for="item-jual" class="text-sm font-medium">Harga jual</label>
            <InputNumber
              v-model="form.harga_jual"
              input-id="item-jual"
              mode="currency"
              currency="IDR"
              locale="id-ID"
              :max-fraction-digits="0"
              fluid
              :disabled="!canEditCost"
              :invalid="!!fieldError('harga_jual')"
            />
            <Message v-if="fieldError('harga_jual')" severity="error" size="small" variant="simple">
              {{ fieldError('harga_jual') }}
            </Message>
          </div>
        </div>

        <p v-if="!canEditCost" class="text-xs text-fg-muted">
          Harga modal dan harga jual diisi oleh role yang berwenang.
        </p>
      </template>

      <div v-else class="grid gap-4 sm:grid-cols-2">
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

        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1.5">
            <label for="item-tkdn" class="text-sm font-medium">TKDN</label>
            <InputText id="item-tkdn" v-model="form.tkdn" autocomplete="off" fluid :invalid="!!fieldError('tkdn')" />
            <Message v-if="fieldError('tkdn')" severity="error" size="small" variant="simple">
              {{ fieldError('tkdn') }}
            </Message>
          </div>

          <div class="flex flex-col gap-1.5">
            <label for="item-tkdn-persen" class="text-sm font-medium">TKDN (%)</label>
            <InputNumber
              v-model="form.tkdn_persen"
              input-id="item-tkdn-persen"
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
          <InputText id="item-satuan" v-model="form.satuan" autocomplete="off" fluid :invalid="!!fieldError('satuan')" />
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
          <Textarea id="item-catatan" v-model="form.catatan_sales" rows="2" auto-resize fluid :invalid="!!fieldError('catatan_sales')" />
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