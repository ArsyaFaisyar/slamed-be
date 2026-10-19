<script setup lang="ts">
import { computed, ref, watch } from "vue";
import Dialog from "primevue/dialog";
import Password from "primevue/password";
import Button from "primevue/button";
import Message from "primevue/message";
import { resetUserPassword } from "../../api/users";
import { getErrorMessage } from "../../utils/error";

const visible = defineModel<boolean>("visible", { default: false });

const props = defineProps<{
  userId: number;
  userName: string;
}>();

const emit = defineEmits<{
  reset: [];
}>();

const password = ref("");
const confirmPassword = ref("");
const submitted = ref(false);
const saving = ref(false);
const formError = ref("");
const successMessage = ref("");

const passwordError = computed(() => {
  if (!submitted.value) return "";
  if (!password.value) return "Password baru wajib diisi";
  if (password.value.length < 8) return "Password minimal 8 karakter";
  return "";
});

const confirmPasswordError = computed(() => {
  if (!submitted.value) return "";
  if (!confirmPassword.value) return "Konfirmasi password wajib diisi";
  if (confirmPassword.value !== password.value) {
    return "Konfirmasi password tidak cocok";
  }
  return "";
});

function resetForm() {
  password.value = "";
  confirmPassword.value = "";
  submitted.value = false;
  formError.value = "";
  successMessage.value = "";
}

watch(visible, (value) => {
  if (value) resetForm();
});

async function onSubmit() {
  submitted.value = true;
  formError.value = "";
  successMessage.value = "";

  if (passwordError.value || confirmPasswordError.value) return;

  saving.value = true;

  try {
    await resetUserPassword(props.userId, password.value);
    successMessage.value = "Password berhasil diubah";
    emit("reset");
    visible.value = false;
  } catch (error) {
    formError.value = getErrorMessage(error, "Gagal mengubah password");
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <Dialog v-model:visible="visible" modal header="Reset Password" class="w-[calc(100vw-2rem)] max-w-md" :draggable="false" :closable="!saving" :close-on-escape="!saving">
    <form id="reset-password-form" class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
      <p class="text-sm text-fg-muted">
        Buat password baru untuk
        <span class="font-medium text-fg">{{ userName }}</span
        >.
      </p>

      <Message v-if="formError" severity="error" size="small">
        {{ formError }}
      </Message>

      <div class="flex flex-col gap-1.5">
        <label for="reset-password" class="text-sm font-medium"> Password baru </label>

        <Password v-model="password" input-id="reset-password" toggle-mask fluid :feedback="false" :invalid="!!passwordError" :input-props="{ autocomplete: 'new-password' }" />

        <Message v-if="passwordError" severity="error" size="small" variant="simple">
          {{ passwordError }}
        </Message>

        <p class="text-xs text-fg-muted">Minimal 8 karakter.</p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label for="reset-confirm-password" class="text-sm font-medium"> Konfirmasi password baru </label>

        <Password v-model="confirmPassword" input-id="reset-confirm-password" toggle-mask fluid :feedback="false" :invalid="!!confirmPasswordError" :input-props="{ autocomplete: 'new-password' }" />

        <Message v-if="confirmPasswordError" severity="error" size="small" variant="simple">
          {{ confirmPasswordError }}
        </Message>
      </div>
    </form>

    <template #footer>
      <Button label="Batal" variant="text" severity="secondary" :disabled="saving" @click="visible = false" />

      <Button type="submit" form="reset-password-form" label="Ubah password" size="small" :loading="saving" />
    </template>
  </Dialog>
</template>
