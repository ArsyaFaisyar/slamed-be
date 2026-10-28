<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import { useRouter } from "vue-router";
import InputText from "primevue/inputtext";
import MultiSelect from "primevue/multiselect";
import Paginator, { type PageState } from "primevue/paginator";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import ConfirmDialog from "primevue/confirmdialog";
import Menu from "primevue/menu";
import type { MenuItem } from "primevue/menuitem";
import { useConfirm } from "primevue/useconfirm";

import LkhExportDialog from "../components/LkhPage/LkhExportDialog.vue";

import {
  deleteLkh,
  getLkh,
  isLkhDone,
  reopenLkh,
  type Lkh,
} from "../api/lkh.ts";
import { getRkh, type Rkh } from "../api/rkh";
import { getCustomers, type Customer } from "../api/customers";
import { getProjects, type Project } from "../api/projects";
import { getUsers, type User } from "../api/users";
import { useAuthStore } from "../stores/auth";
import { getErrorMessage } from "../utils/error";
import { formatDate } from "../utils/date";

import {
  getRequestPenawaranList,
  recallRequestId,
  requestPenawaranDetailPath,
} from "../api/requestPenawaran";

const stateLabel: Record<string, string> = {
  OPEN: "Open",
  DONE: "Done",
};

const stateClass: Record<string, string> = {
  OPEN: "bg-amber-500/10 text-amber-700 dark:text-amber-400",
  DONE: "bg-green-500/10 text-green-700 dark:text-green-400",
};

const stateOptions = Object.entries(stateLabel).map(([value, label]) => ({
  label,
  value,
}));

function labelOf(state: string) {
  return stateLabel[state] ?? stateLabel.OPEN;
}

function classOf(state: string) {
  return stateClass[state] ?? stateClass.OPEN;
}

const confirm = useConfirm();
const auth = useAuthStore();
const router = useRouter();

const isSales = computed(() => auth.user?.role === "SALES");

const rkhList = ref<Rkh[]>([]);
const lkhList = ref<Lkh[]>([]);
const customers = ref<Customer[]>([]);
const projects = ref<Project[]>([]);
const users = ref<User[]>([]);

const requestIdByLkh = ref<Map<number, number>>(new Map());
const requestListLoaded = ref(false);

const search = ref("");
const stateFilter = ref<string | null>(null);
const salesFilter = ref<number[]>([]);
const customerFilter = ref<number[]>([]);
const first = ref(0);
const rows = ref(10);
const rowsOptions = [10, 25, 50];

type SortKey = "tanggal_rencana" | "tanggal_kunjungan";
const sortKey = ref<SortKey | null>(null);
const sortDir = ref<1 | -1>(1);
const exportVisible = ref(false);
const exportInitialStatuses = computed(() =>
  stateFilter.value === "DONE"
    ? ["DONE"]
    : stateFilter.value === "OPEN"
      ? ["NOT_YET"]
      : [],
);
const loading = ref(false);
const errorMessage = ref("");
const actionError = ref("");

const customerNames = computed(
  () =>
    new Map(
      customers.value.map((customer) => [
        customer.id,
        customer.nama_instansi,
      ]),
    ),
);

const projectNames = computed(
  () =>
    new Map(
      projects.value.map((project) => [
        project.id,
        project.nama_project,
      ]),
    ),
);

const userNames = computed(
  () => new Map(users.value.map((user) => [user.id, user.nama])),
);

const lkhByRkh = computed(
  () => new Map(lkhList.value.map((lkh) => [lkh.rkh_id, lkh])),
);

function customerName(rkh: Rkh) {
  return customerNames.value.get(rkh.customer_id) ?? `ID ${rkh.customer_id}`;
}

function projectName(rkh: Rkh) {
  return projectNames.value.get(rkh.project_id) ?? `ID ${rkh.project_id}`;
}

function salesName(rkh: Rkh) {
  return userNames.value.get(rkh.sales_id) ?? `ID ${rkh.sales_id}`;
}

