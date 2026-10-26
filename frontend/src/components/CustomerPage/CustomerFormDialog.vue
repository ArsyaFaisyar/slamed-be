<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Button from 'primevue/button'
import Message from 'primevue/message'

import {
  createCustomer,
  updateCustomer,
  type Customer,
  type CustomerInput,
} from '../../api/customers'
import { getAreas, type Area } from '../../api/areas'
import { getCustomerCategories, type CustomerCategory } from '../../api/customerCategories'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

export interface SalesOption {
  value: number
  label: string
  areaId: number | null
}

interface CategoryOption {
  value: string
  label: string
}

const props = defineProps<{
  customer?: Customer | null
  salesOptions: SalesOption[]
  // Dipakai untuk role SALES: sales otomatis dirinya sendiri dan tidak bisa diganti.
  lockSales?: boolean
}>()

const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

const categories = ref<CustomerCategory[]>([])
const loadingCategories = ref(false)

const categoryOptions = computed<CategoryOption[]>(() => {
  const options = categories.value.map((category) => ({
    value: category.nama,
    label: category.nama,
  }))

  const current = props.customer?.kategori
  if (current && !options.some((option) => option.value === current)) {
    options.unshift({ value: current, label: current })
  }

  return options
})

const areas = ref<Area[]>([])

const form = reactive({
  nama_instansi: '',
  nama_pic: '',
  kontak_pic: '',
  kota: '',
  kategori: null as string | null,
  sales_id: null as number | null,
})

type Field = keyof typeof form | 'area_id'

const allKeys: Field[] = [
  'nama_instansi',
  'nama_pic',
  'kontak_pic',
  'kota',
  'kategori',
  'sales_id',
  'area_id',
]

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const isEdit = computed(() => !!props.customer)

const areaId = computed<number | null>(() => {
  if (form.sales_id === null) return null

  const sales = props.salesOptions.find((option) => option.value === form.sales_id)
  if (sales) return sales.areaId

  return form.sales_id === props.customer?.sales_id ? (props.customer?.area_id ?? null) : null
})

const areaLabel = computed(() => {
  if (areaId.value === null) return ''
  return areas.value.find((area) => area.id === areaId.value)?.nama ?? `ID ${areaId.value}`
})

const namaError = computed(() =>
  form.nama_instansi.trim() ? '' : 'Nama instansi wajib diisi',
)

function fieldError(field: Field) {
  if (serverErrors.value[field]) return serverErrors.value[field]
  if (!submitted.value) return ''

  if (field === 'nama_instansi') return namaError.value
  if (field === 'kategori' && !form.kategori) return 'Kategori wajib dipilih'
  if (field === 'sales_id' && form.sales_id === null) return 'Sales wajib dipilih'
  if (field === 'area_id' && form.sales_id !== null && areaId.value === null) {
    return 'Sales yang dipilih belum memiliki area'
  }

  return ''
}

function reset() {
  form.nama_instansi = props.customer?.nama_instansi ?? ''
  form.nama_pic = props.customer?.nama_pic ?? ''
  form.kontak_pic = props.customer?.kontak_pic ?? ''
  form.kota = props.customer?.kota ?? ''
  form.kategori = props.customer?.kategori ?? null
  form.sales_id = props.customer?.sales_id ?? null

  if (props.lockSales && !props.customer) {
    form.sales_id = props.salesOptions[0]?.value ?? null
  }

  submitted.value = false
  formError.value = ''
  serverErrors.value = {}
}

async function loadAreas() {
  try {
    areas.value = await getAreas()
  } catch {
    areas.value = []
  }
}

async function loadCategories() {
  loadingCategories.value = true

  try {
    categories.value = await getCustomerCategories()
  } catch (error) {
    categories.value = []
    formError.value = getErrorMessage(error, 'Gagal memuat daftar kategori')
  } finally {
    loadingCategories.value = false
  }
}

watch(visible, (value) => {
  if (!value) return

  reset()
  loadAreas()
  loadCategories()
})

function buildPayload(): CustomerInput | Record<string, string | number | null> {
  const payload: Record<string, string | number | null> = {}

  const textFields = [
    'nama_instansi',
    'nama_pic',
    'kontak_pic',
    'kota',
    'kategori',
  ] as const

  for (const key of textFields) {
    const value = form[key]?.trim() ?? ''

    if (isEdit.value) {
      if (value !== (props.customer?.[key] ?? '')) {
        payload[key] = value || null
      }
    } else {
      payload[key] = value || null
    }
  }

  if (isEdit.value) {
    if (areaId.value !== (props.customer?.area_id ?? null)) {
      payload.area_id = areaId.value
    }

    if (form.sales_id !== (props.customer?.sales_id ?? null)) {
      payload.sales_id = form.sales_id
    }
  } else {
    payload.area_id = areaId.value
    payload.sales_id = form.sales_id
  }

  return payload
}

