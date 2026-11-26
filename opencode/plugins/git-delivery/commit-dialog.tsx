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
  const widestCount = Math.max("Lines".length, ...files.map(({ count }) => count.length))
  const graphWidth = Math.max(0, ...files.map(({ added, removed }) => added.length + removed.length))
  const compact = () => dimensions().width < 76
  const countWidth = () => Math.min(widestCount, compact() ? 9 : 18)
  const diffWidth = () => compact() ? 4 : Math.max(4, graphWidth)

  return (
    <>
      <box flexDirection="column" paddingX={1} border={["left"]}
        borderColor={headingColor()} backgroundColor={theme().background.raised.base}>
        <text fg={headingColor()} attributes={TextAttributes.BOLD}>Commit message</text>
        <text fg={theme().text.base} attributes={TextAttributes.BOLD} wrapMode="word">{props.preview.message}</text>
      </box>

      <box flexDirection="column">
        <text fg={headingColor()} attributes={TextAttributes.BOLD}>Commit target</text>
        <GitDialogRow context={props.context} label="Branch" value={props.preview.branch} highlight />
        <GitDialogRow context={props.context} label="Directory" value={props.preview.directory} />
      </box>

      <box flexDirection="column">
        <text fg={headingColor()} attributes={TextAttributes.BOLD}>Staged changes</text>
        <text fg={theme().text.muted} wrapMode="word">{totals}</text>
        <box flexDirection="column" marginTop={1} paddingX={1} border={["left"]}
          borderColor={headingColor()} backgroundColor={theme().background.raised.base}>
          <box flexDirection="row" gap={1}>
            <text flexGrow={1} flexBasis={0} minWidth={0} fg={theme().text.muted}>File</text>
            <text width={countWidth()} flexShrink={0} fg={theme().text.muted}>{"Lines".padStart(countWidth())}</text>
            <Show when={graphWidth > 0}>
              <text width={diffWidth()} flexShrink={0} fg={theme().text.muted}>Diff</text>
            </Show>
          </box>
          <For each={files}>{(file) => (
            <box flexDirection="row" gap={1} alignItems="flex-start">
              <text minWidth={0} flexBasis={0} flexGrow={1} fg={theme().text.base} wrapMode="char">{file.path}</text>
              <text width={countWidth()} flexShrink={0} fg={theme().text.muted}
                wrapMode="char">{file.count.padStart(countWidth())}</text>
              <Show when={graphWidth > 0}>
                <box width={diffWidth()} flexShrink={0} flexDirection="row">
                  <text fg={theme().diff.text.added}>{compact() ? file.added.slice(0, 1) : file.added}</text>
                  <text fg={theme().diff.text.removed}>{compact() ? file.removed.slice(0, 1) : file.removed}</text>
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

export async function showCommitCandidates(context: Plugin.Context, output: string, usage: string) {
  const theme = () => context.theme.surface("dialog")
  const [, ...files] = output.split("\n")

  await showGitDialog(context, { title: "Nothing staged", tone: "warning" }, () => (
    <Show when={files.length > 0}
      fallback={<text fg={theme().text.base}>There are no changes to commit.</text>}>
      <text fg={theme().text.base} wrapMode="word">{usage}</text>
      <box flexDirection="column" paddingX={1} border={["left"]}
        borderColor={theme().text.feedback.info.base} backgroundColor={theme().background.raised.base}>
        <text fg={theme().text.feedback.info.base} attributes={TextAttributes.BOLD}>Working tree changes</text>
        <For each={files}>{(line) => {
          if (line === "(more paths omitted)") return <text fg={theme().text.muted}>{line}</text>
          const status = line.slice(0, 2).trim()
          const color = () => status === "??" ? theme().diff.text.added
            : status.includes("D") ? theme().diff.text.removed : theme().text.feedback.warning.base
          return (
            <box flexDirection="row" gap={1} alignItems="flex-start">
              <text width={2} flexShrink={0} fg={color()} attributes={TextAttributes.BOLD}>{status}</text>
              <text flexGrow={1} minWidth={0} fg={theme().text.base} wrapMode="char">{line.slice(3)}</text>
            </box>
          )
        }}</For>
      </box>
    </Show>
  ))
}

export async function showCommitFailure(context: Plugin.Context, message: string) {
  await showGitDialog(context, { title: "Commit failed", tone: "error" }, () => (
    <text fg={context.theme.surface("dialog").text.base} wrapMode="word">{message}</text>
  ))
}
