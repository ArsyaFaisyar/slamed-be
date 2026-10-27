<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import Message from 'primevue/message'
import Textarea from 'primevue/textarea'

import {
  REVISI_STATUS_LABEL,
  approveRevisi,
  createRevisi,
  getRiwayatRevisi,
  revisiDetailPath,
  type RevisiRiwayat,
  type RevisiStatus,
} from '../../api/revisiPenawaran.ts'
import { useAuthStore } from '../../stores/auth.ts'
import { getErrorMessage } from '../../utils/error.ts'

const props = defineProps<{ requestId: number }>()
const emit = defineEmits<{ changed: [] }>()

const router = useRouter()
const confirm = useConfirm()
const toast = useToast()
const auth = useAuthStore()

const STATUS_CLASS: Record<RevisiStatus, string> = {
  DIMINTA: 'bg-amber-500/15 text-amber-600 dark:text-amber-400',
  DIKIRIM: 'bg-sky-500/15 text-sky-600 dark:text-sky-400',
  SELESAI: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400',
  DITOLAK: 'bg-red-500/15 text-red-600 dark:text-red-400',
}

const riwayat = ref<RevisiRiwayat[]>([])
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

const dialogVisible = ref(false)
const alasan = ref('')
const tried = ref(false)
const saving = ref(false)
const dialogError = ref('')

const role = computed(() => auth.user?.role)
const isSpv = computed(() => role.value === 'SPV')
const isSales = computed(() => role.value === 'SALES')
const latest = computed(() => riwayat.value.reduce<RevisiRiwayat | null>((last, item) => (!last || item.nomor_revisi > last.nomor_revisi ? item : last), null))
const canRequest = computed(() => isSpv.value && !latest.value)
const rejecting = ref(false)
const dialogTitle = computed(() => (rejecting.value ? 'Tolak revisi' : 'Minta revisi penawaran'))
const dialogSubmitLabel = computed(() => (rejecting.value ? 'Kirim penolakan' : 'Kirim permintaan'))
const dialogHint = computed(() =>
  rejecting.value ? 'Jelaskan bagian yang masih perlu diperbaiki Sales' : 'Jelaskan bagian penawaran yang perlu direvisi',
)
const visible = computed(() => loading.value || !!errorMessage.value || riwayat.value.length > 0 || canRequest.value)
const alasanError = computed(() => (alasan.value.trim() ? '' : 'Alasan revisi wajib diisi'))

function formatDate(value: string | null) {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
}

async function load() {
  loading.value = true
  errorMessage.value = ''

  try {
    const data = await getRiwayatRevisi(props.requestId)
    riwayat.value = data.riwayat
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat riwayat revisi')
  } finally {
    loading.value = false
  }
}

watch(() => props.requestId, load, { immediate: true })

function openDialog(reject = false) {
  rejecting.value = reject
  alasan.value = ''
  tried.value = false
  dialogError.value = ''
  dialogVisible.value = true
}

async function submitRequest() {
  tried.value = true
  if (alasanError.value) return

  saving.value = true
  dialogError.value = ''

  try {
    await createRevisi(props.requestId, alasan.value.trim())
    dialogVisible.value = false
    toast.add({
      severity: 'success',
      summary: rejecting.value ? 'Revisi ditolak' : 'Revisi diminta',
      detail: rejecting.value ? 'Revisi dikembalikan ke Sales untuk diperbaiki' : 'Permintaan revisi dikirim ke Sales',
      life: 2500,
    })
    await load()
    emit('changed')
  } catch (error) {
    dialogError.value = getErrorMessage(error, 'Gagal mengirim permintaan revisi')
  } finally {
    saving.value = false
  }
}

function confirmApprove(item: RevisiRiwayat) {
  confirm.require({
    header: 'Setujui revisi',
    message: `Setujui revisi #${item.nomor_revisi}? Setelah disetujui, revisi tidak dapat diubah lagi.`,
    icon: 'pi pi-check-circle',
    rejectProps: { label: 'Batal', severity: 'secondary', variant: 'text' },
    acceptProps: { label: 'Setujui' },
    accept: async () => {
      actionError.value = ''
      try {
        await approveRevisi(props.requestId, item.id)
        toast.add({ severity: 'success', summary: 'Disetujui', detail: `Revisi #${item.nomor_revisi} disetujui`, life: 2500 })
        await load()
        emit('changed')
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menyetujui revisi')
      }
    },
  })
}

function open(item: RevisiRiwayat) {
  router.push(revisiDetailPath(props.requestId, item.id))
}
</script>

