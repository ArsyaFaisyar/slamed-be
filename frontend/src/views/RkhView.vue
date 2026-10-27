<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import InputText from 'primevue/inputtext'
import MultiSelect from 'primevue/multiselect'
import Paginator from 'primevue/paginator'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import RkhFormDialog from '../components/RkhPage/RkhFormDialog.vue'
import EditRkhDialog from '../components/RkhPage/EditRkhDialog.vue'
import RkhDetailDialog from '../components/RkhPage/RkhDetailDialog.vue'
import type { Option, ProjectOption } from '../components/RkhPage/Types'

import { deleteRkh, getRkh, type Rkh } from '../api/rkh'
import { getLkh, type Lkh } from '../api/lkh'
import { getCustomers, isCustomerApproved, type Customer } from '../api/customers'
import { getProjects, type Project } from '../api/projects'
import { getUsers, type User } from '../api/users'
import { getErrorMessage } from '../utils/error'
import { formatDate } from '../utils/date'

const confirm = useConfirm()

const PAGE_SIZES = [10, 25, 50]

const items = ref<Rkh[]>([])
const lkhList = ref<Lkh[]>([])
const customers = ref<Customer[]>([])
const projects = ref<Project[]>([])
const users = ref<User[]>([])

// Pencarian, filter (checklist), dan pagination
const search = ref('')
const salesFilter = ref<number[]>([])
const customerFilter = ref<number[]>([])
const projectFilter = ref<number[]>([])
const statusFilter = ref<string[]>([])
const first = ref(0)
const rows = ref(PAGE_SIZES[0])

const loading = ref(false)
const errorMessage = ref('')

const createDialogVisible = ref(false)
const editDialogVisible = ref(false)
const selectedEditRkh = ref<Rkh | null>(null)
const detailDialogVisible = ref(false)
const selectedDetailRkh = ref<Rkh | null>(null)

const LOCKED_HINT = 'LKH sudah dibuat, RKH tidak bisa diubah'

// RKH yang sudah punya LKH (dibuat pertama kali) dikunci: tidak bisa diedit/dihapus.
const lockedRkhIds = computed(() => new Set(lkhList.value.map((lkh) => Number(lkh.rkh_id))))

function isLocked(item: Rkh) {
  return lockedRkhIds.value.has(Number(item.id))
}

// Hanya customer yang sudah disetujui yang bisa dipilih di form RKH.
const customerOptions = computed<Option[]>(() =>
  customers.value.filter(isCustomerApproved).map((customer) => ({
    label: customer.nama_instansi,
    value: Number(customer.id),
  })),
)

// Safe fallback untuk mapping project options
const projectOptions = computed<ProjectOption[]>(() =>
  (Array.isArray(projects.value) ? projects.value : [])
    .map((project) => {
      const labelName = project?.nama_project ?? (project as unknown as Record<string, string>)?.nama ?? ''
      return {
        label: String(labelName),
        value: Number(project?.id),
        customer_id: Number(project?.customer_id),
      }
    })
    .filter((opt) => opt.label.trim() !== '' && !isNaN(opt.value) && !isNaN(opt.customer_id)),
)

const customerNameById = computed(
  () =>
    new Map(
      customers.value.map((customer) => [
        Number(customer.id),
        customer.nama_instansi,
      ]),
    ),
)

const projectNameById = computed(
  () =>
    new Map(
      (Array.isArray(projects.value) ? projects.value : []).map((project) => [
        Number(project.id),
        project.nama_project ?? (project as unknown as Record<string, string>)?.nama ?? `ID ${project.id}`,
      ]),
    ),
)

const userNameById = computed(
  () =>
    new Map(
      (Array.isArray(users.value) ? users.value : []).map((user) => [
        Number(user.id),
        user.nama ?? (user as unknown as Record<string, string>)?.name ?? `ID ${user.id}`,
      ]),
    ),
)

function customerName(id: number) {
  return customerNameById.value.get(Number(id)) ?? `ID ${id}`
}
function projectName(id: number) {
  return projectNameById.value.get(Number(id)) ?? `ID ${id}`
}
function salesName(id: number) {
  return userNameById.value.get(Number(id)) ?? `ID ${id}`
}

/* ---------- Opsi filter (checklist) ---------- */

interface FilterOption {
  value: number | string
  label: string
}

function byLabel(a: FilterOption, b: FilterOption) {
  return a.label.localeCompare(b.label, 'id')
}

// Hanya sales, customer, dan project yang benar-benar dipakai di daftar RKH.
const salesFilterOptions = computed<FilterOption[]>(() =>
  [...new Set(items.value.map((item) => Number(item.sales_id)))]
    .map((id) => ({ value: id, label: salesName(id) }))
    .sort(byLabel),
)

const customerFilterOptions = computed<FilterOption[]>(() =>
  [...new Set(items.value.map((item) => Number(item.customer_id)))]
    .map((id) => ({ value: id, label: customerName(id) }))
    .sort(byLabel),
)

