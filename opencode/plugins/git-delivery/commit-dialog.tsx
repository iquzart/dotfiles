import type { Plugin } from "@opencode/plugin/tui"
import { TextAttributes } from "@opentui/core"
import { useTerminalDimensions } from "@opentui/solid"
import { For, Show } from "solid-js"
import { GitDialogRow, showGitDialog } from "./git-dialog"

type CommitPreview = {
  message: string
  branch: string
  directory: string
  stat: string
}

function CommitDetails(props: {
  context: Plugin.Context
  preview: CommitPreview
}) {
  const dimensions = useTerminalDimensions()
  const theme = () => props.context.theme.surface("dialog")
  const headingColor = () => theme().text.feedback.info.base
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
  return (
    <>
      <box flexDirection="column">
        <text fg={headingColor()} attributes={TextAttributes.BOLD}>Commit message</text>
        <text fg={theme().text.base} attributes={TextAttributes.BOLD} wrapMode="word">{props.preview.message}</text>
      </box>

      <box flexDirection="column">
        <GitDialogRow context={props.context} label="Branch" value={props.preview.branch} highlight />
        <GitDialogRow context={props.context} label="Directory" value={props.preview.directory} />
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
    </>
  )
}

export function confirmCommit(context: Plugin.Context, preview: CommitPreview) {
  return showGitDialog(context, { title: "Commit staged changes?", action: "Commit" }, () => (
    <CommitDetails context={context} preview={preview} />
  ))
}