async function onSubmit() {
  submitted.value = true

  if (namaError.value || !form.kategori || form.sales_id === null || areaId.value === null) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    const payload = buildPayload()

    if (props.customer) {
      // Untuk sales, setiap simpan = pengajuan ulang, jadi tetap kirim walau tidak ada field berubah.
      if (Object.keys(payload).length > 0 || props.lockSales) {
        await updateCustomer(props.customer.id, payload)
      }
    } else {
      await createCustomer(payload as CustomerInput)
    }

    visible.value = false
    emit('saved')
  } catch (error) {
    const errors = getFieldErrors(error)
    const known = Object.fromEntries(
      Object.entries(errors).filter(([key]) => allKeys.includes(key as Field)),
    )

    serverErrors.value = known

    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, 'Gagal menyimpan customer')
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
    :header="isEdit ? 'Edit customer' : lockSales ? 'Ajukan customer' : 'Tambah customer'"
    class="w-[calc(100vw-2rem)] max-w-2xl"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form
      id="customer-form"
      class="flex flex-col gap-4"
      novalidate
      @submit.prevent="onSubmit"
    >
      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>

      <Message v-if="lockSales && !isEdit" severity="info" size="small" :closable="false">
        Customer yang Anda ajukan akan berstatus menunggu dan baru bisa dipakai di RKH dan project
        setelah disetujui SPV.
      </Message>

      <Message v-if="lockSales && isEdit" severity="warn" size="small" :closable="false">
        <template v-if="customer?.approval_status === 'REJECTED'">
          Customer ini ditolak SPV{{ customer.rejection_reason ? `: ${customer.rejection_reason}` : '' }}.
        </template>
        Setelah disimpan, customer diajukan ulang dan menunggu persetujuan SPV.
      </Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="customer-nama" class="text-sm font-medium">
            Nama instansi <span class="text-red-500">*</span>
          </label>
          <InputText
            id="customer-nama"
            v-model="form.nama_instansi"
            autocomplete="organization"
            fluid
            :invalid="!!fieldError('nama_instansi')"
          />
          <Message
            v-if="fieldError('nama_instansi')"
            severity="error"
            size="small"
            variant="simple"
          >
            {{ fieldError('nama_instansi') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="customer-pic" class="text-sm font-medium">Nama PIC</label>
          <InputText id="customer-pic" v-model="form.nama_pic" autocomplete="off" fluid />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="customer-kontak" class="text-sm font-medium">Kontak PIC</label>
          <InputText
            id="customer-kontak"
            v-model="form.kontak_pic"
            type="tel"
            autocomplete="off"
            fluid
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="customer-kota" class="text-sm font-medium">Kota</label>
          <InputText id="customer-kota" v-model="form.kota" autocomplete="off" fluid />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="customer-kategori" class="text-sm font-medium">
            Kategori <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.kategori"
            input-id="customer-kategori"
            :options="categoryOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih kategori"
            :loading="loadingCategories"
            :disabled="loadingCategories || categoryOptions.length === 0"
            filter
            fluid
            :invalid="!!fieldError('kategori')"
            empty-message="Daftar kategori tidak tersedia"
          />
          <Message
            v-if="fieldError('kategori')"
            severity="error"
            size="small"
            variant="simple"
          >
            {{ fieldError('kategori') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="customer-sales" class="text-sm font-medium">
            Sales <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.sales_id"
            input-id="customer-sales"
            :options="salesOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih sales"
            :disabled="lockSales"
            filter
            fluid
            :invalid="!!fieldError('sales_id')"
            empty-message="Daftar sales tidak tersedia"
          />
          <Message
            v-if="fieldError('sales_id')"
            severity="error"
            size="small"
            variant="simple"
          >
            {{ fieldError('sales_id') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="customer-area" class="text-sm font-medium">Area</label>
          <InputText
            id="customer-area"
            :model-value="areaLabel"
            placeholder="Mengikuti area sales"
            readonly
            fluid
            :invalid="!!fieldError('area_id')"
          />
          <Message
            v-if="fieldError('area_id')"
            severity="error"
            size="small"
            variant="simple"
          >
            {{ fieldError('area_id') }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button
        label="Batal"
        variant="text"
        severity="secondary"
        :disabled="saving"
        @click="visible = false"
      />
      <Button
        type="submit"
        form="customer-form"
        :label="lockSales ? (isEdit ? 'Simpan dan ajukan ulang' : 'Ajukan') : 'Simpan'"
        icon="pi pi-check"
        :loading="saving"
      />
    </template>
  </Dialog>
</template>