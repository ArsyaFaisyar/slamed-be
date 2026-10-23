<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'
import Message from 'primevue/message'
import Select from 'primevue/select'
import ToggleSwitch from 'primevue/toggleswitch'

import RequestItemDialog from '../components/RequestPenawaranPage/RequestItemDialog.vue'
import RequestPenawaranSummary from '../components/RequestPenawaranPage/RequestPenawaranSummary.vue'
import RequestPaguTable from '../components/RequestPenawaranPage/RequestPaguTable.vue'
import RequestModalTable from '../components/RequestPenawaranPage/RequestModalTable.vue'
import RequestJualTable from '../components/RequestPenawaranPage/RequestJualTable.vue'

import {
  MODE_PAGU_OPTIONS,
  PAJAK_OPTIONS,
  REQUEST_PENAWARAN_LIST_PATH,
  getRequestItems,
  getRequestPenawaran,
  updateRequestItem,
  updateRequestPenawaran,
  type RequestItem,
  type RequestPenawaran,
} from '../api/requestPenawaran.ts'
import { getMediaPengadaan, type MediaPengadaan } from '../api/mediaPengadaan.ts'
import { getBranches, type Branch } from '../api/branches.ts'
import { getLkh } from '../api/lkh.ts'
import { getRkhById } from '../api/rkh.ts'
import { getProjects } from '../api/projects.ts'
import { getCustomers } from '../api/customers.ts'
import { useAuthStore } from '../stores/auth.ts'
import { getErrorMessage } from '../utils/error.ts'
import { draftTotal, formatRupiah, toNumber, type Draft } from '../utils/price.ts'

type PriceField = 'harga_pagu' | 'harga_modal' | 'harga_jual'
type Section = 'pagu' | 'modal' | 'jual'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useToast()

const requestId = computed(() => Number(route.params.requestId))
const isFirstVisit = computed(() => route.query.baru === '1')
const canEditCost = computed(() => auth.user?.role !== 'SALES')

const request = ref<RequestPenawaran | null>(null)
const items = ref<RequestItem[]>([])
const mediaList = ref<MediaPengadaan[]>([])
const branches = ref<Branch[]>([])
const projectName = ref('')
const customerName = ref('')

const loading = ref(false)
const loadError = ref('')
const itemsLoading = ref(false)
const itemsError = ref('')

const itemDialogVisible = ref(false)
const selectedItem = ref<RequestItem | null>(null)

/* ---------- Draft tiap section (form terpisah) ---------- */

// Section pagu
const selectedMediaId = ref<number | null>(null)
const selectedBranchId = ref<number | null>(null)
const modePagu = ref<string | null>(null)
const paguDraft = ref<Draft>({})
const totalPaguDraft = ref<number | null>(null)
const paguTried = ref(false) // validasi baru ditampilkan setelah user mencoba menyimpan

// Section harga modal
const selectedPajak = ref<string | null>(null)
const modalDraft = ref<Draft>({})
const modalTried = ref(false)

// Section harga jual
const jualDraft = ref<Draft>({})

function createSectionState() {
  return reactive({ saving: false, error: '' })
}
const paguState = createSectionState()
const modalState = createSectionState()
const jualState = createSectionState()

const MODE_DETAIL = 'DETAIL'
const modeTotal = computed(
  () => MODE_PAGU_OPTIONS.find((option) => option.value !== MODE_DETAIL)?.value ?? 'TOTAL',
)
const isPaguTotal = computed({
  get: () => modePagu.value === modeTotal.value,
  set: (value: boolean) => {
    modePagu.value = value ? modeTotal.value : MODE_DETAIL
  },
})

const mediaOptions = computed(() => mediaList.value.map((media) => ({ value: media.id, label: media.nama })))
const branchOptions = computed(() =>
  branches.value.map((branch) => ({ value: branch.id, label: `${branch.nama} (${branch.kode})` })),
)

/* ---------- Helper ---------- */

function buildDraft(field: PriceField): Draft {
  const draft: Draft = {}
  for (const item of items.value) draft[item.id] = toNumber(item[field])
  return draft
}

