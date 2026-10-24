<script setup lang="ts">
import { ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import Textarea from 'primevue/textarea'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { rejectCustomer, type Customer } from '../../api/customers'
import { getErrorMessage, getFieldErrors } from '../../utils/error'

const props = defineProps<{ customer: Customer | null }>()

const visible = defineModel<boolean>('visible', { default: false })
const emit = defineEmits<{ rejected: [] }>()

const reason = ref('')
const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverError = ref('')

function fieldError() {
  return serverError.value || (submitted.value && !reason.value.trim() ? 'Alasan penolakan wajib diisi' : '')
}

watch(visible, (value) => {
  if (!value) return
  reason.value = ''
  submitted.value = false
  formError.value = ''
  serverError.value = ''
})

async function onSubmit() {
  submitted.value = true
  if (!props.customer || !reason.value.trim()) return

  saving.value = true
  formError.value = ''
  serverError.value = ''

  try {
    await rejectCustomer(props.customer.id, reason.value.trim())
    visible.value = false
    emit('rejected')
  } catch (error) {
    const errors = getFieldErrors(error)
    if (errors.alasan) serverError.value = errors.alasan
    else formError.value = getErrorMessage(error, 'Gagal menolak customer')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="Tolak customer"
    class="w-[calc(100vw-2rem)] max-w-md"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form id="reject-customer-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

      <p v-if="customer" class="text-sm text-fg-muted">
        Customer <span class="font-medium text-fg">{{ customer.nama_instansi }}</span>
        <template v-if="customer.sales_nama"> yang diajukan {{ customer.sales_nama }}</template>
        akan ditolak. Sales dapat melihat alasan yang Anda tulis.
      </p>

      <div class="flex flex-col gap-1.5">
        <label for="reject-reason" class="text-sm font-medium">
          Alasan penolakan <span class="text-red-500">*</span>
        </label>
        <Textarea
          id="reject-reason"
          v-model="reason"
          rows="4"
          auto-resize
          fluid
          :invalid="!!fieldError()"
        />
        <Message v-if="fieldError()" severity="error" size="small" variant="simple">{{ fieldError() }}</Message>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button
        type="submit"
        form="reject-customer-form"
        label="Tolak customer"
        icon="pi pi-times"
        severity="danger"
        :loading="saving"
      />
    </template>
  </Dialog>
</template>