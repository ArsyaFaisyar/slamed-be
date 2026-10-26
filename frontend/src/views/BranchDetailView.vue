<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import BranchFormDialog from '../components/BranchPage/BranchFormDialog.vue'
import BranchImage from '../components/BranchPage/BranchImage.vue'
import BranchLogo from '../components/BranchPage/BranchLogo.vue'

import { deleteBranch, getBranch, type Branch } from '../api/branches'
import { getErrorMessage } from '../utils/error'

const route = useRoute()
const router = useRouter()
const confirm = useConfirm()

const branch = ref<Branch | null>(null)
const loading = ref(false)
const notFound = ref(false)
const errorMessage = ref('')
const actionError = ref('')
const formVisible = ref(false)

const branchId = computed(() => Number(route.params.id))

const websiteUrl = computed(() => {
  const value = branch.value?.website?.trim()
  if (!value) return ''
  return /^https?:\/\//i.test(value) ? value : `https://${value}`
})

async function fetchBranch() {
  if (!Number.isInteger(branchId.value)) {
    notFound.value = true
    return
  }

  loading.value = true
  notFound.value = false
  errorMessage.value = ''

  try {
    branch.value = await getBranch(branchId.value)
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 404) {
      notFound.value = true
      branch.value = null
    } else {
      errorMessage.value = getErrorMessage(error, 'Gagal memuat detail cabang')
    }
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push('/master/branch')
}

function confirmDelete() {
  if (!branch.value) return
  const target = branch.value

  confirm.require({
    header: 'Hapus Cabang',
    message: `Apakah Anda yakin ingin menghapus cabang ${target.nama}? Tindakan ini tidak dapat dibatalkan.`,
    icon: 'pi pi-exclamation-triangle',
    rejectProps: {
      label: 'Batal',
      severity: 'secondary',
      variant: 'text',
    },
    acceptProps: {
      label: 'Hapus',
      severity: 'danger',
    },
    accept: async () => {
      actionError.value = ''
      try {
        await deleteBranch(target.id)
        goBack()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menghapus cabang')
      }
    },
  })
}

watch(branchId, fetchBranch, { immediate: true })
</script>

<template>
  <div class="flex flex-col gap-6">
    <div>
      <Button
        label="Kembali ke daftar cabang"
        icon="pi pi-arrow-left"
        size="small"
        variant="text"
        severity="secondary"
        @click="goBack"
      />
    </div>

    <Message v-if="errorMessage" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ errorMessage }}</span>
        <Button
          label="Coba lagi"
          size="small"
          severity="danger"
          variant="text"
          :loading="loading"
          @click="fetchBranch"
        />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <div
      v-if="loading && !branch"
      class="flex items-center justify-center gap-3 rounded-xl border border-line bg-card p-12 text-sm text-fg-muted"
    >
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat detail cabang...
    </div>

    <div
      v-else-if="notFound"
      class="flex flex-col items-center justify-center gap-2 rounded-xl border border-line bg-card p-12 text-center"
    >
      <i class="pi pi-building text-3xl text-fg-muted" />
      <p class="font-medium">Cabang tidak ditemukan</p>
      <p class="text-sm text-fg-muted">Data mungkin sudah dihapus atau alamat tidak valid.</p>
    </div>

    <template v-else-if="branch">
      <section class="overflow-hidden rounded-xl border border-line bg-card">
        <div class="h-36 w-full bg-brand/10 sm:h-48">
          <BranchImage :src="branch.cover_image" :alt="`Cover ${branch.nama}`" fit="cover">
            <div class="flex size-full items-center justify-center text-fg-muted">
              <i class="pi pi-image text-3xl" />
            </div>
          </BranchImage>
        </div>

        <div class="flex flex-col gap-5 p-6 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-center gap-5">
            <BranchLogo :name="branch.nama" :logo="branch.logo" class="size-20 text-2xl" />

            <div class="min-w-0">
              <h2 class="text-xl font-semibold tracking-tight">{{ branch.nama }}</h2>
              <span class="mt-2 inline-flex rounded-md border border-line px-2.5 py-1 text-xs font-medium">
                {{ branch.kode }}
              </span>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <Button
              label="Edit"
              icon="pi pi-pencil"
              size="small"
              variant="outlined"
              severity="secondary"
              @click="formVisible = true"
            />
            <Button
              label="Hapus"
              icon="pi pi-trash"
              size="small"
              variant="outlined"
              severity="danger"
              @click="confirmDelete"
            />
          </div>
        </div>
      </section>

      <section class="rounded-xl border border-line bg-card p-6">
        <h3 class="font-semibold">Informasi cabang</h3>

        <dl class="mt-5 grid gap-x-8 gap-y-6 sm:grid-cols-2">
          <div>
            <dt class="text-xs text-fg-muted">Nama cabang</dt>
            <dd class="mt-1 break-words text-sm font-medium">{{ branch.nama }}</dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">Kode</dt>
            <dd class="mt-1 break-words text-sm font-medium">{{ branch.kode }}</dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">Nama direktur</dt>
            <dd class="mt-1 break-words text-sm font-medium">{{ branch.nama_direktur || '-' }}</dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">No. telepon</dt>
            <dd class="mt-1 break-words text-sm font-medium">
              <a v-if="branch.no_telepon" :href="`tel:${branch.no_telepon}`" class="hover:text-brand">
                {{ branch.no_telepon }}
              </a>
              <template v-else>-</template>
            </dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">Email</dt>
            <dd class="mt-1 break-words text-sm font-medium">
              <a v-if="branch.email" :href="`mailto:${branch.email}`" class="hover:text-brand">
                {{ branch.email }}
              </a>
              <template v-else>-</template>
            </dd>
          </div>

          <div>
            <dt class="text-xs text-fg-muted">Website</dt>
            <dd class="mt-1 break-words text-sm font-medium">
              <a
                v-if="websiteUrl"
                :href="websiteUrl"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:text-brand"
              >
                {{ branch.website }}
              </a>
              <template v-else>-</template>
            </dd>
          </div>

          <div class="sm:col-span-2">
            <dt class="text-xs text-fg-muted">Alamat</dt>
            <dd class="mt-1 whitespace-pre-line break-words text-sm font-medium">
              {{ branch.alamat || '-' }}
            </dd>
          </div>

          <div class="sm:col-span-2">
            <dt class="text-xs text-fg-muted">Tanda tangan direktur</dt>
            <dd class="mt-2">
              <div
                v-if="branch.signature_image"
                class="inline-flex h-28 w-56 items-center justify-center rounded-lg border border-line bg-white p-2"
              >
                <BranchImage :src="branch.signature_image" alt="Tanda tangan direktur" fit="contain">
                  <span class="text-xs text-neutral-500">Gambar tidak dapat dimuat</span>
                </BranchImage>
              </div>
              <span v-else class="text-sm font-medium">-</span>
            </dd>
          </div>
        </dl>
      </section>

      <BranchFormDialog v-model:visible="formVisible" :branch="branch" @saved="fetchBranch" />
    </template>
  </div>
</template>