function changedItems(draft: Draft, field: PriceField) {
  return items.value.filter((item) => (draft[item.id] ?? null) !== toNumber(item[field]))
}

function syncDrafts(section?: Section) {
  const data = request.value
  if (!data) return

  if (!section || section === 'pagu') {
    selectedMediaId.value = data.media_pengadaan_id ?? null
    selectedBranchId.value = data.branch_id ?? null
    modePagu.value = data.mode_pagu ?? MODE_DETAIL
    paguDraft.value = buildDraft('harga_pagu')
    totalPaguDraft.value = toNumber(data.total_pagu)
  }
  if (!section || section === 'modal') {
    selectedPajak.value = data.pajak_harga_modal ?? null
    modalDraft.value = buildDraft('harga_modal')
  }
  if (!section || section === 'jual') {
    jualDraft.value = buildDraft('harga_jual')
  }
}

const paguDraftTotal = computed(() =>
  isPaguTotal.value ? (totalPaguDraft.value ?? 0) : draftTotal(items.value, paguDraft.value),
)

const paguDirty = computed(
  () =>
    !!request.value &&
    (selectedMediaId.value !== (request.value.media_pengadaan_id ?? null) ||
      selectedBranchId.value !== (request.value.branch_id ?? null) ||
      modePagu.value !== (request.value.mode_pagu ?? MODE_DETAIL) ||
      (isPaguTotal.value
        ? totalPaguDraft.value !== toNumber(request.value.total_pagu)
        : changedItems(paguDraft.value, 'harga_pagu').length > 0)),
)
const modalDirty = computed(
  () =>
    !!request.value &&
    (selectedPajak.value !== (request.value.pajak_harga_modal ?? null) ||
      changedItems(modalDraft.value, 'harga_modal').length > 0),
)
const jualDirty = computed(() => changedItems(jualDraft.value, 'harga_jual').length > 0)

const paguFormError = computed(() => {
  if (!selectedMediaId.value) return 'Media pengadaan wajib dipilih'
  if (!selectedBranchId.value) return 'Branch/PT wajib dipilih'
  return ''
})
const modalFormError = computed(() => (selectedPajak.value ? '' : 'Pajak harga modal wajib dipilih'))

function markEdited(state: { error: string }) {
  state.error = ''
}

function setTotalPagu(value: number | null) {
  if (totalPaguDraft.value === value) return
  totalPaguDraft.value = value
  markEdited(paguState)
}

/* ---------- Load ---------- */

async function loadItems(id: number) {
  itemsLoading.value = true
  itemsError.value = ''

  try {
    items.value = await getRequestItems(id)
  } catch (error) {
    itemsError.value = getErrorMessage(error, 'Gagal memuat daftar barang')
  } finally {
    itemsLoading.value = false
  }
}

async function refreshRequest() {
  if (!request.value) return

  try {
    request.value = await getRequestPenawaran(request.value.id)
  } catch {
    return
  }
}

async function onItemSaved() {
  if (!request.value) return
  await Promise.all([loadItems(request.value.id), refreshRequest()])
  syncDrafts()
}

async function loadContext(lkhId: number) {
  try {
    const lkh = (await getLkh()).find((item) => item.id === lkhId)
    if (!lkh) return
    const rkh = await getRkhById(lkh.rkh_id)

    const [projects, customers] = await Promise.all([
      getProjects().catch(() => []),
      getCustomers().catch(() => []),
    ])

    projectName.value = projects.find((project) => project.id === rkh.project_id)?.nama_project ?? ''
    customerName.value = customers.find((customer) => customer.id === rkh.customer_id)?.nama_instansi ?? ''
  } catch {
    projectName.value = ''
    customerName.value = ''
  }
}

async function load() {
  const id = requestId.value

  loading.value = true
  loadError.value = ''
  request.value = null
  items.value = []
  projectName.value = ''
  customerName.value = ''

  if (!Number.isInteger(id) || id <= 0) {
    loadError.value = 'Request penawaran tidak valid'
    loading.value = false
    return
  }

  try {
    const [requestData, mediaData, branchData] = await Promise.all([
      getRequestPenawaran(id),
      getMediaPengadaan().catch(() => [] as MediaPengadaan[]),
      getBranches().catch(() => [] as Branch[]),
    ])

    request.value = requestData
    mediaList.value = mediaData
    branches.value = branchData

    await Promise.all([loadItems(id), loadContext(requestData.lkh_id)])
    syncDrafts()
  } catch (error) {
    loadError.value = getErrorMessage(error, 'Gagal memuat request penawaran')
  } finally {
    loading.value = false
  }
}

