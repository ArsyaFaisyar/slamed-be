<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Button from 'primevue/button'
import Message from 'primevue/message'

import { getProjectLogs, type ProjectLog } from '../../api/projectsLogs'
import { getUsers } from '../../api/users'
import { getErrorMessage } from '../../utils/error'

const props = defineProps<{ projectId: number }>()

const PAGE_SIZE = 10

// Nama user bisa datang dengan beberapa bentuk tergantung schema backend.
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

const logs = ref<ProjectLog[]>([])
const userNames = ref<Map<number, string>>(new Map())
const loading = ref(false)
const error = ref('')
const limit = ref(PAGE_SIZE)

const dayFormat = new Intl.DateTimeFormat('id-ID', {
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

// Contoh: "Senin, 26 Okt 2026 · 09.56"
function formatTimestamp(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return `${dayFormat.format(date)} · ${timeFormat.format(date)}`
}

function logAction(log: ProjectLog) {
  return log.aktivitas ?? log.aksi ?? null
}

// Ikon mengikuti jenis aktivitas (tanpa warna dan tanpa latar).
function logIcon(log: ProjectLog) {
  const text = (logAction(log) ?? '').toLowerCase()

  if (text.includes('hapus')) return 'pi pi-trash'
  if (text.includes('laporan') || text.includes('kunjungan') || text.includes('lkh') || text.includes('rkh')) {
    return 'pi pi-file-edit'
  }
  if (text.includes('status')) return 'pi pi-sync'
  if (text.includes('dibuat')) return 'pi pi-plus'
  if (text.includes('diperbarui') || text.includes('berubah')) return 'pi pi-pencil'

  return 'pi pi-info-circle'
}

function displayValue(value: string) {
  const trimmed = value.trim()
  return trimmed === '' || trimmed === 'None' || trimmed === 'null' ? 'kosong' : trimmed
}

// Deskripsi berformat "Label: lama → baru; Label: lama → baru" ditampilkan sebagai daftar perubahan.
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
        <p class="mt-0.5 text-xs text-fg-muted">Riwayat aktivitas pada project ini, terbaru di atas.</p>
      </div>

      <div class="flex items-center gap-2">
        <span class="inline-flex rounded-full border border-line px-2.5 py-1 text-xs font-medium tabular-nums">
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

      <div v-else class="flex flex-col gap-6 transition-opacity" :class="loading && 'opacity-60'">
        <ol class="flex flex-col">
          <li v-for="(log, index) in visibleLogs" :key="log.id" class="flex gap-4">
            <!-- Ikon polos dan garis penghubung -->
            <div class="flex w-5 shrink-0 flex-col items-center">
              <i :class="logIcon(log)" class="mt-0.5 text-base text-fg-muted" />
              <span v-if="index < visibleLogs.length - 1" class="mt-2 w-px flex-1 bg-line" />
            </div>

            <!-- Isi log -->
            <div class="min-w-0 flex-1" :class="index < visibleLogs.length - 1 ? 'pb-6' : ''">
              <div class="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-0.5">
                <p class="text-sm font-semibold">{{ logAction(log) ?? 'Aktivitas' }}</p>
                <time class="text-xs tabular-nums text-fg-muted" :datetime="log.created_at">
                  {{ formatTimestamp(log.created_at) }}
                </time>
              </div>

              <ul v-if="parseChanges(log.deskripsi)" class="mt-2 flex flex-col gap-1.5">
                <li
                  v-for="change in parseChanges(log.deskripsi)"
                  :key="change.label"
                  class="flex flex-wrap items-center gap-x-2 gap-y-1 text-sm"
                >
                  <span class="text-fg-muted">{{ change.label }}</span>
                  <span class="rounded-md border border-line px-1.5 py-0.5 text-xs text-fg-muted line-through">
                    {{ change.from }}
                  </span>
                  <i class="pi pi-arrow-right text-[0.65rem] text-fg-muted" />
                  <span class="rounded-md border border-line px-1.5 py-0.5 text-xs font-medium">
                    {{ change.to }}
                  </span>
                </li>
              </ul>
              <p v-else-if="log.deskripsi" class="mt-1 text-sm leading-relaxed">{{ log.deskripsi }}</p>

              <p class="mt-1.5 text-xs text-fg-muted">oleh {{ logUser(log) }}</p>
            </div>
          </li>
        </ol>

        <div v-if="remaining > 0" class="flex justify-center">
          <Button
            :label="`Tampilkan ${Math.min(remaining, PAGE_SIZE)} log lainnya (${remaining} tersisa)`"
            icon="pi pi-chevron-down"
            size="small"
            variant="outlined"
            severity="secondary"
            @click="limit += PAGE_SIZE"
          />
        </div>
      </div>
    </div>
  </section>
</template>