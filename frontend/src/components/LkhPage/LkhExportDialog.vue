<script setup lang="ts">
import { ref, watch } from 'vue'
import Button from 'primevue/button'
import DatePicker from 'primevue/datepicker'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Message from 'primevue/message'
import MultiSelect from 'primevue/multiselect'

import { exportLkhExcel } from '../../api/lkh.ts'
import { exportErrorMessage } from '../../utils/exportFile.ts'

const props = defineProps<{ initialStatuses?: string[] }>()

const visible = defineModel<boolean>('visible', { default: false })

const statusOptions = [
  { value: 'NOT_YET', label: 'Open' },
  { value: 'DONE', label: 'Done' },
]

const statuses = ref<string[]>([])
const namaPic = ref('')
const range = ref<Date[] | null>(null)

const exporting = ref(false)
const errorMessage = ref('')

watch(visible, (value) => {
  if (!value) return
  statuses.value = [...(props.initialStatuses ?? [])]
  namaPic.value = ''
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
      status_lkh: statuses.value,
      nama_pic: namaPic.value.trim(),
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

      <div class="grid gap-4 sm:grid-cols-2">
        <div class="flex flex-col gap-1.5">
          <label for="export-lkh-status" class="text-sm font-medium">Status LKH</label>
          <MultiSelect v-model="statuses" input-id="export-lkh-status" :options="statusOptions" option-label="label" option-value="value" placeholder="Semua status" display="comma" :max-selected-labels="2" selected-items-label="{0} status dipilih" fluid />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="export-lkh-pic" class="text-sm font-medium">Nama PIC</label>
          <InputText id="export-lkh-pic" v-model="namaPic" placeholder="Cari nama PIC" autocomplete="off" fluid />
        </div>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
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