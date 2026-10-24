<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { getProjects, type Project } from '../api/projects'
import { getProjectLogs, type ProjectLog } from '../api/projectsLogs'
import { getCustomers } from '../api/customers'
import { getErrorMessage } from '../utils/error'
import { parseDateString } from '../utils/date'

const PROJECT_LIST_PATH = '/transaksi/project'

const route = useRoute()
const router = useRouter()

const projectId = computed(() => Number(route.params.projectId))

const project = ref<Project | null>(null)
const customerName = ref('')
const logs = ref<ProjectLog[]>([])

const loading = ref(false)
const loadError = ref('')
const logsLoading = ref(false)
const logsError = ref('')

const dateFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' })
const dateTimeFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' })
const rupiahFormat = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
})

const statusName = computed(() => project.value?.status_rel?.nama ?? '')
const statusColor = computed(() => project.value?.status_rel?.warna ?? null)
const statusTextColor = computed(() => {
  const hex = statusColor.value
  if (!hex || !/^#[0-9a-fA-F]{6}$/.test(hex)) return undefined
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return (r * 299 + g * 587 + b * 114) / 1000 > 150 ? '#111827' : '#FFFFFF'
})

const sortedLogs = computed(() =>
  [...logs.value].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
)

function formatDate(value: string | null | undefined) {
  const date = parseDateString(value ?? null)
  return date ? dateFormat.format(date) : '-'
}

function formatDateTime(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : dateTimeFormat.format(date)
}

function formatRupiah(value: string | null | undefined) {
  if (value === null || value === undefined || value === '') return '-'
  const amount = Number(value)
  return Number.isNaN(amount) ? '-' : rupiahFormat.format(amount)
}

function logUser(log: ProjectLog) {
  return log.user_rel?.nama ?? (log.user_id != null ? `User #${log.user_id}` : 'Sistem')
}

async function loadLogs(id: number) {
  logsLoading.value = true
  logsError.value = ''

  try {
    logs.value = await getProjectLogs(id)
  } catch (error) {
    logsError.value = getErrorMessage(error, 'Gagal memuat log project')
  } finally {
    logsLoading.value = false
  }
}

async function load() {
  const id = projectId.value

  loading.value = true
  loadError.value = ''
  project.value = null
  customerName.value = ''
  logs.value = []

  if (!Number.isInteger(id) || id <= 0) {
    loadError.value = 'Project tidak valid'
    loading.value = false
    return
  }

  try {
    const [projects, customers] = await Promise.all([getProjects(), getCustomers().catch(() => [])])

    const found = projects.find((item) => item.id === id) ?? null
    if (!found) {
      loadError.value = 'Project tidak ditemukan atau Anda tidak memiliki akses'
      return
    }

    project.value = found
    customerName.value =
      customers.find((customer) => customer.id === found.customer_id)?.nama_instansi ?? `ID ${found.customer_id}`

    await loadLogs(id)
  } catch (error) {
    loadError.value = getErrorMessage(error, 'Gagal memuat detail project')
  } finally {
    loading.value = false
  }
}

watch(projectId, load, { immediate: true })

function goBack() {
  router.push(PROJECT_LIST_PATH)
}
</script>

<template>
  <div class="flex w-full flex-col gap-6">
    <div>
      <Button
        icon="pi pi-arrow-left"
        label="Kembali ke daftar project"
        variant="text"
        severity="secondary"
        size="small"
        @click="goBack"
      />
    </div>

    <div v-if="loading" class="flex items-center justify-center gap-3 py-16 text-sm text-fg-muted">
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat detail project...
    </div>

    <Message v-else-if="loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <template v-else-if="project">
      <!-- Info project -->
      <section class="rounded-xl border border-line bg-card">
        <div class="flex flex-wrap items-start justify-between gap-3 border-b border-line p-5">
          <div class="min-w-0">
            <h1 class="text-lg font-semibold">{{ project.nama_project }}</h1>
            <p class="mt-1 text-sm text-fg-muted">{{ customerName }}</p>
          </div>

          <span
            v-if="statusName"
            class="inline-flex items-center rounded-md border border-line px-2.5 py-1 text-xs font-medium"
            :style="
              statusColor
                ? { backgroundColor: statusColor, color: statusTextColor, borderColor: statusColor }
                : undefined
            "
          >
            {{ statusName }}
          </span>
        </div>

        <dl class="grid grid-cols-2 gap-x-6 gap-y-4 p-5 text-sm sm:grid-cols-4">
          <div>
            <dt class="text-xs text-fg-muted">Sales</dt>
            <dd class="mt-1 font-medium">{{ project.sales_rel?.nama ?? `ID ${project.sales_id}` }}</dd>
          </div>
          <div>
            <dt class="text-xs text-fg-muted">Nilai proyek</dt>
            <dd class="mt-1 font-medium tabular-nums">{{ formatRupiah(project.nilai_proyek) }}</dd>
          </div>
          <div>
            <dt class="text-xs text-fg-muted">Estimasi closing</dt>
            <dd class="mt-1 font-medium">{{ formatDate(project.estimasi_closing) }}</dd>
          </div>
          <div>
            <dt class="text-xs text-fg-muted">Dibuat</dt>
            <dd class="mt-1 font-medium">{{ formatDate(project.created_at) }}</dd>
          </div>
          <div v-if="project.deskripsi" class="col-span-2 sm:col-span-4">
            <dt class="text-xs text-fg-muted">Deskripsi</dt>
            <dd class="mt-1 whitespace-pre-line">{{ project.deskripsi }}</dd>
          </div>
        </dl>
      </section>

      <!-- Log project -->
      <section class="rounded-xl border border-line bg-card">
        <div class="flex items-baseline justify-between gap-3 border-b border-line p-5">
          <div>
            <h2 class="font-semibold">Log project</h2>
            <p class="mt-1 text-xs text-fg-muted">Riwayat aktivitas pada project ini, terbaru di atas.</p>
          </div>
          <span class="text-sm text-fg-muted">{{ logs.length }} log</span>
        </div>

        <div class="p-5">
          <Message v-if="logsError" severity="error" :closable="false">
            <div class="flex flex-wrap items-center gap-3">
              <span>{{ logsError }}</span>
              <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="loadLogs(project.id)" />
            </div>
          </Message>

          <div v-else-if="logsLoading && logs.length === 0" class="flex items-center justify-center gap-3 py-10 text-sm text-fg-muted">
            <i class="pi pi-spin pi-spinner text-lg" />
            Memuat log project...
          </div>

          <div v-else-if="logs.length === 0" class="flex flex-col items-center justify-center gap-2 py-10 text-center">
            <i class="pi pi-history text-3xl text-fg-muted" />
            <p class="font-medium">Belum ada log</p>
            <p class="text-sm text-fg-muted">Aktivitas project akan tercatat di sini.</p>
          </div>

          <ol
            v-else
            class="relative flex flex-col gap-5 border-l border-line pl-6 transition-opacity"
            :class="logsLoading && 'opacity-60'"
          >
            <li v-for="log in sortedLogs" :key="log.id" class="relative">
              <span class="absolute -left-[31px] top-1.5 size-2.5 rounded-full border border-line bg-fg-muted" />

              <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
                <span
                  v-if="log.aksi"
                  class="inline-flex rounded-md bg-sidebar px-2 py-0.5 text-xs font-medium uppercase tracking-wide"
                >
                  {{ log.aksi }}
                </span>
                <span class="text-xs text-fg-muted">{{ formatDateTime(log.created_at) }}</span>
              </div>

              <p v-if="log.deskripsi" class="mt-1 text-sm">{{ log.deskripsi }}</p>
              <p class="mt-0.5 text-xs text-fg-muted">oleh {{ logUser(log) }}</p>
            </li>
          </ol>
        </div>
      </section>
    </template>
  </div>
</template>