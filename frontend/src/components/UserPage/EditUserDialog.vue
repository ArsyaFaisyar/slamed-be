<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import Select from "primevue/select";
import ToggleSwitch from "primevue/toggleswitch";
import Button from "primevue/button";
import Message from "primevue/message";
import { updateUser, type User } from "../../api/users";
import { roleOptions, type UserRole } from "../../constant/roles";
import { getErrorMessage, getFieldErrors } from "../../utils/error";

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  user: User | null;
}>();

const emit = defineEmits<{
  updated: [];
}>();

const form = reactive({
  nama: "",
  email: "",
  role: null as UserRole | null,
  is_active: true,
});

const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const serverErrors = ref<Record<string, string>>({});

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const clientErrors = computed(() => ({
  nama: form.nama.trim() ? "" : "Nama wajib diisi",
  email: !form.email.trim() ? "Email wajib diisi" : !emailPattern.test(form.email.trim()) ? "Format email tidak valid" : "",
  role: form.role ? "" : "Role wajib dipilih",
}));

function fieldError(field: "nama" | "email" | "role") {
  return serverErrors.value[field] || (submitted.value ? clientErrors.value[field] : "");
}

function resetForm() {
  form.nama = props.user?.nama ?? "";
  form.email = props.user?.email ?? "";
  form.role = (props.user?.role as UserRole) ?? null;
  form.is_active = Boolean(props.user?.is_active);
  submitted.value = false;
  formError.value = "";
  serverErrors.value = {};
}

watch(
  () => [visible.value, props.user] as const,
  ([isVisible]) => {
    if (isVisible) resetForm();
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
    });

    visible.value = false;
    emit("updated");
  } catch (error) {
    const errors = getFieldErrors(error);
    serverErrors.value = errors;

    if (Object.keys(errors).length === 0) {
      formError.value = getErrorMessage(error, "Gagal memperbarui pengguna");
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Edit pengguna" class="w-[calc(100vw-2rem)] max-w-md" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="edit-user-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-nama" class="text-sm font-medium">Nama</label>
        <InputText id="edit-user-nama" v-model="form.nama" fluid :invalid="!!fieldError('nama')" />
        <Message v-if="fieldError('nama')" severity="error" size="small" variant="simple">
          {{ fieldError("nama") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-email" class="text-sm font-medium">Email</label>
        <InputText id="edit-user-email" v-model="form.email" type="email" fluid :invalid="!!fieldError('email')" />
        <Message v-if="fieldError('email')" severity="error" size="small" variant="simple">
          {{ fieldError("email") }}
        </Message>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="edit-user-role" class="text-sm font-medium">Role</label>
        <Select v-model="form.role" input-id="edit-user-role" :options="roleOptions" option-label="label" option-value="value" placeholder="Pilih role" fluid :invalid="!!fieldError('role')" />
        <Message v-if="fieldError('role')" severity="error" size="small" variant="simple">
          {{ fieldError("role") }}
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
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />
      <Button type="submit" form="edit-user-form" label="Simpan perubahan" :loading="saving" />
    </template>
  </Dialog>
</template>
