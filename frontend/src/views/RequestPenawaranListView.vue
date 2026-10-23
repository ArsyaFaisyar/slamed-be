<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import InputText from "primevue/inputtext";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";

import { getLkh, isLkhDone, type Lkh } from "../api/lkh.ts";
import { getRkh, type Rkh } from "../api/rkh.ts";
import { getCustomers, type Customer } from "../api/customers.ts";
import { getProjects, type Project } from "../api/projects.ts";
import { getUsers, type User } from "../api/users.ts";
import {
  getRequestPenawaranList,
  recallRequestId,
  requestPenawaranDetailPath,
  type RequestPenawaran,
} from "../api/requestPenawaran.ts";
import { useAuthStore } from "../stores/auth.ts";
import { getErrorMessage } from "../utils/error.ts";
import { formatDate } from "../utils/date.ts";

const REQUEST_STATUS = [
  "request penawaran",
  "req penawaran",
  "penawaran",
];

interface RequestRef {
  id: number;
  status: string | null;
  slaLabel: string | null;
  completedAt: string | null;
}

interface Row {
  lkh: Lkh;
  rkh: Rkh;
  request: RequestRef | null;
}

const router = useRouter();
const auth = useAuthStore();

const isSales = computed(() => auth.user?.role === "SALES");

const lkhList = ref<Lkh[]>([]);
const rkhList = ref<Rkh[]>([]);
const customers = ref<Customer[]>([]);
const projects = ref<Project[]>([]);
const users = ref<User[]>([]);
const requestByLkh = ref<Map<number, RequestRef>>(new Map());

const search = ref("");
const stateFilter = ref<"created" | "pending" | null>(null);
const loading = ref(false);
const errorMessage = ref("");

const stateOptions = [
  { label: "Belum dibuat", value: "pending" },
  { label: "Sudah dibuat", value: "created" },
];

const customerNames = computed(
  () => new Map(customers.value.map((item) => [item.id, item.nama_instansi])),
);

const userNames = computed(
  () => new Map(users.value.map((item) => [item.id, item.nama])),
);

const projectById = computed(
  () => new Map(projects.value.map((item) => [item.id, item])),
);

const rkhById = computed(
  () => new Map(rkhList.value.map((item) => [item.id, item])),
);

function isRequestStage(rkh: Rkh) {
  const name = projectById.value.get(rkh.project_id)?.status_rel?.nama;
  const normalized = (name ?? "").toLowerCase().trim();

  return REQUEST_STATUS.some((status) => normalized.includes(status));
}

const rows = computed<Row[]>(() => {
  const result: Row[] = [];

  for (const lkh of lkhList.value) {
    const rkh = rkhById.value.get(lkh.rkh_id);
    if (!rkh) continue;

    const request = requestByLkh.value.get(lkh.id) ?? null;
    const eligible =
      request !== null || (isLkhDone(lkh) && isRequestStage(rkh));

    if (eligible) {
      result.push({ lkh, rkh, request });
    }
  }

  return result;
});

function customerName(rkh: Rkh) {
  return customerNames.value.get(rkh.customer_id) ?? "-";
}

function projectName(rkh: Rkh) {
  return projectById.value.get(rkh.project_id)?.nama_project ?? "-";
}

function projectStatus(rkh: Rkh) {
  return projectById.value.get(rkh.project_id)?.status_rel ?? null;
}

function statusName(rkh: Rkh) {
  return projectStatus(rkh)?.nama ?? "";
}

function statusColor(rkh: Rkh): string | null {
  return projectStatus(rkh)?.warna ?? null;
}

/**
 * Menentukan warna teks berdasarkan kecerahan warna status.
 * Mendukung format HEX 3/6 digit dan RGB/RGBA.
 */
