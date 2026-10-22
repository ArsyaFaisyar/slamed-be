<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import InputText from "primevue/inputtext";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import ConfirmDialog from "primevue/confirmdialog";
import { useConfirm } from "primevue/useconfirm";

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

const search = ref("");
const stateFilter = ref<string | null>(null);
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

function stateOf(rkh: Rkh): string {
  return isLkhDone(lkhOf(rkh)) ? "DONE" : "OPEN";
}

const filteredRkh = computed(() => {
  const keyword = search.value.trim().toLowerCase();

  return rkhList.value.filter((rkh) => {
    if (stateFilter.value && stateOf(rkh) !== stateFilter.value) {
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
            {{ filteredRkh.length }} kegiatan ditampilkan
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

          <InputText
            v-model="search"
            placeholder="Cari kegiatan..."
            aria-label="Cari kegiatan"
            size="small"
            class="w-40 sm:w-48"
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
        v-else-if="!errorMessage && filteredRkh.length === 0"
        class="flex flex-col items-center justify-center gap-2 p-12 text-center"
      >
        <i class="pi pi-clipboard text-3xl text-fg-muted" />

        <p class="font-medium">
          {{
            search || stateFilter
              ? "Kegiatan tidak ditemukan"
              : "Belum ada RKH"
          }}
        </p>

        <p class="text-sm text-fg-muted">
          {{
            search || stateFilter
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
              <th class="px-5 py-3 font-medium">Tanggal rencana</th>
              <th class="px-5 py-3 font-medium">Kegiatan</th>
              <th v-if="!isSales" class="px-5 py-3 font-medium">Sales</th>
              <th class="px-5 py-3 font-medium">Customer</th>
              <th class="px-5 py-3 font-medium">Project</th>
              <th class="px-5 py-3 font-medium">Tanggal kunjungan</th>
              <th class="px-5 py-3 font-medium">Status</th>
              <th class="w-44 px-5 py-3 text-center font-medium">Aksi</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-line">
            <tr
              v-for="rkh in filteredRkh"
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

                    <Button
                      icon="pi pi-trash"
                      variant="text"
                      rounded
                      severity="danger"
                      aria-label="Hapus LKH"
                      v-tooltip.top="'Hapus LKH'"
                      @click="confirmDelete(rkh)"
                    />
                  </template>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="border-t border-line px-5 py-3 text-xs text-fg-muted">
        Total {{ rkhList.length }} kegiatan
      </footer>
    </section>
  </div>
</template>