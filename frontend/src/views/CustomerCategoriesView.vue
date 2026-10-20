<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import { useConfirm } from 'primevue/useconfirm'

import CategoryFormDialog from '../components/CustomerCategoryPage/CategoryFormDialog.vue'

import {
  deleteCustomerCategory,
  getCustomerCategories,
  type CustomerCategory,
} from '../api/customerCategories'
import { getErrorMessage } from '../utils/error'

const confirm = useConfirm()

const categories = ref<CustomerCategory[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const actionError = ref('')

const formVisible = ref(false)
const selectedEdit = ref<CustomerCategory | null>(null)

const filteredCategories = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return categories.value

  return categories.value.filter((category) => category.nama.toLowerCase().includes(keyword))
})

function openCreate() {
  selectedEdit.value = null
  formVisible.value = true
}

function openEdit(category: CustomerCategory) {
  selectedEdit.value = category
  formVisible.value = true
}

async function fetchCategories() {
  loading.value = true
  errorMessage.value = ''

  try {
    categories.value = await getCustomerCategories()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar kategori')
  } finally {
    loading.value = false
  }
}

function confirmDelete(category: CustomerCategory) {
  confirm.require({
    header: 'Hapus Kategori',
    message: `Apakah Anda yakin ingin menghapus kategori ${category.nama}? Tindakan ini tidak dapat dibatalkan.`,
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
        await deleteCustomerCategory(category.id)
        await fetchCategories()
      } catch (error) {
        actionError.value = getErrorMessage(error, 'Gagal menghapus kategori')
      }
    },
  })
}

onMounted(fetchCategories)
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
          @click="fetchCategories"
        />
      </div>
    </Message>

    <Message v-if="actionError" severity="error" @close="actionError = ''">{{ actionError }}</Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar kategori customer</h2>
          <p class="mt-1 text-sm text-fg-muted">{{ filteredCategories.length }} kategori ditampilkan</p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari kategori..."
            aria-label="Cari kategori"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah kategori"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="openCreate"
          />
        </div>
      </div>

      <div
        v-if="loading && categories.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar kategori...
      </div>

      <div
        v-else-if="!errorMessage && filteredCategories.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-tags text-3xl text-fg-muted" />

        <p class="font-medium">{{ search ? 'Kategori tidak ditemukan' : 'Belum ada kategori' }}</p>

        <p class="text-sm text-fg-muted">
          {{ search ? 'Coba kata kunci lain.' : 'Data kategori akan muncul di sini.' }}
        </p>
      </div>

      <div
        v-else-if="categories.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[480px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Nama kategori</th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="category in filteredCategories"
              :key="category.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4 font-medium">{{ category.nama }}</td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-pencil"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Edit kategori"
                    v-tooltip.top="'Edit kategori'"
                    @click="openEdit(category)"
                  />

                  <Button
                    icon="pi pi-trash"
                    variant="text"
                    rounded
                    severity="danger"
                    aria-label="Hapus kategori"
                    v-tooltip.top="'Hapus kategori'"
                    @click="confirmDelete(category)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ categories.length }} kategori
      </footer>
    </section>

    <CategoryFormDialog v-model:visible="formVisible" :category="selectedEdit" @saved="fetchCategories" />
  </div>
</template>