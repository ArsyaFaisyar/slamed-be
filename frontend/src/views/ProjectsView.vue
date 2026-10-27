<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import InputText from 'primevue/inputtext'
import MultiSelect from 'primevue/multiselect'
import Paginator from 'primevue/paginator'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import ProjectFormDialog, {
  type CustomerOption,
  type SalesOption,
} from '../components/ProjectPage/ProjectFormDialog.vue'

import {
  deleteProject,
  getProjectDashboardSummary,
  getProjects,
  type Project,
  type ProjectDashboardSummary,
} from '../api/projects'
import { getCustomers, isCustomerApproved, type Customer } from '../api/customers'
import { getProjectStatuses, type ProjectStatus } from '../api/projectStatuses'
import { getUsers, type User } from '../api/users'
import type { UserRole } from '../constant/roles'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage } from '../utils/error'
import { parseDateString } from '../utils/date'

const confirm = useConfirm()
const router = useRouter()

const projectDetailPath = (id: number) => `/transaksi/project/${id}`

const SALES_ROLE: UserRole = 'SALES'
const MANAGER_ROLES: UserRole[] = ['SUPERADMIN', 'SPV']
const PAGE_SIZES = [10, 25, 50]

type SortKey = 'nilai_proyek' | 'estimasi_closing' | 'created_at'
type SortDir = 'asc' | 'desc'

const auth = useAuthStore()
const canManage = computed(() => MANAGER_ROLES.includes(auth.user?.role as UserRole))

const projects = ref<Project[]>([])
const customers = ref<Customer[]>([])
const users = ref<User[]>([])
const projectStatuses = ref<ProjectStatus[]>([])
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

// Pencarian, filter (checklist), urutan, dan pagination
const search = ref('')
const salesFilter = ref<number[]>([])
const customerFilter = ref<number[]>([])
const statusFilter = ref<number[]>([])
const sortKey = ref<SortKey | null>(null)
const sortDir = ref<SortDir>('asc')
const first = ref(0)
const rows = ref(PAGE_SIZES[0])

const summary = ref<ProjectDashboardSummary | null>(null)
const summaryLoading = ref(false)
const summaryError = ref(false)

const formVisible = ref(false)
const selectedEdit = ref<Project | null>(null)

const dateFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' })
const rupiahFormat = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
})

// Hanya customer yang sudah disetujui yang bisa dipilih di form project.
const customerOptions = computed<CustomerOption[]>(() =>
  customers.value
    .filter(isCustomerApproved)
    .map((customer) => ({ value: customer.id, label: customer.nama_instansi })),
)

const customerNames = computed(
  () => new Map(customers.value.map((customer) => [customer.id, customer.nama_instansi])),
)

const salesOptions = computed<SalesOption[]>(() =>
  users.value
    .filter((user) => user.role === SALES_ROLE && user.is_active)
    .map((user) => ({ value: user.id, label: user.nama })),
)

const userNames = computed(() => new Map(users.value.map((user) => [user.id, user.nama])))

function customerName(project: Project) {
  return customerNames.value.get(project.customer_id) ?? `ID ${project.customer_id}`
}

function salesName(project: Project) {
  return project.sales_rel?.nama
    ?? userNames.value.get(project.sales_id)
    ?? `ID ${project.sales_id}`
}

function statusName(project: Project) {
  return project.status_rel?.nama ?? ''
}

function statusColor(project: Project) {
  return project.status_rel?.warna ?? null
}

