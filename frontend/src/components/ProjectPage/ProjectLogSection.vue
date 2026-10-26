<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { getProjectLogs, type ProjectLog } from '../../api/projectsLogs'
import { getUsers } from '../../api/users'
import { getErrorMessage } from '../../utils/error'

const props = defineProps<{ projectId: number }>()

// Nama user bisa datang dengan beberapa bentuk tergantung schema backend.
type LogWithUser = ProjectLog & {
  user_nama?: string | null
  nama_user?: string | null
  user?: { nama?: string | null } | null
}

const logs = ref<ProjectLog[]>([])
const userNames = ref<Map<number, string>>(new Map())
const loading = ref(false)
const error = ref('')

const dateTimeFormat = new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' })

const sortedLogs = computed(() =>
  [...logs.value].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
)

function formatDateTime(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : dateTimeFormat.format(date)
}

function logAction(log: ProjectLog) {
  return log.aktivitas ?? log.aksi ?? null
}

function directUserName(log: ProjectLog): string | null {
  const item = log as LogWithUser
  return item.user_rel?.nama ?? item.user_nama ?? item.nama_user ?? item.user?.nama ?? null
}

function logUser(log: ProjectLog) {
  const name = directUserName(log)
  if (name) return name
  if (log.user_id == null) return 'Sistem'
  return userNames.value.get(log.user_id) ?? `User #${log.user_id}`
}

// Cadangan: kalau respons log tidak membawa nama user, cari dari daftar user (jika role boleh mengaksesnya).
async function resolveUserNames() {
  const needsLookup = logs.value.some((log) => log.user_id != null && !directUserName(log))
  if (!needsLookup) return

  try {
    const users = await getUsers()
    userNames.value = new Map(users.map((user) => [user.id, user.nama]))
  } catch {
    userNames.value = new Map()
  }
}

async function load() {
  loading.value = true
  error.value = ''

  try {
    logs.value = await getProjectLogs(props.projectId)
    await resolveUserNames()
  } catch (err) {
    error.value = getErrorMessage(err, 'Gagal memuat log project')
  } finally {
    loading.value = false
  }
}

watch(() => props.projectId, load, { immediate: true })

defineExpose({ refresh: load })
</script>

<template>
  <section class="rounded-xl border border-line bg-card">
    <div class="flex items-baseline justify-between gap-3 border-b border-line p-5">
      <div>
        <h2 class="font-semibold">Log project</h2>
        <p class="mt-1 text-xs text-fg-muted">Riwayat aktivitas pada project ini, terbaru di atas.</p>
      </div>
      <span class="text-sm text-fg-muted">{{ logs.length }} log</span>
    </div>

    <div class="p-5">
      <Message v-if="error" severity="error" :closable="false">
        <div class="flex flex-wrap items-center gap-3">
          <span>{{ error }}</span>
          <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
        </div>
      </Message>

      <div v-else-if="loading && logs.length === 0" class="flex items-center justify-center gap-3 py-10 text-sm text-fg-muted">
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat log project...
      </div>

      <div v-else-if="logs.length === 0" class="flex flex-col items-center justify-center gap-2 py-10 text-center">
        <i class="pi pi-history text-3xl text-fg-muted" />
        <p class="font-medium">Belum ada log</p>
        <p class="text-sm text-fg-muted">Aktivitas project akan tercatat di sini.</p>
      </div>

      <ol
        v-else
        class="relative flex flex-col gap-5 border-l border-line pl-6 transition-opacity"
        :class="loading && 'opacity-60'"
      >
        <li v-for="log in sortedLogs" :key="log.id" class="relative">
          <span class="absolute -left-[31px] top-1.5 size-2.5 rounded-full border border-line bg-fg-muted" />

          <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
            <span
              v-if="logAction(log)"
              class="inline-flex rounded-md bg-sidebar px-2 py-0.5 text-xs font-medium uppercase tracking-wide"
            >
              {{ logAction(log) }}
            </span>
            <span class="text-xs text-fg-muted">{{ formatDateTime(log.created_at) }}</span>
          </div>

          <p v-if="log.deskripsi" class="mt-1 text-sm">{{ log.deskripsi }}</p>
          <p class="mt-0.5 text-xs text-fg-muted">oleh {{ logUser(log) }}</p>
        </li>
      </ol>
    </div>
  </section>
</template>