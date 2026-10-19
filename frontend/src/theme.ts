import { definePreset } from "@primeuix/themes";
import Aura from "@primeuix/themes/aura";
import type { PrimeVueConfiguration } from "primevue/config";

export type ThemeMode = "light" | "dark";

export const DARK_CLASS = "app-dark";
export const THEME_STORAGE_KEY = "slamed-theme";

export function getInitialThemeMode(): ThemeMode {
  try {
    const stored = localStorage.getItem(THEME_STORAGE_KEY);
    if (stored === "light" || stored === "dark") return stored;
  } catch {
  }
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

export function applyThemeMode(mode: ThemeMode): void {
  const root = document.documentElement;
  root.classList.toggle(DARK_CLASS, mode === "dark");
  root.style.colorScheme = mode;
}

export function toggleThemeMode(): ThemeMode {
  const next: ThemeMode = document.documentElement.classList.contains(DARK_CLASS) ? "light" : "dark";
  applyThemeMode(next);
  try {
    localStorage.setItem(THEME_STORAGE_KEY, next);
  } catch {
  }
  return next;
}

const SlamedPreset = definePreset(Aura, {
  semantic: {
    primary: {
      50: "{blue.50}",
      100: "{blue.100}",
      200: "{blue.200}",
      300: "{blue.300}",
      400: "{blue.400}",
      500: "{blue.500}",
      600: "{blue.600}",
      700: "{blue.700}",
      800: "{blue.800}",
      900: "{blue.900}",
      950: "{blue.950}",
    },
    colorScheme: {
      light: {
        primary: {
          color: "#2563EB",
          contrastColor: "#FFFFFF",
          hoverColor: "#1D4ED8",
          activeColor: "#1E40AF",
        },
        surface: {
          0: "#FFFFFF",
          50: "#F5F7FC",
          100: "#EDF1F8",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#3B4760",
          700: "#172033",
          800: "#111A2B",
          900: "#0B1220",
          950: "#050A14",
        },
        text: {
          color: "#172033",
          hoverColor: "#172033",
          mutedColor: "#64748B",
          hoverMutedColor: "#475569",
        },
      },
      dark: {
        primary: {
          color: "#3B82F6",
          contrastColor: "#FFFFFF",
          hoverColor: "#60A5FA",
          activeColor: "#93C5FD",
        },
        surface: {
          0: "#FFFFFF",
          50: "#E8EEFF",
          100: "#D3DBEE",
          200: "#BAC5DB",
          300: "#A5B1C8",
          400: "#94A3B8",
          500: "#64748B",
          600: "#3A4968",
          700: "#25314B",
          800: "#1A2540",
          900: "#111A30",
          950: "#080D20",
        },
        text: {
          color: "#E8EEFF",
          hoverColor: "#FFFFFF",
          mutedColor: "#94A3B8",
          hoverMutedColor: "#CBD5E1",
        },
      },
    },
  },
});

export const primeVueOptions: PrimeVueConfiguration = {
  theme: {
    preset: SlamedPreset,
    options: {
      darkModeSelector: `.${DARK_CLASS}`,
      cssLayer: {
        name: "primevue",
        order: "theme, base, primevue, components, utilities",
      },
    },
  },
};
