<script setup lang="ts">
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import Message from 'primevue/message'

import type { Rkh } from '../../api/rkh'
import { formatDate } from '../../utils/date'

defineProps<{
  rkh: Rkh | null
  customerName: string
  projectName: string
  salesName: string
  locked?: boolean
}>()

const visible = defineModel<boolean>('visible', { required: true })

function formatRupiah(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === '') return '-'
  const amount = Number(value)
  if (Number.isNaN(amount)) return '-'
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(amount)
}
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="Detail RKH"
    :draggable="false"
    :style="{ width: '42rem' }"
    :breakpoints="{ '768px': '95vw' }"
  >
    <div v-if="rkh" class="flex flex-col gap-5">
      <div class="flex flex-wrap items-start justify-between gap-3">
        <h3 class="min-w-0 text-base font-semibold">{{ rkh.judul_kegiatan }}</h3>
        <span class="inline-flex rounded-full bg-sidebar px-2.5 py-1 text-xs font-medium capitalize">
          {{ rkh.status }}
        </span>
      </div>

      <Message v-if="locked" severity="info" size="small" :closable="false">
        LKH sudah dibuat, jadi RKH ini tidak bisa diubah.
      </Message>

      <dl class="grid grid-cols-1 gap-x-6 gap-y-4 text-sm sm:grid-cols-2">
        <div>
          <dt class="text-xs text-fg-muted">Tanggal rencana</dt>
          <dd class="mt-1 font-medium">{{ formatDate(rkh.tanggal_rencana) }}</dd>
        </div>
        <div>
          <dt class="text-xs text-fg-muted">Tanggal pelaksanaan</dt>
          <dd class="mt-1 font-medium">
            {{ rkh.tanggal_pelaksanaan ? formatDate(rkh.tanggal_pelaksanaan) : 'Belum terlaksana' }}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-fg-muted">Sales</dt>
          <dd class="mt-1 font-medium">{{ salesName }}</dd>
        </div>
        <div>
          <dt class="text-xs text-fg-muted">Tipe aktivitas</dt>
          <dd class="mt-1 font-medium">{{ rkh.tipe_aktivitas }}</dd>
        </div>
        <div>
          <dt class="text-xs text-fg-muted">Customer</dt>
          <dd class="mt-1 font-medium">{{ customerName }}</dd>
        </div>
        <div>
          <dt class="text-xs text-fg-muted">Project</dt>
          <dd class="mt-1 font-medium">{{ projectName }}</dd>
        </div>
        <div>
          <dt class="text-xs text-fg-muted">Estimasi biaya harian</dt>
          <dd class="mt-1 font-medium tabular-nums">{{ formatRupiah(rkh.estimasi_biaya_harian) }}</dd>
        </div>
      </dl>

      <div>
        <p class="text-xs text-fg-muted">Rencana kegiatan</p>
        <p class="mt-1 whitespace-pre-line rounded-lg border border-line bg-sidebar/40 p-3 text-sm leading-relaxed">
          {{ rkh.rencana_kegiatan || '-' }}
        </p>
      </div>
    </div>

    <template #footer>
      <Button label="Tutup" variant="text" severity="secondary" @click="visible = false" />
    </template>
  </Dialog>
</template>