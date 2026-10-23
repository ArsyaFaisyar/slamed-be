<script setup lang="ts">
import type { RequestPenawaran } from '../../api/requestPenawaran.ts'
import { formatDate } from '../../utils/date.ts'

defineProps<{
  request: RequestPenawaran
  itemCount: number
}>()
</script>

<template>
  <section class="rounded-xl border border-line bg-card p-5">
    <dl class="grid grid-cols-2 gap-x-6 gap-y-4 text-sm sm:grid-cols-3 xl:grid-cols-5">
      <div>
        <dt class="text-xs text-fg-muted">Request masuk</dt>
        <dd class="mt-1 font-semibold">{{ formatDate(request.tanggal_request) }}</dd>
      </div>
      <div>
        <dt class="text-xs text-fg-muted">Diminta oleh</dt>
        <dd class="mt-1 truncate font-semibold" :title="request.diminta_oleh">{{ request.diminta_oleh }}</dd>
      </div>
      <div>
        <dt class="text-xs text-fg-muted">Status</dt>
        <dd class="mt-1">
          <span class="inline-flex rounded-full bg-sidebar px-2.5 py-1 text-xs font-medium">
            {{ request.status_request }}
          </span>
        </dd>
      </div>
      <div>
        <dt class="text-xs text-fg-muted">Durasi</dt>
        <dd class="mt-1 font-semibold">{{ request.durasi }}</dd>
      </div>
      <div>
        <dt class="text-xs text-fg-muted">Jumlah barang</dt>
        <dd class="mt-1 font-semibold">{{ itemCount }} barang</dd>
      </div>
    </dl>
  </section>
</template>