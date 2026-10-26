<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, toRaw } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Editor from 'primevue/editor'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'

import {
  createTemplatePenawaran,
  getTemplatePenawaran,
  updateTemplatePenawaran,
  uploadTemplatePreview,
  type TemplatePenawaran,
} from '../api/templatePenawaran'
import { TEMPLATE_TAGS } from '../constant/templateTags'
import { getErrorMessage, getFieldErrors } from '../utils/error'
import { resolveMediaUrl } from '../utils/media'

const LIST_PATH = '/setting/template-penawaran'
const MAX_PREVIEW_SIZE = 2 * 1024 * 1024
const PREVIEW_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
const EMPTY_HTML = ['', '<p><br></p>']

interface QuillLike {
  getSelection: (focus?: boolean) => { index: number; length: number } | null
  getLength: () => number
  insertText: (index: number, text: string, source?: string) => void
  setSelection: (index: number, length?: number) => void
  focus: () => void
}

const route = useRoute()
const router = useRouter()

const templateId = computed(() => {
  const raw = route.params.id
  const value = Array.isArray(raw) ? raw[0] : raw
  const parsed = Number(value)
  return value && Number.isInteger(parsed) ? parsed : null
})
const isEdit = computed(() => templateId.value !== null)

const original = ref<TemplatePenawaran | null>(null)
const judul = ref('')
const konten = ref('')
const previewFile = ref<File | null>(null)
const previewUrl = ref<string | undefined>()
const fileInput = ref<HTMLInputElement | null>(null)
let quill: QuillLike | null = null

const loading = ref(false)
const saving = ref(false)
const submitted = ref(false)
const loadError = ref('')
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})
const previewError = ref('')

const judulError = computed(
  () => serverErrors.value.judul || (submitted.value && !judul.value.trim() ? 'Judul wajib diisi' : ''),
)
const kontenError = computed(
  () => serverErrors.value.konten || (submitted.value && EMPTY_HTML.includes(konten.value.trim()) ? 'Isi template wajib diisi' : ''),
)

let objectUrl: string | null = null

function revokeObjectUrl() {
  if (objectUrl) URL.revokeObjectURL(objectUrl)
  objectUrl = null
}

function onEditorLoad(event: { instance: QuillLike }) {
  quill = toRaw(event.instance)
}

function tagText(key: string) {
  return '{{' + key + '}}'
}

function insertTag(key: string) {
  const instance = quill
  if (!instance) return
  const text = tagText(key)
  const range = instance.getSelection(true)
  const index = range ? range.index : Math.max(instance.getLength() - 1, 0)
  instance.insertText(index, text, 'user')
  instance.setSelection(index + text.length)
  instance.focus()
}

function pickPreview() {
  fileInput.value?.click()
}

function onPreviewChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return

  previewError.value = ''
  if (!PREVIEW_TYPES.includes(file.type)) {
    previewError.value = 'Format gambar harus JPG, PNG, WEBP, atau GIF'
    return
  }
  if (file.size > MAX_PREVIEW_SIZE) {
    previewError.value = 'Ukuran gambar maksimal 2MB'
    return
  }

  revokeObjectUrl()
  objectUrl = URL.createObjectURL(file)
  previewFile.value = file
  previewUrl.value = objectUrl
}

function removeNewPreview() {
  revokeObjectUrl()
  previewFile.value = null
  previewUrl.value = resolveMediaUrl(original.value?.preview_path)
}

async function load() {
  if (templateId.value === null) return
  loading.value = true
  loadError.value = ''
  try {
    const data = await getTemplatePenawaran(templateId.value)
    original.value = data
    judul.value = data.judul
    konten.value = data.konten
    previewUrl.value = resolveMediaUrl(data.preview_path)
  } catch (error) {
    loadError.value = getErrorMessage(error, 'Gagal memuat template')
  } finally {
    loading.value = false
  }
}

async function onSubmit() {
  submitted.value = true
  formError.value = ''
  serverErrors.value = {}
  if (!judul.value.trim() || EMPTY_HTML.includes(konten.value.trim())) return

  saving.value = true
  let savedId = templateId.value

  try {
    if (original.value && savedId !== null) {
      const payload: Record<string, string> = {}
      if (judul.value.trim() !== original.value.judul) payload.judul = judul.value.trim()
      if (konten.value !== original.value.konten) payload.konten = konten.value
      if (Object.keys(payload).length > 0) await updateTemplatePenawaran(savedId, payload)
    } else {
      const created = await createTemplatePenawaran({ judul: judul.value.trim(), konten: konten.value })
      savedId = created.id
    }
  } catch (error) {
    const errors = getFieldErrors(error)
    const known = Object.fromEntries(Object.entries(errors).filter(([key]) => key === 'judul' || key === 'konten'))
    serverErrors.value = known
    if (Object.keys(known).length === 0) formError.value = getErrorMessage(error, 'Gagal menyimpan template')
    saving.value = false
    return
  }

  if (previewFile.value && savedId !== null) {
    try {
      await uploadTemplatePreview(savedId, previewFile.value)
    } catch (error) {
      formError.value = `Template tersimpan, tetapi gambar preview gagal diunggah: ${getErrorMessage(error, 'terjadi kesalahan')}`
      saving.value = false
      if (!isEdit.value) router.replace(`${LIST_PATH}/${savedId}`)
      return
    }
  }

  saving.value = false
  router.replace(LIST_PATH)
}