function statusTextColor(project: Project) {
  const hex = statusColor(project)
  if (!hex || !/^#[0-9a-fA-F]{6}$/.test(hex)) return undefined
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return (r * 299 + g * 587 + b * 114) / 1000 > 150 ? '#111827' : '#FFFFFF'
}

function formatDate(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : dateFormat.format(date)
}

function formatClosing(value: string | null) {
  const date = parseDateString(value)
  return date ? dateFormat.format(date) : '-'
}

function formatRupiah(value: string | null) {
  if (value === null || value === undefined || value === '') return '-'
  const amount = Number(value)
  return Number.isNaN(amount) ? '-' : rupiahFormat.format(amount)
}

const numberFormat = new Intl.NumberFormat('id-ID')

const summaryCards = computed(() => {
  const data = summary.value

  return [
    {
      key: 'project',
      label: 'Jumlah project',
      icon: 'pi pi-briefcase',
      value: data ? numberFormat.format(data.jumlah_project) : '-',
      hint: data ? `Total nilai ${formatRupiah(data.total_nilai_project)}` : '',
    },
    {
      key: 'prospek',
      label: 'Prospek',
      icon: 'pi pi-chart-line',
      value: data ? numberFormat.format(data.jumlah_prospek) : '-',
      hint: data ? `Nilai ${formatRupiah(data.nilai_prospek)}` : '',
    },
    {
      key: 'hot',
      label: 'Hot prospek',
      icon: 'pi pi-bolt',
      value: data ? numberFormat.format(data.jumlah_hot_prospek) : '-',
      hint: data ? `Nilai ${formatRupiah(data.nilai_hot_prospek)}` : '',
    },
  ]
})

// Nilai pipeline_status dari backend: "Prospek" dan "Hot Prospek".
const PIPELINE_CLASSES: Record<string, string> = {
  Prospek: 'bg-blue-500/10 text-blue-700 dark:text-blue-400',
  'Hot Prospek': 'bg-red-500/10 text-red-700 dark:text-red-400',
}

function pipelineClass(value: string | null) {
  return PIPELINE_CLASSES[value ?? ''] ?? 'bg-sidebar'
}

async function fetchSummary() {
  summaryLoading.value = true
  summaryError.value = false

  try {
    summary.value = await getProjectDashboardSummary()
  } catch {
    summary.value = null
    summaryError.value = true
  } finally {
    summaryLoading.value = false
  }
}

/* ---------- Opsi filter (checklist) ---------- */

interface FilterOption {
  value: number
  label: string
  color?: string | null
}

// Semua sales: dari daftar user (bila boleh diakses) + sales yang muncul di data project.
const salesFilterOptions = computed<FilterOption[]>(() => {
  const map = new Map<number, string>()

  for (const user of users.value) {
    if (user.role === SALES_ROLE) map.set(user.id, user.nama)
  }
  for (const project of projects.value) {
    if (!map.has(project.sales_id)) map.set(project.sales_id, project.sales_rel?.nama ?? `ID ${project.sales_id}`)
  }

  return [...map]
    .map(([value, label]) => ({ value, label }))
    .sort((a, b) => a.label.localeCompare(b.label, 'id'))
})

// Semua customer: dari daftar customer + customer yang muncul di data project.
const customerFilterOptions = computed<FilterOption[]>(() => {
  const map = new Map<number, string>()

  for (const customer of customers.value) map.set(customer.id, customer.nama_instansi)
  for (const project of projects.value) {
    if (!map.has(project.customer_id)) map.set(project.customer_id, `ID ${project.customer_id}`)
  }

  return [...map]
    .map(([value, label]) => ({ value, label }))
    .sort((a, b) => a.label.localeCompare(b.label, 'id'))
})

// Semua status project, urut sesuai urutan di Master Status Project.
const statusFilterOptions = computed<FilterOption[]>(() => {
  const map = new Map<number, FilterOption & { order: number }>()

  for (const status of projectStatuses.value) {
    map.set(status.id, { value: status.id, label: status.nama, color: status.warna, order: status.urutan })
  }
  for (const project of projects.value) {
    if (project.status_id != null && project.status_rel && !map.has(project.status_id)) {
      map.set(project.status_id, {
        value: project.status_id,
        label: project.status_rel.nama,
        color: project.status_rel.warna,
        order: project.status_rel.urutan,
      })
    }
  }

  return [...map.values()]
    .sort((a, b) => a.order - b.order || a.label.localeCompare(b.label, 'id'))
    .map(({ value, label, color }) => ({ value, label, color }))
})

const hasActiveFilters = computed(
  () => salesFilter.value.length > 0 || customerFilter.value.length > 0 || statusFilter.value.length > 0,
)

function resetFilters() {
  salesFilter.value = []
  customerFilter.value = []
  statusFilter.value = []
}

/* ---------- Filter, urutan, pagination ---------- */

const filteredProjects = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  return projects.value.filter((project) => {
    if (salesFilter.value.length > 0 && !salesFilter.value.includes(project.sales_id)) return false
    if (customerFilter.value.length > 0 && !customerFilter.value.includes(project.customer_id)) return false
    if (
      statusFilter.value.length > 0 &&
      !(project.status_id != null && statusFilter.value.includes(project.status_id))
    ) {
      return false
    }

    if (!keyword) return true

    return [
      project.nama_project,
      statusName(project),
      project.pipeline_status,
      project.deskripsi,
      customerName(project),
      salesName(project),
    ].some((value) => String(value ?? '').toLowerCase().includes(keyword))
  })
})

