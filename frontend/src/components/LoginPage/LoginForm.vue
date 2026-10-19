<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'
import Message from 'primevue/message'
import CaptchaField from './CaptchaField.vue'
import type { LoginPayload } from '../../api/auth'

defineProps<{ loading?: boolean; error?: string }>()

const emit = defineEmits<{ submit: [payload: LoginPayload] }>()

const form = reactive({ username: '', password: '', captchaId: '', captchaAnswer: '' })
const submitted = ref(false)
const captcha = ref<InstanceType<typeof CaptchaField>>()

const errors = computed(() => {
  const answer = form.captchaAnswer.trim()
  return {
    username: form.username.trim() ? '' : 'Username wajib diisi',
    password: form.password ? '' : 'Kata sandi wajib diisi',
    captcha: !answer
      ? 'Jawaban CAPTCHA wajib diisi'
      : !/^-?\d+$/.test(answer)
        ? 'Jawaban harus berupa angka'
        : !form.captchaId
          ? 'CAPTCHA belum dimuat'
          : '',
  }
})

function onSubmit() {
  submitted.value = true
  if (errors.value.username || errors.value.password || errors.value.captcha) return
  emit('submit', {
    username: form.username.trim(),
    password: form.password,
    captcha_id: form.captchaId,
    captcha_answer: Number(form.captchaAnswer.trim()),
  })
}

defineExpose({ refreshCaptcha: () => captcha.value?.refresh() })
</script>

<template>
  <form class="flex flex-col gap-5" novalidate @submit.prevent="onSubmit">
    <Message v-if="error" severity="error" size="small">{{ error }}</Message>

    <div class="flex flex-col gap-1.5">
      <FloatLabel variant="on">
        <InputText
          id="username"
          v-model="form.username"
          autocomplete="username"
          fluid
          :invalid="submitted && !!errors.username"
        />
        <label for="username">Username</label>
      </FloatLabel>
      <Message v-if="submitted && errors.username" severity="error" size="small" variant="simple">
        {{ errors.username }}
      </Message>
    </div>

    <div class="flex flex-col gap-1.5">
      <FloatLabel variant="on">
        <Password
          v-model="form.password"
          input-id="password"
          toggle-mask
          fluid
          :feedback="false"
          :invalid="submitted && !!errors.password"
          :input-props="{ autocomplete: 'current-password' }"
        />
        <label for="password">Kata sandi</label>
      </FloatLabel>
      <Message v-if="submitted && errors.password" severity="error" size="small" variant="simple">
        {{ errors.password }}
      </Message>
    </div>

    <CaptchaField
      ref="captcha"
      v-model:captcha-id="form.captchaId"
      v-model:answer="form.captchaAnswer"
      :error="submitted ? errors.captcha : ''"
    />

    <Button type="submit" label="Masuk" icon="pi pi-sign-in" fluid :loading="loading" />
  </form>
</template>