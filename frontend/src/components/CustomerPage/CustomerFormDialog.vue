
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
import { getErrorMessage, getFieldErrors } from '../../utils/error'

export interface SalesOption {
  value: number
  label: string
}

interface AreaOption {
  value: number
  label: string
}

const props = defineProps<{
  customer?: Customer | null
  salesOptions: SalesOption[]
}>()

const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

const categories = [
  { label: 'Pemerintah', value: 'Pemerintah' },
  { label: 'Swasta', value: 'Swasta' },
  { label: 'Pendidikan', value: 'Pendidikan' },
  { label: 'Kesehatan', value: 'Kesehatan' },
  { label: 'Lainnya', value: 'Lainnya' },
]

const areas = ref<Area[]>([])
const loadingAreas = ref(false)

const areaOptions = computed<AreaOption[]>(() =>
  areas.value.map((area) => ({
    value: area.id,
    label: area.nama,
  })),
)

const form = reactive({
  nama_instansi: '',
  nama_pic: '',
  kontak_pic: '',
  kota: '',
  kategori: null as string | null,
  area_id: null as number | null,
  sales_id: null as number | null,
})

type Field = keyof typeof form

const allKeys: Field[] = [
  'nama_instansi',
  'nama_pic',
  'kontak_pic',
  'kota',
  'kategori',
  'area_id',
  'sales_id',
]

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const isEdit = computed(() => !!props.customer)

const namaError = computed(() =>
  form.nama_instansi.trim() ? '' : 'Nama instansi wajib diisi',
)

function fieldError(field: Field) {
  if (serverErrors.value[field]) return serverErrors.value[field]
  if (!submitted.value) return ''

  if (field === 'nama_instansi') return namaError.value
  if (field === 'kategori' && !form.kategori) return 'Kategori wajib dipilih'
  if (field === 'area_id' && form.area_id === null) return 'Area wajib dipilih'

  return ''
}

function reset() {
  form.nama_instansi = props.customer?.nama_instansi ?? ''
  form.nama_pic = props.customer?.nama_pic ?? ''
  form.kontak_pic = props.customer?.kontak_pic ?? ''
  form.kota = props.customer?.kota ?? ''
  form.kategori = props.customer?.kategori ?? null
  form.area_id = props.customer?.area_id ?? null
  form.sales_id = props.customer?.sales_id ?? null
  submitted.value = false
  formError.value = ''
  serverErrors.value = {}
}

watch(visible, async (value) => {
  if (!value) return

  reset()
  loadingAreas.value = true

  try {
    areas.value = await getAreas()
  } catch (error) {
    areas.value = []
    formError.value = getErrorMessage(error, 'Gagal memuat daftar area')
  } finally {
    loadingAreas.value = false
  }
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
    if (form.area_id !== (props.customer?.area_id ?? null)) {
      payload.area_id = form.area_id
    }

    if (form.sales_id !== (props.customer?.sales_id ?? null)) {
      payload.sales_id = form.sales_id
    }
  } else {
    payload.area_id = form.area_id
    payload.sales_id = form.sales_id
  }

  return payload
}

async function onSubmit() {
  submitted.value = true

  if (namaError.value || !form.kategori || form.area_id === null) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    const payload = buildPayload()

    if (props.customer) {
      if (Object.keys(payload).length > 0) {
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
    :header="isEdit ? 'Edit customer' : 'Tambah customer'"
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
            :options="categories"
            option-label="label"
            option-value="value"
            placeholder="Pilih kategori"
            fluid
            :invalid="!!fieldError('kategori')"
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
          <label for="customer-area" class="text-sm font-medium">
            Area <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.area_id"
            input-id="customer-area"
            :options="areaOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih area"
            :loading="loadingAreas"
            :disabled="loadingAreas || areaOptions.length === 0"
            filter
            fluid
            :invalid="!!fieldError('area_id')"
            empty-message="Daftar area tidak tersedia"
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

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="customer-sales" class="text-sm font-medium">Sales</label>
          <Select
            v-model="form.sales_id"
            input-id="customer-sales"
            :options="salesOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih sales"
            filter
            show-clear
            fluid
            empty-message="Daftar sales tidak tersedia"
          />
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
        label="Simpan"
        icon="pi pi-check"
        :loading="saving"
      />
    </template>
  </Dialog>
</template>
