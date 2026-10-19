```vue
<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { getCaptcha } from '../../api/auth'
import { getErrorMessage } from '../../utils/error'

defineProps<{ error?: string }>()

const captchaId = defineModel<string>('captchaId', { default: '' })
const answer = defineModel<string>('answer', { default: '' })

const question = ref('')
const loading = ref(false)
const loadError = ref('')
let timer: ReturnType<typeof setTimeout> | undefined

async function refresh() {
  clearTimeout(timer)
  loading.value = true
  loadError.value = ''
  answer.value = ''

  try {
    const data = await getCaptcha()
    captchaId.value = data.captcha_id
    question.value = data.question
    timer = setTimeout(refresh, data.expires_in * 1000)
  } catch (error) {
    captchaId.value = ''
    question.value = ''
    loadError.value = getErrorMessage(error, 'Gagal memuat CAPTCHA')
  } finally {
    loading.value = false
  }
}

onMounted(refresh)

onBeforeUnmount(() => {
  clearTimeout(timer)
})

defineExpose({ refresh })
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="grid grid-cols-[minmax(0,1fr)_minmax(0,1fr)] items-center gap-3">
      <div class="flex min-w-0 items-center gap-2">
        <div
          class="flex h-12 min-w-0 flex-1 items-center justify-center rounded-lg border border-line bg-page px-3 font-heading text-lg font-semibold tabular-nums text-fg"
          :class="{ 'text-fg-muted': loading }"
          aria-live="polite"
        >
          {{ loading ? 'Memuat...' : question || 'CAPTCHA' }}
        </div>

        <Button
          type="button"
          icon="pi pi-refresh"
          severity="secondary"
          variant="outlined"
          class="size-12 shrink-0"
          aria-label="Muat ulang CAPTCHA"
          title="Muat ulang CAPTCHA"
          :loading="loading"
          @click="refresh"
        />
      </div>

      <InputText
        id="captcha"
        v-model="answer"
        placeholder="Jawaban"
        inputmode="numeric"
        autocomplete="off"
        fluid
        :invalid="!!error || !!loadError"
        :disabled="loading || !captchaId"
        aria-label="Jawaban CAPTCHA"
        class="h-12"
        @keydown.enter.prevent
      />
    </div>

    <Message
      v-if="loadError"
      severity="error"
      size="small"
      variant="simple"
    >
      {{ loadError }}
    </Message>

    <Message
      v-if="error"
      severity="error"
      size="small"
      variant="simple"
    >
      {{ error }}
    </Message>
  </div>
</template>
```