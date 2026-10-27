<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'
import InputText from 'primevue/inputtext'
import Message from 'primevue/message'
import Textarea from 'primevue/textarea'

import {
  REVISI_STATUS_LABEL,
  approveRevisi,
  getDetailRevisi,
  submitRevisi,
  updateRevisi,
  type Numeric,
  type RevisiDetail,
  type RevisiItem,
  type RevisiItemUpdate,
} from '../api/revisiPenawaran.ts'
import { useAuthStore } from '../stores/auth.ts'
import { getErrorMessage } from '../utils/error.ts'

interface DraftItem {
  id: number
  nama_barang: string
  merk: string
  tkdn: string
  tkdn_persen: number | null
  spesifikasi: string
  catatan_sales: string
  jumlah: number | null
  satuan: string
  harga_pagu: number | null
  harga_modal: number | null
  harga_jual: number | null
}

const route = useRoute()
const router = useRouter()
const confirm = useConfirm()
const toast = useToast()
const auth = useAuthStore()

const requestId = computed(() => Number(route.params.requestId))
const revisiId = computed(() => Number(route.params.revisiId))
const detailPath = computed(() => `/aktivitas/request-penawaran/${requestId.value}`)
const backPath = computed(() => {
  const target = route.query.kembali
  const value = Array.isArray(target) ? target[0] : target
  return typeof value === 'string' && value.startsWith('/') && !value.startsWith('//') ? value : detailPath.value
})
const backLabel = computed(() => (backPath.value === detailPath.value ? 'Kembali ke request penawaran' : 'Kembali'))

const detail = ref<RevisiDetail | null>(null)
const catatan = ref('')
const items = ref<DraftItem[]>([])
const snapshot = ref('')

const loading = ref(false)
const loadError = ref('')
const saving = ref(false)
const actionError = ref('')
const tried = ref(false)

const role = computed(() => auth.user?.role)
const editable = computed(() => role.value === 'SALES' && detail.value?.status_revisi === 'DIMINTA')
const canApprove = computed(() => role.value === 'SPV' && detail.value?.status_revisi === 'DIKIRIM')
const dirty = computed(() => snapshot.value !== JSON.stringify({ c: catatan.value, i: items.value }))

function num(value: Numeric | null | undefined): number | null {
  if (value === null || value === undefined || value === '') return null
  const parsed = Number(value)
  return Number.isNaN(parsed) ? null : parsed
}

function rupiah(value: number | null) {
  if (value === null) return '-'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value)
}

function toDraft(item: RevisiItem): DraftItem {
  return {
    id: item.id,
    nama_barang: item.nama_barang,
    merk: item.merk ?? '',
    tkdn: item.tkdn ?? '',
    tkdn_persen: num(item.tkdn_persen),
    spesifikasi: item.spesifikasi ?? '',
    catatan_sales: item.catatan_sales ?? '',
    jumlah: num(item.jumlah),
    satuan: item.satuan,
    harga_pagu: num(item.harga_pagu),
    harga_modal: num(item.harga_modal),
    harga_jual: num(item.harga_jual),
  }
}

function applyDetail(data: RevisiDetail) {
  detail.value = data
  catatan.value = data.catatan_sales ?? ''
  items.value = data.items.map(toDraft)
  snapshot.value = JSON.stringify({ c: catatan.value, i: items.value })
}

async function load() {
  loading.value = true
  loadError.value = ''
  actionError.value = ''
  detail.value = null

  if (!Number.isInteger(requestId.value) || !Number.isInteger(revisiId.value)) {
    loadError.value = 'Revisi tidak valid'
    loading.value = false
    return
  }

  try {
    applyDetail(await getDetailRevisi(requestId.value, revisiId.value))
  } catch (error) {
    loadError.value = getErrorMessage(error, 'Gagal memuat revisi')
  } finally {
    loading.value = false
  }
}

watch([requestId, revisiId], load, { immediate: true })

