import { getPreferenceValues } from "@raycast/api";

/** Every rendition carries these; sizes arrive as strings. */
export interface Rendition {
  url: string;
  width: string;
  height: string;
  size?: string;
}

export interface Gif {
  id: string;
  url: string;
  title: string;
  rating: string;
  images: Record<string, Rendition | undefined>;
}

export interface GiphyResponse {
  data: Gif[];
  pagination: {
    total_count: number;
    count: number;
    offset: number;
  };
  meta: {
    status: number;
    msg: string;
  };
}

interface Preferences {
  apiKey: string;
  rating?: string;
  columns?: string;
  fit?: string;
  aspectRatio?: string;
  downloadDir?: string;
}

/** The subset of Grid.Props["aspectRatio"] offered in preferences. */
type AspectRatio = "1" | "4/3" | "3/2" | "16/9";

export const PAGE_SIZE = 25;
/** GIPHY rejects an offset past this. */
const MAX_OFFSET = 4999;

export function getPreferences() {
  const prefs = getPreferenceValues<Preferences>();
  return {
    apiKey: prefs.apiKey?.trim() ?? "",
    rating: prefs.rating?.trim() || "g",
    columns: prefs.columns?.trim() || "3",
    fit: prefs.fit?.trim() || "fill",
    aspectRatio: (prefs.aspectRatio?.trim() || "1") as AspectRatio,
    downloadDir: prefs.downloadDir?.trim() || "~/Downloads",
  };
}

/** An empty query browses trending, so the grid opens populated. */
export function buildUrl(query: string, page: number): string {
  const { apiKey, rating } = getPreferences();
  const trimmed = query.trim();
  const endpoint = trimmed ? "search" : "trending";

  // No `bundle` param on purpose: bundles trim which renditions come back, and
  // previewUrl's fallback chain needs the full set to stay reliable.
  const params = new URLSearchParams({
    api_key: apiKey,
    limit: String(PAGE_SIZE),
    offset: String(Math.min(page * PAGE_SIZE, MAX_OFFSET)),
    rating,
  });

  if (trimmed) {
    // GIPHY caps the query at 50 characters.
    params.set("q", trimmed.slice(0, 50));
  }

  return `https://api.giphy.com/v1/gifs/${endpoint}?${params.toString()}`;
}

export function hasMore(pagination: GiphyResponse["pagination"]): boolean {
  const consumed = pagination.offset + pagination.count;
  return consumed < pagination.total_count && consumed <= MAX_OFFSET;
}

/**
 * Renditions vary per GIF, so fall back through a chain rather than trusting a
 * single key to exist. Ordered biggest-first: a grid cell is wider than the
 * 200px `fixed_width` renditions, and upscaling those looks soft and small.
 * `original` is last because it can weigh several MB, times 25 per page.
 */
export function previewUrl(gif: Gif): string {
  const candidates = [
    "downsized_medium",
    "downsized",
    "fixed_width",
    "fixed_width_downsampled",
    "preview_gif",
    "original",
  ];
  for (const name of candidates) {
    const url = gif.images[name]?.url;
    if (url) return url;
  }
  return gif.url;
}

/** Full quality file, for pasting and downloading. */
export function fullUrl(gif: Gif): string {
  return gif.images.original?.url ?? gif.images.downsized?.url ?? gif.url;
}

export function dimensions(gif: Gif): string {
  const image = gif.images.original ?? gif.images.fixed_width;
  return image ? `${image.width}×${image.height}` : "";
}

/**
 * GIPHY answers auth problems with a real HTTP status, but the default fetch
 * error would just say "401". Translate it into something actionable.
 */
export async function parseGiphyResponse(
  response: Response,
): Promise<GiphyResponse> {
  if (response.status === 401 || response.status === 403) {
    throw new Error(
      "GIPHY rejected the API key. Check it in this extension's preferences (⌘,).",
    );
  }
  if (!response.ok) {
    throw new Error(`GIPHY returned ${response.status} ${response.statusText}`);
  }
  return (await response.json()) as GiphyResponse;
}
