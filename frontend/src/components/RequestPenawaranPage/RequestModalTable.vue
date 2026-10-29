<script setup lang="ts">
import { computed } from 'vue'
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'
import Select from 'primevue/select'

import { JENIS_PAJAK_OPTIONS, resolveGambarUrl, type RequestItem } from '../../api/requestPenawaran.ts'
import { draftTotal, formatQty, formatRupiah, lineTotal, type Draft } from '../../utils/price.ts'

type PajakDraft = Record<number, string | null>

const props = defineProps<{
  items: RequestItem[]
  modelValue: Draft
  pajak: PajakDraft
  disabled?: boolean
  tried?: boolean
  canManage?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: Draft]
  'update:pajak': [value: PajakDraft]
  edited: []
  edit: [item: RequestItem]
  delete: [item: RequestItem]
  add: []
}>()

const total = computed(() => draftTotal(props.items, props.modelValue))

function setPrice(id: number, value: number | string | null | undefined) {
  const price = value == null || value === '' ? null : Number(value)
  if (price !== null && Number.isNaN(price)) return
  if ((props.modelValue[id] ?? null) === price) return
  emit('update:modelValue', { ...props.modelValue, [id]: price })
  emit('edited')
}

function setPajak(id: number, value: string | null) {
  if ((props.pajak[id] ?? null) === value) return
  emit('update:pajak', { ...props.pajak, [id]: value })
  emit('edited')
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="overflow-x-auto">
      <table class="w-full min-w-[1250px] text-left text-sm">
        <thead class="border-b border-line text-xs text-fg-muted">
          <tr>
            <th class="w-12 px-3 py-3 font-medium">No</th>
            <th class="w-20 px-3 py-3 font-medium">Gambar</th>
            <th class="px-3 py-3 font-medium">Nama barang</th>
            <th class="px-3 py-3 font-medium">Merk</th>
            <th class="px-3 py-3 font-medium">Spesifikasi</th>
            <th class="px-3 py-3 text-right font-medium">Jml</th>
            <th class="px-3 py-3 font-medium">Satuan</th>
            <th class="w-44 px-3 py-3 font-medium">Jenis pajak</th>
            <th class="w-52 px-3 py-3 font-medium">Harga modal</th>
            <th class="px-3 py-3 text-right font-medium">Subtotal</th>
            <th v-if="canManage" class="w-28 px-3 py-3 text-center font-medium">Aksi</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-line">
          <tr v-for="(item, index) in items" :key="item.id" class="align-top">
            <td class="px-3 py-3 tabular-nums text-fg-muted">{{ index + 1 }}</td>
            <td class="px-3 py-2">
              <a
                v-if="item.gambar_path"
                :href="resolveGambarUrl(item.gambar_path)"
                target="_blank"
                rel="noopener"
                class="block h-14 w-14 overflow-hidden rounded-lg border border-line bg-sidebar/50"
                :title="`Lihat gambar ${item.nama_barang}`"
              >
                <img
                  :src="resolveGambarUrl(item.gambar_path)"
                  :alt="item.nama_barang"
                  loading="lazy"
                  class="h-full w-full object-contain"
                />
              </a>
              <div
                v-else
                class="flex h-14 w-14 items-center justify-center rounded-lg border border-dashed border-line text-fg-muted"
                title="Belum ada gambar"
              >
                <i class="pi pi-image" />
              </div>
            </td>
            <td class="min-w-[180px] px-3 py-3 font-medium">
              {{ item.nama_barang }}
              <span
                v-if="item.is_tambahan"
                class="ml-2 rounded-md border border-line px-1.5 py-0.5 text-[0.65rem] font-medium text-fg-muted"
              >Tambahan</span>
            </td>
            <td class="px-3 py-3">{{ item.merk || '-' }}</td>
            <td class="min-w-[200px] max-w-[280px] px-3 py-3 text-fg-muted">
              <p v-if="item.spesifikasi" class="line-clamp-2" :title="item.spesifikasi">{{ item.spesifikasi }}</p>
              <span v-else>-</span>
            </td>
            <td class="px-3 py-3 text-right tabular-nums">{{ formatQty(item.jumlah) }}</td>
            <td class="px-3 py-3">{{ item.satuan }}</td>
            <td class="px-3 py-2">
              <Select
                :model-value="pajak[item.id] ?? null"
                :input-id="`pajak-${item.id}`"
                :options="JENIS_PAJAK_OPTIONS"
                option-label="label"
                option-value="value"
                placeholder="Pilih pajak"
                size="small"
                fluid
                :disabled="disabled"
                :invalid="!!tried && !pajak[item.id]"
                @update:model-value="setPajak(item.id, $event)"
              />
            </td>
            <td class="px-3 py-2">
              <InputNumber
                :model-value="modelValue[item.id] ?? null"
                :input-id="`modal-${item.id}`"
                mode="currency"
                currency="IDR"
                locale="id-ID"
                :min-fraction-digits="0"
                :min="0"
                :max="10000000000"
                placeholder="Harga modal"
                size="small"
                fluid
                :disabled="disabled"
                @input="setPrice(item.id, $event.value)"
                @update:model-value="setPrice(item.id, $event)"
              />
            </td>
            <td class="whitespace-nowrap px-3 py-3 text-right tabular-nums">
              {{ formatRupiah(lineTotal(item, modelValue[item.id])) }}
            </td>
            <td v-if="canManage" class="whitespace-nowrap px-3 py-2 text-center">
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
                v-if="item.is_tambahan"
                type="button"
                icon="pi pi-trash"
                variant="text"
                rounded
                size="small"
                severity="danger"
                :aria-label="`Hapus ${item.nama_barang}`"
                title="Hapus barang tambahan"
                @click="emit('delete', item)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="flex items-center justify-end gap-4 border-t border-line pt-4 text-sm">
      <span class="font-semibold">Total harga modal</span>
      <span class="tabular-nums">{{ formatRupiah(total) }}</span>
    </div>
  </div>
</template>