function isNonTkdn(value: string | null | undefined) {
  return /^(non|tidak)/.test((value ?? '').trim().toLowerCase())
}

function onTkdnChange(item: DraftItem, value: string | undefined) {
  if (isNonTkdn(value)) item.tkdn_persen = null
}

function limitPersen(event: { value?: number | string | null; originalEvent: Event }, item: DraftItem) {
  const value = typeof event.value === 'number' ? event.value : null
  if (value === null || value <= 100) return
  item.tkdn_persen = 100
  const target = event.originalEvent?.target as HTMLInputElement | null
  if (target) target.value = '100%'
}

function rowError(item: DraftItem) {
  if (!item.nama_barang.trim()) return 'Nama barang wajib diisi'
  if (!item.jumlah || item.jumlah <= 0) return 'Jumlah harus lebih dari 0'
  if (!item.satuan.trim()) return 'Satuan wajib diisi'
  return ''
}

const hasErrors = computed(() => items.value.some((item) => !!rowError(item)))

const totals = computed(() => {
  const sum = (field: 'harga_pagu' | 'harga_modal' | 'harga_jual') =>
    items.value.reduce((total, item) => total + (item.jumlah ?? 0) * (item[field] ?? 0), 0)
  return { pagu: sum('harga_pagu'), modal: sum('harga_modal'), jual: sum('harga_jual') }
})

function buildPayload() {
  const text = (value: string) => value.trim() || null
  const rows: RevisiItemUpdate[] = items.value.map((item) => ({
    id: item.id,
    nama_barang: item.nama_barang.trim(),
    merk: text(item.merk),
    tkdn: text(item.tkdn),
    tkdn_persen: isNonTkdn(item.tkdn) ? null : item.tkdn_persen,
    spesifikasi: text(item.spesifikasi),
    catatan_sales: text(item.catatan_sales),
    jumlah: item.jumlah ?? 0,
    satuan: item.satuan.trim(),
    harga_pagu: item.harga_pagu,
    harga_modal: item.harga_modal,
    harga_jual: item.harga_jual,
  }))
  return { catatan_sales: text(catatan.value), items: rows }
}

async function persist() {
  await updateRevisi(requestId.value, revisiId.value, buildPayload())
}

async function save() {
  tried.value = true
  if (hasErrors.value) return

  saving.value = true
  actionError.value = ''

  try {
    await persist()
    applyDetail(await getDetailRevisi(requestId.value, revisiId.value))
    tried.value = false
    toast.add({ severity: 'success', summary: 'Tersimpan', detail: 'Perubahan revisi berhasil disimpan', life: 2500 })
  } catch (error) {
    actionError.value = getErrorMessage(error, 'Gagal menyimpan revisi')
  } finally {
    saving.value = false
  }
}

function confirmSubmit() {
  tried.value = true
  if (hasErrors.value) return

  confirm.require({
    header: 'Kirim revisi',
    message: 'Kirim revisi ke SPV? Setelah dikirim, revisi tidak dapat diubah lagi.',
    icon: 'pi pi-send',
    rejectProps: { label: 'Batal', severity: 'secondary', variant: 'text' },
    acceptProps: { label: 'Kirim' },
    accept: async () => {
      saving.value = true
      actionError.value = ''
      try {
        if (dirty.value) await persist()
        await submitRevisi(requestId.value, revisiId.value)
        toast.add({ severity: 'success', summary: 'Terkirim', detail: 'Revisi dikirim ke SPV', life: 2500 })
        router.replace(backPath.value)
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal mengirim revisi')
      } finally {
        saving.value = false
      }
    },
  })
}

