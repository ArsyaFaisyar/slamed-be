<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import CustomerRejectDialog from '../components/CustomerPage/CustomerRejectDialog.vue'

import {
  APPROVAL_LABELS,
  approveCustomer,
  getCustomers,
  type ApprovalStatus,
  type Customer,
} from '../api/customers'
import { getErrorMessage } from '../utils/error'

const confirm = useConfirm()

const TABS: ApprovalStatus[] = ['PENDING', 'APPROVED', 'REJECTED']

const customers = ref<Customer[]>([])
const tab = ref<ApprovalStatus>('PENDING')
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')
const processingId = ref<number | null>(null)

const rejectVisible = ref(false)
const rejectTarget = ref<Customer | null>(null)

const dateFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' })
const dateTimeFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' })

function formatDate(value: string | null | undefined, withTime = false) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return (withTime ? dateTimeFormat : dateFormat).format(date)
}

const counts = computed(() => {
  const result: Record<ApprovalStatus, number> = { PENDING: 0, APPROVED: 0, REJECTED: 0 }
  for (const customer of customers.value) {
    if (customer.approval_status) result[customer.approval_status] += 1
  }
  return result
})

const filtered = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  return customers.value.filter((customer) => {
    if (customer.approval_status !== tab.value) return false
    if (!keyword) return true

    return [
      customer.nama_instansi,
      customer.nama_pic,
      customer.kota,
      customer.kategori,
      customer.area_nama,
      customer.sales_nama,
    ].some((value) => String(value ?? '').toLowerCase().includes(keyword))
  })
})

async function fetchCustomers() {
  loading.value = true
  errorMessage.value = ''

  try {
    const list = await getCustomers()
    customers.value = [...list].sort(
      (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    )
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar customer')
  } finally {
    loading.value = false
  }
}

function confirmApprove(customer: Customer) {
  confirm.require({
    header: 'Setujui customer',
    message: `Setujui customer "${customer.nama_instansi}"${customer.sales_nama ? ` yang diajukan ${customer.sales_nama}` : ''}?`,
    icon: 'pi pi-check-circle',
    rejectProps: { label: 'Batal', severity: 'secondary', variant: 'text' },
    acceptProps: { label: 'Setujui', severity: 'success' },
    accept: async () => {
      actionError.value = ''
      processingId.value = customer.id

      try {
        await approveCustomer(customer.id)
        await fetchCustomers()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menyetujui customer')
      } finally {
        processingId.value = null
      }
    },
  })
}

function openReject(customer: Customer) {
  actionError.value = ''
  rejectTarget.value = customer
  rejectVisible.value = true
}

onMounted(fetchCustomers)
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

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <section class="rounded-xl border border-line bg-card">
      <div class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="font-semibold">Approval customer</h2>
          <p class="mt-1 text-sm text-fg-muted">
            Tinjau customer yang diajukan sales sebelum dipakai di RKH dan project.
          </p>
        </div>

        <InputText
          v-model="search"
          placeholder="Cari customer..."
          aria-label="Cari customer"
          size="small"
          class="w-full sm:w-56"
        />
      </div>

      <div class="flex flex-wrap gap-2 border-b border-line px-4 py-3">
        <Button
          v-for="status in TABS"
          :key="status"
          type="button"
          size="small"
          :label="`${APPROVAL_LABELS[status]} (${counts[status]})`"
          :variant="tab === status ? undefined : 'outlined'"
          :severity="tab === status ? undefined : 'secondary'"
          @click="tab = status"
        />
      </div>

      <div
        v-if="loading && customers.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar customer...
      </div>

      <div
        v-else-if="!errorMessage && filtered.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-verified text-3xl text-fg-muted" />
        <p class="font-medium">
          {{ search ? 'Customer tidak ditemukan' : `Tidak ada customer berstatus ${APPROVAL_LABELS[tab].toLowerCase()}` }}
        </p>
        <p class="text-sm text-fg-muted">
          {{ search ? 'Coba kata kunci lain.' : tab === 'PENDING' ? 'Pengajuan baru dari sales akan muncul di sini.' : 'Data akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="filtered.length > 0"
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
              <th class="px-5 py-3 font-medium">Area</th>
              <th class="px-5 py-3 font-medium">Sales</th>
              <th class="px-5 py-3 font-medium">Diajukan</th>
              <th v-if="tab !== 'PENDING'" class="px-5 py-3 font-medium">Keterangan</th>
              <th v-if="tab === 'PENDING'" class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr v-for="customer in filtered" :key="customer.id" class="transition-colors hover:bg-sidebar/60">
              <td class="px-5 py-4">
                <p class="font-medium">{{ customer.nama_instansi }}</p>
                <p v-if="customer.kota" class="text-xs text-fg-muted">{{ customer.kota }}</p>
              </td>

              <td class="px-5 py-4">
                <p>{{ customer.nama_pic || '-' }}</p>
                <p v-if="customer.kontak_pic" class="text-xs text-fg-muted">{{ customer.kontak_pic }}</p>
              </td>

              <td class="px-5 py-4">{{ customer.kategori || '-' }}</td>
              <td class="px-5 py-4 text-fg-muted">{{ customer.area_nama || '-' }}</td>
              <td class="px-5 py-4 text-fg-muted">{{ customer.sales_nama || '-' }}</td>
              <td class="whitespace-nowrap px-5 py-4 text-fg-muted">{{ formatDate(customer.created_at, true) }}</td>

              <td v-if="tab !== 'PENDING'" class="max-w-[280px] px-5 py-4">
                <p class="text-xs text-fg-muted">{{ formatDate(customer.verified_at, true) }}</p>
                <p
                  v-if="customer.rejection_reason"
                  class="mt-0.5 line-clamp-2 text-sm"
                  :title="customer.rejection_reason"
                >
                  {{ customer.rejection_reason }}
                </p>
              </td>

              <td v-if="tab === 'PENDING'" class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-2">
                  <Button
                    label="Setujui"
                    icon="pi pi-check"
                    size="small"
                    severity="success"
                    :loading="processingId === customer.id"
                    :disabled="processingId !== null"
                    @click="confirmApprove(customer)"
                  />
                  <Button
                    label="Tolak"
                    icon="pi pi-times"
                    size="small"
                    severity="danger"
                    variant="outlined"
                    :disabled="processingId !== null"
                    @click="openReject(customer)"
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

    <CustomerRejectDialog v-model:visible="rejectVisible" :customer="rejectTarget" @rejected="fetchCustomers" />
  </div>
</template>