<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import ColorPicker from 'primevue/colorpicker'
import ToggleSwitch from 'primevue/toggleswitch'
import Button from 'primevue/button'
import Message from 'primevue/message'
import {
  createProjectStatus,
  updateProjectStatus,
  type ProjectStatus,
  type ProjectStatusUpdate,
} from '../../api/projectStatuses'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

const props = defineProps<{ status?: ProjectStatus | null; nextOrder: number }>()
const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

type Field = 'nama' | 'warna' | 'urutan' | 'is_active'

const allKeys: Field[] = ['nama', 'warna', 'urutan', 'is_active']
const hexPattern = /^#[0-9a-fA-F]{6}$/
const fallbackColor = '3b82f6'

const form = reactive({
  nama: '',
  warna: '',
  urutan: 0 as number | null,
  is_active: true,
})

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const isEdit = computed(() => !!props.status)

const pickerValue = computed(() => (hexPattern.test(form.warna) ? form.warna.slice(1) : fallbackColor))

const clientErrors = computed<Partial<Record<Field, string>>>(() => ({
  nama: form.nama.trim() ? '' : 'Nama status wajib diisi',
  warna: form.warna.trim() && !hexPattern.test(form.warna.trim()) ? 'Gunakan format hex, contoh #3B82F6' : '',
  urutan: form.urutan === null ? 'Urutan wajib diisi' : '',
}))

const hasClientErrors = computed(() => Object.values(clientErrors.value).some(Boolean))

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '') || ''
}

function onPick(value: unknown) {
  if (typeof value === 'string') form.warna = `#${value.toUpperCase()}`
}

watch(visible, (value) => {
  if (!value) return

  form.nama = props.status?.nama ?? ''
  form.warna = props.status ? (props.status.warna ?? '') : `#${fallbackColor.toUpperCase()}`
  form.urutan = props.status?.urutan ?? props.nextOrder
  form.is_active = props.status?.is_active ?? true
  submitted.value = false
  formError.value = ''
  serverErrors.value = {}
})

function buildPayload() {
  const payload: ProjectStatusUpdate = {}
  const nama = form.nama.trim()
  const warna = form.warna.trim()

  if (!props.status) {
    payload.nama = nama
    if (warna) payload.warna = warna
    payload.urutan = form.urutan ?? 0
    return payload
  }

  if (nama !== props.status.nama) payload.nama = nama
  if (warna !== (props.status.warna ?? '')) payload.warna = warna || null
  if (form.urutan !== null && form.urutan !== props.status.urutan) payload.urutan = form.urutan
  if (form.is_active !== props.status.is_active) payload.is_active = form.is_active

  return payload
}

async function onSubmit() {
  submitted.value = true
  if (hasClientErrors.value) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    const payload = buildPayload()

    if (props.status) {
      if (Object.keys(payload).length > 0) await updateProjectStatus(props.status.id, payload)
    } else {
      await createProjectStatus({ nama: payload.nama ?? '', warna: payload.warna, urutan: payload.urutan })
    }

    visible.value = false
    emit('saved')
  } catch (error) {
    const errors = getFieldErrors(error)
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => allKeys.includes(key as Field)))
    serverErrors.value = known
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, 'Gagal menyimpan status project')
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
    :header="isEdit ? 'Edit status project' : 'Tambah status project'"
    class="w-[calc(100vw-2rem)] max-w-md"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="project-status-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="flex flex-col gap-1.5">
        <label for="status-nama" class="text-sm font-medium">
          Nama status <span class="text-red-500">*</span>
        </label>
        <InputText
          id="status-nama"
          v-model="form.nama"
          autocomplete="off"
          fluid
          :invalid="!!fieldError('nama')"
        />
        <Message v-if="fieldError('nama')" severity="error" size="small" variant="simple">
          {{ fieldError('nama') }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="status-warna" class="text-sm font-medium">Warna</label>
        <div class="flex items-center gap-3">
          <ColorPicker :model-value="pickerValue" format="hex" @update:model-value="onPick" />
          <InputText
            id="status-warna"
            v-model="form.warna"
            placeholder="#3B82F6"
            autocomplete="off"
            class="flex-1"
            :invalid="!!fieldError('warna')"
          />
        </div>
        <Message v-if="fieldError('warna')" severity="error" size="small" variant="simple">
          {{ fieldError('warna') }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="status-urutan" class="text-sm font-medium">
          Urutan <span class="text-red-500">*</span>
        </label>
        <InputNumber
          v-model="form.urutan"
          input-id="status-urutan"
          :min="0"
          :use-grouping="false"
          fluid
          :invalid="!!fieldError('urutan')"
        />
        <Message v-if="fieldError('urutan')" severity="error" size="small" variant="simple">
          {{ fieldError('urutan') }}
        </Message>
      </div>

      <div v-if="isEdit" class="flex items-center gap-3">
        <ToggleSwitch v-model="form.is_active" input-id="status-active" />
        <label for="status-active" class="text-sm font-medium">Status aktif</label>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="project-status-form" label="Simpan" icon="pi pi-check" :loading="saving" />
    </template>
  </Dialog>
</template>