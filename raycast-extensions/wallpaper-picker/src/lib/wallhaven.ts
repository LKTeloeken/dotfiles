import { getPreferenceValues } from "@raycast/api";

export interface Wallpaper {
  id: string;
  url: string;
  short_url: string;
  /** Full resolution image. */
  path: string;
  resolution: string;
  ratio: string;
  file_size: number;
  file_type: string;
  colors: string[];
  thumbs: {
    large: string;
    original: string;
    small: string;
  };
}

export interface SearchResponse {
  data: Wallpaper[];
  meta: {
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
  };
}

interface Preferences {
  dotfilesPath?: string;
  wallpaperDir?: string;
  minResolution?: string;
  columns?: string;
  apiKey?: string;
}

export function getPreferences(): Required<Omit<Preferences, "apiKey">> & {
  apiKey?: string;
} {
  const prefs = getPreferenceValues<Preferences>();
  return {
    dotfilesPath: prefs.dotfilesPath?.trim() || "~/projects/personal/dotfiles",
    wallpaperDir: prefs.wallpaperDir?.trim() || "~/Pictures/Wallpapers",
    minResolution: prefs.minResolution?.trim() || "1920x1080",
    columns: prefs.columns?.trim() || "4",
    apiKey: prefs.apiKey?.trim() || undefined,
  };
}

/**
 * An empty query falls back to the monthly toplist, so the grid opens populated
 * instead of blank.
 */
export function buildSearchUrl(query: string, page: number): string {
  const { minResolution, apiKey } = getPreferences();
  const trimmed = query.trim();

  const params = new URLSearchParams({
    categories: "100", // general only
    purity: "100", // sfw only
    atleast: minResolution,
    page: String(page),
  });

  if (trimmed) {
    params.set("q", trimmed);
    params.set("sorting", "relevance");
  } else {
    params.set("sorting", "toplist");
    params.set("topRange", "1M");
  }

  if (apiKey) {
    params.set("apikey", apiKey);
  }

  return `https://wallhaven.cc/api/v1/search?${params.toString()}`;
}

export function formatFileSize(bytes: number): string {
  const mb = bytes / (1024 * 1024);
  return mb >= 1 ? `${mb.toFixed(1)} MB` : `${Math.round(bytes / 1024)} KB`;
}
