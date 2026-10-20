<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Button from 'primevue/button'
import Message from 'primevue/message'
import BranchLogo from './BranchLogo.vue'
import {
  createBranch,
  updateBranch,
  uploadBranchLogo,
  type Branch,
  type BranchInput,
} from '../../api/branches.ts'
import { getErrorMessage, getFieldErrors } from '../../utils/error.ts'

const MAX_LOGO_SIZE = 5 * 1024 * 1024
const LOGO_TYPES = ['image/jpeg', 'image/png', 'image/webp']

const props = defineProps<{ branch?: Branch | null }>()
const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

const fields = [
  { key: 'nama', label: 'Nama cabang', required: true },
  { key: 'kode', label: 'Kode', required: true },
  { key: 'nama_direktur', label: 'Nama direktur' },
  { key: 'no_telepon', label: 'No. telepon', type: 'tel' },
  { key: 'email', label: 'Email', type: 'email' },
  { key: 'website', label: 'Website' },
] as const

type Field = (typeof fields)[number]['key'] | 'alamat'

const allKeys: Field[] = ['nama', 'kode', 'nama_direktur', 'no_telepon', 'email', 'website', 'alamat']
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const form = reactive<Record<Field, string>>({
  nama: '',
  kode: '',
  nama_direktur: '',
  no_telepon: '',
  email: '',
  website: '',
  alamat: '',
})

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})
const createdId = ref<number>()

const logoInput = ref<HTMLInputElement>()
const logoFile = ref<File | null>(null)
const logoPreview = ref<string | null>(null)
const logoError = ref('')

const isEdit = computed(() => !!props.branch)
const targetId = computed(() => props.branch?.id ?? createdId.value)

const clientErrors = computed<Partial<Record<Field, string>>>(() => {
  const email = form.email.trim()
  return {
    nama: form.nama.trim() ? '' : 'Nama cabang wajib diisi',
    kode: form.kode.trim() ? '' : 'Kode wajib diisi',
    email: email && !emailPattern.test(email) ? 'Format email tidak valid' : '',
  }
})

const hasClientErrors = computed(() => Object.values(clientErrors.value).some(Boolean))

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '') || ''
}

function clearLogo() {
  if (logoPreview.value) URL.revokeObjectURL(logoPreview.value)
  logoPreview.value = null
  logoFile.value = null
  if (logoInput.value) logoInput.value.value = ''
}

function reset() {
  for (const key of allKeys) form[key] = props.branch?.[key] ?? ''
  submitted.value = false
  formError.value = ''
  serverErrors.value = {}
  logoError.value = ''
  createdId.value = undefined
  clearLogo()
}

watch(visible, (value) => {
  if (value) reset()
})

onBeforeUnmount(clearLogo)

function onLogoSelect(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return

  clearLogo()
  logoError.value = ''

  if (!LOGO_TYPES.includes(file.type)) {
    logoError.value = 'Format harus JPG, PNG, atau WEBP'
    return
  }
  if (file.size > MAX_LOGO_SIZE) {
    logoError.value = 'Ukuran file maksimal 5 MB'
    return
  }

  logoFile.value = file
  logoPreview.value = URL.createObjectURL(file)
}

function buildPayload() {
  const payload: Record<string, string | null> = {}
  for (const key of allKeys) {
    const value = form[key].trim()
    if (isEdit.value) {
      if (value !== (props.branch?.[key] ?? '')) payload[key] = value || null
    } else if (value) {
      payload[key] = value
    }
  }
  return payload
}

async function saveData() {
  const payload = buildPayload()

  if (targetId.value === undefined) {
    const created = await createBranch(payload as BranchInput)
    createdId.value = typeof created?.id === 'number' ? created.id : undefined
    return
  }

  if (Object.keys(payload).length > 0) await updateBranch(targetId.value, payload)
}

function handleSaveError(error: unknown) {
  const errors = getFieldErrors(error)
  const known = Object.fromEntries(Object.entries(errors).filter(([key]) => allKeys.includes(key as Field)))
  serverErrors.value = known
  if (Object.keys(known).length === 0) {
    formError.value = getErrorMessage(error, 'Gagal menyimpan cabang')
  }
}

async function onSubmit() {
  submitted.value = true
  if (hasClientErrors.value) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    await saveData()
  } catch (error) {
    handleSaveError(error)
    saving.value = false
    return
  }

  emit('saved')

  if (logoFile.value && targetId.value !== undefined) {
    try {
      await uploadBranchLogo(targetId.value, logoFile.value)
      emit('saved')
    } catch (error) {
      formError.value = `Data tersimpan, tetapi logo gagal diunggah: ${getErrorMessage(error, 'terjadi kesalahan')}`
      clearLogo()
      saving.value = false
      return
    }
  }

  saving.value = false
  visible.value = false
}
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    :header="isEdit ? 'Edit cabang' : 'Tambah cabang'"
    class="w-[calc(100vw-2rem)] max-w-2xl"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="branch-form" class="flex flex-col gap-5" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="flex items-center gap-4">
        <BranchLogo
          :name="form.nama || form.kode"
          :logo="branch?.logo"
          :preview="logoPreview"
          class="size-16 text-lg"
        />
        <div class="flex flex-col items-start gap-1">
          <input
            ref="logoInput"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            class="hidden"
            @change="onLogoSelect"
          />
          <Button
            type="button"
            :label="logoFile ? 'Ganti pilihan' : 'Pilih logo'"
            icon="pi pi-image"
            size="small"
            variant="outlined"
            severity="secondary"
            :disabled="saving"
            @click="logoInput?.click()"
          />
          <p class="text-xs text-fg-muted">JPG, PNG, atau WEBP. Maksimal 5 MB.</p>
          <Message v-if="logoError" severity="error" size="small" variant="simple">{{ logoError }}</Message>
        </div>
      </div>

      <div class="grid gap-4 sm:grid-cols-2">
        <div v-for="field in fields" :key="field.key" class="flex flex-col gap-1.5">
          <label :for="`branch-${field.key}`" class="text-sm font-medium">
            {{ field.label }}
            <span v-if="'required' in field" class="text-red-500">*</span>
          </label>
          <InputText
            :id="`branch-${field.key}`"
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
          <label for="branch-alamat" class="text-sm font-medium">Alamat</label>
          <Textarea
            id="branch-alamat"
            v-model="form.alamat"
            rows="3"
            auto-resize
            fluid
            :invalid="!!fieldError('alamat')"
          />
          <Message v-if="fieldError('alamat')" severity="error" size="small" variant="simple">
            {{ fieldError('alamat') }}
          </Message>
        </div>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="branch-form" label="Simpan" icon="pi pi-check" :loading="saving" />
    </template>
  </Dialog>
</template>