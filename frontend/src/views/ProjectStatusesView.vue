<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import ProjectStatusFormDialog from '../components/ProjectStatusPage/ProjectStatusFormDialog.vue'

import {
  deactivateProjectStatus,
  getProjectStatuses,
  updateProjectStatus,
  type ProjectStatus,
} from '../api/projectStatuses'
import { getErrorMessage } from '../utils/error'

const confirm = useConfirm()

const statuses = ref<ProjectStatus[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

const formVisible = ref(false)
const selectedEdit = ref<ProjectStatus | null>(null)

const sortedStatuses = computed(() => [...statuses.value].sort((a, b) => a.urutan - b.urutan))

const filteredStatuses = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return sortedStatuses.value

  return sortedStatuses.value.filter((status) => status.nama.toLowerCase().includes(keyword))
})

const nextOrder = computed(() =>
  statuses.value.length === 0 ? 1 : Math.max(...statuses.value.map((status) => status.urutan)) + 1,
)

function openCreate() {
  selectedEdit.value = null
  formVisible.value = true
}

function openEdit(status: ProjectStatus) {
  selectedEdit.value = status
  formVisible.value = true
}

async function fetchStatuses() {
  loading.value = true
  errorMessage.value = ''

  try {
    statuses.value = await getProjectStatuses()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar status project')
  } finally {
    loading.value = false
  }
}

function confirmDeactivate(status: ProjectStatus) {
  confirm.require({
    header: 'Nonaktifkan Status',
    message: `Apakah Anda yakin ingin menonaktifkan status ${status.nama}?`,
    icon: 'pi pi-exclamation-triangle',
    rejectProps: {
      label: 'Batal',
      severity: 'secondary',
      variant: 'text',
    },
    acceptProps: {
      label: 'Nonaktifkan',
      severity: 'danger',
    },
    accept: async () => {
      actionError.value = ''
      try {
        await deactivateProjectStatus(status.id)
        await fetchStatuses()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menonaktifkan status')
      }
    },
  })
}

async function activate(status: ProjectStatus) {
  actionError.value = ''
  try {
    await updateProjectStatus(status.id, { is_active: true })
    await fetchStatuses()
  } catch (error) {
    actionError.value = getErrorMessage(error, 'Gagal mengaktifkan status')
  }
}

onMounted(fetchStatuses)
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
          @click="fetchStatuses"
        />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar status project</h2>
          <p class="mt-1 text-sm text-fg-muted">{{ filteredStatuses.length }} status ditampilkan</p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari status..."
            aria-label="Cari status"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah status"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="openCreate"
          />
        </div>
      </div>

      <div
        v-if="loading && statuses.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar status...
      </div>

      <div
        v-else-if="!errorMessage && filteredStatuses.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-flag text-3xl text-fg-muted" />

        <p class="font-medium">{{ search ? 'Status tidak ditemukan' : 'Belum ada status' }}</p>

        <p class="text-sm text-fg-muted">
          {{ search ? 'Coba kata kunci lain.' : 'Data status project akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="statuses.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[640px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="w-24 px-5 py-3 font-medium">Urutan</th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th class="px-5 py-3 font-medium">Warna</th>
              <th class="px-5 py-3 font-medium">Keaktifan</th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="status in filteredStatuses"
              :key="status.id"
              class="transition-colors hover:bg-sidebar/60"
              :class="!status.is_active && 'opacity-60'"
            >
              <td class="px-5 py-4 text-fg-muted">{{ status.urutan }}</td>

              <td class="px-5 py-4">
                <div class="flex items-center gap-2.5">
                  <span
                    class="size-3 shrink-0 rounded-full border border-line"
                    :style="{ backgroundColor: status.warna ?? 'transparent' }"
                  />
                  <span class="font-medium">{{ status.nama }}</span>
                </div>
              </td>

              <td class="px-5 py-4 font-mono text-xs text-fg-muted">{{ status.warna || '-' }}</td>

              <td class="px-5 py-4">
                <span
                  class="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="
                    status.is_active
                      ? 'bg-green-500/10 text-green-700 dark:text-green-400'
                      : 'bg-red-500/10 text-red-700 dark:text-red-400'
                  "
                >
                  <span
                    class="size-1.5 rounded-full"
                    :class="status.is_active ? 'bg-green-500' : 'bg-red-500'"
                  />
                  {{ status.is_active ? 'Aktif' : 'Nonaktif' }}
                </span>
              </td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-pencil"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Edit status"
                    v-tooltip.top="'Edit status'"
                    @click="openEdit(status)"
                  />

                  <Button
                    v-if="status.is_active"
                    icon="pi pi-ban"
                    variant="text"
                    rounded
                    severity="danger"
                    aria-label="Nonaktifkan status"
                    v-tooltip.top="'Nonaktifkan status'"
                    @click="confirmDeactivate(status)"
                  />

                  <Button
                    v-else
                    icon="pi pi-replay"
                    variant="text"
                    rounded
                    severity="success"
                    aria-label="Aktifkan status"
                    v-tooltip.top="'Aktifkan status'"
                    @click="activate(status)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ statuses.length }} status
      </footer>
    </section>

    <ProjectStatusFormDialog
      v-model:visible="formVisible"
      :status="selectedEdit"
      :next-order="nextOrder"
      @saved="fetchStatuses"
    />
  </div>
</template>