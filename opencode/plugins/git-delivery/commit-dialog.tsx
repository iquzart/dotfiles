import type { Plugin } from "@opencode/plugin/tui"
import { TextAttributes, type ScrollBoxRenderable } from "@opentui/core"
import { useKeyboard, useTerminalDimensions } from "@opentui/solid"
import { For, Show } from "solid-js"

type CommitPreview = {
  message: string
  branch: string
  directory: string
  stat: string
}

function CommitDialog(props: {
  context: Plugin.Context
  preview: CommitPreview
  finish: (confirmed: boolean) => void
}) {
  const dimensions = useTerminalDimensions()
  const theme = () => props.context.theme.surface("dialog")
  const headingColor = () => theme().text.feedback.info.base
  const bodyHeight = () => Math.max(3, dimensions().height - 14)
  const lines = props.preview.stat.split("\n")
  const totals = lines.pop()?.trim() ?? ""
  const files = lines.map((line) => {
    const separator = line.lastIndexOf(" | ")
    if (separator < 0) return { path: line.trim(), count: "", added: "", removed: "" }

    const path = line.slice(0, separator).trim()
    const details = line.slice(separator + 3).trim()
    const [, count, added, removed] = /^(.*?)\s+(\+*)(-*)$/.exec(details) ?? []
    return { path, count: count ?? details, added: added ?? "", removed: removed ?? "" }
  })
  const countWidth = Math.max(0, ...files.map(({ count }) => count.length))
  const graphWidth = Math.max(0, ...files.map(({ added, removed }) => added.length + removed.length))
  const showGraph = () => graphWidth > 0 && dimensions().width >= 76
  let body: ScrollBoxRenderable | undefined

  useKeyboard((event) => {
    if (event.defaultPrevented) return
    if (event.name === "return" && !event.repeated) {
      event.preventDefault()
      props.finish(true)
    } else if (event.name === "up" || event.name === "down") {
      event.preventDefault()
      body?.scrollBy(event.name === "up" ? -1 : 1, "step")
    } else if (event.name === "pageup" || event.name === "pagedown") {
      event.preventDefault()
      body?.scrollBy(event.name === "pageup" ? -1 : 1, "viewport")
    }
  })

  return (
    <box flexDirection="column" gap={1} paddingX={2} paddingY={1} backgroundColor={theme().background.base}>
      <text fg={theme().text.base} attributes={TextAttributes.BOLD}>Commit staged changes?</text>

      <scrollbox ref={(box) => { body = box }} maxHeight={bodyHeight()} flexShrink={1} scrollX={false}>
        <box flexDirection="column" gap={1} paddingRight={1}>
          <box flexDirection="column">
            <text fg={headingColor()} attributes={TextAttributes.BOLD}>Commit message</text>
            <text fg={theme().text.base} attributes={TextAttributes.BOLD} wrapMode="word">{props.preview.message}</text>
          </box>

          <box flexDirection="column">
            <box flexDirection="row" gap={1}>
              <text width={9} flexShrink={0} fg={theme().text.muted}>Branch</text>
              <text minWidth={0} flexGrow={1} fg={headingColor()} wrapMode="char">{props.preview.branch}</text>
            </box>
            <box flexDirection="row" gap={1}>
              <text width={9} flexShrink={0} fg={theme().text.muted}>Directory</text>
              <text minWidth={0} flexGrow={1} fg={theme().text.base} wrapMode="char">{props.preview.directory}</text>
            </box>
          </box>

          <box flexDirection="column">
            <text fg={headingColor()} attributes={TextAttributes.BOLD}>Staged changes</text>
            <text fg={theme().text.muted} wrapMode="word">{totals}</text>
            <box flexDirection="column" marginTop={1}>
              <For each={files}>{(file) => (
                <box flexDirection="row" gap={1} alignItems="flex-start">
                  <text minWidth={0} flexBasis={0} flexGrow={1} fg={theme().text.base} wrapMode="char">{file.path}</text>
                  <text width={countWidth} flexShrink={0} fg={theme().text.muted}>{file.count.padStart(countWidth)}</text>
                  <Show when={showGraph()}>
                    <box width={graphWidth} flexShrink={0} flexDirection="row">
                      <text fg={theme().diff.text.added}>{file.added}</text>
                      <text fg={theme().diff.text.removed}>{file.removed}</text>
                    </box>
                  </Show>
                </box>
              )}</For>
            </box>
          </box>
        </box>
      </scrollbox>

      <box flexDirection="row" gap={1} justifyContent="flex-end" flexShrink={0}>
        <box paddingX={1} backgroundColor={theme().background.action.secondary.base}
          onMouseUp={(event) => { if (event.button === 0) props.finish(false) }}>
          <text fg={theme().text.action.secondary.base}>Esc Cancel</text>
        </box>
        <box paddingX={1} backgroundColor={theme().background.action.primary.base}
          onMouseUp={(event) => { if (event.button === 0) props.finish(true) }}>
          <text fg={theme().text.action.primary.base} attributes={TextAttributes.BOLD}>Enter Commit</text>
        </box>
      </box>
    </box>
  )
}

export function confirmCommit(context: Plugin.Context, preview: CommitPreview) {
  return new Promise<boolean>((resolve) => {
    const dialog = context.ui.dialog
    dialog.show(
      () => <CommitDialog context={context} preview={preview} finish={(confirmed) => {
        resolve(confirmed)
        dialog.clear()
      }} />,
      () => resolve(false),
    )
    dialog.set({ size: "large", centered: true })
  })
}
