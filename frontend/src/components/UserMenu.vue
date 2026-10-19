<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import Popover from 'primevue/popover'
import { getInitials } from '../utils/format'

const props = defineProps<{ name: string; role: string; image?: string }>()
const emit = defineEmits<{ profile: []; logout: [] }>()

const popover = ref<InstanceType<typeof Popover>>()
const open = ref(false)
const imageFailed = ref(false)

const reveal =
  'group-hover:ml-2 group-hover:mr-3 group-hover:max-w-48 group-hover:opacity-100 ' +
  'group-focus-visible:ml-2 group-focus-visible:mr-3 group-focus-visible:max-w-48 group-focus-visible:opacity-100 ' +
  'group-data-[open=true]:ml-2 group-data-[open=true]:mr-3 group-data-[open=true]:max-w-48 group-data-[open=true]:opacity-100'

const initials = computed(() => getInitials(props.name))
const showImage = computed(() => !!props.image && !imageFailed.value)

watch(
  () => props.image,
  () => {
    imageFailed.value = false
  },
)

function toggle(event: Event) {
  popover.value?.toggle(event)
}

function goProfile() {
  popover.value?.hide()
  emit('profile')
}

function logout() {
  popover.value?.hide()
  emit('logout')
}
</script>

<template>
  <button
    type="button"
    class="group flex items-center rounded-full border border-line bg-card p-1 transition-colors hover:bg-line/40 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
    :data-open="open"
    aria-haspopup="true"
    :aria-expanded="open"
    :aria-label="`Menu pengguna ${name}`"
    @click="toggle"
  >
    <Avatar
      :image="showImage ? image : undefined"
      :label="showImage ? undefined : initials"
      shape="circle"
      class="size-9 shrink-0 bg-brand text-sm font-semibold text-white"
      @error="imageFailed = true"
    />
    <span
      class="grid max-w-0 min-w-0 overflow-hidden text-left leading-tight whitespace-nowrap opacity-0 transition-all duration-300"
      :class="reveal"
    >
      <span class="truncate text-sm font-medium">{{ name }}</span>
      <span class="truncate text-xs text-fg-muted">{{ role }}</span>
    </span>
  </button>

  <Popover ref="popover" @show="open = true" @hide="open = false">
    <div class="flex w-52 flex-col gap-1">
      <div class="mb-2 px-1">
        <p class="truncate text-sm font-medium">{{ name }}</p>
        <p class="truncate text-xs text-fg-muted">{{ role }}</p>
      </div>
      <Button
        label="Profil"
        icon="pi pi-user"
        variant="text"
        severity="secondary"
        fluid
        class="justify-start"
        @click="goProfile"
      />
      <Button
        label="Keluar"
        icon="pi pi-sign-out"
        variant="text"
        severity="secondary"
        fluid
        class="justify-start"
        @click="logout"
      />
    </div>
  </Popover>
</template>