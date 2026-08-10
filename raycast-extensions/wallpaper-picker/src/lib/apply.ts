import { Toast, showToast } from "@raycast/api";
import { execFile } from "node:child_process";
import { mkdir, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import { getPreferences, type Wallpaper } from "./wallhaven";

const execFileAsync = promisify(execFile);

/** Preferences are plain text fields, so "~" arrives unexpanded. */
function expandHome(input: string): string {
  if (input === "~") return homedir();
  if (input.startsWith("~/")) return path.join(homedir(), input.slice(2));
  return input;
}

async function exists(target: string): Promise<boolean> {
  try {
    await stat(target);
    return true;
  } catch {
    return false;
  }
}

async function download(
  wallpaper: Wallpaper,
  destination: string,
): Promise<void> {
  const response = await fetch(wallpaper.path);
  if (!response.ok) {
    throw new Error(
      `wallhaven returned ${response.status} downloading the full resolution image`,
    );
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  await writeFile(destination, buffer);
}

/**
 * Downloads the full resolution image and hands it to the repo's
 * scripts/set_wallpaper.sh, which applies it across every display and re-runs
 * sync_colors.sh (which itself reloads sketchybar).
 */
export async function applyWallpaper(wallpaper: Wallpaper): Promise<void> {
  const { wallpaperDir, dotfilesPath } = getPreferences();

  const targetDir = expandHome(wallpaperDir);
  const extension = path.extname(new URL(wallpaper.path).pathname) || ".jpg";
  const destination = path.join(
    targetDir,
    `wallhaven-${wallpaper.id}${extension}`,
  );
  const script = path.join(
    expandHome(dotfilesPath),
    "scripts",
    "set_wallpaper.sh",
  );

  if (!(await exists(script))) {
    await showToast({
      style: Toast.Style.Failure,
      title: "set_wallpaper.sh not found",
      message: `Looked in ${script}. Check the Dotfiles Path preference.`,
    });
    return;
  }

  const toast = await showToast({
    style: Toast.Style.Animated,
    title: "Downloading wallpaper",
  });

  try {
    await mkdir(targetDir, { recursive: true });

    if (await exists(destination)) {
      toast.title = "Already downloaded";
    } else {
      await download(wallpaper, destination);
    }

    toast.title = "Applying and syncing colors";
    // The script also triggers pywal and `sketchybar --reload`, so this can take
    // a few seconds.
    await execFileAsync(script, ["-y", destination], { timeout: 120_000 });

    toast.style = Toast.Style.Success;
    toast.title = "Wallpaper set";
    toast.message = `${wallpaper.resolution} · palette synced`;
  } catch (error) {
    toast.style = Toast.Style.Failure;
    toast.title = "Could not set wallpaper";
    toast.message = error instanceof Error ? error.message : String(error);
  }
}
