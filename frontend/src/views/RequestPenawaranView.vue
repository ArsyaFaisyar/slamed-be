<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Button from 'primevue/button'
import Message from 'primevue/message'

import {
  MODE_PAGU_OPTIONS,
  PAJAK_OPTIONS,
  createRequestPenawaran,
  forgetRequestId,
  getRequestPenawaran,
  recallRequestId,
  rememberRequestId,
  requestPenawaranDetailPath,
} from '../api/requestPenawaran'
import { getMediaPengadaan, type MediaPengadaan } from '../api/mediaPengadaan'
import { getBranches, type Branch } from '../api/branches'
import { getLkh, type Lkh } from '../api/lkh'
import { getRkhById, type Rkh } from '../api/rkh'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage, getFieldErrors } from '../utils/error'
import { formatDate } from '../utils/date'

const LIST_PATH = '/aktivitas/lkh'

type Field = 'diminta_oleh' | 'media_pengadaan_id' | 'branch_id' | 'mode_pagu' | 'pajak_harga_modal'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const lkhId = computed(() => Number(route.params.lkhId))

const lkh = ref<Lkh | null>(null)
const rkh = ref<Rkh | null>(null)
const mediaList = ref<MediaPengadaan[]>([])
const branches = ref<Branch[]>([])

const loading = ref(false)
const loadError = ref('')

const form = reactive({
  diminta_oleh: '',
  media_pengadaan_id: null as number | null,
  branch_id: null as number | null,
  mode_pagu: 'DETAIL' as string | null,
  pajak_harga_modal: null as string | null,
})

const submitted = ref(false)
const saving = ref(false)
const formError = ref('')
const serverErrors = ref<Record<string, string>>({})

const mediaOptions = computed(() => mediaList.value.map((media) => ({ value: media.id, label: media.nama })))
const branchOptions = computed(() =>
  branches.value.map((branch) => ({ value: branch.id, label: `${branch.nama} (${branch.kode})` })),
)

const clientErrors = computed<Record<Field, string>>(() => ({
  diminta_oleh: form.diminta_oleh.trim() ? '' : 'Nama peminta wajib diisi',
  media_pengadaan_id: form.media_pengadaan_id === null ? 'Media pengadaan wajib dipilih' : '',
  branch_id: form.branch_id === null ? 'Branch/PT wajib dipilih' : '',
  mode_pagu: form.mode_pagu ? '' : 'Mode pagu wajib dipilih',
  pajak_harga_modal: form.pajak_harga_modal ? '' : 'Pajak harga modal wajib dipilih',
}))

function fieldError(field: Field) {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : '')
}

async function load() {
  const id = lkhId.value

  loading.value = true
  loadError.value = ''
  lkh.value = null
  rkh.value = null

  if (!Number.isInteger(id) || id <= 0) {
    loadError.value = 'LKH tidak valid'
    loading.value = false
    return
  }

  try {
    const storedId = recallRequestId(id)
    if (storedId !== null) {
      try {
        await getRequestPenawaran(storedId)
        await router.replace(requestPenawaranDetailPath(storedId))
        return
      } catch {
        forgetRequestId(id)
      }
    }

    const [lkhList, mediaData, branchData] = await Promise.all([
      getLkh(),
      getMediaPengadaan().catch(() => [] as MediaPengadaan[]),
      getBranches().catch(() => [] as Branch[]),
    ])

    const found = lkhList.find((item) => item.id === id) ?? null
    if (!found) {
      loadError.value = 'LKH tidak ditemukan atau Anda tidak memiliki akses'
      return
    }

    lkh.value = found
    mediaList.value = mediaData
    branches.value = branchData
    form.diminta_oleh = String(auth.user?.nama ?? '')
    rkh.value = await getRkhById(found.rkh_id).catch(() => null)
  } catch (error) {
    loadError.value = getErrorMessage(error, 'Gagal memuat data request penawaran')
  } finally {
    loading.value = false
  }
}

watch(lkhId, load, { immediate: true })

async function onSubmit() {
  submitted.value = true
  if (Object.values(clientErrors.value).some(Boolean)) return

  saving.value = true
  formError.value = ''
  serverErrors.value = {}

  try {
    const created = await createRequestPenawaran({
      lkh_id: lkhId.value,
      diminta_oleh: form.diminta_oleh.trim(),
      media_pengadaan_id: form.media_pengadaan_id as number,
      branch_id: form.branch_id as number,
      mode_pagu: form.mode_pagu as string,
      pajak_harga_modal: form.pajak_harga_modal as string,
    })

    rememberRequestId(lkhId.value, created.id)
    await router.replace({ path: requestPenawaranDetailPath(created.id), query: { baru: '1' } })
  } catch (error) {
    const errors = getFieldErrors(error)
    const known: Record<string, string> = {}

    for (const [key, message] of Object.entries(errors)) {
      if (key in clientErrors.value) known[key] = message
    }

    serverErrors.value = known
    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(error, 'Gagal membuat request penawaran')
    }
  } finally {
    saving.value = false
  }
}

