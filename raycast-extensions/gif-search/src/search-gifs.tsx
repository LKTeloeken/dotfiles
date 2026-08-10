import { Action, ActionPanel, Grid, Icon, Keyboard } from "@raycast/api";
import { useFetch } from "@raycast/utils";
import { useState } from "react";
import { downloadGif } from "./lib/download";
import {
  buildUrl,
  dimensions,
  fullUrl,
  getPreferences,
  hasMore,
  parseGiphyResponse,
  previewUrl,
  type Gif,
  type GiphyResponse,
} from "./lib/giphy";

export default function SearchGifs() {
  const [searchText, setSearchText] = useState("");
  const { columns } = getPreferences();

  const { isLoading, data, pagination } = useFetch(
    // A url-building function is what makes useFetch return the `pagination`
    // object that drives the Grid's infinite scroll.
    (options) => buildUrl(searchText, options.page),
    {
      parseResponse: parseGiphyResponse,
      mapResult(result: GiphyResponse) {
        return { data: result.data, hasMore: hasMore(result.pagination) };
      },
      // Without this the grid empties on every keystroke and flickers.
      keepPreviousData: true,
      initialData: [] as Gif[],
    },
  );

  return (
    <Grid
      isLoading={isLoading}
      pagination={pagination}
      columns={Number(columns)}
      aspectRatio="16/9"
      // Contain rather than Fill: GIFs come in wildly different shapes and
      // cropping them hides the punchline.
      fit={Grid.Fit.Contain}
      inset={Grid.Inset.Small}
      searchText={searchText}
      onSearchTextChange={setSearchText}
      // GIPHY already filtered; local filtering would fight the pagination.
      filtering={false}
      throttle
      searchBarPlaceholder="Search GIPHY…"
    >
      <Grid.EmptyView
        icon={Icon.Video}
        title={isLoading ? "Searching…" : "No GIFs found"}
        description={isLoading ? undefined : "Try a different search term."}
      />
      {data.map((gif) => (
        <Grid.Item
          key={gif.id}
          id={gif.id}
          content={previewUrl(gif)}
          title={gif.title?.trim() || "Untitled"}
          subtitle={dimensions(gif)}
          actions={
            <ActionPanel>
              <Action.Paste title="Paste GIF URL" content={fullUrl(gif)} />
              <Action.CopyToClipboard
                title="Copy GIF URL"
                content={fullUrl(gif)}
              />
              <Action.CopyToClipboard
                title="Copy as Markdown"
                content={`![${gif.title?.trim() || "gif"}](${fullUrl(gif)})`}
                shortcut={{ modifiers: ["cmd", "shift"], key: "m" }}
              />
              <Action
                title="Download GIF"
                icon={Icon.Download}
                shortcut={{ modifiers: ["cmd", "shift"], key: "d" }}
                onAction={() => downloadGif(gif)}
              />
              <Action.OpenInBrowser
                title="Open on Giphy"
                url={gif.url}
                shortcut={Keyboard.Shortcut.Common.OpenWith}
              />
            </ActionPanel>
          }
        />
      ))}
    </Grid>
  );
}