function lkhOf(rkh: Rkh) {
  return lkhByRkh.value.get(rkh.id) ?? null;
}

function requestIdOf(lkhId: number): number | null {
  const fromServer = requestIdByLkh.value.get(lkhId);
  if (fromServer !== undefined) return fromServer;
  return requestListLoaded.value ? null : recallRequestId(lkhId);
}

function hasRequest(rkh: Rkh): boolean {
  const lkh = lkhOf(rkh);
  return lkh ? requestIdOf(lkh.id) !== null : false;
}

function stateOf(rkh: Rkh): string {
  return isLkhDone(lkhOf(rkh)) ? "DONE" : "OPEN";
}

const salesOptions = computed(() =>
  [...new Set(rkhList.value.map((rkh) => rkh.sales_id))]
    .map((id) => ({
      value: id,
      label: userNames.value.get(id) ?? `ID ${id}`,
    }))
    .sort((a, b) => a.label.localeCompare(b.label)),
);

const customerOptions = computed(() =>
  [...new Set(rkhList.value.map((rkh) => rkh.customer_id))]
    .map((id) => ({
      value: id,
      label: customerNames.value.get(id) ?? `ID ${id}`,
    }))
    .sort((a, b) => a.label.localeCompare(b.label)),
);

const hasFilter = computed(
  () =>
    Boolean(search.value.trim()) ||
    Boolean(stateFilter.value) ||
    salesFilter.value.length > 0 ||
    customerFilter.value.length > 0,
);

const filteredRkh = computed(() => {
  const keyword = search.value.trim().toLowerCase();

  return rkhList.value.filter((rkh) => {
    if (stateFilter.value && stateOf(rkh) !== stateFilter.value) {
      return false;
    }

    if (
      salesFilter.value.length > 0 &&
      !salesFilter.value.includes(rkh.sales_id)
    ) {
      return false;
    }

    if (
      customerFilter.value.length > 0 &&
      !customerFilter.value.includes(rkh.customer_id)
    ) {
      return false;
    }

    if (!keyword) return true;

    return [
      rkh.judul_kegiatan,
      rkh.rencana_kegiatan,
      customerName(rkh),
      projectName(rkh),
      salesName(rkh),
      lkhOf(rkh)?.hasil_kunjungan,
    ].some((value) =>
      String(value ?? "").toLowerCase().includes(keyword),
    );
  });
});

function sortValue(rkh: Rkh, key: SortKey): number | null {
  const raw =
    key === "tanggal_rencana"
      ? rkh.tanggal_rencana
      : lkhOf(rkh)?.tanggal_kunjungan;

  if (!raw) return null;

  const time = Date.parse(raw);
  return Number.isNaN(time) ? null : time;
}

const sortedRkh = computed(() => {
  const key = sortKey.value;
  if (!key) return filteredRkh.value;

  const direction = sortDir.value;

  return [...filteredRkh.value].sort((a, b) => {
    const left = sortValue(a, key);
    const right = sortValue(b, key);

    if (left === null && right === null) return 0;
    if (left === null) return 1;
    if (right === null) return -1;

    return (left - right) * direction;
  });
});

const pagedRkh = computed(() =>
  sortedRkh.value.slice(first.value, first.value + rows.value),
);

function toggleSort(key: SortKey) {
  if (sortKey.value !== key) {
    sortKey.value = key;
    sortDir.value = 1;
  } else if (sortDir.value === 1) {
    sortDir.value = -1;
  } else {
    sortKey.value = null;
    sortDir.value = 1;
  }
}

function sortIcon(key: SortKey) {
  if (sortKey.value !== key) return "pi-sort-alt opacity-50";
  return sortDir.value === 1
    ? "pi-sort-amount-up-alt text-brand"
    : "pi-sort-amount-down text-brand";
}

function ariaSort(key: SortKey) {
  if (sortKey.value !== key) return "none";
  return sortDir.value === 1 ? "ascending" : "descending";
}

function onPage(event: PageState) {
  first.value = event.first;
  rows.value = event.rows;
}

