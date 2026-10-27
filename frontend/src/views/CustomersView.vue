<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import MultiSelect from 'primevue/multiselect'
import Paginator from 'primevue/paginator'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import CustomerFormDialog, {
  type SalesOption,
} from '../components/CustomerPage/CustomerFormDialog.vue'

import {
  APPROVAL_LABELS,
  deleteCustomer,
  getCustomers,
  type ApprovalStatus,
  type Customer,
} from '../api/customers'
import { getUsers, type User } from '../api/users'
import { getAreas, type Area } from '../api/areas'
import { getErrorMessage } from '../utils/error'
import { useAuthStore } from '../stores/auth'
import type { UserRole } from '../constant/roles'

const confirm = useConfirm()
const auth = useAuthStore()

const PAGE_SIZES = [10, 25, 50]

const customers = ref<Customer[]>([])
const users = ref<User[]>([])
const areas = ref<Area[]>([])

const search = ref('')
const statusFilter = ref<ApprovalStatus | null>(null)
const areaFilter = ref<number[]>([])
const salesFilter = ref<number[]>([])

// Pagination
const first = ref(0)
const rows = ref(PAGE_SIZES[0])

const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')
const formVisible = ref(false)
const selectedEdit = ref<Customer | null>(null)

const isSales = computed(() => auth.user?.role === 'SALES')

const canManage = computed(() =>
  (['SUPERADMIN', 'SPV'] as UserRole[]).includes(
    auth.user?.role as UserRole,
  ),
)

// Sales boleh mengajukan customer baru (menunggu persetujuan SPV).
const canCreate = computed(() => canManage.value || isSales.value)

const statusOptions = (Object.keys(APPROVAL_LABELS) as ApprovalStatus[]).map((status) => ({
  value: status,
  label: APPROVAL_LABELS[status],
}))

const statusClasses: Record<ApprovalStatus, string> = {
  PENDING: 'bg-amber-500/10 text-amber-700 dark:text-amber-400',
  APPROVED: 'bg-green-500/10 text-green-700 dark:text-green-400',
  REJECTED: 'bg-red-500/10 text-red-700 dark:text-red-400',
}

// Sales hanya bisa memilih dirinya sendiri; role lain memilih dari daftar user.
const salesOptions = computed<SalesOption[]>(() => {
  if (isSales.value) {
    const currentUser = auth.user as {
      id: number
      nama: string
      area_id?: number | null
    } | null
    if (!currentUser) return []

    return [
      {
        value: currentUser.id,
        label: currentUser.nama,
        areaId: currentUser.area_id ?? null,
      },
    ]
  }

  return users.value
    .filter((user) => user.role === 'SALES')
    .map((user): SalesOption => ({
      value: user.id,
      label: user.is_active ? user.nama : `${user.nama} (nonaktif)`,
      areaId: user.area_id ?? null,
    }))
})

function salesName(customer: Customer) {
  return customer.sales_nama ?? '-'
}

function areaName(customer: Customer) {
  return customer.area_nama ?? '-'
}

// Opsi filter diambil dari data customer yang bisa dilihat user, jadi tidak butuh akses ke daftar area/user.
function uniqueOptions(pairs: Array<[number | null, string | null]>, fallbackPrefix: string) {
  const map = new Map<number, string>()

  for (const [id, name] of pairs) {
    if (id != null && (name || !map.has(id))) map.set(id, name || `${fallbackPrefix} ${id}`)
  }

  return [...map]
    .map(([value, label]) => ({ value, label }))
    .sort((a, b) => a.label.localeCompare(b.label, 'id'))
}

// Semua area/sales yang tersedia (dari daftar area dan user bila boleh diakses), ditambah yang muncul di data customer.
const areaFilterOptions = computed(() =>
  uniqueOptions(
    [
      ...areas.value.map((area): [number | null, string | null] => [area.id, area.nama]),
      ...customers.value.map((c): [number | null, string | null] => [c.area_id, c.area_nama]),
    ],
    'Area',
  ),
)

const salesFilterOptions = computed(() =>
  uniqueOptions(
    [
      ...users.value
        .filter((user) => user.role === 'SALES')
        .map((user): [number | null, string | null] => [user.id, user.nama]),
      ...customers.value.map((c): [number | null, string | null] => [c.sales_id, c.sales_nama]),
    ],
    'Sales',
  ),
)

