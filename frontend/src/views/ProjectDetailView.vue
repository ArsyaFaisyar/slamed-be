<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Button from 'primevue/button'
import Message from 'primevue/message'

import Tab from 'primevue/tab'
import TabList from 'primevue/tablist'
import TabPanel from 'primevue/tabpanel'
import TabPanels from 'primevue/tabpanels'
import Tabs from 'primevue/tabs'

import ProjectLogSection from '../components/ProjectPage/ProjectLogSection.vue'
import ProjectRabSection from '../components/ProjectPage/ProjectRabSection.vue'

import { getProjects, type Project } from '../api/projects'
import { getCustomers } from '../api/customers'
import { getErrorMessage } from '../utils/error'
import { parseDateString } from '../utils/date'

const PROJECT_LIST_PATH = '/transaksi/project'

const route = useRoute()
const router = useRouter()

const projectId = computed(() => Number(route.params.projectId))

const project = ref<Project | null>(null)
const customerName = ref('')

const loading = ref(false)
const loadError = ref('')

// Tab aktif disimpan di URL (?tab=rab) supaya tetap sama setelah halaman dimuat ulang.
const TAB_VALUES = ['logs', 'rab']
const activeTab = ref<string>(
  TAB_VALUES.includes(String(route.query.tab)) ? String(route.query.tab) : 'logs',
)

watch(activeTab, (tab) => {
  router.replace({ query: { ...route.query, tab } })
})

const dateFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' })
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

function formatDate(value: string | null | undefined) {
  const date = parseDateString(value ?? null)
  return date ? dateFormat.format(date) : '-'
}

function formatRupiah(value: string | null | undefined) {
  if (value === null || value === undefined || value === '') return '-'
  const amount = Number(value)
  return Number.isNaN(amount) ? '-' : rupiahFormat.format(amount)
}

async function load() {
  const id = projectId.value

  loading.value = true
  loadError.value = ''
  project.value = null
  customerName.value = ''

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

      <Tabs v-model:value="activeTab" lazy>
        <TabList>
          <Tab value="logs">
            <span class="flex items-center gap-2"><i class="pi pi-history" />Log</span>
          </Tab>
          <Tab value="rab">
            <span class="flex items-center gap-2"><i class="pi pi-calculator" />RAB</span>
          </Tab>
        </TabList>

        <TabPanels class="bg-transparent! px-0! pb-0!">
          <TabPanel value="logs">
            <ProjectLogSection :project-id="project.id" />
          </TabPanel>
          <TabPanel value="rab">
            <ProjectRabSection :project-id="project.id" />
          </TabPanel>
        </TabPanels>
      </Tabs>
    </template>
  </div>
</template>