function sortValue(project: Project, key: SortKey): number | null {
  const raw = project[key]
  if (raw === null || raw === undefined || raw === '') return null

  if (key === 'nilai_proyek') {
    const amount = Number(raw)
    return Number.isNaN(amount) ? null : amount
  }

  const time = new Date(raw).getTime()
  return Number.isNaN(time) ? null : time
}

// Data kosong selalu di paling bawah, apa pun arah urutannya.
const sortedProjects = computed(() => {
  const key = sortKey.value
  if (!key) return filteredProjects.value

  const direction = sortDir.value === 'asc' ? 1 : -1

  return [...filteredProjects.value].sort((a, b) => {
    const valueA = sortValue(a, key)
    const valueB = sortValue(b, key)

    if (valueA === null && valueB === null) return 0
    if (valueA === null) return 1
    if (valueB === null) return -1
    return (valueA - valueB) * direction
  })
})

const pagedProjects = computed(() => sortedProjects.value.slice(first.value, first.value + rows.value))

// Klik judul kolom: naik -> turun -> kembali ke urutan awal.
function toggleSort(key: SortKey) {
  if (sortKey.value !== key) {
    sortKey.value = key
    sortDir.value = 'asc'
  } else if (sortDir.value === 'asc') {
    sortDir.value = 'desc'
  } else {
    sortKey.value = null
    sortDir.value = 'asc'
  }
}

function sortIcon(key: SortKey) {
  if (sortKey.value !== key) return 'pi pi-sort-alt opacity-50'
  return sortDir.value === 'asc' ? 'pi pi-sort-amount-up-alt' : 'pi pi-sort-amount-down'
}

function ariaSort(key: SortKey) {
  if (sortKey.value !== key) return 'none'
  return sortDir.value === 'asc' ? 'ascending' : 'descending'
}

// Kembali ke halaman pertama saat pencarian, filter, urutan, atau jumlah per halaman berubah.
watch([search, salesFilter, customerFilter, statusFilter, sortKey, sortDir, rows], () => {
  first.value = 0
})

// Kalau data berkurang (mis. setelah hapus) dan halaman saat ini jadi kosong, mundur ke halaman terakhir.
watch(
  () => filteredProjects.value.length,
  (total) => {
    if (first.value >= total && total > 0) {
      first.value = Math.floor((total - 1) / rows.value) * rows.value
    }
  },
)

/* ---------- Aksi dan data ---------- */

function openCreate() {
  selectedEdit.value = null
  formVisible.value = true
}

function openEdit(project: Project) {
  selectedEdit.value = project
  formVisible.value = true
}

function openDetail(project: Project) {
  router.push(projectDetailPath(project.id))
}

async function fetchProjects() {
  loading.value = true
  errorMessage.value = ''
  void fetchSummary()

  try {
    projects.value = await getProjects()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar project')
  } finally {
    loading.value = false
  }
}

async function fetchCustomers() {
  try {
    customers.value = await getCustomers()
  } catch {
    customers.value = []
  }
}

async function fetchStatuses() {
  try {
    projectStatuses.value = await getProjectStatuses()
  } catch {
    projectStatuses.value = []
  }
}

