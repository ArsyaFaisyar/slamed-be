
<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { ChevronDown, TrendingUp } from '@lucide/vue'
import { menu, type MenuItem } from '../constant/menu'
import { useAuthStore } from '../stores/auth'
import { canAccessMenu } from '../constant/permissions'

const open = defineModel<boolean>('open', { default: false })

const route = useRoute()
const auth = useAuthStore()
const hovered = ref(false)
const openGroup = ref<string | null>(null)

// Filter menu berdasarkan role user yang login
const visibleMenu = computed<MenuItem[]>(() =>
  menu
    .map((item) => {
      if (item.children) {
        const children = item.children.filter((child) =>
          canAccessMenu(
            child.to,
            typeof auth.user?.role === 'string' ? auth.user.role : undefined,
          ),
        )

        return { ...item, children }
      }

      if (
        item.to &&
        canAccessMenu(
          item.to,
          typeof auth.user?.role === 'string' ? auth.user.role : undefined,
        )
      ) {
        return item
      }

      return null
    })
    .filter(
      (item): item is MenuItem =>
        item !== null &&
        (!item.children || item.children.length > 0),
    ),
)

const itemBase =
  'flex h-11 w-full items-center gap-3 rounded-lg px-3.5 text-sm font-medium whitespace-nowrap transition-colors'
const itemIdle = 'text-fg-muted hover:bg-line/50 hover:text-fg'
const itemActive = 'bg-brand/10 text-brand'
const railHidden =
  'transition-opacity duration-150 lg:group-data-[hover=false]/sb:opacity-0'

function hasActiveChild(item: MenuItem) {
  return item.children?.some((child) => child.to === route.path) ?? false
}

function syncOpenGroup() {
  const active = visibleMenu.value.find(hasActiveChild)
  if (active) {
    openGroup.value = active.label
  } else if (
    openGroup.value &&
    !visibleMenu.value.some((item) => item.label === openGroup.value)
  ) {
    openGroup.value = null
  }
}

function toggleGroup(label: string) {
  openGroup.value = openGroup.value === label ? null : label
}

function onFocusOut(event: FocusEvent) {
  const root = event.currentTarget as HTMLElement
  if (!root.contains(event.relatedTarget as Node | null)) {
    hovered.value = false
  }
}

watch(
  [() => route.path, visibleMenu],
  () => {
    syncOpenGroup()
    open.value = false
  },
  { immediate: true },
)
</script>

<template>
  <div
    class="fixed inset-0 z-30 bg-black/50 transition-opacity duration-200"
    :class="
      open
        ? 'opacity-100'
        : ['pointer-events-none opacity-0', hovered && 'lg:opacity-100']
    "
    @click="open = false"
  ></div>

  <aside
    class="group/sb fixed inset-y-0 left-0 z-40 flex w-64 flex-col overflow-hidden border-r border-line bg-sidebar transition-[width,translate] duration-200 ease-out"
    :class="[
      open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
      hovered ? 'lg:w-64' : 'lg:w-[4.5rem]',
    ]"
    :data-hover="hovered"
    @mouseenter="hovered = true"
    @mouseleave="hovered = false"
    @focusin="hovered = true"
    @focusout="onFocusOut"
  >
    <div class="flex h-16 shrink-0 items-center gap-3 px-4">
      <div
        class="grid size-10 shrink-0 place-items-center rounded-xl bg-brand text-white"
      >
        <TrendingUp :size="20" />
      </div>
      <span class="font-heading text-lg font-bold whitespace-nowrap" :class="railHidden">
        SLAMED
      </span>
    </div>

    <nav
      class="flex-1 overflow-y-auto overflow-x-hidden px-3 py-2"
      aria-label="Menu utama"
    >
      <ul class="flex flex-col gap-1">
        <li v-for="item in visibleMenu" :key="item.label">
          <RouterLink
            v-if="item.to"
            :to="item.to"
            :class="[
              itemBase,
              route.path === item.to ? itemActive : itemIdle,
            ]"
          >
            <component :is="item.icon" :size="20" class="shrink-0" />
            <span :class="railHidden">{{ item.label }}</span>
          </RouterLink>

          <template v-else>
            <button
              type="button"
              :class="[
                itemBase,
                hasActiveChild(item)
                  ? 'text-brand hover:bg-line/50'
                  : itemIdle,
              ]"
              :aria-expanded="openGroup === item.label"
              @click="toggleGroup(item.label)"
            >
              <component :is="item.icon" :size="20" class="shrink-0" />
              <span class="flex-1 text-left" :class="railHidden">
                {{ item.label }}
              </span>
              <ChevronDown
                :size="16"
                class="mr-1 shrink-0 transition-transform duration-200"
                :class="[
                  railHidden,
                  openGroup === item.label && 'rotate-180',
                ]"
              />
            </button>

            <div
              class="grid transition-[grid-template-rows] duration-200 lg:group-data-[hover=false]/sb:hidden"
              :class="
                openGroup === item.label
                  ? 'grid-rows-[1fr]'
                  : 'grid-rows-[0fr]'
              "
            >
              <div class="overflow-hidden">
                <ul
                  class="mt-1 ml-6 flex flex-col gap-1 border-l border-line pl-3"
                >
                  <li
                    v-for="child in item.children"
                    :key="child.to"
                  >
                    <RouterLink
                      :to="child.to"
                      class="block rounded-lg px-3 py-2 text-sm whitespace-nowrap transition-colors"
                      :class="
                        route.path === child.to
                          ? 'bg-brand/10 font-medium text-brand'
                          : itemIdle
                      "
                    >
                      {{ child.label }}
                    </RouterLink>
                  </li>
                </ul>
              </div>
            </div>
          </template>
        </li>
      </ul>
    </nav>
  </aside>
</template>