watch(
  [search, stateFilter, salesFilter, customerFilter, sortKey, sortDir],
  () => {
    first.value = 0;
  },
);

watch(
  () => sortedRkh.value.length,
  (total) => {
    if (total > 0 && first.value >= total) {
      first.value = Math.floor((total - 1) / rows.value) * rows.value;
    }
  },
);

const REQUEST_STATUS = [
  "request penawaran",
  "req penawaran",
  "penawaran",
];

const isRequestStage = (rkh: Rkh) => {
  const name = projectById.value
    .get(rkh.project_id)
    ?.status_rel?.nama;

  const normalizedName = (name ?? "")
    .toLowerCase()
    .trim();

  return REQUEST_STATUS.some((status) =>
    normalizedName.includes(status)
  );
};

const projectById = computed(
  () => new Map(projects.value.map((project) => [project.id, project])),
);


const rowMenu = ref<InstanceType<typeof Menu> | null>(null);
const rowMenuItems = ref<MenuItem[]>([]);

function openRowMenu(event: Event, rkh: Rkh) {
  const lkh = lkhOf(rkh);
  if (!lkh) return;

  const requestId = requestIdOf(lkh.id);
  const sudahRequest = requestId !== null;

  rowMenuItems.value = sudahRequest
    ? [
        {
          label: "Request penawaran (sudah dibuat)",
          icon: "pi pi-file-edit",
          disabled: true,
        },
        {
          label: "Lihat request penawaran",
          icon: "pi pi-eye",
          command: () => router.push(requestPenawaranDetailPath(requestId)),
        },
      ]
    : [
        {
          label: "Request penawaran",
          icon: "pi pi-file-edit",
          command: () =>
            router.push(`/aktivitas/lkh/${lkh.id}/request-penawaran`),
        },
      ];

  rowMenu.value?.toggle(event);
}

function openForm(rkh: Rkh) {
  router.push(`/aktivitas/lkh/${rkh.id}`);
}

function confirmDelete(rkh: Rkh) {
  const lkh = lkhOf(rkh);
  if (!lkh) return;

  confirm.require({
    header: "Hapus LKH",
    message: `Yakin ingin menghapus LKH untuk kegiatan "${rkh.judul_kegiatan}"? RKH akan kembali berstatus Open.`,
    icon: "pi pi-exclamation-triangle",
    rejectProps: {
      label: "Batal",
      severity: "secondary",
      variant: "text",
    },
    acceptProps: {
      label: "Hapus",
      severity: "danger",
    },
    accept: async () => {
      actionError.value = "";

      try {
        await deleteLkh(lkh.id);
        await fetchData();
      } catch (error) {
        actionError.value = getErrorMessage(error, "Gagal menghapus LKH");
      }
    },
  });
}

function confirmReopen(rkh: Rkh) {
  const lkh = lkhOf(rkh);
  if (!lkh) return;

  confirm.require({
    header: "Kembalikan status LKH",
    message: `Kembalikan LKH untuk kegiatan "${rkh.judul_kegiatan}" ke status Open? LKH akan bisa diedit lagi.`,
    icon: "pi pi-replay",
    rejectProps: {
      label: "Batal",
      severity: "secondary",
      variant: "text",
    },
    acceptProps: {
      label: "Kembalikan",
    },
    accept: async () => {
      actionError.value = "";

      try {
        await reopenLkh(lkh.id);
        await fetchData();
      } catch (error) {
        actionError.value = getErrorMessage(
          error,
          "Gagal mengembalikan status LKH",
        );
      }
    },
  });
}

async function loadRequests() {
  const map = new Map<number, number>();

  try {
    for (const request of await getRequestPenawaranList()) {
      if (!map.has(request.lkh_id)) map.set(request.lkh_id, request.id);
    }
    requestListLoaded.value = true;
  } catch {
    requestListLoaded.value = false;
  }

  requestIdByLkh.value = map;
}