function statusTextColor(rkh: Rkh): string {
  const color = statusColor(rkh);

  if (!color) return "inherit";

  let red: number;
  let green: number;
  let blue: number;

  const hex = color.trim().match(/^#([\da-f]{3}|[\da-f]{6})$/i);

  if (hex) {
    let value = hex[1];

    if (value.length === 3) {
      value = value
        .split("")
        .map((char) => char + char)
        .join("");
    }

    red = parseInt(value.slice(0, 2), 16);
    green = parseInt(value.slice(2, 4), 16);
    blue = parseInt(value.slice(4, 6), 16);
  } else {
    const rgb = color.match(
      /^rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)/i,
    );

    if (!rgb) return "#ffffff";

    red = Number(rgb[1]);
    green = Number(rgb[2]);
    blue = Number(rgb[3]);
  }

  const luminance =
    (0.299 * red + 0.587 * green + 0.114 * blue) / 255;

  return luminance > 0.6 ? "#172033" : "#ffffff";
}

function salesName(rkh: Rkh) {
  return userNames.value.get(rkh.sales_id) ?? "-";
}

const filteredRows = computed(() => {
  const keyword = search.value.trim().toLowerCase();

  return rows.value.filter((row) => {
    if (stateFilter.value === "created" && !row.request) return false;
    if (stateFilter.value === "pending" && row.request) return false;

    if (!keyword) return true;

    return [
      customerName(row.rkh),
      projectName(row.rkh),
      salesName(row.rkh),
      row.rkh.judul_kegiatan,
      row.request?.status,
      row.request?.slaLabel,
    ].some((value) =>
      String(value ?? "")
        .toLowerCase()
        .includes(keyword),
    );
  });
});

function openRow(row: Row) {
  if (row.request) {
    router.push(requestPenawaranDetailPath(row.request.id));
    return;
  }

  router.push(`/aktivitas/lkh/${row.lkh.id}/request-penawaran`);
}

function toRef(request: RequestPenawaran): RequestRef {
  return {
    id: request.id,
    status: request.status_request,
    slaLabel: request.sla_label,
    completedAt: request.completed_at,
  };
}

async function loadRequests() {
  const map = new Map<number, RequestRef>();

  try {
    const requests = await getRequestPenawaranList();

    for (const request of requests) {
      map.set(request.lkh_id, toRef(request));
    }
  } catch {
    for (const lkh of lkhList.value) {
      const id = recallRequestId(lkh.id);

      if (id !== null) {
        map.set(lkh.id, { id, status: null, slaLabel: null, completedAt: null });
      }
    }
  }

  requestByLkh.value = map;
}

