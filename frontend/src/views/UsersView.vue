<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'

import UserFormDialog from '../components/UserPage/UserFormDialog.vue'
import ResetPasswordDialog from '../components/UserPage/ResetPasswordDialog.vue'
import EditUserDialog from '../components/UserPage/EditUserDialog.vue'

import { getUsers, type User } from '../api/users'
import { getBranches, type Branch } from '../api/branches'
import { getAreas, type Area } from '../api/areas'
import { getErrorMessage } from '../utils/error'

const editDialogVisible = ref(false)
const selectedEditUser = ref<User | null>(null)

const users = ref<User[]>([])
const branches = ref<Branch[]>([])
const areas = ref<Area[]>([])
const search = ref('')
const loading = ref(false)
const errorMessage = ref('')
const areaError = ref('')
const loadingAreas = ref(false)
const dialogVisible = ref(false)

const resetDialogVisible = ref(false)
const selectedUser = ref<User | null>(null)

const branchMap = computed(() => {
  return new Map(
    branches.value.map((branch) => [String(branch.id), branch.nama]),
  )
})

function getBranchName(branchId: number | string | null | undefined) {
  if (branchId == null) return '-'

  return branchMap.value.get(String(branchId)) ?? `Cabang tidak ditemukan (ID ${branchId})`
}

const areaMap = computed(() =>
  new Map(areas.value.map((area) => [String(area.id), area.nama])),
)

function getAreaName(areaId: number | string | null | undefined) {
  if (areaId == null) return '-'

  return areaMap.value.get(String(areaId)) ?? `Area tidak ditemukan (ID ${areaId})`
}

function openEditUser(user: User) {
  selectedEditUser.value = user
  editDialogVisible.value = true
}

function openResetPassword(user: User) {
  selectedUser.value = user
  resetDialogVisible.value = true
}

const filteredUsers = computed(() => {
  const keyword = search.value.trim().toLowerCase()

  if (!keyword) return users.value

  return users.value.filter((user) =>
    [
      user.nama,
      user.username,
      user.email,
      user.role,
      getBranchName(user.branch_id),
      getAreaName(user.area_id),
    ].some((value) =>
      String(value ?? '').toLowerCase().includes(keyword),
    ),
  )
})

async function fetchUsers() {
  loading.value = true
  errorMessage.value = ''

  try {
    users.value = await getUsers()
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      'Gagal memuat daftar pengguna',
    )
  } finally {
    loading.value = false
  }
}

async function fetchBranches() {
  try {
    branches.value = await getBranches()
  } catch {
    branches.value = []
  }
}

async function fetchAreas() {
  loadingAreas.value = true
  areaError.value = ''

  try {
    areas.value = await getAreas()
  } catch (error) {
    areas.value = []
    areaError.value = getErrorMessage(error, 'Gagal memuat daftar area')
  } finally {
    loadingAreas.value = false
  }
}

function formatRole(role: string) {
  return role.replaceAll('_', ' ')
}

onMounted(() => {
  fetchUsers()
  fetchBranches()
  fetchAreas()
})
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
          @click="fetchUsers"
        />
      </div>
    </Message>

    <Message v-if="areaError" severity="error" :closable="false">
      {{ areaError }}
    </Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar pengguna</h2>

          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredUsers.length }} pengguna ditampilkan
          </p>
        </div>

        <div class="flex items-center gap-2">
          <InputText
            v-model="search"
            placeholder="Cari pengguna..."
            aria-label="Cari pengguna"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Tambah pengguna"
            icon="pi pi-plus"
            size="small"
            class="whitespace-nowrap"
            @click="dialogVisible = true"
          />
        </div>
      </div>

      <div
        v-if="loading && users.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg"></i>
        Memuat daftar pengguna...
      </div>

      <div
        v-else-if="!errorMessage && filteredUsers.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-users text-3xl text-fg-muted"></i>

        <p class="font-medium">
          {{ search ? 'Pengguna tidak ditemukan' : 'Belum ada pengguna' }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            search
              ? 'Coba kata kunci lain.'
              : 'Data pengguna akan muncul di sini.'
          }}
        </p>
      </div>

      <div
        v-else-if="users.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[1050px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">Nama</th>
              <th class="px-5 py-3 font-medium">Username</th>
              <th class="px-5 py-3 font-medium">Email</th>
              <th class="px-5 py-3 font-medium">Role</th>
              <th class="px-5 py-3 font-medium">Cabang</th>
              <th class="px-5 py-3 font-medium">Area</th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th class="px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="user in filteredUsers"
              :key="user.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4">
                <span class="font-medium">{{ user.nama }}</span>
              </td>

              <td class="px-5 py-4 text-fg-muted">
                {{ user.username }}
              </td>

              <td class="px-5 py-4 text-fg-muted">
                {{ user.email }}
              </td>

              <td class="px-5 py-4">
                <span
                  class="inline-flex rounded-md border border-line px-2.5 py-1 text-xs font-medium"
                >
                  {{ formatRole(user.role) }}
                </span>
              </td>

              <td class="px-5 py-4 text-fg-muted">
                {{ getBranchName(user.branch_id) }}
              </td>

              <td class="px-5 py-4 text-fg-muted">
                {{ getAreaName(user.area_id) }}
              </td>

              <td class="px-5 py-4">
                <span
                  class="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="
                    user.is_active
                      ? 'bg-green-500/10 text-green-700 dark:text-green-400'
                      : 'bg-red-500/10 text-red-700 dark:text-red-400'
                  "
                >
                  <span
                    class="size-1.5 rounded-full"
                    :class="user.is_active ? 'bg-green-500' : 'bg-red-500'"
                  ></span>

                  {{ user.is_active ? 'Aktif' : 'Nonaktif' }}
                </span>
              </td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    icon="pi pi-pencil"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Edit pengguna"
                    v-tooltip.top="'Edit pengguna'"
                    @click="openEditUser(user)"
                  />

                  <Button
                    icon="pi pi-key"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Reset password"
                    v-tooltip.top="'Reset password'"
                    @click="openResetPassword(user)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ users.length }} pengguna
      </footer>
    </section>

    <UserFormDialog
      v-model:visible="dialogVisible"
      :areas="areas"
      :loading-areas="loadingAreas"
      :areas-error="areaError"
      @created="fetchUsers"
    />

    <ResetPasswordDialog
      v-if="selectedUser"
      v-model:visible="resetDialogVisible"
      :user-id="selectedUser.id"
      :user-name="selectedUser.nama"
    />

    <EditUserDialog
      v-if="selectedEditUser"
      v-model:visible="editDialogVisible"
      :user="selectedEditUser"
      :areas="areas"
      :loading-areas="loadingAreas"
      :areas-error="areaError"
      @updated="fetchUsers"
    />
  </div>
</template>
