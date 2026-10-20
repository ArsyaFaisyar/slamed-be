
<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import Password from "primevue/password";
import Select from "primevue/select";
import Button from "primevue/button";
import Message from "primevue/message";
import { createUser } from "../../api/users";
import { getBranches, type Branch } from "../../api/branches";
import type { Area } from "../../api/areas";
import { roleOptions, type UserRole } from "../../constant/roles";
import { getErrorMessage, getFieldErrors } from "../../utils/error";

interface BranchOption {
  label: string;
  value: number;
}

const visible = defineModel<boolean>("visible", { default: false });
const emit = defineEmits<{ created: [] }>();
const props = defineProps<{
  areas: Area[];
  loadingAreas: boolean;
  areasError: string;
}>();

const fields = [
  "nama",
  "username",
  "email",
  "password",
  "role",
  "branch_id",
  "area_id",
] as const;

type Field = (typeof fields)[number];

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const branches = ref<Branch[]>([]);
const loadingBranches = ref(false);

const branchOptions = computed<BranchOption[]>(() =>
  branches.value.map((branch) => ({
    label: branch.nama,
    value: branch.id,
  })),
);

function emptyForm() {
  return {
    nama: "",
    username: "",
    email: "",
    password: "",
    role: null as UserRole | null,
    branch_id: null as number | null,
    area_id: null as number | null,
  };
}

const form = reactive(emptyForm());
const areaOptions = computed(() =>
  props.areas.map((area) => ({
    label: area.nama,
    value: area.id,
  })),
);
const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const clientErrors = computed<Record<Field, string>>(() => {
  const email = form.email.trim();

  return {
    nama: form.nama.trim() ? "" : "Nama wajib diisi",
    username: form.username.trim() ? "" : "Username wajib diisi",
    email: !email
      ? "Email wajib diisi"
      : !emailPattern.test(email)
        ? "Format email tidak valid"
        : "",
    password: form.password ? "" : "Kata sandi wajib diisi",
    role: form.role ? "" : "Role wajib dipilih",
    branch_id: "",
    area_id: "",
  };
});

function fieldError(field: Field) {
  return serverErrors.value[field] ||
    (submitted.value ? clientErrors.value[field] : "");
}

function reset() {
  Object.assign(form, emptyForm());
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

watch(visible, async (value) => {
  if (!value) return;

  reset();
  await fetchBranches();
});

async function onSubmit() {
  submitted.value = true;

  if (Object.values(clientErrors.value).some(Boolean)) return;

  saving.value = true;
  formError.value = "";
  serverErrors.value = {};

  try {
    await createUser({
      nama: form.nama.trim(),
      username: form.username.trim(),
      email: form.email.trim(),
      password: form.password,
      role: form.role as UserRole,
      branch_id: form.branch_id,
      area_id: form.area_id,
    });

    visible.value = false;
    emit("created");
  } catch (error) {
    const errors = getFieldErrors(error);
    const known = Object.fromEntries(
      Object.entries(errors).filter(([key]) =>
        fields.includes(key as Field),
      ),
    );

    serverErrors.value = known;

    if (Object.keys(known).length === 0) {
      formError.value = getErrorMessage(
        error,
        "Gagal menambahkan pengguna",
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
    header="Tambah pengguna"
    class="w-[calc(100vw-2rem)] max-w-md"
    :draggable="false"
    :closable="!saving"
    :close-on-escape="!saving"
  >
    <form
      id="create-user-form"
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
        <label for="user-nama" class="text-sm font-medium">Nama</label>
        <InputText
          id="user-nama"
          v-model="form.nama"
          autocomplete="off"
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
        <label for="user-username" class="text-sm font-medium">
          Username
        </label>
        <InputText
          id="user-username"
          v-model="form.username"
          autocomplete="off"
          fluid
          :invalid="!!fieldError('username')"
        />
        <Message
          v-if="fieldError('username')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("username") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="user-email" class="text-sm font-medium">Email</label>
        <InputText
          id="user-email"
          v-model="form.email"
          type="email"
          autocomplete="off"
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
        <label for="user-password" class="text-sm font-medium">
          Kata sandi
        </label>
        <Password
          v-model="form.password"
          input-id="user-password"
          toggle-mask
          fluid
          :feedback="false"
          :invalid="!!fieldError('password')"
          :input-props="{ autocomplete: 'new-password' }"
        />
        <Message
          v-if="fieldError('password')"
          severity="error"
          size="small"
          variant="simple"
        >
          {{ fieldError("password") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="user-role" class="text-sm font-medium">Role</label>
        <Select
          v-model="form.role"
          input-id="user-role"
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
        <label for="user-branch" class="text-sm font-medium">
          Cabang
        </label>
        <Select
          v-model="form.branch_id"
          input-id="user-branch"
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
        <label for="user-area" class="text-sm font-medium">Area</label>
        <Select
          v-model="form.area_id"
          input-id="user-area"
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
        form="create-user-form"
        label="Simpan"
        :loading="saving"
      />
    </template>
  </Dialog>
</template>
