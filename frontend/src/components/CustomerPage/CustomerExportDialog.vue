<script setup lang="ts">
import { ref, watch } from 'vue'
import Button from 'primevue/button'
import DatePicker from 'primevue/datepicker'
import Dialog from 'primevue/dialog'
import Message from 'primevue/message'
import MultiSelect from 'primevue/multiselect'

import { APPROVAL_LABELS, type ApprovalStatus } from '../../api/customers.ts'
import { exportCustomersExcel, exportErrorMessage } from '../../api/customerExport.ts'

const props = defineProps<{
  areaNames: string[]
  salesNames: string[]
  initialAreas?: string[]
  initialSales?: string[]
  initialStatuses?: ApprovalStatus[]
}>()

const visible = defineModel<boolean>('visible', { default: false })

const statusOptions = (Object.keys(APPROVAL_LABELS) as ApprovalStatus[]).map((status) => ({
  value: status,
  label: APPROVAL_LABELS[status],
}))

const areas = ref<string[]>([])
const sales = ref<string[]>([])
const statuses = ref<ApprovalStatus[]>([])
const range = ref<Date[] | null>(null)

const exporting = ref(false)
const errorMessage = ref('')

watch(visible, (value) => {
  if (!value) return
  areas.value = [...(props.initialAreas ?? [])]
  sales.value = [...(props.initialSales ?? [])]
  statuses.value = [...(props.initialStatuses ?? [])]
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
    await exportCustomersExcel({
      area: areas.value,
      sales: sales.value,
      status_approval: statuses.value,
      tanggal_mulai: start ? toDateString(start) : null,
      tanggal_selesai: end ? toDateString(end) : null,
    })
    visible.value = false
  } catch (error) {
    errorMessage.value = await exportErrorMessage(error, 'Gagal mengekspor data customer')
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Export customer ke Excel" class="w-[calc(100vw-2rem)] max-w-lg" :draggable="false" :closable="!exporting" :close-on-escape="!exporting">
    <div class="flex flex-col gap-4">
      <p class="text-sm text-fg-muted">Kosongkan filter untuk mengekspor semua customer yang bisa kamu lihat.</p>

      <Message v-if="errorMessage" severity="error" size="small">{{ errorMessage }}</Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="export-area" class="text-sm font-medium">Area</label>
          <MultiSelect v-model="areas" input-id="export-area" :options="areaNames" placeholder="Semua area" filter filter-placeholder="Cari area..." display="comma" :max-selected-labels="1" selected-items-label="{0} area dipilih" fluid empty-message="Tidak ada area" empty-filter-message="Area tidak ditemukan" />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-sales" class="text-sm font-medium">Sales</label>
          <MultiSelect v-model="sales" input-id="export-sales" :options="salesNames" placeholder="Semua sales" filter filter-placeholder="Cari sales..." display="comma" :max-selected-labels="1" selected-items-label="{0} sales dipilih" fluid empty-message="Tidak ada sales" empty-filter-message="Sales tidak ditemukan" />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-status" class="text-sm font-medium">Status approval</label>
          <MultiSelect v-model="statuses" input-id="export-status" :options="statusOptions" option-label="label" option-value="value" placeholder="Semua status" display="comma" :max-selected-labels="1" selected-items-label="{0} status dipilih" fluid />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-periode" class="text-sm font-medium">Periode</label>
          <DatePicker v-model="range" input-id="export-periode" selection-mode="range" date-format="dd/mm/yy" placeholder="Pilih periode" show-icon show-button-bar :manual-input="false" fluid />
        </div>
      </div>
    </div>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="exporting" @click="visible = false" />
      <Button label="Export Excel" icon="pi pi-file-excel" :loading="exporting" @click="onExport" />
    </template>
  </Dialog>
</template>