watch(requestId, load, { immediate: true })

/* ---------- Simpan per section ---------- */

async function runSave(
  state: { saving: boolean; error: string },
  section: Section,
  successMessage: string,
  task: () => Promise<unknown>,
) {
  if (!request.value) return

  state.saving = true
  state.error = ''

  try {
    await task()
    await Promise.all([loadItems(request.value.id), refreshRequest()])
    syncDrafts(section)
    toast.add({ severity: 'success', summary: 'Tersimpan', detail: successMessage, life: 2500 })
  } catch (error) {
    state.error = getErrorMessage(error, 'Gagal menyimpan')
  } finally {
    state.saving = false
  }
}

async function savePagu() {
  const current = request.value
  if (!current) return

  paguTried.value = true
  const mediaId = selectedMediaId.value
  const branchId = selectedBranchId.value
  const mode = modePagu.value
  if (paguFormError.value || !mediaId || !branchId || !mode) return

  return runSave(paguState, 'pagu', 'Harga pagu berhasil disimpan', async () => {
    await updateRequestPenawaran(current.id, {
      media_pengadaan_id: mediaId,
      branch_id: branchId,
      mode_pagu: mode,
      ...(isPaguTotal.value ? { total_pagu: totalPaguDraft.value } : {}),
    })

    if (!isPaguTotal.value) {
      await Promise.all(
        changedItems(paguDraft.value, 'harga_pagu').map((item) =>
          updateRequestItem(current.id, item.id, { harga_pagu: paguDraft.value[item.id] }),
        ),
      )
    }
    paguTried.value = false
  })
}

async function saveModal() {
  const current = request.value
  if (!current || !canEditCost.value) return

  modalTried.value = true
  const pajak = selectedPajak.value
  if (modalFormError.value || !pajak) return

  return runSave(modalState, 'modal', 'Harga modal berhasil disimpan', async () => {
    await updateRequestPenawaran(current.id, { pajak_harga_modal: pajak })

    await Promise.all(
      changedItems(modalDraft.value, 'harga_modal').map((item) =>
        updateRequestItem(current.id, item.id, { harga_modal: modalDraft.value[item.id] }),
      ),
    )
    modalTried.value = false
  })
}

function saveJual() {
  const current = request.value
  if (!current) return

  return runSave(jualState, 'jual', 'Harga jual berhasil disimpan', async () => {
    await Promise.all(
      changedItems(jualDraft.value, 'harga_jual').map((item) =>
        updateRequestItem(current.id, item.id, { harga_jual: jualDraft.value[item.id] }),
      ),
    )
  })
}

/* ---------- Navigasi & dialog ---------- */

function openAddItem() {
  selectedItem.value = null
  itemDialogVisible.value = true
}

function openEditItem(item: RequestItem) {
  selectedItem.value = item
  itemDialogVisible.value = true
}

function goBack() {
  router.push(REQUEST_PENAWARAN_LIST_PATH)
}

function finish() {
  router.replace(REQUEST_PENAWARAN_LIST_PATH)
}
</script>

