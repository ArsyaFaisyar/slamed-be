<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { getProjectLogs, type ProjectLog } from '../../api/projectsLogs'
import { getUserOptions } from '../../api/users'
import { getErrorMessage } from '../../utils/error'

const props = defineProps<{ projectId: number }>()

const PAGE_SIZE = 10

type LogWithUser = ProjectLog & {
  user_nama?: string | null
  nama_user?: string | null
  user?: { nama?: string | null } | null
}

interface Change {
  label: string
  from: string
  to: string
}

interface LogType {
  label: string
  icon: string
}

const logs = ref<ProjectLog[]>([])
const userNames = ref<Map<number, string>>(new Map())
const loading = ref(false)
const error = ref('')
const limit = ref(PAGE_SIZE)

const dateFormat = new Intl.DateTimeFormat('id-ID', {
  weekday: 'long',
  day: 'numeric',
  month: 'short',
  year: 'numeric',
})
const timeFormat = new Intl.DateTimeFormat('id-ID', { hour: '2-digit', minute: '2-digit' })

const sortedLogs = computed(() =>
  [...logs.value].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
)

const visibleLogs = computed(() => sortedLogs.value.slice(0, limit.value))
const remaining = computed(() => Math.max(sortedLogs.value.length - limit.value, 0))

function formatDate(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : dateFormat.format(date)
}

function formatTime(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '' : timeFormat.format(date)
}

function logAction(log: ProjectLog) {
  return log.aktivitas ?? log.aksi ?? null
}

function logType(log: ProjectLog): LogType {
  const text = (logAction(log) ?? '').toLowerCase()

  if (text.includes('hapus')) return { label: 'Dihapus', icon: 'pi pi-trash' }
  if (text.includes('dibuat')) return { label: 'Dibuat', icon: 'pi pi-plus' }
  if (text.includes('status')) return { label: 'Status', icon: 'pi pi-sync' }
  if (text.includes('diperbarui') || text.includes('berubah')) {
    return { label: 'Diperbarui', icon: 'pi pi-pencil' }
  }
  if (
    text.includes('laporan') ||
    text.includes('kunjungan') ||
    text.includes('lkh') ||
    text.includes('rkh')
  ) {
    return { label: 'Kunjungan', icon: 'pi pi-file-edit' }
  }

  return { label: 'Aktivitas', icon: 'pi pi-info-circle' }
}

function displayValue(value: string) {
  const trimmed = value.trim()
  return trimmed === '' || trimmed === 'None' || trimmed === 'null' ? 'kosong' : trimmed
}

