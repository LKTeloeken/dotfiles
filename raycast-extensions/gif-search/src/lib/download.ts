import { Toast, showToast, open } from "@raycast/api";
import { mkdir, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";
import { fullUrl, getPreferences, type Gif } from "./giphy";

/** The folder preference is a plain text field, so "~" arrives unexpanded. */
function expandHome(input: string): string {
  if (input === "~") return homedir();
  if (input.startsWith("~/")) return path.join(homedir(), input.slice(2));
  return input;
}

/** Keeps the filename readable without letting a GIF title break the path. */
function slugify(title: string): string {
  const slug = title
    .toLowerCase()
    .replace(/gif$/i, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 50);
  return slug || "gif";
}

export async function downloadGif(gif: Gif): Promise<void> {
  const { downloadDir } = getPreferences();
  const targetDir = expandHome(downloadDir);
  const destination = path.join(
    targetDir,
    `giphy-${slugify(gif.title)}-${gif.id}.gif`,
  );

  const toast = await showToast({
    style: Toast.Style.Animated,
    title: "Downloading GIF",
  });

  try {
    const response = await fetch(fullUrl(gif));
    if (!response.ok) {
      throw new Error(`GIPHY returned ${response.status} downloading the file`);
    }

    await mkdir(targetDir, { recursive: true });
    await writeFile(destination, Buffer.from(await response.arrayBuffer()));

    toast.style = Toast.Style.Success;
    toast.title = "GIF downloaded";
    toast.message = destination;
    toast.primaryAction = {
      title: "Show in Finder",
      onAction: () => open(targetDir),
    };
  } catch (error) {
    toast.style = Toast.Style.Failure;
    toast.title = "Could not download GIF";
    toast.message = error instanceof Error ? error.message : String(error);
  }
}
