export function resolveMediaUrl(path?: string | null): string | undefined {
  if (!path) return undefined;
  try {
    return new URL(path, import.meta.env.VITE_API_BASE_URL).toString();
  } catch {
    return undefined;
  }
}
