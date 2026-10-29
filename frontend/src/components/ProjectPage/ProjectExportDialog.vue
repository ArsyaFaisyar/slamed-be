<script setup lang="ts">
import { ref, watch } from 'vue'
import Button from 'primevue/button'
import DatePicker from 'primevue/datepicker'
import Dialog from 'primevue/dialog'
import Message from 'primevue/message'
import MultiSelect from 'primevue/multiselect'

import { exportProjectsExcel, type ProjectExportParams } from '../../api/projects'
import { exportErrorMessage } from '../../utils/exportFile'

interface ExportOption {
  value: number
  label: string
  color?: string | null
}

const props = defineProps<{
  salesOptions: ExportOption[]
  customerOptions: ExportOption[]
  statusOptions: ExportOption[]
  initialSales?: number[]
  initialCustomers?: number[]
  initialStatuses?: number[]
}>()

const visible = defineModel<boolean>('visible', { default: false })

const sales = ref<number[]>([])
const customers = ref<number[]>([])
const statuses = ref<number[]>([])
const range = ref<Date[] | null>(null)

const exporting = ref(false)
const errorMessage = ref('')

watch(visible, (value) => {
  if (!value) return
  sales.value = [...(props.initialSales ?? [])]
  customers.value = [...(props.initialCustomers ?? [])]
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

  const params: ProjectExportParams = {}
  if (sales.value.length > 0) params.sales = sales.value.join(',')
  if (customers.value.length > 0) params.customer = customers.value.join(',')
  if (statuses.value.length > 0) params.status = statuses.value.join(',')
  if (start) params.tanggal_mulai = toDateString(start)
  if (end) params.tanggal_selesai = toDateString(end)

  try {
    await exportProjectsExcel(params)
    visible.value = false
  } catch (error) {
    errorMessage.value = await exportErrorMessage(error, 'Gagal mengekspor data project')
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="Export project ke Excel"
    class="w-[calc(100vw-2rem)] max-w-lg"
    :draggable="false"
    :closable="!exporting"
    :close-on-escape="!exporting"
  >
    <div class="flex flex-col gap-4">
      <p class="text-sm text-fg-muted">
        Kosongkan filter untuk mengekspor semua project yang bisa kamu lihat.
      </p>

      <Message v-if="errorMessage" severity="error" size="small">{{ errorMessage }}</Message>

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="export-sales" class="text-sm font-medium">Sales</label>
          <MultiSelect
            v-model="sales"
            input-id="export-sales"
            :options="salesOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua sales"
            filter
            filter-placeholder="Cari sales..."
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} sales dipilih"
            fluid
            empty-message="Tidak ada sales"
            empty-filter-message="Sales tidak ditemukan"
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-customer" class="text-sm font-medium">Customer</label>
          <MultiSelect
            v-model="customers"
            input-id="export-customer"
            :options="customerOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua customer"
            filter
            filter-placeholder="Cari customer..."
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} customer dipilih"
            fluid
            empty-message="Tidak ada customer"
            empty-filter-message="Customer tidak ditemukan"
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-status" class="text-sm font-medium">Status project</label>
          <MultiSelect
            v-model="statuses"
            input-id="export-status"
            :options="statusOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua status"
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} status dipilih"
            fluid
            empty-message="Tidak ada status"
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
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-periode" class="text-sm font-medium">Periode</label>
          <DatePicker
            v-model="range"
            input-id="export-periode"
            selection-mode="range"
            date-format="dd/mm/yy"
            placeholder="Pilih periode"
            show-icon
            show-button-bar
            :manual-input="false"
            fluid
          />
        </div>
      </div>
    </div>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="exporting" @click="visible = false" />
      <Button label="Export Excel" icon="pi pi-file-excel" :loading="exporting" @click="onExport" />
    </template>
  </Dialog>
</template>