onMounted(load)
onBeforeUnmount(revokeObjectUrl)
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="flex items-center gap-3">
        <Button icon="pi pi-arrow-left" variant="text" rounded severity="secondary" aria-label="Kembali" :disabled="saving" @click="router.push(LIST_PATH)" />
        <div>
          <h2 class="text-lg font-semibold">{{ isEdit ? 'Edit template' : 'Template baru' }}</h2>
          <p class="text-sm text-fg-muted">Gunakan tag untuk data yang terisi otomatis saat penawaran dibuat.</p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="router.push(LIST_PATH)" />
        <Button label="Simpan" icon="pi pi-check" :loading="saving" :disabled="loading || !!loadError" @click="onSubmit" />
      </div>
    </div>

    <Message v-if="loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" :loading="loading" @click="load" />
      </div>
    </Message>

    <Message v-if="formError" severity="error" @close="formError = ''">{{ formError }}</Message>

    <div v-if="loading" class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted">
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat template...
    </div>

    <div v-else-if="!loadError" class="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_22rem]">
      <div class="flex min-w-0 flex-col gap-6">
        <section class="grid gap-5 rounded-xl border border-line bg-card p-5 md:grid-cols-[minmax(0,1fr)_14rem]">
          <div class="flex flex-col gap-1.5">
            <label for="template-judul" class="text-sm font-medium">Judul <span class="text-red-500">*</span></label>
            <InputText id="template-judul" v-model="judul" autocomplete="off" fluid :invalid="!!judulError" />
            <Message v-if="judulError" severity="error" size="small" variant="simple">{{ judulError }}</Message>
          </div>

          <div class="flex flex-col gap-1.5">
            <span class="text-sm font-medium">Gambar preview</span>
            <input ref="fileInput" type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="hidden" @change="onPreviewChange" />

            <div class="flex items-center gap-3">
              <img v-if="previewUrl" :src="previewUrl" alt="Preview template" class="h-16 w-24 rounded-md border border-line object-cover" />
              <div v-else class="flex h-16 w-24 items-center justify-center rounded-md border border-dashed border-line text-fg-muted">
                <i class="pi pi-image text-xl" />
              </div>

              <div class="flex flex-col items-start gap-1">
                <Button :label="previewUrl ? 'Ganti' : 'Pilih gambar'" icon="pi pi-upload" size="small" severity="secondary" variant="outlined" @click="pickPreview" />
                <Button v-if="previewFile" label="Batalkan" size="small" variant="text" severity="secondary" @click="removeNewPreview" />
              </div>
            </div>

            <Message v-if="previewError" severity="error" size="small" variant="simple">{{ previewError }}</Message>
            <p v-else class="text-xs text-fg-muted">JPG, PNG, WEBP, atau GIF, maks 2MB</p>
          </div>
        </section>

        <section class="rounded-xl border border-line bg-card p-5">
          <label class="mb-2 block text-sm font-medium">Isi penawaran <span class="text-red-500">*</span></label>
          <Editor v-model="konten" editor-style="height: 32rem" @load="onEditorLoad" />
          <Message v-if="kontenError" severity="error" size="small" variant="simple" class="mt-2">{{ kontenError }}</Message>
        </section>
      </div>

      <aside class="rounded-xl border border-line bg-card p-5 xl:sticky xl:top-4">
        <h3 class="text-sm font-semibold">Tag yang bisa diganti</h3>
        <p class="mt-1 text-xs text-fg-muted">Klik tag untuk menyisipkannya ke teks.</p>

        <div class="mt-4 grid max-h-[36rem] gap-2 overflow-y-auto pr-1">
          <button
            v-for="tag in TEMPLATE_TAGS"
            :key="tag.key"
            type="button"
            class="rounded-lg border border-line px-3 py-2 text-left transition-colors hover:border-brand hover:bg-sidebar"
            @click="insertTag(tag.key)">
            <code class="block text-xs font-medium text-accent">{{ tagText(tag.key) }}</code>
            <span class="text-xs text-fg-muted">{{ tag.label }}</span>
          </button>
        </div>
      </aside>
    </div>
  </div>
</template>