function confirmApprove() {
  confirm.require({
    header: 'Setujui revisi',
    message: 'Setujui revisi ini? Setelah disetujui, revisi tidak dapat diubah lagi.',
    icon: 'pi pi-check-circle',
    rejectProps: { label: 'Batal', severity: 'secondary', variant: 'text' },
    acceptProps: { label: 'Setujui' },
    accept: async () => {
      saving.value = true
      actionError.value = ''
      try {
        await approveRevisi(requestId.value, revisiId.value)
        toast.add({ severity: 'success', summary: 'Disetujui', detail: 'Revisi berhasil disetujui', life: 2500 })
        router.replace(backPath.value)
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menyetujui revisi')
      } finally {
        saving.value = false
      }
    },
  })
}

function formatDate(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return date.toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' })
}
</script>

<template>
  <div class="flex w-full flex-col gap-6">
    <div v-if="loading" class="flex items-center justify-center gap-3 py-16 text-sm text-fg-muted">
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat revisi...
    </div>

    <Message v-else-if="loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <template v-else-if="detail">
      <header class="flex flex-wrap items-start justify-between gap-4">
        <div class="flex items-start gap-3">
          <Button icon="pi pi-arrow-left" variant="text" rounded severity="secondary" aria-label="Kembali" v-tooltip.top="backLabel" :disabled="saving" @click="router.push(backPath)" />
          <div>
            <h1 class="text-lg font-semibold">Revisi #{{ detail.nomor_revisi }}</h1>
            <p class="mt-1 text-sm text-fg-muted">
              {{ REVISI_STATUS_LABEL[detail.status_revisi] ?? detail.status_revisi }} · diminta {{ formatDate(detail.tanggal_diminta) }}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <Button v-if="editable" label="Simpan perubahan" icon="pi pi-save" size="small" severity="secondary" variant="outlined" :loading="saving" :disabled="!dirty" @click="save" />
          <Button v-if="editable" label="Kirim ke SPV" icon="pi pi-send" size="small" :disabled="saving" @click="confirmSubmit" />
          <Button v-if="canApprove" label="Setujui revisi" icon="pi pi-check" size="small" :loading="saving" @click="confirmApprove" />
        </div>
      </header>

      <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

      <section class="rounded-xl border border-line bg-card p-5">
        <h2 class="text-xs font-medium uppercase tracking-wide text-fg-muted">Alasan revisi</h2>
        <p class="mt-2 whitespace-pre-line text-sm">{{ detail.alasan_revisi }}</p>

        <div class="mt-5 flex flex-col gap-1.5">
          <label for="catatan-sales" class="text-xs text-fg-muted">Catatan sales</label>
          <Textarea v-if="editable" id="catatan-sales" v-model="catatan" rows="3" auto-resize fluid placeholder="Catatan untuk SPV (opsional)" />
          <p v-else class="whitespace-pre-line text-sm" :class="!catatan && 'text-fg-muted'">{{ catatan || '-' }}</p>
        </div>
      </section>

      <section class="rounded-xl border border-line bg-card">
        <div class="border-b border-line p-4">
          <h2 class="font-semibold">Barang revisi</h2>
          <p class="mt-1 text-xs text-fg-muted">
            {{ editable ? 'Ubah data barang sesuai permintaan revisi. Harga modal dan harga jual hanya sebagai acuan.' : 'Data barang pada revisi ini.' }}
          </p>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[1200px] text-left text-sm">
            <thead class="bg-sidebar text-fg-muted">
              <tr>
                <th class="px-4 py-3 font-medium">No</th>
                <th class="px-4 py-3 font-medium">Barang</th>
                <th class="px-4 py-3 font-medium">Spesifikasi</th>
                <th class="px-4 py-3 font-medium">Catatan sales</th>
                <th class="px-4 py-3 font-medium">TKDN</th>
                <th class="px-4 py-3 font-medium">Jumlah</th>
                <th class="px-4 py-3 text-right font-medium">Harga pagu</th>
                <th class="px-4 py-3 text-right font-medium">Harga modal</th>
                <th class="px-4 py-3 text-right font-medium">Harga jual</th>
              </tr>
            </thead>

            <tbody class="divide-y divide-line">
              <tr v-for="(item, index) in items" :key="item.id" class="align-top">
                <td class="px-4 py-3 text-fg-muted">{{ index + 1 }}</td>

                <td class="min-w-52 px-4 py-3">
                  <div v-if="editable" class="flex flex-col gap-1.5">
                    <InputText v-model="item.nama_barang" size="small" fluid placeholder="Nama barang" :invalid="tried && !item.nama_barang.trim()" />
                    <InputText v-model="item.merk" size="small" fluid placeholder="Merk" />
                    <small v-if="tried && rowError(item)" class="text-red-500">{{ rowError(item) }}</small>
                  </div>
                  <template v-else>
                    <p class="font-medium">{{ item.nama_barang }}</p>
                    <p v-if="item.merk" class="text-xs text-fg-muted">{{ item.merk }}</p>
                  </template>
                </td>

                <td class="min-w-56 px-4 py-3">
                  <Textarea v-if="editable" v-model="item.spesifikasi" rows="2" auto-resize fluid size="small" />
                  <p v-else class="whitespace-pre-line text-fg-muted">{{ item.spesifikasi || '-' }}</p>
                </td>

                <td class="min-w-48 px-4 py-3">
                  <Textarea v-if="editable" v-model="item.catatan_sales" rows="2" auto-resize fluid size="small" />
                  <p v-else class="whitespace-pre-line text-fg-muted">{{ item.catatan_sales || '-' }}</p>
                </td>

                <td class="min-w-32 px-4 py-3">
                  <div v-if="editable" class="flex flex-col gap-1.5">
                    <InputText v-model="item.tkdn" size="small" fluid placeholder="TKDN" @update:model-value="(value) => onTkdnChange(item, value)" />
                    <InputNumber v-if="!isNonTkdn(item.tkdn)" v-model="item.tkdn_persen" size="small" fluid suffix="%" :min="0" :max="100" :max-fraction-digits="2" :use-grouping="false" :maxlength="8" placeholder="Persen" @input="limitPersen($event, item)" />
                  </div>
                  <p v-else class="text-fg-muted">
                    {{ item.tkdn || '-' }}<template v-if="item.tkdn_persen !== null && !isNonTkdn(item.tkdn)"> ({{ item.tkdn_persen }}%)</template>
                  </p>
                </td>

                <td class="min-w-32 px-4 py-3">
                  <div v-if="editable" class="flex flex-col gap-1.5">
                    <InputNumber v-model="item.jumlah" size="small" fluid :min="0" :max-fraction-digits="2" :invalid="tried && (!item.jumlah || item.jumlah <= 0)" />
                    <InputText v-model="item.satuan" size="small" fluid placeholder="Satuan" :invalid="tried && !item.satuan.trim()" />
                  </div>
                  <p v-else class="whitespace-nowrap">{{ item.jumlah }} {{ item.satuan }}</p>
                </td>

                <td class="min-w-40 px-4 py-3 text-right">
                  <InputNumber v-if="editable" v-model="item.harga_pagu" size="small" fluid mode="currency" currency="IDR" locale="id-ID" :min-fraction-digits="0" :min="0" />
                  <span v-else class="tabular-nums">{{ rupiah(item.harga_pagu) }}</span>
                </td>

                <td class="px-4 py-3 text-right tabular-nums text-fg-muted">{{ rupiah(item.harga_modal) }}</td>
                <td class="px-4 py-3 text-right tabular-nums text-fg-muted">{{ rupiah(item.harga_jual) }}</td>
              </tr>
            </tbody>

            <tfoot class="bg-sidebar font-semibold">
              <tr>
                <td colspan="6" class="px-4 py-3 text-right">Total</td>
                <td class="px-4 py-3 text-right tabular-nums">{{ rupiah(totals.pagu) }}</td>
                <td class="px-4 py-3 text-right tabular-nums">{{ rupiah(totals.modal) }}</td>
                <td class="px-4 py-3 text-right tabular-nums">{{ rupiah(totals.jual) }}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </section>
    </template>
  </div>
</template>