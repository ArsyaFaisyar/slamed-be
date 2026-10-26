<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'
import { useRouter } from 'vue-router'

import {
  deleteTemplatePenawaran,
  getTemplatePenawaranList,
  type TemplatePenawaran,
} from '../api/templatePenawaran'
import { getErrorMessage } from '../utils/error'
import { resolveMediaUrl } from '../utils/media'

const confirm = useConfirm()
const router = useRouter()

const templates = ref<TemplatePenawaran[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

const filtered = computed(() => {
  const keyword = search.value.trim().toLowerCase()
  if (!keyword) return templates.value
  return templates.value.filter((item) => item.judul.toLowerCase().includes(keyword))
})

function formatDateTime(value: string | null) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return date.toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' })
}

function confirmDelete(item: TemplatePenawaran) {
  confirm.require({
    header: 'Hapus Template',
    message: `Apakah Anda yakin ingin menghapus template ${item.judul}? Tindakan ini tidak dapat dibatalkan.`,
    icon: 'pi pi-exclamation-triangle',
    rejectProps: { label: 'Batal', severity: 'secondary', variant: 'text' },
    acceptProps: { label: 'Hapus', severity: 'danger' },
    accept: async () => {
      actionError.value = ''
      try {
        await deleteTemplatePenawaran(item.id)
        await fetchTemplates()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menghapus template')
      }
    },
  })
}

async function fetchTemplates() {
  loading.value = true
  errorMessage.value = ''
  try {
    templates.value = await getTemplatePenawaranList()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar template')
  } finally {
    loading.value = false
  }
}

onMounted(fetchTemplates)
</script>

<template>
  <div class="flex flex-col gap-6">
    <Message v-if="errorMessage" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ errorMessage }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" :loading="loading" @click="fetchTemplates" />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <section class="rounded-xl border border-line bg-card">
      <div class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="font-semibold">Template penawaran</h2>
          <p class="mt-1 text-sm text-fg-muted">{{ filtered.length }} template ditampilkan</p>
        </div>

        <div class="flex items-center gap-2">
          <InputText v-model="search" placeholder="Cari template..." aria-label="Cari template" size="small" class="w-40 sm:w-48" />
          <Button label="Template baru" icon="pi pi-plus" size="small" class="whitespace-nowrap" @click="router.push('/setting/template-penawaran/baru')" />
        </div>
      </div>

      <div v-if="loading && templates.length === 0" class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted">
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar template...
      </div>

      <div v-else-if="!errorMessage && filtered.length === 0" class="flex flex-col items-center justify-center gap-2 p-12 text-center">
        <i class="pi pi-file-edit text-3xl text-fg-muted" />
        <p class="font-medium">{{ search ? 'Template tidak ditemukan' : 'Belum ada template' }}</p>
        <p class="text-sm text-fg-muted">{{ search ? 'Coba kata kunci lain.' : 'Buat template penawaran pertama Anda.' }}</p>
      </div>

      <div v-else-if="templates.length > 0" class="overflow-x-auto transition-opacity" :class="loading && 'pointer-events-none opacity-60'" :aria-busy="loading">
        <table class="w-full min-w-[720px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Judul</th>
              <th class="px-5 py-3 font-medium">Preview</th>
              <th class="px-5 py-3 font-medium">Diperbarui</th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr v-for="item in filtered" :key="item.id" class="transition-colors hover:bg-sidebar/60">
              <td class="px-5 py-4">
                <RouterLink :to="`/setting/template-penawaran/${item.id}`" class="font-medium hover:text-brand hover:underline">
                  {{ item.judul }}
                </RouterLink>
              </td>

              <td class="px-5 py-4">
                <img v-if="resolveMediaUrl(item.preview_path)" :src="resolveMediaUrl(item.preview_path)" :alt="`Preview ${item.judul}`" class="h-14 w-24 rounded-md border border-line object-cover" />
                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-5 py-4 text-fg-muted">{{ formatDateTime(item.updated_at ?? item.created_at) }}</td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button icon="pi pi-pencil" variant="text" rounded severity="secondary" aria-label="Edit template" v-tooltip.top="'Edit template'" @click="router.push(`/setting/template-penawaran/${item.id}`)" />
                  <Button icon="pi pi-trash" variant="text" rounded severity="danger" aria-label="Hapus template" v-tooltip.top="'Hapus template'" @click="confirmDelete(item)" />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">Total {{ templates.length }} template</footer>
    </section>
  </div>
</template>