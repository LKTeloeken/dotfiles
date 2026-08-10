import { Action, ActionPanel, Grid, Icon } from "@raycast/api";
import { useFetch } from "@raycast/utils";
import { useState } from "react";
import { applyWallpaper } from "./lib/apply";
import {
  buildSearchUrl,
  formatFileSize,
  getPreferences,
  type SearchResponse,
  type Wallpaper,
} from "./lib/wallhaven";

export default function SearchWallpapers() {
  const [searchText, setSearchText] = useState("");
  const { columns } = getPreferences();

  const { isLoading, data, pagination } = useFetch(
    // useFetch turns a url-building function into a paginated source; the
    // returned `pagination` drives the Grid's infinite scroll.
    (options) => buildSearchUrl(searchText, options.page + 1),
    {
      mapResult(result: SearchResponse) {
        return {
          data: result.data,
          hasMore: result.meta.current_page < result.meta.last_page,
        };
      },
      // Without this the grid empties on every keystroke and flickers.
      keepPreviousData: true,
      initialData: [] as Wallpaper[],
    },
  );

  return (
    <Grid
      isLoading={isLoading}
      pagination={pagination}
      columns={Number(columns)}
      aspectRatio="16/9"
      fit={Grid.Fit.Fill}
      inset={Grid.Inset.Zero}
      searchText={searchText}
      onSearchTextChange={setSearchText}
      // Results come from the API already filtered; throttling is also what
      // keeps us under wallhaven's 45 requests/minute.
      filtering={false}
      throttle
      searchBarPlaceholder="Search wallhaven…"
    >
      <Grid.EmptyView
        icon={Icon.Image}
        title={isLoading ? "Searching…" : "No wallpapers found"}
        description={isLoading ? undefined : "Try a different search term."}
      />
      {data.map((wallpaper) => (
        <Grid.Item
          key={wallpaper.id}
          id={wallpaper.id}
          content={wallpaper.thumbs.large}
          title={wallpaper.resolution}
          subtitle={formatFileSize(wallpaper.file_size)}
          actions={
            <ActionPanel>
              <Action
                title="Set as Wallpaper"
                icon={Icon.Desktop}
                onAction={() => applyWallpaper(wallpaper)}
              />
              {/* Raycast already binds cmd+enter to the second action. */}
              <Action.OpenInBrowser
                title="Open on Wallhaven"
                url={wallpaper.url}
              />
              <Action.CopyToClipboard
                title="Copy Image URL"
                content={wallpaper.path}
                shortcut={{ modifiers: ["cmd"], key: "c" }}
              />
            </ActionPanel>
          }
        />
      ))}
    </Grid>
  );
}
