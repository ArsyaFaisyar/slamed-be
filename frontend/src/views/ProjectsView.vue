<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import ProjectFormDialog, {
  type CustomerOption,
  type SalesOption,
} from '../components/ProjectPage/ProjectFormDialog.vue'

import { deleteProject, getProjects, type Project } from '../api/projects'
import { getCustomers, type Customer } from '../api/customers'
import { getUsers, type User } from '../api/users'
import type { UserRole } from '../constant/roles'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage } from '../utils/error'
import { parseDateString } from '../utils/date'

const confirm = useConfirm()

const SALES_ROLE: UserRole = 'SALES'
const MANAGER_ROLES: UserRole[] = ['SUPERADMIN', 'SPV']

const auth = useAuthStore()
const canManage = computed(() => MANAGER_ROLES.includes(auth.user?.role as UserRole))

const projects = ref<Project[]>([])
const customers = ref<Customer[]>([])
const users = ref<User[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

const formVisible = ref(false)
const selectedEdit = ref<Project | null>(null)

const dateFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' })
const rupiahFormat = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
})

const customerOptions = computed<CustomerOption[]>(() =>
  customers.value.map((customer) => ({ value: customer.id, label: customer.nama_instansi })),
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

const filteredProjects = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return projects.value

  return projects.value.filter((project) =>
    [project.nama_project, statusName(project), project.deskripsi, customerName(project), salesName(project)].some(
      (value) => String(value ?? '').toLowerCase().includes(keyword),
    ),
  )
})

function openCreate() {
  selectedEdit.value = null
  formVisible.value = true
}

function openEdit(project: Project) {
  selectedEdit.value = project
  formVisible.value = true
}

async function fetchProjects() {
  loading.value = true
  errorMessage.value = ''

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

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar project</h2>
          <p class="mt-1 text-sm text-fg-muted">{{ filteredProjects.length }} project ditampilkan</p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari project..."
            aria-label="Cari project"
            size="small"
            class="w-40 sm:w-48"
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

        <p class="font-medium">{{ search ? 'Project tidak ditemukan' : 'Belum ada project' }}</p>

        <p class="text-sm text-fg-muted">
          {{ search ? 'Coba kata kunci lain.' : 'Data project akan muncul di sini.' }}
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
              <th class="px-5 py-3 text-right font-medium">Nilai proyek</th>
              <th class="px-5 py-3 font-medium">Estimasi closing</th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th class="px-5 py-3 font-medium">Dibuat</th>
              <th v-if="canManage" class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="project in filteredProjects"
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

              <td class="px-5 py-4 text-fg-muted">{{ formatDate(project.created_at) }}</td>

              <td v-if="canManage" class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
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
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

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