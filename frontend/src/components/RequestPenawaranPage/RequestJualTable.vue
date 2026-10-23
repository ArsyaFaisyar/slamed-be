<script setup lang="ts">
import { computed } from 'vue'
import InputNumber from 'primevue/inputnumber'
import Message from 'primevue/message'

import type { RequestItem } from '../../api/requestPenawaran.ts'
import { draftTotal, formatQty, formatRupiah, lineTotal, toNumber, type Draft } from '../../utils/price.ts'

const props = defineProps<{
  items: RequestItem[]
  modelValue: Draft
}>()

const emit = defineEmits<{
  'update:modelValue': [value: Draft]
  edited: []
}>()

const total = computed(() => draftTotal(props.items, props.modelValue))

function belowModal(item: RequestItem) {
  const jual = props.modelValue[item.id]
  const modal = toNumber(item.harga_modal)
  return jual !== null && jual !== undefined && modal !== null && jual < modal
}
const hasWarning = computed(() => props.items.some(belowModal))

function setPrice(id: number, value: number | null) {
  if ((props.modelValue[id] ?? null) === value) return
  emit('update:modelValue', { ...props.modelValue, [id]: value })
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
            <th class="px-3 py-3 text-right font-medium">Jml</th>
            <th class="px-3 py-3 font-medium">Satuan</th>
            <th class="px-3 py-3 text-right font-medium">Harga modal</th>
            <th class="w-52 px-3 py-3 font-medium">Harga jual</th>
            <th class="px-3 py-3 text-right font-medium">Subtotal</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-line">
          <tr v-for="(item, index) in items" :key="item.id" class="align-top">
            <td class="px-3 py-3 tabular-nums text-fg-muted">{{ index + 1 }}</td>
            <td class="min-w-[180px] px-3 py-3 font-medium">{{ item.nama_barang }}</td>
            <td class="px-3 py-3 text-right tabular-nums">{{ formatQty(item.jumlah) }}</td>
            <td class="px-3 py-3">{{ item.satuan }}</td>
            <td class="whitespace-nowrap px-3 py-3 text-right tabular-nums">{{ formatRupiah(item.harga_modal) }}</td>
            <td class="px-3 py-2">
              <InputNumber
                :model-value="modelValue[item.id] ?? null"
                :input-id="`jual-${item.id}`"
                mode="currency"
                currency="IDR"
                locale="id-ID"
                :min-fraction-digits="0"
                :min="0"
                :max="10000000000"
                placeholder="Harga jual"
                size="small"
                fluid
                :invalid="belowModal(item)"
                @input="setPrice(item.id, $event.value == null ? null : Number($event.value))"
                @update:model-value="setPrice(item.id, $event)"
              />
              <p v-if="belowModal(item)" class="mt-1 text-xs text-red-500">Di bawah harga modal</p>
            </td>
            <td class="whitespace-nowrap px-3 py-3 text-right tabular-nums">
              {{ formatRupiah(lineTotal(item, modelValue[item.id])) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="flex items-center justify-end gap-4 border-t border-line pt-4 text-sm">
      <span class="font-semibold">Total harga jual</span>
      <span class="tabular-nums">{{ formatRupiah(total) }}</span>
    </div>

    <Message v-if="hasWarning" severity="warn" size="small">
      Ada barang dengan harga jual di bawah harga modal.
    </Message>
  </div>
</template>