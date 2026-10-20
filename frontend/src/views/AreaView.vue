<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
import ConfirmDialog from 'primevue/confirmdialog'
import { useConfirm } from 'primevue/useconfirm'

import AreaFormDialog, {
  type SpvOption,
} from '../components/AreaPage/AreaFormDialog.vue'
import EditAreaDialog from '../components/AreaPage/EditAreaDialog.vue'

import { deleteArea, getAreas, type Area } from '../api/areas'
import { getUsers, type User } from '../api/users'
import { getErrorMessage } from '../utils/error'

const SPV_ROLE = 'SPV'

const confirm = useConfirm()

const areas = ref<Area[]>([])
const users = ref<User[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')

const createDialogVisible = ref(false)

const editDialogVisible = ref(false)
const selectedEditArea = ref<Area | null>(null)

const spvOptions = computed<SpvOption[]>(() =>
  users.value
    .filter(
      (user) =>
        user.role?.toUpperCase() === SPV_ROLE &&
        Number(user.is_active) === 1,
    )
    .map((user) => ({
      label: user.nama,
      value: user.id,
    })),
)

const userNameById = computed(
  () => new Map(users.value.map((user) => [user.id, user.nama])),
)

function spvName(spvId: number) {
  return userNameById.value.get(spvId) ?? `ID ${spvId}`
}

function formatTarget(value: number) {
  return new Intl.NumberFormat('id-ID').format(value)
}

const filteredAreas = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return areas.value

  return areas.value.filter((area) =>
    [area.nama, spvName(area.spv_id)].some((value) =>
      (value ?? '').toLowerCase().includes(keyword),
    ),
  )
})

function openEdit(area: Area) {
  selectedEditArea.value = area
  editDialogVisible.value = true
}

function confirmDelete(area: Area) {
  confirm.require({
    header: 'Hapus area',
    message: `Yakin ingin menghapus area "${area.nama}"? Tindakan ini tidak dapat dibatalkan.`,
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
      errorMessage.value = ''
      try {
        await deleteArea(area.id)
        await fetchAreas()
      } catch (error) {
        errorMessage.value = getErrorMessage(error, 'Gagal menghapus area')
      }
    },
  })
}

async function fetchAreas() {
  loading.value = true
  errorMessage.value = ''

  try {
    const [areaList, userList] = await Promise.all([getAreas(), getUsers()])
    areas.value = areaList
    users.value = userList
  } catch (error) {
    errorMessage.value = getErrorMessage(error, 'Gagal memuat daftar area')
  } finally {
    loading.value = false
  }
}

onMounted(fetchAreas)
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
          @click="fetchAreas"
        />
      </div>
    </Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar area</h2>
          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredAreas.length }} area ditampilkan
          </p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari area..."
            aria-label="Cari area"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah area"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="createDialogVisible = true"
          />
        </div>
      </div>

      <div
        v-if="loading && areas.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar area...
      </div>

      <div
        v-else-if="!errorMessage && filteredAreas.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-map text-3xl text-fg-muted" />

        <p class="font-medium">
          {{ search ? 'Area tidak ditemukan' : 'Belum ada area' }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            search
              ? 'Coba kata kunci lain.'
              : 'Data area akan muncul di sini.'
          }}
        </p>
      </div>

      <div
        v-else-if="areas.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[640px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="w-20 px-5 py-3 font-medium">No</th>
              <th class="px-5 py-3 font-medium">Nama</th>
              <th class="px-5 py-3 font-medium">SPV</th>
              <th class="px-5 py-3 text-right font-medium">Target</th>
              <th class="w-32 px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="(area, index) in filteredAreas"
              :key="area.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4 text-fg-muted">
                {{ index + 1 }}
              </td>

              <td class="px-5 py-4">
                <span class="font-medium">{{ area.nama }}</span>
              </td>

              <td class="px-5 py-4 text-fg-muted">
                {{ spvName(area.spv_id) }}
              </td>

              <td class="px-5 py-4 text-right tabular-nums">
                {{ formatTarget(area.target) }}
              </td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-pencil"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Edit area"
                    v-tooltip.top="'Edit area'"
                    @click="openEdit(area)"
                  />

                  <Button
                    icon="pi pi-trash"
                    variant="text"
                    rounded
                    severity="danger"
                    aria-label="Hapus area"
                    v-tooltip.top="'Hapus area'"
                    @click="confirmDelete(area)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ areas.length }} area
      </footer>
    </section>

    <AreaFormDialog
      v-model:visible="createDialogVisible"
      :spv-options="spvOptions"
      @created="fetchAreas"
    />

    <EditAreaDialog
      v-if="selectedEditArea"
      v-model:visible="editDialogVisible"
      :area="selectedEditArea"
      :spv-options="spvOptions"
      @updated="fetchAreas"
    />

    <ConfirmDialog />
  </div>
</template>