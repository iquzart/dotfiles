import type { Plugin } from "@opencode/plugin/tui"
import { TextAttributes } from "@opentui/core"
import { For } from "solid-js"
import { GitDialogRow, showGitDialog } from "./git-dialog"

function outgoingGroups(commits: string) {
  return commits.split("\n\n").map((group) => {
    const [destination, count, ...lines] = group.split("\n")
    const entries = lines.map((line) => {
      const id = line.split(" ", 1)[0]
      return { id, subject: line.slice(id.length + 1) }
    })
    return { destination, count, entries }
  })
}

export function confirmPush(context: Plugin.Context, preview: {
  branch: string
  upstream: string
  directory: string
  commits: string
}) {
  const theme = () => context.theme.surface("dialog")
  const headingColor = () => theme().text.feedback.info.base
  const groups = outgoingGroups(preview.commits)
  const idWidth = Math.min(12, Math.max(6, ...groups.flatMap(({ entries }) => entries.map(({ id }) => id.length))))

  return showGitDialog(context, { title: "Push branch?", action: "Push" }, () => (
    <>
      <box flexDirection="column">
        <text fg={headingColor()} attributes={TextAttributes.BOLD}>Push target</text>
        <GitDialogRow context={context} label="Branch" value={preview.branch} />
        <GitDialogRow context={context} label="Upstream" value={preview.upstream} highlight />
        <GitDialogRow context={context} label="Directory" value={preview.directory} />
      </box>
      <box flexDirection="column" gap={1}>
        <text fg={headingColor()} attributes={TextAttributes.BOLD}>Commits to push</text>
        <For each={groups}>{(group) => (
          <box flexDirection="column" paddingX={1} border={["left"]}
            borderColor={headingColor()} backgroundColor={theme().background.raised.base}>
            <text fg={headingColor()} attributes={TextAttributes.BOLD} wrapMode="char">{group.destination}</text>
            <text fg={theme().text.feedback.success.base} wrapMode="word">{group.count}</text>
            <box flexDirection="row" gap={2} marginTop={1}>
              <text width={idWidth} flexShrink={0} fg={theme().text.muted}>Commit</text>
              <text fg={theme().text.muted}>Subject</text>
            </box>
            <For each={group.entries}>{({ id, subject }) => (
              <box flexDirection="row" gap={2} alignItems="flex-start">
                <text width={idWidth} flexShrink={0} wrapMode="char" fg={theme().syntax.number}
                  attributes={TextAttributes.BOLD}>{id}</text>
                <text flexGrow={1} flexBasis={0} minWidth={0} wrapMode="word"
                  fg={subject ? theme().text.base : theme().text.muted}>{subject || "(no subject)"}</text>
              </box>
            )}</For>
          </box>
        )}</For>
      </box>
    </>
  ))
}

export async function showPushResult(context: Plugin.Context, options: {
  title: string
  tone: "success" | "error"
  output: string
}) {
  await showGitDialog(context, { title: options.title, tone: options.tone }, () => (
    <text fg={context.theme.surface("dialog").text.base} wrapMode="word">{options.output}</text>
  ))
}