async function fetchData() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const [lkhData, rkhData, customerData, projectData] =
      await Promise.all([
        getLkh(),
        getRkh(),
        getCustomers(),
        getProjects(),
      ]);

    lkhList.value = lkhData;

    rkhList.value = isSales.value
      ? rkhData.filter((rkh) => rkh.sales_id === auth.user?.id)
      : rkhData;

    customers.value = customerData;
    projects.value = projectData;

    await loadRequests();
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      "Gagal memuat daftar request penawaran",
    );
  } finally {
    loading.value = false;
  }

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
    <Message
      v-if="errorMessage"
      severity="error"
      :closable="false"
    >
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

    <section class="rounded-xl border border-line bg-card">
      <div
        class="flex flex-col gap-3 border-b border-line p-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h2 class="font-semibold">Daftar request penawaran</h2>

          <p class="mt-1 text-sm text-fg-muted">
            {{ filteredRows.length }} LKH di tahap request penawaran
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
            aria-label="Filter status request"
          />

          <InputText
            v-model="search"
            placeholder="Cari..."
            aria-label="Cari"
            size="small"
            class="w-40 sm:w-48"
          />
        </div>
      </div>

      <div
        v-if="loading && rows.length === 0"
        class="flex items-center justify-center gap-3 p-12 text-sm text-fg-muted"
      >
        <i class="pi pi-spin pi-spinner text-lg" />
        Memuat daftar request penawaran...
      </div>

      <div
        v-else-if="!errorMessage && filteredRows.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-file-edit text-3xl text-fg-muted" />

        <p class="font-medium">
          {{
            search || stateFilter
              ? "Data tidak ditemukan"
              : "Belum ada request penawaran"
          }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            search || stateFilter
              ? "Coba kata kunci atau filter lain."
              : "LKH yang sudah Done dan project-nya berstatus Request Penawaran akan muncul di sini."
          }}
        </p>
      </div>

      <div
        v-else-if="rows.length > 0"
        class="overflow-x-auto transition-opacity"
        :class="loading && 'pointer-events-none opacity-60'"
        :aria-busy="loading"
      >
        <table class="w-full min-w-[1060px] text-left text-sm">
          <thead class="bg-sidebar text-fg-muted">
            <tr>
              <th class="px-5 py-3 font-medium">
                Tanggal kunjungan
              </th>

              <th
                v-if="!isSales"
                class="px-5 py-3 font-medium"
              >
                Sales
              </th>

              <th class="px-5 py-3 font-medium">Customer</th>
              <th class="px-5 py-3 font-medium">Project</th>
              <th class="px-5 py-3 font-medium">Status project</th>
              <th class="px-5 py-3 font-medium">Request</th>
              <th class="px-5 py-3 font-medium">SLA</th>

              <th class="w-32 px-5 py-3 text-center font-medium">
                Aksi
              </th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="row in filteredRows"
              :key="row.lkh.id"
              class="transition-colors hover:bg-sidebar/60"
            >
              <td class="whitespace-nowrap px-5 py-4">
                {{ formatDate(row.lkh.tanggal_kunjungan) }}
              </td>

              <td
                v-if="!isSales"
                class="px-5 py-4 text-fg-muted"
              >
                {{ salesName(row.rkh) }}
              </td>

              <td class="px-5 py-4">
                {{ customerName(row.rkh) }}
              </td>

              <td class="px-5 py-4">
                <p class="font-medium">
                  {{ projectName(row.rkh) }}
                </p>

                <p class="mt-0.5 line-clamp-1 text-xs text-fg-muted">
                  {{ row.rkh.judul_kegiatan }}
                </p>
              </td>

              <td class="px-5 py-4">
                <span
                  v-if="statusName(row.rkh)"
                  class="inline-flex items-center rounded-md border border-line px-2.5 py-1 text-xs font-medium"
                  :style="
                    statusColor(row.rkh)
                      ? {
                          backgroundColor: statusColor(row.rkh) ?? undefined,
                          color: statusTextColor(row.rkh),
                          borderColor: statusColor(row.rkh) ?? undefined,
                        }
                      : undefined
                  "
                >
                  {{ statusName(row.rkh) }}
                </span>

                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-5 py-4">
                <span
                  class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="
                    row.request
                      ? 'bg-green-500/10 text-green-700 dark:text-green-400'
                      : 'bg-amber-500/10 text-amber-700 dark:text-amber-400'
                  "
                >
                  {{
                    row.request
                      ? row.request.status || "Sudah dibuat"
                      : "Belum dibuat"
                  }}
                </span>
              </td>

              <td class="px-5 py-4">
                <template v-if="row.request?.slaLabel">
                  <p class="font-medium">{{ row.request.slaLabel }}</p>

                  <p
                    v-if="row.request.completedAt"
                    class="mt-0.5 text-xs text-fg-muted"
                  >
                    Selesai {{ formatDate(row.request.completedAt) }}
                  </p>
                </template>

                <span v-else class="text-fg-muted">-</span>
              </td>

              <td class="px-5 py-4 text-center">
                <Button
                  v-if="row.request"
                  icon="pi pi-eye"
                  variant="text"
                  rounded
                  severity="secondary"
                  aria-label="Lihat request penawaran"
                  v-tooltip.top="'Lihat request penawaran'"
                  @click="openRow(row)"
                />

                <Button
                  v-else
                  label="Buat request"
                  icon="pi pi-plus"
                  size="small"
                  @click="openRow(row)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ rows.length }} LKH
      </footer>
    </section>
  </div>
</template>