// Kalau customer dipilih, pilihan project dipersempit ke project milik customer itu.
const projectFilterOptions = computed<FilterOption[]>(() => {
  const customerIds = customerFilter.value

  return [
    ...new Set(
      items.value
        .filter((item) => customerIds.length === 0 || customerIds.includes(Number(item.customer_id)))
        .map((item) => Number(item.project_id)),
    ),
  ]
    .map((id) => ({ value: id, label: projectName(id) }))
    .sort(byLabel)
})

const statusFilterOptions = computed<FilterOption[]>(() =>
  [...new Set(items.value.map((item) => item.status).filter(Boolean))]
    .map((status) => ({ value: status, label: status }))
    .sort(byLabel),
)

const hasActiveFilters = computed(
  () =>
    salesFilter.value.length > 0 ||
    customerFilter.value.length > 0 ||
    projectFilter.value.length > 0 ||
    statusFilter.value.length > 0,
)

function resetFilters() {
  salesFilter.value = []
  customerFilter.value = []
  projectFilter.value = []
  statusFilter.value = []
}

/* ---------- Filter dan pagination ---------- */

const filteredItems = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  return items.value.filter((item) => {
    if (salesFilter.value.length > 0 && !salesFilter.value.includes(Number(item.sales_id))) return false
    if (customerFilter.value.length > 0 && !customerFilter.value.includes(Number(item.customer_id))) return false
    if (projectFilter.value.length > 0 && !projectFilter.value.includes(Number(item.project_id))) return false
    if (statusFilter.value.length > 0 && !statusFilter.value.includes(item.status)) return false

    if (!keyword) return true

    return [
      item.judul_kegiatan,
      item.tipe_aktivitas,
      customerName(item.customer_id),
      projectName(item.project_id),
      salesName(item.sales_id),
    ].some((value) => (value ?? '').toLowerCase().includes(keyword))
  })
})

const pagedItems = computed(() => filteredItems.value.slice(first.value, first.value + rows.value))

// Pilihan project yang tidak lagi cocok dengan customer terpilih dibuang dari filter.
watch(customerFilter, () => {
  const allowed = new Set(projectFilterOptions.value.map((option) => option.value))
  projectFilter.value = projectFilter.value.filter((id) => allowed.has(id))
})

// Kembali ke halaman pertama saat pencarian, filter, atau jumlah per halaman berubah.
watch([search, salesFilter, customerFilter, projectFilter, statusFilter, rows], () => {
  first.value = 0
})

// Kalau data berkurang (mis. setelah hapus) dan halaman saat ini jadi kosong, mundur ke halaman terakhir.
watch(
  () => filteredItems.value.length,
  (total) => {
    if (first.value >= total && total > 0) {
      first.value = Math.floor((total - 1) / rows.value) * rows.value
    }
  },
)

/* ---------- Aksi dan data ---------- */

function openDetail(item: Rkh) {
  selectedDetailRkh.value = item
  detailDialogVisible.value = true
}

function openEdit(item: Rkh) {
  if (isLocked(item)) return
  selectedEditRkh.value = item
  editDialogVisible.value = true
}

function confirmDelete(item: Rkh) {
  if (isLocked(item)) return

  confirm.require({
    header: 'Hapus RKH',
    message: `Yakin ingin menghapus RKH "${item.judul_kegiatan}"? Tindakan ini tidak dapat dibatalkan.`,
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
        await deleteRkh(item.id)
        await fetchItems()
      } catch (error) {
        errorMessage.value = getErrorMessage(error, 'Gagal menghapus RKH')
      }
    },
  })
}

