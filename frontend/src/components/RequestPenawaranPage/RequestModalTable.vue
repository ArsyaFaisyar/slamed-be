<script setup lang="ts">
import { computed } from 'vue'
import InputNumber from 'primevue/inputnumber'

import type { RequestItem } from '../../api/requestPenawaran.ts'
import { draftTotal, formatQty, formatRupiah, lineTotal, type Draft } from '../../utils/price.ts'

const props = defineProps<{
  items: RequestItem[]
  modelValue: Draft
  disabled?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: Draft]
  edited: []
}>()

const total = computed(() => draftTotal(props.items, props.modelValue))

function setPrice(id: number, value: number | string | null | undefined) {
  const price = value == null || value === '' ? null : Number(value)
  if (price !== null && Number.isNaN(price)) return
  if ((props.modelValue[id] ?? null) === price) return
  emit('update:modelValue', { ...props.modelValue, [id]: price })
  emit('edited')
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="overflow-x-auto">
      <table class="w-full min-w-[760px] text-left text-sm">
        <thead class="border-b border-line text-xs text-fg-muted">
          <tr>
            <th class="w-12 px-3 py-3 font-medium">No</th>
            <th class="px-3 py-3 font-medium">Nama barang</th>
            <th class="px-3 py-3 font-medium">Merk</th>
            <th class="px-3 py-3 text-right font-medium">Jml</th>
            <th class="px-3 py-3 font-medium">Satuan</th>
            <th class="w-52 px-3 py-3 font-medium">Harga modal</th>
            <th class="px-3 py-3 text-right font-medium">Subtotal</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-line">
          <tr v-for="(item, index) in items" :key="item.id" class="align-top">
            <td class="px-3 py-3 tabular-nums text-fg-muted">{{ index + 1 }}</td>
            <td class="min-w-[180px] px-3 py-3 font-medium">{{ item.nama_barang }}</td>
            <td class="px-3 py-3">{{ item.merk || '-' }}</td>
            <td class="px-3 py-3 text-right tabular-nums">{{ formatQty(item.jumlah) }}</td>
            <td class="px-3 py-3">{{ item.satuan }}</td>
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