const hasActiveFilters = computed(
  () => !!statusFilter.value || areaFilter.value.length > 0 || salesFilter.value.length > 0,
)

function resetFilters() {
  statusFilter.value = null
  areaFilter.value = []
  salesFilter.value = []
}

const filteredCustomers = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  return customers.value.filter((customer) => {
    if (statusFilter.value && customer.approval_status !== statusFilter.value) return false

    if (areaFilter.value.length > 0 && !(customer.area_id != null && areaFilter.value.includes(customer.area_id))) {
      return false
    }

    if (salesFilter.value.length > 0 && !(customer.sales_id != null && salesFilter.value.includes(customer.sales_id))) {
      return false
    }

    if (!keyword) return true

    return [
      customer.nama_instansi,
      customer.nama_pic,
      customer.kontak_pic,
      customer.kota,
      customer.kategori,
      customer.area_id,
      areaName(customer),
      salesName(customer),
    ].some((value) =>
      String(value ?? '').toLowerCase().includes(keyword),
    )
  })
})

const pagedCustomers = computed(() =>
  filteredCustomers.value.slice(first.value, first.value + rows.value),
)

// Kembali ke halaman pertama saat pencarian atau filter berubah.
watch([search, statusFilter, areaFilter, salesFilter, rows], () => {
  first.value = 0
})

// Kalau data berkurang (mis. setelah hapus) dan halaman saat ini jadi kosong, mundur ke halaman terakhir.
watch(
  () => filteredCustomers.value.length,
  (total) => {
    if (first.value >= total && total > 0) {
      first.value = Math.floor((total - 1) / rows.value) * rows.value
    }
  },
)

async function fetchCustomers() {
  loading.value = true
  errorMessage.value = ''

  try {
    customers.value = await getCustomers()
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      'Gagal memuat daftar customer',
    )
  } finally {
    loading.value = false
  }
}

async function fetchUsers() {
  try {
    users.value = await getUsers()
  } catch (error) {
    users.value = []
    console.error('Gagal memuat data user:', getErrorMessage(error, 'Error memuat user'))
  }
}

async function fetchAreas() {
  try {
    areas.value = await getAreas()
  } catch (error) {
    areas.value = []
    console.error('Gagal memuat data area:', getErrorMessage(error, 'Error memuat area'))
  }
}

function openCreate() {
  selectedEdit.value = null
  actionError.value = ''
  formVisible.value = true
}

function openEdit(customer: Customer) {
  selectedEdit.value = customer
  actionError.value = ''
  formVisible.value = true
}

function closeForm() {
  formVisible.value = false
  selectedEdit.value = null
}

function confirmDelete(customer: Customer) {
  confirm.require({
    message: `Apakah Anda yakin ingin menghapus customer "${customer.nama_instansi}"?`,
    header: 'Konfirmasi Hapus Customer',
    icon: 'pi pi-exclamation-triangle',
    rejectLabel: 'Batal',
    acceptLabel: 'Hapus',
    acceptClass: 'p-button-danger',
    accept: async () => {
      actionError.value = ''

      try {
        await deleteCustomer(customer.id)
        await fetchCustomers()
      } catch (error) {
        actionError.value = getErrorMessage(
          error,
          'Gagal menghapus customer',
        )
      }
    },
  })
}