function confirmDelete(project: Project) {
  confirm.require({
    header: 'Hapus Project',
    message: `Apakah Anda yakin ingin menghapus project ${project.nama_project}? Tindakan ini tidak dapat dibatalkan.`,
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
      actionError.value = ''
      try {
        await deleteProject(project.id)
        await fetchProjects()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menghapus project')
      }
    },
  })
}

async function fetchUsers() {
  try {
    users.value = await getUsers()
  } catch {
    users.value = []
  }
}

onMounted(() => {
  fetchProjects()
  fetchCustomers()
  fetchStatuses()
  if (canManage.value) fetchUsers()
})
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
          @click="fetchProjects"
        />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <!-- Ringkasan di atas tabel -->
    <Message v-if="summaryError" severity="warn" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>Ringkasan project gagal dimuat.</span>
        <Button label="Coba lagi" size="small" variant="text" :loading="summaryLoading" @click="fetchSummary" />
      </div>
    </Message>

    <div
      v-else
      class="grid gap-4 transition-opacity sm:grid-cols-3"
      :class="summaryLoading && 'opacity-60'"
      :aria-busy="summaryLoading"
    >
      <div v-for="card in summaryCards" :key="card.key" class="rounded-xl border border-line bg-card p-5">
        <div class="flex items-center justify-between gap-3">
          <p class="text-sm text-fg-muted">{{ card.label }}</p>
          <i :class="card.icon" class="text-fg-muted" />
        </div>
        <p class="mt-2 text-2xl font-semibold tabular-nums">{{ card.value }}</p>
        <p class="mt-1 text-xs text-fg-muted tabular-nums">{{ card.hint || '\u00A0' }}</p>
      </div>
    </div>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 xl:flex-row xl:items-center xl:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar project</h2>
          <p class="mt-1 text-sm text-fg-muted">{{ filteredProjects.length }} project ditampilkan</p>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <MultiSelect
            v-model="salesFilter"
            :options="salesFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua sales"
            filter
            filter-placeholder="Cari sales..."
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} sales dipilih"
            empty-message="Tidak ada sales"
            empty-filter-message="Sales tidak ditemukan"
            size="small"
            class="w-44"
            aria-label="Filter sales"
          />

          <MultiSelect
            v-model="customerFilter"
            :options="customerFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua customer"
            filter
            filter-placeholder="Cari customer..."
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} customer dipilih"
            empty-message="Tidak ada customer"
            empty-filter-message="Customer tidak ditemukan"
            size="small"
            class="w-48"
            aria-label="Filter customer"
          />

          <MultiSelect
            v-model="statusFilter"
            :options="statusFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua status"
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} status dipilih"
            empty-message="Tidak ada status"
            size="small"
            class="w-44"
            aria-label="Filter status project"
          >
            <template #option="{ option }">
              <div class="flex items-center gap-2">
                <span
                  class="size-3 shrink-0 rounded-full border border-line"
                  :style="{ backgroundColor: option.color ?? 'transparent' }"
                />
                <span>{{ option.label }}</span>
              </div>
            </template>
          </MultiSelect>

          <InputText
            v-model="search"
            placeholder="Cari project..."
            aria-label="Cari project"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            v-if="hasActiveFilters"
            label="Reset filter"
            icon="pi pi-filter-slash"
            size="small"
            variant="text"
            severity="secondary"
            class="whitespace-nowrap"
            @click="resetFilters"
          />

          <Button
            v-if="canManage"
            label="Tambah project"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="openCreate"
          />
        </div>
      </div>

      <div
        v-if="loading && projects.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar project...
      </div>

      <div
        v-else-if="!errorMessage && filteredProjects.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-briefcase text-3xl text-fg-muted" />

        <p class="font-medium">{{ search || hasActiveFilters ? 'Project tidak ditemukan' : 'Belum ada project' }}</p>

        <p class="text-sm text-fg-muted">
          {{ search || hasActiveFilters ? 'Coba kata kunci atau filter lain.' : 'Data project akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="projects.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[1200px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Project</th>
              <th class="px-5 py-3 font-medium">Customer</th>
              <th class="px-5 py-3 font-medium">Sales</th>
              <th class="px-5 py-3 text-right font-medium" :aria-sort="ariaSort('nilai_proyek')">
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 font-medium hover:text-fg"
                  @click="toggleSort('nilai_proyek')"
                >
                  Nilai proyek
                  <i :class="sortIcon('nilai_proyek')" class="text-[0.7rem]" />
                </button>
              </th>
              <th class="px-5 py-3 font-medium" :aria-sort="ariaSort('estimasi_closing')">
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 font-medium hover:text-fg"
                  @click="toggleSort('estimasi_closing')"
                >
                  Estimasi closing
                  <i :class="sortIcon('estimasi_closing')" class="text-[0.7rem]" />
                </button>
              </th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th class="px-5 py-3 font-medium">Pipeline</th>
              <th class="px-5 py-3 font-medium" :aria-sort="ariaSort('created_at')">
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 font-medium hover:text-fg"
                  @click="toggleSort('created_at')"
                >
                  Dibuat
                  <i :class="sortIcon('created_at')" class="text-[0.7rem]" />
                </button>
              </th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="project in pagedProjects"
              :key="project.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4">
                <p class="font-medium">{{ project.nama_project }}</p>
                <p v-if="project.deskripsi" class="max-w-72 truncate text-xs text-fg-muted">
                  {{ project.deskripsi }}
                </p>
              </td>

              <td class="px-5 py-4 text-fg-muted">{{ customerName(project) }}</td>

              <td class="px-5 py-4 text-fg-muted">{{ salesName(project) }}</td>

              <td class="whitespace-nowrap px-5 py-4 text-right tabular-nums">
                {{ formatRupiah(project.nilai_proyek) }}
              </td>

              <td class="whitespace-nowrap px-5 py-4 text-fg-muted">
                {{ formatClosing(project.estimasi_closing) }}
              </td>

              <td class="px-5 py-4">
                <span
                  v-if="statusName(project)"
                  class="inline-flex items-center rounded-md border border-line px-2.5 py-1 text-xs font-medium"
                  :style="
                    statusColor(project)
                      ? { backgroundColor: statusColor(project) ?? undefined, color: statusTextColor(project), borderColor: statusColor(project) ?? undefined }
                      : undefined
                  "
                >
                  {{ statusName(project) }}
                </span>
                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-5 py-4">
                <span
                  v-if="project.pipeline_status"
                  class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="pipelineClass(project.pipeline_status)"
                >
                  {{ project.pipeline_status }}
                </span>
                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-5 py-4 text-fg-muted">{{ formatDate(project.created_at) }}</td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-eye"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Lihat detail project"
                    v-tooltip.top="'Lihat detail'"
                    @click="openDetail(project)"
                  />

                  <template v-if="canManage">
                    <Button
                      icon="pi pi-pencil"
                      variant="text"
                      rounded
                      severity="secondary"
                      aria-label="Edit project"
                      v-tooltip.top="'Edit project'"
                      @click="openEdit(project)"
                    />

                    <Button
                      icon="pi pi-trash"
                      variant="text"
                      rounded
                      severity="danger"
                      aria-label="Hapus project"
                      v-tooltip.top="'Hapus project'"
                      @click="confirmDelete(project)"
                    />
                  </template>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <Paginator
        v-if="filteredProjects.length > 0"
        v-model:first="first"
        v-model:rows="rows"
        :total-records="filteredProjects.length"
        :rows-per-page-options="PAGE_SIZES"
        template="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink RowsPerPageDropdown CurrentPageReport"
        current-page-report-template="{first}–{last} dari {totalRecords}"
        class="border-t border-line"
      />

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ projects.length }} project
      </footer>
    </section>

    <ProjectFormDialog
      v-model:visible="formVisible"
      :project="selectedEdit"
      :customer-options="customerOptions"
      :sales-options="salesOptions"
      @saved="fetchProjects"
    />
  </div>
</template>