<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'
import { useRouter } from 'vue-router'

import BranchFormDialog from '../components/BranchPage/BranchFormDialog.vue'
import BranchLogo from '../components/BranchPage/BranchLogo.vue'

import { deleteBranch, getBranches, type Branch } from '../api/branches'
import { getErrorMessage } from '../utils/error'

const confirm = useConfirm()
const router = useRouter()

const branches = ref<Branch[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

const formVisible = ref(false)
const selectedEdit = ref<Branch | null>(null)

const filteredBranches = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return branches.value

  return branches.value.filter((branch) =>
    [branch.nama, branch.kode, branch.nama_direktur, branch.email, branch.alamat].some((value) =>
      (value ?? '').toLowerCase().includes(keyword),
    ),
  )
})

function openCreate() {
  selectedEdit.value = null
  formVisible.value = true
}

function openEdit(branch: Branch) {
  selectedEdit.value = branch
  formVisible.value = true
}

function confirmDelete(branch: Branch) {
  confirm.require({
    header: 'Hapus Cabang',
    message: `Apakah Anda yakin ingin menghapus cabang ${branch.nama}? Tindakan ini tidak dapat dibatalkan.`,
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
        await deleteBranch(branch.id)
        await fetchBranches()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menghapus cabang')
      }
    },
  })
}

async function fetchBranches() {
  loading.value = true
  errorMessage.value = ''

  try {
    branches.value = await getBranches()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar cabang')
  } finally {
    loading.value = false
  }
}

onMounted(fetchBranches)
</script>

<template>
  <div class="flex flex-col gap-6">
    <Message v-if="errorMessage" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ errorMessage }}</span>
        <Button
          label="Coba lagi"
          size="small"
          severity="danger"
          variant="text"
          :loading="loading"
          @click="fetchBranches"
        />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar cabang</h2>
          <p class="mt-1 text-sm text-fg-muted">{{ filteredBranches.length }} cabang ditampilkan</p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari cabang..."
            aria-label="Cari cabang"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah cabang"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="openCreate"
          />
        </div>
      </div>

      <div
        v-if="loading && branches.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar cabang...
      </div>

      <div
        v-else-if="!errorMessage && filteredBranches.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-building text-3xl text-fg-muted" />

        <p class="font-medium">{{ search ? 'Cabang tidak ditemukan' : 'Belum ada cabang' }}</p>

        <p class="text-sm text-fg-muted">
          {{ search ? 'Coba kata kunci lain.' : 'Data cabang akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="branches.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[900px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Cabang</th>
              <th class="px-5 py-3 font-medium">Kode</th>
              <th class="px-5 py-3 font-medium">Direktur</th>
              <th class="px-5 py-3 font-medium">Telepon</th>
              <th class="px-5 py-3 font-medium">Email</th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="branch in filteredBranches"
              :key="branch.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4">
                <div class="flex items-center gap-3">
                  <BranchLogo :name="branch.nama" :logo="branch.logo" class="size-10 text-sm" />

                  <div class="min-w-0">
                    <RouterLink
                      :to="`/master/branch/${branch.id}`"
                      class="font-medium hover:text-brand hover:underline"
                    >
                      {{ branch.nama }}
                    </RouterLink>
                  </div>
                </div>
              </td>

              <td class="px-5 py-4">
                <span class="inline-flex rounded-md border border-line px-2.5 py-1 text-xs font-medium">
                  {{ branch.kode }}
                </span>
              </td>

              <td class="px-5 py-4 text-fg-muted">{{ branch.nama_direktur || '-' }}</td>

              <td class="px-5 py-4 text-fg-muted">{{ branch.no_telepon || '-' }}</td>

              <td class="px-5 py-4 text-fg-muted">{{ branch.email || '-' }}</td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-eye"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Lihat detail"
                    v-tooltip.top="'Lihat detail'"
                    @click="router.push(`/master/branch/${branch.id}`)"
                  />

                  <Button
                    icon="pi pi-pencil"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Edit cabang"
                    v-tooltip.top="'Edit cabang'"
                    @click="openEdit(branch)"
                  />

                  <Button
                    icon="pi pi-trash"
                    variant="text"
                    rounded
                    severity="danger"
                    aria-label="Hapus cabang"
                    v-tooltip.top="'Hapus cabang'"
                    @click="confirmDelete(branch)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ branches.length }} cabang
      </footer>
    </section>

    <BranchFormDialog v-model:visible="formVisible" :branch="selectedEdit" @saved="fetchBranches" />
  </div>
</template>