function goBack() {
  router.push(LIST_PATH)
}
</script>

<template>
  <div class="mx-auto flex w-full max-w-5xl flex-col gap-4">
    <div>
      <Button
        icon="pi pi-arrow-left"
        label="Kembali ke daftar LKH"
        variant="text"
        severity="secondary"
        size="small"
        @click="goBack"
      />
    </div>

    <div
      v-if="loading"
      class="flex items-center justify-center gap-3 rounded-xl border border-line bg-card p-12 text-sm text-fg-muted"
    >
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat data...
    </div>

    <Message v-else-if="loadError" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ loadError }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <section v-else-if="lkh" class="rounded-xl border border-line bg-card">
      <div class="border-b border-line p-4 sm:p-5">
        <h2 class="font-semibold">Buat request penawaran</h2>
        <p class="mt-1 text-sm text-fg-muted">
          {{ rkh?.judul_kegiatan ?? `LKH tanggal ${formatDate(lkh.tanggal_kunjungan)}` }}
        </p>
      </div>

      <form
        id="request-form"
        class="grid gap-4 p-4 sm:grid-cols-2 sm:p-5"
        novalidate
        @submit.prevent="onSubmit"
      >
        <Message v-if="formError" class="sm:col-span-2" severity="error" size="small">{{ formError }}</Message>

        <div class="flex flex-col gap-1.5 sm:col-span-2">
          <label for="rp-diminta" class="text-sm font-medium">
            Diminta oleh <span class="text-red-500">*</span>
          </label>
          <InputText id="rp-diminta" v-model="form.diminta_oleh" readonly autocomplete="off" fluid class="cursor-not-allowed opacity-80" :invalid="!!fieldError('diminta_oleh')" />
          <Message v-if="fieldError('diminta_oleh')" severity="error" size="small" variant="simple">
            {{ fieldError('diminta_oleh') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rp-media" class="text-sm font-medium">
            Media pengadaan <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.media_pengadaan_id"
            input-id="rp-media"
            :options="mediaOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih media pengadaan"
            filter
            fluid
            empty-message="Daftar media pengadaan tidak tersedia"
            :invalid="!!fieldError('media_pengadaan_id')"
          />
          <Message v-if="fieldError('media_pengadaan_id')" severity="error" size="small" variant="simple">
            {{ fieldError('media_pengadaan_id') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rp-branch" class="text-sm font-medium">
            Branch/PT <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.branch_id"
            input-id="rp-branch"
            :options="branchOptions"
            option-label="label"
            option-value="value"
            placeholder="Pilih branch/PT"
            filter
            fluid
            empty-message="Daftar branch tidak tersedia"
            :invalid="!!fieldError('branch_id')"
          />
          <Message v-if="fieldError('branch_id')" severity="error" size="small" variant="simple">
            {{ fieldError('branch_id') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rp-mode" class="text-sm font-medium">
            Mode pagu <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.mode_pagu"
            input-id="rp-mode"
            :options="MODE_PAGU_OPTIONS"
            option-label="label"
            option-value="value"
            placeholder="Pilih mode pagu"
            fluid
            :invalid="!!fieldError('mode_pagu')"
          />
          <Message v-if="fieldError('mode_pagu')" severity="error" size="small" variant="simple">
            {{ fieldError('mode_pagu') }}
          </Message>
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="rp-pajak" class="text-sm font-medium">
            Pajak harga modal <span class="text-red-500">*</span>
          </label>
          <Select
            v-model="form.pajak_harga_modal"
            input-id="rp-pajak"
            :options="PAJAK_OPTIONS"
            option-label="label"
            option-value="value"
            placeholder="Pilih pajak"
            fluid
            :invalid="!!fieldError('pajak_harga_modal')"
          />
          <Message v-if="fieldError('pajak_harga_modal')" severity="error" size="small" variant="simple">
            {{ fieldError('pajak_harga_modal') }}
          </Message>
        </div>

        <div class="flex justify-end sm:col-span-2">
          <Button type="submit" label="Buat request" icon="pi pi-check" :loading="saving" />
        </div>
      </form>
    </section>
  </div>
</template>