function parseChanges(text: string | null | undefined): Change[] | null {
  if (!text || !text.includes('→')) return null

  const changes: Change[] = []

  for (const part of text.split('; ')) {
    const match = part.match(/^(.+?):\s(.*)\s→\s(.*)$/)
    if (!match) return null
    changes.push({ label: match[1], from: displayValue(match[2]), to: displayValue(match[3]) })
  }

  return changes
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

async function resolveUserNames() {
  const needsLookup = logs.value.some((log) => log.user_id != null && !directUserName(log))
  if (!needsLookup) return

  try {
    const users = await getUserOptions()
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

watch(
  () => props.projectId,
  () => {
    limit.value = PAGE_SIZE
    load()
  },
  { immediate: true },
)

defineExpose({ refresh: load })
</script>

<template>
  <section class="rounded-xl border border-line bg-card">
    <div class="flex flex-wrap items-center justify-between gap-3 border-b border-line px-5 py-4">
      <div>
        <h2 class="font-semibold">Log project</h2>
        <p class="mt-0.5 text-xs text-fg-muted">
          Riwayat aktivitas pada project ini, terbaru di atas.
        </p>
      </div>

      <div class="flex items-center gap-2">
        <span
          class="inline-flex rounded-full border border-line px-2.5 py-1 text-xs font-medium tabular-nums"
        >
          {{ logs.length }} log
        </span>
        <Button
          icon="pi pi-refresh"
          variant="text"
          rounded
          severity="secondary"
          size="small"
          aria-label="Muat ulang log"
          v-tooltip.top="'Muat ulang'"
          :loading="loading"
          @click="load"
        />
      </div>
    </div>

    <Message v-if="error" severity="error" :closable="false" class="m-5">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ error }}</span>
        <Button label="Coba lagi" size="small" severity="danger" variant="text" @click="load" />
      </div>
    </Message>

    <div
      v-else-if="loading && logs.length === 0"
      class="flex items-center justify-center gap-3 py-12 text-sm text-fg-muted"
    >
      <i class="pi pi-spin pi-spinner text-lg" />
      Memuat log project...
    </div>

    <div
      v-else-if="logs.length === 0"
      class="flex flex-col items-center justify-center gap-2 py-12 text-center"
    >
      <i class="pi pi-history text-3xl text-fg-muted" />
      <p class="font-medium">Belum ada log</p>
      <p class="text-sm text-fg-muted">Aktivitas project akan tercatat di sini.</p>
    </div>

    <div v-else class="transition-opacity" :class="loading && 'opacity-60'">
      <div class="overflow-x-auto">
        <table class="w-full min-w-[900px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="w-48 px-5 py-3 font-medium">Tanggal</th>
              <th class="w-48 px-5 py-3 font-medium">User</th>
              <th class="w-56 px-5 py-3 font-medium">Kegiatan</th>
              <th class="px-5 py-3 font-medium">Keterangan</th>
              <th class="w-36 px-5 py-3 font-medium">Jenis</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="log in visibleLogs"
              :key="log.id"
              class="align-top transition-colors hover:bg-sidebar/60"
            >
              <td class="px-5 py-4">
                <time :datetime="log.created_at" class="block">
                  <span class="block font-medium">{{ formatDate(log.created_at) }}</span>
                  <span class="block text-xs tabular-nums text-fg-muted">
                    {{ formatTime(log.created_at) }}
                  </span>
                </time>
              </td>

              <td class="px-5 py-4 font-medium">{{ logUser(log) }}</td>

              <td class="px-5 py-4 font-medium">{{ logAction(log) ?? 'Aktivitas' }}</td>

              <td class="px-5 py-4">
                <ul v-if="parseChanges(log.deskripsi)" class="flex flex-col gap-2">
                  <li
                    v-for="change in parseChanges(log.deskripsi)"
                    :key="change.label"
                    class="flex flex-wrap items-center gap-x-2 gap-y-1"
                  >
                    <span class="text-fg-muted">{{ change.label }}:</span>
                    <span
                      class="rounded-md border border-line px-1.5 py-0.5 text-xs text-fg-muted line-through"
                    >
                      {{ change.from }}
                    </span>
                    <i class="pi pi-arrow-right text-[0.65rem] text-fg-muted" />
                    <span class="rounded-md border border-line px-1.5 py-0.5 text-xs font-medium">
                      {{ change.to }}
                    </span>
                  </li>
                </ul>
                <p v-else-if="log.deskripsi" class="leading-relaxed">{{ log.deskripsi }}</p>
                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-5 py-4">
                <span
                  class="inline-flex items-center gap-1.5 rounded-full border border-line px-2.5 py-1 text-xs font-medium"
                >
                  <i :class="logType(log).icon" class="text-[0.7rem] text-fg-muted" />
                  {{ logType(log).label }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer
        class="flex flex-wrap items-center justify-between gap-3 border-t border-line px-5 py-3 text-xs text-fg-muted"
      >
        <span>Menampilkan {{ visibleLogs.length }} dari {{ logs.length }} log</span>

        <Button
          v-if="remaining > 0"
          :label="`Tampilkan ${Math.min(remaining, PAGE_SIZE)} log lainnya`"
          icon="pi pi-chevron-down"
          size="small"
          variant="outlined"
          severity="secondary"
          @click="limit += PAGE_SIZE"
        />
      </footer>
    </div>
  </section>
</template>