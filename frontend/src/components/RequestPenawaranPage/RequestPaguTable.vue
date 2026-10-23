<script setup lang="ts">
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'

import type { RequestItem } from '../../api/requestPenawaran.ts'
import { formatQty, formatRupiah, lineTotal, type Draft } from '../../utils/price.ts'

const props = defineProps<{
  items: RequestItem[]
  modelValue: Draft
  /** false saat mode pagu total (kolom harga & subtotal disembunyikan) */
  showPrice: boolean
  loading?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: Draft]
  edited: []
  /** klik tombol edit data barang (bukan edit harga) */
  edit: [item: RequestItem]
  /** klik tombol hapus barang */
  delete: [item: RequestItem]
}>()

// Dipanggil dari @input (tiap ketikan) DAN @update:model-value (blur/clear),
// supaya subtotal & tombol simpan langsung ikut berubah saat mengetik.
function setPrice(id: number, value: number | null) {
  if ((props.modelValue[id] ?? null) === value) return
  emit('update:modelValue', { ...props.modelValue, [id]: value })
  emit('edited')
}
</script>

<template>
  <div class="overflow-x-auto transition-opacity" :class="loading && 'pointer-events-none opacity-60'">
    <table class="w-full min-w-[980px] text-left text-sm">
      <thead class="border-b border-line text-xs text-fg-muted">
        <tr>
          <th class="w-12 px-3 py-3 font-medium">No</th>
          <th class="px-3 py-3 font-medium">Nama barang</th>
          <th class="px-3 py-3 font-medium">Merk</th>
          <th class="px-3 py-3 font-medium">TKDN</th>
          <th class="px-3 py-3 font-medium">TKDN %</th>
          <th class="px-3 py-3 font-medium">Spesifikasi</th>
          <th class="px-3 py-3 text-right font-medium">Jml</th>
          <th class="px-3 py-3 font-medium">Satuan</th>
          <template v-if="showPrice">
            <th class="w-48 px-3 py-3 font-medium">Harga pagu</th>
            <th class="px-3 py-3 text-right font-medium">Subtotal</th>
          </template>
          <th class="w-28 px-3 py-3 text-center font-medium">Aksi</th>
        </tr>
      </thead>

      <tbody class="divide-y divide-line">
        <tr v-for="(item, index) in items" :key="item.id" class="align-top">
          <td class="px-3 py-3 tabular-nums text-fg-muted">{{ index + 1 }}</td>
          <td class="min-w-[180px] px-3 py-3 font-medium">{{ item.nama_barang }}</td>
          <td class="px-3 py-3">{{ item.merk || '-' }}</td>
          <td class="px-3 py-3">{{ item.tkdn || '-' }}</td>
          <td class="px-3 py-3 tabular-nums">{{ item.tkdn_persen != null ? formatQty(item.tkdn_persen) : '-' }}</td>
          <td class="min-w-[200px] max-w-[280px] px-3 py-3 text-fg-muted">
            <p v-if="item.spesifikasi" class="line-clamp-2" :title="item.spesifikasi">{{ item.spesifikasi }}</p>
            <span v-else>-</span>
          </td>
          <td class="px-3 py-3 text-right tabular-nums">{{ formatQty(item.jumlah) }}</td>
          <td class="px-3 py-3">{{ item.satuan }}</td>
          <template v-if="showPrice">
            <td class="px-3 py-2">
              <InputNumber
                :model-value="modelValue[item.id] ?? null"
                :input-id="`pagu-${item.id}`"
                mode="currency"
                currency="IDR"
                locale="id-ID"
                :min-fraction-digits="0"
                :min="0"
                placeholder="Harga pagu"
                size="small"
                fluid
                @input="setPrice(item.id, $event.value == null || $event.value === '' ? null : Number($event.value))"
                @update:model-value="setPrice(item.id, $event)"
              />
            </td>
            <td class="whitespace-nowrap px-3 py-3 text-right tabular-nums">
              {{ formatRupiah(lineTotal(item, modelValue[item.id])) }}
            </td>
          </template>
          <td class="whitespace-nowrap px-3 py-2 text-center">
            <Button
              type="button"
              icon="pi pi-pencil"
              variant="text"
              rounded
              size="small"
              severity="secondary"
              :aria-label="`Edit ${item.nama_barang}`"
              title="Edit barang"
              @click="emit('edit', item)"
            />
            <Button
              type="button"
              icon="pi pi-trash"
              variant="text"
              rounded
              size="small"
              severity="danger"
              :aria-label="`Hapus ${item.nama_barang}`"
              title="Hapus barang"
              @click="emit('delete', item)"
            />
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>