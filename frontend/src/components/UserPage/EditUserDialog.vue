
<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import Select from "primevue/select";
import ToggleSwitch from "primevue/toggleswitch";
import Button from "primevue/button";
import Message from "primevue/message";
import { updateUser, type User } from "../../api/users";
import { getBranches, type Branch } from "../../api/branches";
import type { Area } from "../../api/areas";
import { roleOptions, type UserRole } from "../../constant/roles";
import { getErrorMessage, getFieldErrors } from "../../utils/error";

interface BranchOption {
  label: string;
  value: number;
}

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  user: User | null;
  areas: Area[];
  loadingAreas: boolean;
  areasError: string;
}>();

const emit = defineEmits<{
  updated: [];
}>();

const branches = ref<Branch[]>([]);
const loadingBranches = ref(false);

const branchOptions = computed<BranchOption[]>(() =>
  branches.value.map((branch) => ({
    label: branch.nama,
    value: branch.id,
  })),
);

const areaOptions = computed(() =>
  props.areas.map((area) => ({
    label: area.nama,
    value: area.id,
  })),
);

const form = reactive({
  nama: "",
  email: "",
  role: null as UserRole | null,
  is_active: true,
  branch_id: null as number | null,
  area_id: null as number | null,
});

const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const clientErrors = computed(() => ({
  nama: form.nama.trim() ? "" : "Nama wajib diisi",
  email: !form.email.trim()
    ? "Email wajib diisi"
    : !emailPattern.test(form.email.trim())
      ? "Format email tidak valid"
      : "",
  role: form.role ? "" : "Role wajib dipilih",
}));

function fieldError(field: "nama" | "email" | "role" | "branch_id" | "area_id") {
  if (serverErrors.value[field]) return serverErrors.value[field];

  if (submitted.value && field in clientErrors.value) {
    return clientErrors.value[field as keyof typeof clientErrors.value];
  }

  return "";
}

function resetForm() {
  form.nama = props.user?.nama ?? "";
  form.email = props.user?.email ?? "";
  form.role = (props.user?.role as UserRole) ?? null;
  form.is_active = Number(props.user?.is_active) === 1;
  form.branch_id = props.user?.branch_id ?? null;
  form.area_id = props.user?.area_id ?? null;

  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

async function fetchBranches() {
  loadingBranches.value = true;

  try {
    branches.value = await getBranches();
  } catch (error) {
    branches.value = [];
    formError.value = getErrorMessage(
      error,
      "Gagal memuat daftar cabang",
    );
  } finally {
    loadingBranches.value = false;
  }
}

watch(
  () => [visible.value, props.user] as const,
  async ([isVisible]) => {
    if (!isVisible) return;

    resetForm();
    await fetchBranches();
  },
  { immediate: true },
);

async function onSubmit() {
  submitted.value = true;

  if (!props.user) return;
  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    await updateUser(props.user.id, {
      nama: form.nama.trim(),
      email: form.email.trim(),
      role: form.role as UserRole,
      is_active: form.is_active,
      branch_id: form.branch_id,
      area_id: form.area_id,
    });

    visible.value = false;
    emit("updated");
  } catch (error) {
    const errors = getFieldErrors(error);
    serverErrors.value = errors;

    if (Object.keys(errors).length === 0) {
      formError.value = getErrorMessage(
        error,
        "Gagal memperbarui pengguna",
      );
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="Edit pengguna"
    class="w-[calc(100vw-2rem)] max-w-md"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form
      id="edit-user-form"
      class="flex flex-col gap-4"
      novalidate
      @submit.prevent="onSubmit"
    >
      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>
      <Message v-if="areasError" severity="error" size="small">
        {{ areasError }}
      </Message>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-nama" class="text-sm font-medium">
          Nama
        </label>
        <InputText
          id="edit-user-nama"
          v-model="form.nama"
          fluid
          :invalid="!!fieldError('nama')"
        />
        <Message
          v-if="fieldError('nama')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("nama") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-email" class="text-sm font-medium">
          Email
        </label>
        <InputText
          id="edit-user-email"
          v-model="form.email"
          type="email"
          fluid
          :invalid="!!fieldError('email')"
        />
        <Message
          v-if="fieldError('email')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("email") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-role" class="text-sm font-medium">
          Role
        </label>
        <Select
          v-model="form.role"
          input-id="edit-user-role"
          :options="roleOptions"
          option-label="label"
          option-value="value"
          placeholder="Pilih role"
          fluid
          :invalid="!!fieldError('role')"
          empty-message="Role tidak tersedia"
        />
        <Message
          v-if="fieldError('role')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("role") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-branch" class="text-sm font-medium">
          Cabang
        </label>
        <Select
          v-model="form.branch_id"
          input-id="edit-user-branch"
          :options="branchOptions"
          option-label="label"
          option-value="value"
          placeholder="Pilih cabang"
          filter
          show-clear
          fluid
          :loading="loadingBranches"
          :disabled="loadingBranches || branchOptions.length === 0"
          :invalid="!!fieldError('branch_id')"
          empty-message="Daftar cabang tidak tersedia"
        />
        <Message
          v-if="fieldError('branch_id')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("branch_id") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-area" class="text-sm font-medium">
          Area
        </label>
        <Select
          v-model="form.area_id"
          input-id="edit-user-area"
          :options="areaOptions"
          option-label="label"
          option-value="value"
          placeholder="Pilih area"
          filter
          show-clear
          fluid
          :loading="loadingAreas"
          :disabled="loadingAreas || areaOptions.length === 0"
          :invalid="!!fieldError('area_id')"
          empty-message="Daftar area tidak tersedia"
        />
        <Message
          v-if="fieldError('area_id')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("area_id") }}
        </Message>
      </div>

      <div class="flex items-center justify-between rounded-lg border border-line p-3">
        <div>
          <p class="text-sm font-medium">Status akun</p>
          <p class="text-xs text-fg-muted">
            {{ form.is_active ? "Akun aktif" : "Akun nonaktif" }}
          </p>
        </div>
        <ToggleSwitch v-model="form.is_active" />
      </div>
    </form>

    <template #footer>
      <Button
        label="Batal"
        variant="text"
        severity="secondary"
        :disabled="saving"
        @click="visible = false"
      />
      <Button
        type="submit"
        form="edit-user-form"
        label="Simpan perubahan"
        :loading="saving"
      />
    </template>
  </Dialog>
</template>
