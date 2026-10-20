<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import {
  createCustomerCategory,
  updateCustomerCategory,
  type CustomerCategory,
} from '../../api/customerCategories'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

const props = defineProps<{ category?: CustomerCategory | null }>()
const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ saved: [] }>()

const nama = ref('')
const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverError = ref('')

const isEdit = computed(() => !!props.category)
const clientError = computed(() => (nama.value.trim() ? '' : 'Nama kategori wajib diisi'))
const error = computed(() => serverError.value || (submitted.value ? clientError.value : ''))

watch(visible, (value) => {
  if (!value) return
  nama.value = props.category?.nama ?? ''
  submitted.value = false
  formError.value = ''
  serverError.value = ''
})

async function onSubmit() {
  submitted.value = true
  if (clientError.value) return

  const value = nama.value.trim()

  if (props.category && value === props.category.nama) {
    visible.value = false
    return
  }

  saving.value = true
  formError.value = ''
  serverError.value = ''

  try {
    if (props.category) {
      await updateCustomerCategory(props.category.id, { nama: value })
    } else {
      await createCustomerCategory({ nama: value })
    }

    visible.value = false
    emit('saved')
  } catch (err) {
    const fieldError = getFieldErrors(err).nama
    if (fieldError) {
      serverError.value = fieldError
    } else {
      formError.value = getErrorMessage(err, 'Gagal menyimpan kategori')
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
    :header="isEdit ? 'Edit kategori' : 'Tambah kategori'"
    class="w-[calc(100vw-2rem)] max-w-sm"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="category-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <div class="flex flex-col gap-1.5">
        <label for="category-nama" class="text-sm font-medium">
          Nama kategori <span class="text-red-500">*</span>
        </label>
        <InputText id="category-nama" v-model="nama" autocomplete="off" fluid :invalid="!!error" />
        <Message v-if="error" severity="error" size="small" variant="simple">{{ error }}</Message>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="category-form" label="Simpan" icon="pi pi-check" :loading="saving" />
    </template>
  </Dialog>
</template>