async function fetchItems() {
  loading.value = true
  errorMessage.value = ''

  try {
    const [rkhData, customerList, projectList, lkhData] = await Promise.all([
      getRkh(),
      getCustomers(),
      getProjects(),
      getLkh(),
    ])
    items.value = Array.isArray(rkhData) ? rkhData : []
    customers.value = Array.isArray(customerList) ? customerList : []
    projects.value = Array.isArray(projectList) ? projectList : []
    lkhList.value = Array.isArray(lkhData) ? lkhData : []
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar RKH')
  } finally {
    loading.value = false
  }

  try {
    const userList = await getUsers()
    users.value = Array.isArray(userList) ? userList : []
  } catch {
    users.value = []
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
        class="flex flex-col gap-3 border-b border-line p-4 xl:flex-row xl:items-center xl:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar RKH</h2>
          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredItems.length }} RKH ditampilkan
          </p>
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
            v-model="projectFilter"
            :options="projectFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua project"
            filter
            filter-placeholder="Cari project..."
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} project dipilih"
            empty-message="Tidak ada project"
            empty-filter-message="Project tidak ditemukan"
            size="small"
            class="w-48"
            aria-label="Filter project"
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
            class="w-40"
            aria-label="Filter status"
          />

          <InputText
            v-model="search"
            placeholder="Cari RKH..."
            aria-label="Cari RKH"
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
            label="Tambah RKH"
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
        Memuat daftar RKH...
      </div>

      <div
        v-else-if="!errorMessage && filteredItems.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-calendar text-3xl text-fg-muted" />

        <p class="font-medium">
          {{ search || hasActiveFilters ? 'RKH tidak ditemukan' : 'Belum ada RKH' }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            search || hasActiveFilters
              ? 'Coba kata kunci atau filter lain.'
              : 'Data RKH akan muncul di sini.'
          }}
        </p>
      </div>

      <div
        v-else-if="items.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <!-- Ringkas: detail lengkap (tipe, estimasi biaya, rencana kegiatan) ada di modal detail -->
        <table class="w-full min-w-[780px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-6 py-3.5 font-medium">Tanggal</th>
              <th class="px-6 py-3.5 font-medium">Kegiatan</th>
              <th class="px-6 py-3.5 font-medium">Sales</th>
              <th class="px-6 py-3.5 font-medium">Status</th>
              <th class="w-36 px-6 py-3.5 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="item in pagedItems"
              :key="item.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="whitespace-nowrap px-6 py-5 align-top">
                <div class="font-medium">
                  {{ formatDate(item.tanggal_rencana) }}
                </div>
                <div
                  v-if="item.tanggal_pelaksanaan"
                  class="mt-1 text-xs text-fg-muted"
                >
                  Terlaksana {{ formatDate(item.tanggal_pelaksanaan) }}
                </div>
              </td>

              <td class="max-w-[420px] px-6 py-5 align-top">
                <div class="font-medium">{{ item.judul_kegiatan }}</div>
                <div class="mt-1 line-clamp-1 text-xs text-fg-muted">
                  {{ customerName(item.customer_id) }} · {{ projectName(item.project_id) }}
                </div>
              </td>

              <td class="whitespace-nowrap px-6 py-5 align-top text-fg-muted">
                {{ salesName(item.sales_id) }}
              </td>

              <td class="px-6 py-5 align-top">
                <span
                  class="inline-flex rounded-full bg-sidebar px-2.5 py-1 text-xs font-medium capitalize"
                >
                  {{ item.status }}
                </span>
              </td>

              <td class="px-6 py-4 text-center align-top">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-eye"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Lihat detail RKH"
                    v-tooltip.top="'Lihat detail'"
                    @click="openDetail(item)"
                  />

                  <!-- Dikunci: sudah ada LKH -->
                  <template v-if="isLocked(item)">
                    <span v-tooltip.top="LOCKED_HINT" class="inline-flex">
                      <Button
                        icon="pi pi-lock"
                        variant="text"
                        rounded
                        severity="secondary"
                        aria-label="RKH terkunci, LKH sudah dibuat"
                        disabled
                      />
                    </span>
                  </template>

                  <template v-else>
                    <Button
                      icon="pi pi-pencil"
                      variant="text"
                      rounded
                      severity="secondary"
                      aria-label="Edit RKH"
                      v-tooltip.top="'Edit RKH'"
                      @click="openEdit(item)"
                    />

                    <Button
                      icon="pi pi-trash"
                      variant="text"
                      rounded
                      severity="danger"
                      aria-label="Hapus RKH"
                      v-tooltip.top="'Hapus RKH'"
                      @click="confirmDelete(item)"
                    />
                  </template>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <Paginator
        v-if="filteredItems.length > 0"
        v-model:first="first"
        v-model:rows="rows"
        :total-records="filteredItems.length"
        :rows-per-page-options="PAGE_SIZES"
        template="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink RowsPerPageDropdown CurrentPageReport"
        current-page-report-template="{first}–{last} dari {totalRecords}"
        class="border-t border-line"
      />

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ items.length }} RKH
      </footer>
    </section>

    <RkhDetailDialog
      v-model:visible="detailDialogVisible"
      :rkh="selectedDetailRkh"
      :customer-name="selectedDetailRkh ? customerName(selectedDetailRkh.customer_id) : '-'"
      :project-name="selectedDetailRkh ? projectName(selectedDetailRkh.project_id) : '-'"
      :sales-name="selectedDetailRkh ? salesName(selectedDetailRkh.sales_id) : '-'"
      :locked="selectedDetailRkh ? isLocked(selectedDetailRkh) : false"
    />

    <RkhFormDialog
      v-model:visible="createDialogVisible"
      :customer-options="customerOptions"
      :project-options="projectOptions"
      @created="fetchItems"
    />

    <EditRkhDialog
      v-if="selectedEditRkh"
      v-model:visible="editDialogVisible"
      :rkh="selectedEditRkh"
      :customer-options="customerOptions"
      :project-options="projectOptions"
      @updated="fetchItems"
    />
  </div>
</template>