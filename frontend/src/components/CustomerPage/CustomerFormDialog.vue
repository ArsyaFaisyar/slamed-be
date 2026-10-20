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
import { getErrorMessage, getFieldErrors } from '../../utils/error'

export interface SalesOption {
  value: number
  label: string
}

const props = defineProps<{ customer?: Customer | null; salesOptions: SalesOption[] }>()
const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

const textFields = [
  { key: 'nama_instansi', label: 'Nama instansi', required: true, wide: true },
  { key: 'nama_pic', label: 'Nama PIC' },
  { key: 'kontak_pic', label: 'Kontak PIC', type: 'tel' },
  { key: 'kota', label: 'Kota' },
  { key: 'kategori', label: 'Kategori' },
  { key: 'area', label: 'Area' },
] as const

type TextKey = (typeof textFields)[number]['key']
type Field = TextKey | 'sales_id'

const textKeys = textFields.map((field) => field.key) as TextKey[]
const allKeys: Field[] = [...textKeys, 'sales_id']

const form = reactive({
  nama_instansi: '',
  nama_pic: '',
  kontak_pic: '',
  kota: '',
  kategori: '',
  area: '',
  sales_id: null as number | null,
})

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const isEdit = computed(() => !!props.customer)
const namaError = computed(() => (form.nama_instansi.trim() ? '' : 'Nama instansi wajib diisi'))

function fieldError(field: Field) {
  if (serverErrors.value[field]) return serverErrors.value[field]
  return submitted.value && field === 'nama_instansi' ? namaError.value : ''
}

function reset() {
  for (const key of textKeys) form[key] = props.customer?.[key] ?? ''
  form.sales_id = props.customer?.sales_id ?? null
  submitted.value = false
  formError.value = ''
  serverErrors.value = {}
}

watch(visible, (value) => {
  if (value) reset()
})

function buildPayload() {
  const payload: Record<string, string | number | null> = {}

  for (const key of textKeys) {
    const value = form[key].trim()
    if (isEdit.value) {
      if (value !== (props.customer?.[key] ?? '')) payload[key] = value || null
    } else if (value) {
      payload[key] = value
    }
  }

  if (isEdit.value) {
    if (form.sales_id !== (props.customer?.sales_id ?? null)) payload.sales_id = form.sales_id
  } else if (form.sales_id !== null) {
    payload.sales_id = form.sales_id
  }

  return payload
}

async function onSubmit() {
  submitted.value = true
  if (namaError.value) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    const payload = buildPayload()

    if (props.customer) {
      if (Object.keys(payload).length > 0) await updateCustomer(props.customer.id, payload)
    } else {
      await createCustomer(payload as CustomerInput)
    }

    visible.value = false
    emit('saved')
  } catch (error) {
    const errors = getFieldErrors(error)
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => allKeys.includes(key as Field)))
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
    <form id="customer-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div
          v-for="field in textFields"
          :key="field.key"
          class="flex flex-col gap-1.5"
          :class="'wide' in field && 'sm:col-span-2'"
        >
          <label :for="`customer-${field.key}`" class="text-sm font-medium">
            {{ field.label }}
            <span v-if="'required' in field" class="text-red-500">*</span>
          </label>
          <InputText
            :id="`customer-${field.key}`"
            v-model="form[field.key]"
            :type="'type' in field ? field.type : 'text'"
            autocomplete="off"
            fluid
            :invalid="!!fieldError(field.key)"
          />
          <Message v-if="fieldError(field.key)" severity="error" size="small" variant="simple">
            {{ fieldError(field.key) }}
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
            :invalid="!!fieldError('sales_id')"
          />
          <Message v-if="fieldError('sales_id')" severity="error" size="small" variant="simple">
            {{ fieldError('sales_id') }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="customer-form" label="Simpan" icon="pi pi-check" :loading="saving" />
    </template>
  </Dialog>
</template>