<template>
  <div class="flex w-full flex-col gap-6">
    <div v-if="loading" class="flex items-center justify-center gap-3 py-16 text-sm text-fg-muted">
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat request penawaran...
    </div>

    <Message v-else-if="loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <template v-else-if="request">
      <!-- Header halaman -->
      <header class="flex flex-wrap items-start justify-between gap-4">
        <div class="min-w-0">
          <h1 class="text-lg font-semibold">Detail Request Penawaran</h1>
          <p class="mt-1 text-sm text-fg-muted">
            {{ [customerName, projectName].filter(Boolean).join(' — ') || `Request penawaran #${request.id}` }}
          </p>
        </div>

        <Button v-if="!isFirstVisit" icon="pi pi-arrow-left" label="Kembali" variant="text" size="small" @click="goBack" />
      </header>

      <RequestPenawaranSummary :request="request" :item-count="items.length" />

      <Message v-if="itemsError" severity="error" :closable="false">
        <div class="flex flex-wrap items-center gap-3">
          <span>{{ itemsError }}</span>
          <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="loadItems(request.id)" />
        </div>
      </Message>

      <!-- ================= FORM 1: PAGU ================= -->
      <form class="flex flex-col gap-4 rounded-xl border border-line bg-card p-5" novalidate @submit.prevent="savePagu">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <span class="text-sm" :class="!isPaguTotal ? 'font-semibold' : 'text-fg-muted'">Pagu detail</span>
            <ToggleSwitch
              v-model="isPaguTotal"
              input-id="toggle-pagu"
              aria-label="Pilih mode pagu"
              @update:model-value="markEdited(paguState)"
            />
            <span class="text-sm" :class="isPaguTotal ? 'font-semibold' : 'text-fg-muted'">Pagu total</span>
          </div>

          <Button
            type="button"
            label="Tambah barang"
            icon="pi pi-plus"
            size="small"
            variant="outlined"
            class="whitespace-nowrap"
            @click="openAddItem"
          />
        </div>

        <p class="text-xs text-fg-muted">
          <template v-if="!isPaguTotal">
            Isi harga pagu per satuan. Subtotal = jumlah × harga pagu, lalu dijumlahkan menjadi total harga pagu.
          </template>
          <template v-else>Mode pagu total: isi total harga pagu langsung, tanpa harga per satuan.</template>
        </p>

        <div class="grid gap-4 sm:grid-cols-2">
          <div class="flex flex-col gap-1.5">
            <label for="dt-media" class="text-xs text-fg-muted">Media pengadaan</label>
            <Select
              v-model="selectedMediaId"
              input-id="dt-media"
              :options="mediaOptions"
              option-label="label"
              option-value="value"
              placeholder="Pilih media pengadaan"
              size="small"
              filter
              fluid
              :invalid="paguTried && !selectedMediaId"
              empty-message="Daftar media pengadaan tidak tersedia"
              @update:model-value="markEdited(paguState)"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label for="dt-branch" class="text-xs text-fg-muted">Branch/PT</label>
            <Select
              v-model="selectedBranchId"
              input-id="dt-branch"
              :options="branchOptions"
              option-label="label"
              option-value="value"
              placeholder="Pilih branch/PT"
              size="small"
              filter
              fluid
              :invalid="paguTried && !selectedBranchId"
              empty-message="Daftar branch tidak tersedia"
              @update:model-value="markEdited(paguState)"
            />
          </div>
        </div>

        <div v-if="itemsLoading && items.length === 0" class="flex items-center justify-center gap-3 py-12 text-sm text-fg-muted">
          <i class="pi pi-spin pi-spinner text-lg" />
          Memuat daftar barang...
        </div>

        <div
          v-else-if="!itemsError && items.length === 0"
          class="flex flex-col items-center justify-center gap-2 border-y border-dashed border-line py-12 text-center"
        >
          <i class="pi pi-box text-3xl text-fg-muted" />
          <p class="font-medium">Belum ada barang</p>
          <p class="text-sm text-fg-muted">Tambahkan barang untuk request penawaran ini.</p>
        </div>

        <RequestPaguTable
          v-else-if="items.length > 0"
          v-model="paguDraft"
          :items="items"
          :show-price="!isPaguTotal"
          :loading="itemsLoading"
          @edited="markEdited(paguState)"
          @edit="openEditItem"
        />

        <div class="flex flex-wrap items-center justify-end gap-4 border-t border-line pt-4 text-sm">
          <span class="font-semibold">Total harga pagu</span>
          <InputNumber
            v-if="isPaguTotal"
            :model-value="totalPaguDraft"
            input-id="total-pagu"
            mode="currency"
            currency="IDR"
            locale="id-ID"
            :min-fraction-digits="0"
            :min="0"
            placeholder="Total pagu"
            size="small"
            @input="setTotalPagu($event.value == null ? null : Number($event.value))"
            @update:model-value="setTotalPagu"
          />
          <span v-else class="tabular-nums">{{ formatRupiah(paguDraftTotal) }}</span>
        </div>

        <Message v-if="paguState.error" severity="error" size="small">{{ paguState.error }}</Message>
        <Message v-else-if="paguTried && paguFormError" severity="warn" size="small">{{ paguFormError }}</Message>

        <div class="flex items-center justify-end gap-3">
          <Button
            type="submit"
            label="Simpan pagu"
            icon="pi pi-save"
            :loading="paguState.saving"
            :disabled="!paguDirty"
          />
        </div>
      </form>

      <!-- ================= FORM 2: HARGA MODAL ================= -->
      <form
        v-if="items.length > 0"
        class="flex flex-col gap-4 rounded-xl border border-line bg-card p-5"
        novalidate
        @submit.prevent="saveModal"
      >
        <div>
          <h2 class="font-semibold">Harga modal</h2>
          <p class="mt-1 text-xs text-fg-muted">
            Harga modal diisi per barang oleh PPIC atau admin. Item tambahan tidak masuk ke pagu.
          </p>
        </div>

        <Message v-if="!canEditCost" severity="info" size="small">
          Harga modal hanya bisa diisi oleh PPIC atau admin.
        </Message>

        <div class="flex max-w-sm flex-col gap-1.5">
          <label for="dt-pajak" class="text-xs text-fg-muted">Pajak harga modal</label>
          <Select
            v-model="selectedPajak"
            input-id="dt-pajak"
            :options="PAJAK_OPTIONS"
            option-label="label"
            option-value="value"
            placeholder="Pilih pajak"
            size="small"
            fluid
            :disabled="!canEditCost"
            :invalid="modalTried && !selectedPajak"
            @update:model-value="markEdited(modalState)"
          />
        </div>

        <RequestModalTable
          v-model="modalDraft"
          :items="items"
          :disabled="!canEditCost"
          @edited="markEdited(modalState)"
        />

        <Message v-if="modalState.error" severity="error" size="small">{{ modalState.error }}</Message>
        <Message v-else-if="modalTried && modalFormError" severity="warn" size="small">{{ modalFormError }}</Message>

        <div class="flex items-center justify-end gap-3">
          <Button
            type="submit"
            label="Simpan harga modal"
            icon="pi pi-save"
            :loading="modalState.saving"
            :disabled="!canEditCost || !modalDirty"
          />
        </div>
      </form>

      <!-- ================= FORM 3: HARGA JUAL ================= -->
      <form
        v-if="items.length > 0"
        class="flex flex-col gap-4 rounded-xl border border-line bg-card p-5"
        novalidate
        @submit.prevent="saveJual"
      >
        <div>
          <h2 class="font-semibold">Setting harga jual</h2>
          <p class="mt-1 text-xs text-fg-muted">Isi harga jual tiap barang. Harga modal ditampilkan sebagai acuan.</p>
        </div>

        <RequestJualTable v-model="jualDraft" :items="items" @edited="markEdited(jualState)" />

        <Message v-if="jualState.error" severity="error" size="small">{{ jualState.error }}</Message>

        <div class="flex items-center justify-end gap-3">
          <Button
            type="submit"
            label="Simpan harga jual"
            icon="pi pi-save"
            :loading="jualState.saving"
            :disabled="!jualDirty"
          />
        </div>
      </form>

      <div v-if="isFirstVisit" class="flex flex-wrap items-center justify-between gap-3 border-t border-line pt-5">
        <p class="text-sm text-fg-muted">
          Tambahkan barang yang diminta, lalu simpan untuk melanjutkan ke daftar request penawaran.
        </p>
        <Button label="Simpan dan lanjut" icon="pi pi-check" class="whitespace-nowrap" @click="finish" />
      </div>

      <RequestItemDialog
        v-model:visible="itemDialogVisible"
        :request-id="request.id"
        :item="selectedItem"
        :can-edit-cost="canEditCost"
        @saved="onItemSaved"
      />
    </template>
  </div>
</template>