async function fetchData() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const [rkhData, lkhData, customerData, projectData] = await Promise.all([
      getRkh(),
      getLkh(),
      getCustomers(),
      getProjects(),
    ]);

    rkhList.value = isSales.value
      ? rkhData.filter((rkh) => rkh.sales_id === auth.user?.id)
      : rkhData;

    lkhList.value = lkhData;
    customers.value = customerData;
    projects.value = projectData;
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      "Gagal memuat daftar LKH",
    );
  } finally {
    loading.value = false;
  }

  await loadRequests();

  try {
    users.value = await getUsers();
  } catch {
    users.value = [];
  }
}

onMounted(fetchData);
</script>

<template>
  <div class="flex flex-col gap-6">
    <Message v-if="errorMessage" severity="error" :closable="false">
      <div class="flex flex-wrap items-center gap-3">
        <span>{{ errorMessage }}</span>
        <Button
          label="Coba lagi"
          size="small"
          severity="danger"
          variant="text"
          :loading="loading"
          @click="fetchData"
        />
      </div>
    </Message>

    <Message
      v-if="actionError"
      severity="error"
      @close="actionError = ''"
    >
      {{ actionError }}
    </Message>

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Laporan kegiatan harian</h2>
          <p class="mt-1 text-sm text-fg-muted">
            {{ sortedRkh.length }} kegiatan ditampilkan
          </p>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <Select
            v-model="stateFilter"
            :options="stateOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua status"
            show-clear
            size="small"
            class="w-40"
            aria-label="Filter status LKH"
          />

          <MultiSelect
            v-if="!isSales"
            v-model="salesFilter"
            :options="salesOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua sales"
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} sales dipilih"
            filter
            size="small"
            class="w-44"
            aria-label="Filter sales"
          />

          <MultiSelect
            v-model="customerFilter"
            :options="customerOptions"
            option-label="label"
            option-value="value"
            placeholder="Semua customer"
            display="comma"
            :max-selected-labels="1"
            selected-items-label="{0} customer dipilih"
            filter
            size="small"
            class="w-48"
            aria-label="Filter customer"
          />

          <InputText
            v-model="search"
            placeholder="Cari kegiatan..."
            aria-label="Cari kegiatan"
            size="small"
            class="w-40 sm:w-48"
          />

          <Button
            label="Export Excel"
            icon="pi pi-file-excel"
            size="small"
            class="whitespace-nowrap !border-[#217346] !bg-[#217346] !text-white hover:!border-[#185C37] hover:!bg-[#185C37]"
            @click="exportVisible = true"
          />
        </div>
      </div>

      <div
        v-if="loading && rkhList.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar kegiatan...
      </div>

      <div
        v-else-if="!errorMessage && sortedRkh.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-clipboard text-3xl text-fg-muted" />

        <p class="font-medium">
          {{
            hasFilter
              ? "Kegiatan tidak ditemukan"
              : "Belum ada RKH"
          }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            hasFilter
              ? "Coba kata kunci atau filter lain."
              : "Buat RKH terlebih dahulu, lalu isi LKH-nya di sini."
          }}
        </p>
      </div>

      <div
        v-else-if="rkhList.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[1100px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th
                class="px-5 py-3 font-medium"
                :aria-sort="ariaSort('tanggal_rencana')"
              >
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 font-medium hover:text-fg"
                  @click="toggleSort('tanggal_rencana')"
                >
                  Tanggal rencana
                  <i class="pi text-xs" :class="sortIcon('tanggal_rencana')" />
                </button>
              </th>
              <th class="px-5 py-3 font-medium">Kegiatan</th>
              <th v-if="!isSales" class="px-5 py-3 font-medium">Sales</th>
              <th class="px-5 py-3 font-medium">Customer</th>
              <th class="px-5 py-3 font-medium">Project</th>
              <th
                class="px-5 py-3 font-medium"
                :aria-sort="ariaSort('tanggal_kunjungan')"
              >
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 font-medium hover:text-fg"
                  @click="toggleSort('tanggal_kunjungan')"
                >
                  Tanggal kunjungan
                  <i class="pi text-xs" :class="sortIcon('tanggal_kunjungan')" />
                </button>
              </th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th class="w-44 px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="rkh in pagedRkh"
              :key="rkh.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="whitespace-nowrap px-5 py-4">
                {{ formatDate(rkh.tanggal_rencana) }}
              </td>

              <td class="max-w-[260px] px-5 py-4">
                <div class="font-medium">{{ rkh.judul_kegiatan }}</div>
                <div class="mt-0.5 line-clamp-1 text-xs text-fg-muted">
                  {{ rkh.tipe_aktivitas }}
                </div>
              </td>

              <td v-if="!isSales" class="px-5 py-4 text-fg-muted">
                {{ salesName(rkh) }}
              </td>

              <td class="px-5 py-4">{{ customerName(rkh) }}</td>

              <td class="px-5 py-4 text-fg-muted">
                {{ projectName(rkh) }}
              </td>

              <td class="whitespace-nowrap px-5 py-4 text-fg-muted">
                {{
                  lkhOf(rkh)
                    ? formatDate(lkhOf(rkh)?.tanggal_kunjungan)
                    : "-"
                }}
              </td>

              <td class="px-5 py-4">
                <span
                  class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="classOf(stateOf(rkh))"
                >
                  {{ labelOf(stateOf(rkh)) }}
                </span>
              </td>

              <td class="px-5 py-4 text-center">
                <div class="flex items-center justify-center gap-1">
                  <Button
                    v-if="!lkhOf(rkh)"
                    label="Isi LKH"
                    icon="pi pi-pencil"
                    size="small"
                    @click="openForm(rkh)"
                  />

                  <template v-else-if="isLkhDone(lkhOf(rkh))">
                    <Button
                      icon="pi pi-eye"
                      variant="text"
                      rounded
                      severity="secondary"
                      aria-label="Lihat LKH"
                      v-tooltip.top="'Lihat LKH'"
                      @click="openForm(rkh)"
                    />

                    <Button
                      icon="pi pi-replay"
                      variant="text"
                      rounded
                      severity="warn"
                      aria-label="Kembalikan status"
                      v-tooltip.top="'Kembalikan ke status open'"
                      @click="confirmReopen(rkh)"
                    />
                  </template>

                  <template v-else>
                    <Button
                      icon="pi pi-pencil"
                      variant="text"
                      rounded
                      severity="secondary"
                      aria-label="Edit LKH"
                      v-tooltip.top="'Edit LKH'"
                      @click="openForm(rkh)"
                    />
                  </template>

                  <Button
                    v-if="
                      hasRequest(rkh) ||
                      (stateOf(rkh) === 'DONE' && isRequestStage(rkh))
                    "
                    icon="pi pi-ellipsis-v"
                    variant="text"
                    rounded
                    severity="secondary"
                    aria-label="Menu lainnya"
                    aria-haspopup="true"
                    @click="openRowMenu($event, rkh)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer
        class="flex flex-col gap-2 border-t border-line px-5 py-3 text-xs text-fg-muted sm:flex-row sm:items-center sm:justify-between"
      >
        <span>
          Total {{ rkhList.length }} kegiatan
          <template v-if="hasFilter">
            · {{ sortedRkh.length }} sesuai filter
          </template>
        </span>

        <Paginator
          v-if="sortedRkh.length > rowsOptions[0]"
          :first="first"
          :rows="rows"
          :total-records="sortedRkh.length"
          :rows-per-page-options="rowsOptions"
          template="FirstPageLink PrevPageLink PageLinks NextPageLink RowsPerPageDropdown"
          class="!bg-transparent !p-0"
          @page="onPage"
        />
      </footer>
    </section>

    <Menu ref="rowMenu" :model="rowMenuItems" popup />

    <LkhExportDialog
      v-model:visible="exportVisible"
      :initial-statuses="exportInitialStatuses"
    />
  </div>
</template>