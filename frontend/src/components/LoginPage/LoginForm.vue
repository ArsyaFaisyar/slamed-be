<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import Button from 'primevue/button'
import Message from 'primevue/message'

defineProps<{ loading?: boolean }>()

const emit = defineEmits<{
  submit: [payload: { email: string; password: string }]
}>()

const form = reactive({ email: '', password: '' })
const submitted = ref(false)

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const errors = computed(() => {
  const email = form.email.trim()
  return {
    email: !email ? 'Email wajib diisi' : !emailPattern.test(email) ? 'Format email tidak valid' : '',
    password: form.password ? '' : 'Kata sandi wajib diisi',
  }
})

function onSubmit() {
  submitted.value = true
  if (errors.value.email || errors.value.password) return
  emit('submit', { email: form.email.trim(), password: form.password })
}
</script>

<template>
  <form class="flex flex-col gap-5" novalidate @submit.prevent="onSubmit">
    <div class="flex flex-col gap-2">
      <label for="email" class="text-sm font-medium">Email</label>
      <InputText
        id="email"
        v-model="form.email"
        type="email"
        placeholder="nama@email.com"
        autocomplete="email"
        fluid
        :invalid="submitted && !!errors.email"
      />
      <Message v-if="submitted && errors.email" severity="error" size="small" variant="simple">
        {{ errors.email }}
      </Message>
    </div>

    <div class="flex flex-col gap-2">
      <label for="password" class="text-sm font-medium">Kata sandi</label>
      <Password
        v-model="form.password"
        input-id="password"
        placeholder="Masukkan kata sandi"
        toggle-mask
        :feedback="false"
        fluid
        :invalid="submitted && !!errors.password"
        :input-props="{ autocomplete: 'current-password' }"
      />
      <Message v-if="submitted && errors.password" severity="error" size="small" variant="simple">
        {{ errors.password }}
      </Message>
    </div>

    <Button type="submit" label="Masuk" fluid :loading="loading" />
  </form>
</template>