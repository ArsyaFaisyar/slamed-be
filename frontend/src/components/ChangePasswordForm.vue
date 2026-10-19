<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import Password from 'primevue/password'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { changePassword } from '../api/profile'
import { getErrorMessage, getFieldErrors } from '../utils/error'

const fields = [
  { key: 'password_lama', label: 'Kata sandi lama', autocomplete: 'current-password' },
  { key: 'password_baru', label: 'Kata sandi baru', autocomplete: 'new-password' },
  { key: 'konfirmasi', label: 'Konfirmasi kata sandi baru', autocomplete: 'new-password' },
] as const

type Field = (typeof fields)[number]['key']

const form = reactive<Record<Field, string>>({ password_lama: '', password_baru: '', konfirmasi: '' })
const submitted = ref(false)
const saving = ref(false)
const success = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const clientErrors = computed<Record<Field, string>>(() => ({
  password_lama: form.password_lama ? '' : 'Kata sandi lama wajib diisi',
  password_baru: !form.password_baru
    ? 'Kata sandi baru wajib diisi'
    : form.password_baru === form.password_lama
      ? 'Kata sandi baru harus berbeda dari yang lama'
      : '',
  konfirmasi: form.konfirmasi === form.password_baru ? '' : 'Konfirmasi tidak sama dengan kata sandi baru',
}))

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '')
}

function reset() {
  form.password_lama = ''
  form.password_baru = ''
  form.konfirmasi = ''
  submitted.value = false
}

async function onSubmit() {
  submitted.value = true
  success.value = false
  if (Object.values(clientErrors.value).some(Boolean)) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    await changePassword({ password_lama: form.password_lama, password_baru: form.password_baru })
    reset()
    success.value = true
  } catch (error) {
    const errors = getFieldErrors(error)
    const known = Object.fromEntries(
      Object.entries(errors).filter(([key]) => key === 'password_lama' || key === 'password_baru'),
    )
    serverErrors.value = known
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, 'Gagal mengubah kata sandi')
    }
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <form class="flex max-w-md flex-col gap-4" novalidate @submit.prevent="onSubmit">
    <Message v-if="success" severity="success" size="small">Kata sandi berhasil diubah.</Message>
    <Message v-if="formError" severity="error" size="small">{{ formError }}</Message>

    <div v-for="field in fields" :key="field.key" class="flex flex-col gap-1.5">
      <label :for="`pw-${field.key}`" class="text-sm font-medium">{{ field.label }}</label>
      <Password
        v-model="form[field.key]"
        :input-id="`pw-${field.key}`"
        toggle-mask
        fluid
        :feedback="false"
        :invalid="!!fieldError(field.key)"
        :input-props="{ autocomplete: field.autocomplete }"
      />
      <Message v-if="fieldError(field.key)" severity="error" size="small" variant="simple">
        {{ fieldError(field.key) }}
      </Message>
    </div>

    <Button type="submit" label="Simpan kata sandi" class="self-start" :loading="saving" />
  </form>
</template>