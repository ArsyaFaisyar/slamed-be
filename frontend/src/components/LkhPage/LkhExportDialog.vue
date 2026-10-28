<script setup lang="ts">
import { ref, watch } from 'vue'
import Button from 'primevue/button'
import DatePicker from 'primevue/datepicker'
import Dialog from 'primevue/dialog'
import Message from 'primevue/message'
import MultiSelect from 'primevue/multiselect'

import { exportLkhExcel } from '../../api/lkh.ts'
import { exportErrorMessage } from '../../utils/exportFile.ts'

interface FilterOption {
  value: number
  label: string
}

// Opsi dikirim dari halaman LKH (data yang sama dengan filter di halaman), tidak diambil ulang di sini.
defineProps<{
  salesOptions: FilterOption[]
  customerOptions: FilterOption[]
}>()

const visible = defineModel<boolean>('visible', { default: false })

const salesIds = ref<number[]>([])
const customerIds = ref<number[]>([])
const range = ref<Date[] | null>(null)

const exporting = ref(false)
const errorMessage = ref('')

watch(visible, (value) => {
  if (!value) return
  salesIds.value = []
  customerIds.value = []
  range.value = null
  errorMessage.value = ''
})

function toDateString(date: Date) {
  const pad = (value: number) => String(value).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

async function onExport() {
  exporting.value = true
  errorMessage.value = ''

  const start = range.value?.[0] ?? null
  const end = range.value?.[1] ?? start

  try {
    await exportLkhExcel({
      sales_id: salesIds.value,
      customer_id: customerIds.value,
      tanggal_mulai: start ? toDateString(start) : null,
      tanggal_selesai: end ? toDateString(end) : null,
    })
    visible.value = false
  } catch (error) {
    errorMessage.value = await exportErrorMessage(error, 'Gagal mengekspor data LKH')
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Export LKH ke Excel" class="w-[calc(100vw-2rem)] max-w-lg" :draggable="false" :closable="!exporting" :close-on-escape="!exporting">
    <div class="flex flex-col gap-4">
      <p class="text-sm text-fg-muted">Kosongkan filter untuk mengekspor semua LKH yang bisa kamu lihat.</p>

      <Message v-if="errorMessage" severity="error" size="small">{{ errorMessage }}</Message>

      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-1.5">
          <label for="export-lkh-sales" class="text-sm font-medium">Sales</label>
          <MultiSelect
            v-model="salesIds"
            input-id="export-lkh-sales"
            :options="salesOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua sales"
            filter
            filter-placeholder="Cari sales..."
            display="comma"
            :max-selected-labels="2"
            selected-items-label="{0} sales dipilih"
            empty-message="Tidak ada sales"
            empty-filter-message="Sales tidak ditemukan"
            fluid
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-lkh-customer" class="text-sm font-medium">Customer</label>
          <MultiSelect
            v-model="customerIds"
            input-id="export-lkh-customer"
            :options="customerOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua customer"
            filter
            filter-placeholder="Cari customer..."
            display="comma"
            :max-selected-labels="2"
            selected-items-label="{0} customer dipilih"
            empty-message="Tidak ada customer"
            empty-filter-message="Customer tidak ditemukan"
            fluid
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-lkh-periode" class="text-sm font-medium">Periode kunjungan</label>
          <DatePicker v-model="range" input-id="export-lkh-periode" selection-mode="range" date-format="dd/mm/yy" placeholder="Pilih periode" show-icon show-button-bar :manual-input="false" fluid />
        </div>
      </div>
    </div>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="exporting" @click="visible = false" />
      <Button label="Export Excel" icon="pi pi-file-excel" :loading="exporting" @click="onExport" />
    </template>
  </Dialog>
</template>