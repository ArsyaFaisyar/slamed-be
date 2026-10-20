<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import ConfirmDialog from 'primevue/confirmdialog'
import { useConfirm } from 'primevue/useconfirm'

import MediaFormDialog from '../components/MediaPengadaanPage/MediaFormDialog.vue'
import EditMediaDialog from '../components/MediaPengadaanPage/EditMediaDialog.vue'

import {
  deleteMediaPengadaan,
  getMediaPengadaan,
  type MediaPengadaan,
} from '../api/mediaPengadaan.ts'
import { getErrorMessage } from '../utils/error'

const confirm = useConfirm()

const items = ref<MediaPengadaan[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')

const createDialogVisible = ref(false)

const editDialogVisible = ref(false)
const selectedEditMedia = ref<MediaPengadaan | null>(null)

function openEdit(media: MediaPengadaan) {
  selectedEditMedia.value = media
  editDialogVisible.value = true
}

function confirmDelete(media: MediaPengadaan) {
  confirm.require({
    header: 'Hapus media pengadaan',
    message: `Yakin ingin menghapus "${media.nama}"? Tindakan ini tidak dapat dibatalkan.`,
    icon: 'pi pi-exclamation-triangle',
    rejectProps: {
      label: 'Batal',
      severity: 'secondary',
      variant: 'text',
    },
    acceptProps: {
      label: 'Hapus',
      severity: 'danger',
    },
    accept: async () => {
      errorMessage.value = ''
      try {
        await deleteMediaPengadaan(media.id)
        await fetchItems()
      } catch (error) {
        errorMessage.value = getErrorMessage(
          error,
          'Gagal menghapus media pengadaan',
        )
      }
    },
  })
}

const filteredItems = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return items.value

  return items.value.filter((item) =>
    (item.nama ?? '').toLowerCase().includes(keyword),
  )
})

async function fetchItems() {
  loading.value = true
  errorMessage.value = ''

  try {
    items.value = await getMediaPengadaan()
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      'Gagal memuat daftar media pengadaan',
    )
  } finally {
    loading.value = false
  }
}

onMounted(fetchItems)
</script>

<template>
  <div class="flex flex-col gap-6">
    <Message v-if="errorMessage" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ errorMessage }}</span>
        <Button
          label="Coba lagi"
          size="small"
          severity="danger"
          variant="text"
          :loading="loading"
          @click="fetchItems"
        />
      </div>
    </Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar media pengadaan</h2>
          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredItems.length }} media ditampilkan
          </p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari media..."
            aria-label="Cari media pengadaan"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah media"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="createDialogVisible = true"
          />
        </div>
      </div>

      <div
        v-if="loading && items.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar media pengadaan...
      </div>

      <div
        v-else-if="!errorMessage && filteredItems.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-inbox text-3xl text-fg-muted" />

        <p class="font-medium">
          {{ search ? 'Media tidak ditemukan' : 'Belum ada media pengadaan' }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            search
              ? 'Coba kata kunci lain.'
              : 'Data media pengadaan akan muncul di sini.'
          }}
        </p>
      </div>

      <div
        v-else-if="items.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[480px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="w-20 px-5 py-3 font-medium">No</th>
              <th class="px-5 py-3 font-medium">Nama</th>
              <th class="w-32 px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="(item, index) in filteredItems"
              :key="item.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4 text-fg-muted">
                {{ index + 1 }}
              </td>

              <td class="px-5 py-4">
                <span class="font-medium">{{ item.nama }}</span>
              </td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-pencil"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Edit media"
                    v-tooltip.top="'Edit media'"
                    @click="openEdit(item)"
                  />

                  <Button
                    icon="pi pi-trash"
                    variant="text"
                    rounded
                    severity="danger"
                    aria-label="Hapus media"
                    v-tooltip.top="'Hapus media'"
                    @click="confirmDelete(item)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ items.length }} media pengadaan
      </footer>
    </section>

    <MediaFormDialog
      v-model:visible="createDialogVisible"
      @created="fetchItems"
    />

    <EditMediaDialog
      v-if="selectedEditMedia"
      v-model:visible="editDialogVisible"
      :media="selectedEditMedia"
      @updated="fetchItems"
    />

    <ConfirmDialog />
  </div>
</template>