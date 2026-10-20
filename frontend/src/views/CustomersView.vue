<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import CustomerFormDialog, {
  type SalesOption,
} from '../components/CustomerPage/CustomerFormDialog.vue'

import { deleteCustomer, getCustomers, type Customer } from '../api/customers'
import { getUsers, type User } from '../api/users'
import { getAreas, type Area } from '../api/areas'
import { getErrorMessage } from '../utils/error'

const confirm = useConfirm()

const customers = ref<Customer[]>([])
const users = ref<User[]>([])
const areas = ref<Area[]>([])

const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')
const formVisible = ref(false)
const selectedEdit = ref<Customer | null>(null)

const salesOptions = computed<SalesOption[]>(() =>
  users.value
    .filter((user) => user.role === 'SALES')
    .map((user) => ({
      value: user.id,
      label: user.is_active ? user.nama : `${user.nama} (nonaktif)`,
      areaId: user.area_id ?? null,
    })),
)

const salesNames = computed(
  () => new Map(users.value.map((user) => [user.id, user.nama])),
)

const areaNames = computed(
  () => new Map(areas.value.map((area) => [area.id, area.nama])),
)

function salesName(customer: Customer) {
  if (customer.sales_id == null) return '-'

  return salesNames.value.get(customer.sales_id) ?? `ID ${customer.sales_id}`
}

function areaName(areaId: number | null | undefined) {
  if (areaId == null) return '-'

  return areaNames.value.get(areaId) ?? `Area ID ${areaId}`
}

const filteredCustomers = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return customers.value

  return customers.value.filter((customer) =>
    [
      customer.nama_instansi,
      customer.nama_pic,
      customer.kontak_pic,
      customer.kota,
      customer.kategori,
      customer.area_id,
      areaName(customer.area_id),
      salesName(customer),
    ].some((value) =>
      String(value ?? '').toLowerCase().includes(keyword),
    ),
  )
})

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
  } catch {
    users.value = []
  }
}

async function fetchAreas() {
  try {
    areas.value = await getAreas()
  } catch {
    areas.value = []
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
  fetchUsers()
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
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar customer</h2>
          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredCustomers.length }} customer ditampilkan
          </p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari customer..."
            aria-label="Cari customer"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah customer"
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
          {{ search ? 'Customer tidak ditemukan' : 'Belum ada customer' }}
        </p>
        <p class="text-sm text-fg-muted">
          {{ search ? 'Coba kata kunci lain.' : 'Data customer akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="customers.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[1000px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Instansi</th>
              <th class="px-5 py-3 font-medium">PIC</th>
              <th class="px-5 py-3 font-medium">Kategori</th>
              <th class="px-5 py-3 font-medium">Area ID</th>
              <th class="px-5 py-3 font-medium">Sales</th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="customer in filteredCustomers"
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
                {{ areaName(customer.area_id) }}
              </td>
              <td class="px-5 py-4 text-fg-muted">{{ salesName(customer) }}</td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
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
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ customers.length }} customer
      </footer>
    </section>

    <CustomerFormDialog
      v-model:visible="formVisible"
      :customer="selectedEdit"
      :sales-options="salesOptions"
      @saved="fetchCustomers"
    />
  </div>
</template>