onMounted(() => {
  fetchCustomers()
  // Sales tidak perlu daftar user (opsi sales diambil dari akunnya sendiri).
  if (!isSales.value) fetchUsers()
  fetchAreas()
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
          @click="fetchCustomers"
        />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">
      {{ actionError }}
    </Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 xl:flex-row xl:items-center xl:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar customer</h2>
          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredCustomers.length }} customer ditampilkan
          </p>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <MultiSelect
            v-model="areaFilter"
            :options="areaFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua area"
            filter
            filter-placeholder="Cari area..."
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} area dipilih"
            empty-message="Tidak ada area"
            empty-filter-message="Area tidak ditemukan"
            size="small"
            class="w-44"
            aria-label="Filter area"
          />

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

          <Select
            v-model="statusFilter"
            :options="statusOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua status"
            show-clear
            size="small"
            class="w-40"
            aria-label="Filter status approval"
          />

          <InputText
            v-model="search"
            placeholder="Cari customer..."
            aria-label="Cari customer"
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
            v-if="canCreate"
            :label="isSales ? 'Ajukan customer' : 'Tambah customer'"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="openCreate"
          />
        </div>
      </div>

      <div
        v-if="loading && customers.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg"></i>
        Memuat daftar customer...
      </div>

      <div
        v-else-if="!errorMessage && filteredCustomers.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-users text-3xl text-fg-muted"></i>
        <p class="font-medium">
          {{ search || hasActiveFilters ? 'Customer tidak ditemukan' : 'Belum ada customer' }}
        </p>
        <p class="text-sm text-fg-muted">
          {{ search || hasActiveFilters ? 'Coba kata kunci atau filter lain.' : 'Data customer akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="customers.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[1100px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Instansi</th>
              <th class="px-5 py-3 font-medium">PIC</th>
              <th class="px-5 py-3 font-medium">Kategori</th>
              <th class="px-5 py-3 font-medium">Area</th>
              <th class="px-5 py-3 font-medium">Sales</th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th
                v-if="canManage || isSales"
                class="px-5 py-3 text-center font-medium"
              >
                Aksi
              </th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="customer in pagedCustomers"
              :key="customer.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4">
                <p class="font-medium">{{ customer.nama_instansi }}</p>
                <p v-if="customer.kota" class="text-xs text-fg-muted">
                  {{ customer.kota }}
                </p>
              </td>

              <td class="px-5 py-4">
                <p>{{ customer.nama_pic || '-' }}</p>
                <p v-if="customer.kontak_pic" class="text-xs text-fg-muted">
                  {{ customer.kontak_pic }}
                </p>
              </td>

              <td class="px-5 py-4">{{ customer.kategori || '-' }}</td>
              <td class="px-5 py-4 text-fg-muted">
                {{ areaName(customer) }}
              </td>
              <td class="px-5 py-4 text-fg-muted">{{ salesName(customer) }}</td>

              <td class="max-w-[240px] px-5 py-4">
                <span
                  v-if="customer.approval_status"
                  class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="statusClasses[customer.approval_status]"
                >
                  {{ APPROVAL_LABELS[customer.approval_status] }}
                </span>
                <span v-else class="text-fg-muted">-</span>

                <p
                  v-if="customer.approval_status === 'REJECTED' && customer.rejection_reason"
                  class="mt-1 line-clamp-2 text-xs text-fg-muted"
                  :title="customer.rejection_reason"
                >
                  Alasan: {{ customer.rejection_reason }}
                </p>
              </td>

              <td v-if="canManage || isSales" class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <template v-if="canManage">
                    <Button
                      icon="pi pi-pencil"
                      variant="text"
                      rounded
                      severity="secondary"
                      aria-label="Edit customer"
                      v-tooltip.top="'Edit customer'"
                      @click="openEdit(customer)"
                    />
                    <Button
                      icon="pi pi-trash"
                      variant="text"
                      rounded
                      severity="danger"
                      aria-label="Hapus customer"
                      v-tooltip.top="'Hapus customer'"
                      @click="confirmDelete(customer)"
                    />
                  </template>

                  <!-- Sales: boleh edit selama belum disetujui; menyimpan = diajukan ulang -->
                  <template v-else>
                    <Button
                      v-if="customer.approval_status !== 'APPROVED'"
                      icon="pi pi-pencil"
                      variant="text"
                      rounded
                      severity="secondary"
                      aria-label="Edit dan ajukan ulang"
                      v-tooltip.top="'Edit dan ajukan ulang'"
                      @click="openEdit(customer)"
                    />
                    <span
                      v-else
                      v-tooltip.top="'Customer yang sudah disetujui tidak bisa diedit'"
                      class="inline-flex"
                    >
                      <Button
                        icon="pi pi-lock"
                        variant="text"
                        rounded
                        severity="secondary"
                        aria-label="Customer sudah disetujui"
                        disabled
                      />
                    </span>
                  </template>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <Paginator
        v-if="filteredCustomers.length > 0"
        v-model:first="first"
        v-model:rows="rows"
        :total-records="filteredCustomers.length"
        :rows-per-page-options="PAGE_SIZES"
        template="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink RowsPerPageDropdown CurrentPageReport"
        current-page-report-template="{first}–{last} dari {totalRecords}"
        class="border-t border-line"
      />

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ customers.length }} customer
      </footer>
    </section>

    <CustomerFormDialog
      v-model:visible="formVisible"
      :customer="selectedEdit"
      :sales-options="salesOptions"
      :lock-sales="isSales"
      @saved="fetchCustomers"
    />
  </div>
</template>