<template>
  <section v-if="visible" class="rounded-xl border border-line bg-card">
    <div class="flex flex-wrap items-center justify-between gap-3 border-b border-line p-4">
      <div>
        <h2 class="font-semibold">Riwayat revisi</h2>
        <p class="mt-1 text-xs text-fg-muted">{{ riwayat.length }} revisi untuk request penawaran ini</p>
      </div>

      <Button
        v-if="canRequest"
        icon="pi pi-replay"
        label="Minta revisi"
        size="small"
        severity="secondary"
        variant="outlined"
        class="whitespace-nowrap"
        @click="openDialog(false)" />
    </div>

    <Message v-if="errorMessage" severity="error" :closable="false" class="m-4">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ errorMessage }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" class="m-4" @close="actionError = ''">{{ actionError }}</Message>

    <div v-if="loading && riwayat.length === 0" class="flex items-center justify-center gap-3 p-8 text-sm text-fg-muted">
      <i class="pi pi-spin pi-spinner" />
      Memuat riwayat revisi...
    </div>

    <div v-else-if="riwayat.length > 0" class="overflow-x-auto">
      <table class="w-full min-w-[820px] text-left text-sm">
        <thead class="bg-sidebar text-fg-muted">
          <tr>
            <th class="px-5 py-3 font-medium">Revisi</th>
            <th class="px-5 py-3 font-medium">Alasan</th>
            <th class="px-5 py-3 font-medium">Status</th>
            <th class="px-5 py-3 font-medium">Diminta</th>
            <th class="px-5 py-3 font-medium">Dikirim</th>
            <th class="px-5 py-3 font-medium">Disetujui</th>
            <th class="px-5 py-3 text-center font-medium">Aksi</th>
          </tr>
        </thead>

        <tbody class="divide-y divide-line">
          <tr v-for="item in riwayat" :key="item.id" class="transition-colors hover:bg-sidebar/60">
            <td class="px-5 py-3 font-medium">#{{ item.nomor_revisi }}</td>
            <td class="max-w-xs px-5 py-3 text-fg-muted">
              <p class="line-clamp-2" :title="item.alasan_revisi">{{ item.alasan_revisi }}</p>
            </td>
            <td class="px-5 py-3">
              <span class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium" :class="STATUS_CLASS[item.status_revisi]">
                {{ REVISI_STATUS_LABEL[item.status_revisi] ?? item.status_revisi }}
              </span>
            </td>
            <td class="px-5 py-3 text-fg-muted">{{ formatDate(item.tanggal_diminta) }}</td>
            <td class="px-5 py-3 text-fg-muted">{{ formatDate(item.tanggal_dikirim) }}</td>
            <td class="px-5 py-3 text-fg-muted">{{ formatDate(item.tanggal_disetujui) }}</td>
            <td class="px-5 py-3">
              <div class="flex items-center justify-center gap-1">
                <Button
                  v-if="isSales && item.status_revisi === 'DIMINTA'"
                  icon="pi pi-pencil"
                  label="Kerjakan"
                  size="small"
                  variant="text"
                  @click="open(item)" />
                <Button
                  v-else
                  icon="pi pi-eye"
                  variant="text"
                  rounded
                  severity="secondary"
                  aria-label="Lihat revisi"
                  v-tooltip.top="'Lihat revisi'"
                  @click="open(item)" />
                <Button
                  v-if="isSpv && item.status_revisi === 'DIKIRIM' && item.id === latest?.id"
                  icon="pi pi-check"
                  label="Setujui"
                  size="small"
                  variant="text"
                  severity="success"
                  @click="confirmApprove(item)" />
                <Button
                  v-if="isSpv && item.status_revisi === 'DIKIRIM' && item.id === latest?.id"
                  icon="pi pi-times"
                  label="Tolak"
                  size="small"
                  variant="text"
                  severity="danger"
                  @click="openDialog(true)" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <Dialog v-model:visible="dialogVisible" modal :header="dialogTitle" class="w-[calc(100vw-2rem)] max-w-lg" :draggable="false" :closable="!saving" :close-on-escape="!saving">
      <form id="revisi-form" class="flex flex-col gap-3" novalidate @submit.prevent="submitRequest">
        <div class="flex flex-col gap-1.5">
          <label for="alasan-revisi" class="text-xs text-fg-muted">Alasan revisi</label>
          <Textarea id="alasan-revisi" v-model="alasan" rows="5" auto-resize fluid :placeholder="dialogHint" :invalid="tried && !!alasanError" @update:model-value="dialogError = ''" />
        </div>

        <Message v-if="dialogError" severity="error" size="small">{{ dialogError }}</Message>
        <Message v-else-if="tried && alasanError" severity="warn" size="small">{{ alasanError }}</Message>
      </form>

      <template #footer>
        <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="dialogVisible = false" />
        <Button type="submit" form="revisi-form" :label="dialogSubmitLabel" icon="pi pi-send" :loading="saving" />
      </template>
    </Dialog>
  </section>
</template>