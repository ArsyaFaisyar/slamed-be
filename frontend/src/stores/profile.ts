import { ref } from "vue";
import { defineStore } from "pinia";
import { getPhotoUrl, getProfile, uploadPhoto, type Profile } from "../api/profile";
import { getErrorMessage } from "../utils/error";

export const useProfileStore = defineStore("profile", () => {
  const profile = ref<Profile | null>(null);
  const photoUrl = ref<string | null>(null);
  const loading = ref(false);
  const loadError = ref("");

  let inflight: Promise<void> | null = null;

  function setPhotoUrl(url: string | null) {
    if (photoUrl.value?.startsWith("blob:")) URL.revokeObjectURL(photoUrl.value);
    photoUrl.value = url;
  }

  async function loadPhoto() {
    setPhotoUrl(await getPhotoUrl());
  }

  function load() {
    if (inflight) return inflight;

    loading.value = true;
    loadError.value = "";

    inflight = Promise.all([
      getProfile().then((data) => {
        profile.value = data;
      }),
      loadPhoto(),
    ])
      .then(() => undefined)
      .catch((error) => {
        loadError.value = getErrorMessage(error, "Gagal memuat profil");
      })
      .finally(() => {
        loading.value = false;
        inflight = null;
      });

    return inflight;
  }

  async function changePhoto(file: File) {
    await uploadPhoto(file);
    await loadPhoto();
  }

  function reset() {
    profile.value = null;
    loadError.value = "";
    setPhotoUrl(null);
  }

  return { profile, photoUrl, loading, loadError, load, changePhoto, reset };
});
