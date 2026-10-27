<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { getProjectRab } from '../../api/projectsRab.ts'
import {
  REVISI_STATUS_LABEL,
  getRiwayatRevisi,
  revisiDetailPath,
  type RevisiRiwayat,
  type RevisiStatus,
} from '../../api/revisiPenawaran.ts'
import { getErrorMessage } from '../../utils/error.ts'

interface Row extends RevisiRiwayat {
  requestId: number
  requestLabel: string
}

const props = defineProps<{ projectId: number }>()

const router = useRouter()

const STATUS_CLASS: Record<RevisiStatus, string> = {
  DIMINTA: 'bg-amber-500/15 text-amber-600 dark:text-amber-400',
  DIKIRIM: 'bg-sky-500/15 text-sky-600 dark:text-sky-400',
  SELESAI: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400',
  DITOLAK: 'bg-red-500/15 text-red-600 dark:text-red-400',
}

const rows = ref<Row[]>([])
const multipleRequests = ref(false)
const loading = ref(false)
const error = ref('')

const sorted = computed(() =>
  [...rows.value].sort((a, b) => new Date(a.tanggal_diminta).getTime() - new Date(b.tanggal_diminta).getTime()),
)

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function extractRequests(raw: unknown): { id: number; label: string }[] {
  const list = Array.isArray(raw) ? raw : isRecord(raw) ? Object.values(raw).find((value) => Array.isArray(value)) : null
  if (!Array.isArray(list)) return []

  const seen = new Map<number, string>()

  for (const item of list.filter(isRecord)) {
    const id = Number(item.request_penawaran_id)
    if (!Number.isInteger(id) || id <= 0 || seen.has(id)) continue
    const date = typeof item.tanggal_request === 'string' ? new Date(item.tanggal_request) : null
    const label = date && !Number.isNaN(date.getTime())
      ? date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
      : `Request #${id}`
    seen.set(id, label)
  }

  return [...seen].map(([id, label]) => ({ id, label }))
}

function dayText(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleDateString('id-ID', { weekday: 'long', day: '2-digit', month: 'short', year: 'numeric' })
}

function timeText(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace('.', ':')
}

async function load() {
  loading.value = true
  error.value = ''

  try {
    const requests = extractRequests(await getProjectRab(props.projectId))
    multipleRequests.value = requests.length > 1
    const results = await Promise.allSettled(requests.map((request) => getRiwayatRevisi(request.id)))

    const collected: Row[] = []
    let firstFailure: unknown = null

    results.forEach((result, index) => {
      const request = requests[index]
      if (!request) return
      if (result.status === 'fulfilled') {
        for (const item of result.value.riwayat) collected.push({ ...item, requestId: request.id, requestLabel: request.label })
      } else if (firstFailure === null) {
        firstFailure = result.reason
      }
    })

    rows.value = collected
    if (collected.length === 0 && firstFailure !== null) {
      error.value = getErrorMessage(firstFailure, 'Gagal memuat riwayat revisi')
    }
  } catch (err) {
    rows.value = []
    error.value = getErrorMessage(err, 'Gagal memuat riwayat revisi')
  } finally {
    loading.value = false
  }
}

function openRevisi(row: Row) {
  router.push({
    path: revisiDetailPath(row.requestId, row.id),
    query: { kembali: `/transaksi/project/${props.projectId}` },
  })
}

watch(() => props.projectId, load, { immediate: true })

defineExpose({ refresh: load })
</script>

<template>
  <section class="rounded-xl border border-line bg-card">
    <div class="flex flex-wrap items-center justify-between gap-3 border-b border-line px-5 py-4">
      <div>
        <h2 class="font-semibold">Riwayat revisi</h2>
        <p class="mt-0.5 text-xs text-fg-muted">Permintaan revisi penawaran untuk project ini.</p>
      </div>

      <div class="flex items-center gap-2">
        <span class="inline-flex rounded-full border border-line px-2.5 py-1 text-xs font-medium tabular-nums">
          {{ rows.length }} revisi
        </span>
        <Button icon="pi pi-refresh" variant="text" rounded severity="secondary" size="small" aria-label="Muat ulang riwayat revisi" v-tooltip.top="'Muat ulang'" :loading="loading" @click="load" />
      </div>
    </div>

    <div class="p-5">
      <Message v-if="error" severity="error" :closable="false">
        <div class="flex flex-wrap items-center gap-3">
          <span>{{ error }}</span>
          <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
        </div>
      </Message>

      <div v-else-if="loading && rows.length === 0" class="flex items-center justify-center gap-3 py-10 text-sm text-fg-muted">
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat riwayat revisi...
      </div>

      <div v-else-if="rows.length === 0" class="flex flex-col items-center justify-center gap-2 py-10 text-center">
        <i class="pi pi-history text-3xl text-fg-muted" />
        <p class="font-medium">Belum ada revisi</p>
        <p class="text-sm text-fg-muted">Riwayat muncul setelah SPV meminta revisi penawaran.</p>
      </div>

      <div v-else class="overflow-x-auto transition-opacity" :class="loading && 'opacity-60'">
        <table class="w-full min-w-[960px] text-left text-sm">
          <thead class="border-b border-line text-xs text-fg-muted">
            <tr>
              <th class="px-3 py-2.5 font-medium">Revisi</th>
              <th class="px-3 py-2.5 font-medium">Alasan</th>
              <th class="px-3 py-2.5 font-medium">Status</th>
              <th class="px-3 py-2.5 font-medium">Diminta</th>
              <th class="px-3 py-2.5 font-medium">Dikirim</th>
              <th class="px-3 py-2.5 font-medium">Disetujui</th>
              <th class="w-12 px-3 py-2.5 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr v-for="row in sorted" :key="`${row.requestId}-${row.id}`" class="align-top">
              <td class="whitespace-nowrap px-3 py-3 font-medium">
                #{{ row.nomor_revisi }}
                <span v-if="multipleRequests" class="block text-xs font-normal text-fg-muted">Request {{ row.requestLabel }}</span>
              </td>

              <td class="min-w-[220px] max-w-[360px] px-3 py-3">
                <p class="whitespace-pre-line">{{ row.alasan_revisi }}</p>
                <p v-if="row.catatan_sales" class="mt-1 whitespace-pre-line text-xs text-fg-muted">Catatan sales: {{ row.catatan_sales }}</p>
              </td>

              <td class="px-3 py-3">
                <span class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium" :class="STATUS_CLASS[row.status_revisi]">
                  {{ REVISI_STATUS_LABEL[row.status_revisi] ?? row.status_revisi }}
                </span>
              </td>

              <td v-for="stamp in [row.tanggal_diminta, row.tanggal_dikirim, row.tanggal_disetujui]" :key="stamp ?? 'kosong'" class="whitespace-nowrap px-3 py-3">
                <template v-if="stamp">
                  <p>{{ dayText(stamp) }}</p>
                  <p class="text-xs text-fg-muted">{{ timeText(stamp) }} WIB</p>
                </template>
                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-3 py-3 text-center">
                <Button icon="pi pi-eye" variant="text" rounded severity="secondary" size="small" aria-label="Lihat revisi" v-tooltip.top="'Lihat revisi'" @click="openRevisi(row)" />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>
</template>