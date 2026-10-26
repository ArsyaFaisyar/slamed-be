<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { getProjectRab, type ProjectRab, type RabItem, type RabRequest } from '../../api/projectsRab'
import { formatDate } from '../../utils/date'
import { getErrorMessage } from '../../utils/error'

const props = defineProps<{ projectId: number }>()

const router = useRouter()

const data = ref<ProjectRab | null>(null)
const loading = ref(false)
const error = ref('')

const rupiahFormat = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
})
const numberFormat = new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 })

function toNumber(value: number | string | null | undefined) {
  if (value === null || value === undefined || value === '') return null
  const number = Number(value)
  return Number.isNaN(number) ? null : number
}

function formatRupiah(value: number | string | null | undefined) {
  const number = toNumber(value)
  return number === null ? '-' : rupiahFormat.format(number)
}

function formatQty(value: number | string | null | undefined) {
  const number = toNumber(value)
  return number === null ? '-' : numberFormat.format(number)
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

const requests = computed<RabRequest[]>(() => {
  const raw = data.value
  if (!raw) return []

  const list = Array.isArray(raw) ? raw : Object.values(raw).find((value) => Array.isArray(value))
  return Array.isArray(list) ? (list.filter(isRecord) as unknown as RabRequest[]) : []
})

const requestCount = computed(() => data.value?.jumlah_request_penawaran ?? requests.value.length)

function itemsOf(request: RabRequest): RabItem[] {
  return Array.isArray(request.items) ? request.items : []
}

function isTotalMode(mode: string | null | undefined) {
  return (mode ?? '').toUpperCase() === 'TOTAL'
}

function itemSubtotal(item: RabItem) {
  return toNumber(item.subtotal) ?? (toNumber(item.jumlah) ?? 0) * (toNumber(item.harga_pagu) ?? 0)
}

function totalOf(request: RabRequest) {
  const items = itemsOf(request)

  if (!isTotalMode(request.mode_pagu) && items.length > 0) {
    return items.reduce((sum, item) => sum + itemSubtotal(item), 0)
  }

  return toNumber(request.total_pagu)
}

function emptyText(request: RabRequest) {
  return isTotalMode(request.mode_pagu)
    ? 'Pagu total: hanya total pagu yang diisi, tanpa harga per barang.'
    : 'Belum ada barang pada request ini.'
}

const itemRows = computed(() =>
  requests.value.flatMap((request) => itemsOf(request).map((item) => ({ request, item }))),
)

const summaryRequests = computed(() =>
  requests.value.filter((request) => isTotalMode(request.mode_pagu) || itemsOf(request).length === 0),
)

const grandTotal = computed(() =>
  requests.value.reduce((sum, request) => sum + (totalOf(request) ?? 0), 0),
)

function openRequest(request: RabRequest) {
  router.push(`/aktivitas/request-penawaran/${request.request_penawaran_id}`)
}

async function load() {
  loading.value = true
  error.value = ''

  try {
    data.value = await getProjectRab(props.projectId)
  } catch (err) {
    error.value = getErrorMessage(err, 'Gagal memuat RAB')
  } finally {
    loading.value = false
  }
}

watch(() => props.projectId, load, { immediate: true })

defineExpose({ refresh: load })
</script>

<template>
  <section class="rounded-xl border border-line bg-card">
    <div class="flex flex-wrap items-center justify-between gap-3 border-b border-line px-5 py-4">
      <div>
        <h2 class="font-semibold">RAB</h2>
        <p class="mt-0.5 text-xs text-fg-muted">Rencana anggaran biaya untuk project ini.</p>
      </div>

      <div class="flex items-center gap-2">
        <span class="inline-flex rounded-full border border-line px-2.5 py-1 text-xs font-medium tabular-nums">
          {{ requestCount }} request
        </span>
        <Button
          icon="pi pi-refresh"
          variant="text"
          rounded
          severity="secondary"
          size="small"
          aria-label="Muat ulang RAB"
          v-tooltip.top="'Muat ulang'"
          :loading="loading"
          @click="load"
        />
      </div>
    </div>

    <div class="p-5">
      <Message v-if="error" severity="error" :closable="false">
        <div class="flex flex-wrap items-center gap-3">
          <span>{{ error }}</span>
          <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
        </div>
      </Message>

      <div v-else-if="loading && !data" class="flex items-center justify-center gap-3 py-10 text-sm text-fg-muted">
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat RAB...
      </div>

      <div v-else-if="requests.length === 0" class="flex flex-col items-center justify-center gap-2 py-10 text-center">
        <i class="pi pi-calculator text-3xl text-fg-muted" />
        <p class="font-medium">Belum ada RAB</p>
        <p class="text-sm text-fg-muted">RAB akan muncul setelah request penawaran dibuat.</p>
      </div>

      <div v-else class="overflow-x-auto transition-opacity" :class="loading && 'opacity-60'">
        <table class="w-full min-w-[760px] text-left text-sm">
          <thead class="border-b border-line text-xs text-fg-muted">
            <tr>
              <th class="w-12 px-3 py-2.5 font-medium">No</th>
              <th class="px-3 py-2.5 font-medium">Nama barang</th>
              <th class="px-3 py-2.5 font-medium">Spesifikasi</th>
              <th class="px-3 py-2.5 font-medium">Jml</th>
              <th class="px-3 py-2.5 font-medium">Satuan</th>
              <th class="px-3 py-2.5 font-medium">Harga pagu</th>
              <th class="px-3 py-2.5 font-medium">Subtotal</th>
              <th class="px-3 py-2.5 font-medium">Request</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="(row, index) in itemRows"
              :key="`${row.request.request_penawaran_id}-${row.item.id}`"
              class="align-top"
            >
              <td class="px-3 py-3 tabular-nums">{{ index + 1 }}</td>
              <td class="min-w-[140px] px-3 py-3">{{ row.item.nama_barang }}</td>
              <td class="min-w-[220px] max-w-[420px] px-3 py-3">{{ row.item.spesifikasi || '-' }}</td>
              <td class="px-3 py-3 tabular-nums">{{ formatQty(row.item.jumlah) }}</td>
              <td class="px-3 py-3">{{ row.item.satuan || '-' }}</td>
              <td class="whitespace-nowrap px-3 py-3 tabular-nums">{{ formatRupiah(row.item.harga_pagu) }}</td>
              <td class="whitespace-nowrap px-3 py-3 tabular-nums">{{ formatRupiah(row.item.subtotal) }}</td>
              <td class="px-3 py-3">
                <button type="button" class="text-left text-primary hover:underline" @click="openRequest(row.request)">
                  {{ formatDate(row.request.tanggal_request) }}
                </button>
              </td>
            </tr>

            <tr v-for="request in summaryRequests" :key="`sum-${request.request_penawaran_id}`" class="align-top">
              <td class="px-3 py-3 tabular-nums">-</td>
              <td colspan="5" class="px-3 py-3 text-fg-muted">{{ emptyText(request) }}</td>
              <td class="whitespace-nowrap px-3 py-3 tabular-nums">{{ formatRupiah(totalOf(request)) }}</td>
              <td class="px-3 py-3">
                <button type="button" class="text-left text-primary hover:underline" @click="openRequest(request)">
                  {{ formatDate(request.tanggal_request) }}
                </button>
              </td>
            </tr>
          </tbody>

          <tfoot class="border-t border-line">
            <tr>
              <td colspan="6" class="px-3 py-3 text-right font-semibold">Total harga pagu</td>
              <td class="whitespace-nowrap px-3 py-3 font-semibold tabular-nums">{{ formatRupiah(grandTotal) }}</td>
              <td />
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  </section>
</template>