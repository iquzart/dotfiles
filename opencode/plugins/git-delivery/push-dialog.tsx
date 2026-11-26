import type { Plugin } from "@opencode/plugin/tui"
import { TextAttributes } from "@opentui/core"
import { GitDialogRow, showGitDialog } from "./git-dialog"

export function confirmPush(context: Plugin.Context, preview: {
  branch: string
  upstream: string
  directory: string
  commits: string
}) {
  const theme = () => context.theme.surface("dialog")
  return showGitDialog(context, { title: "Push branch?", action: "Push" }, () => (
    <>
      <box flexDirection="column">
        <GitDialogRow context={context} label="Branch" value={preview.branch} />
        <GitDialogRow context={context} label="Upstream" value={preview.upstream} highlight />
        <GitDialogRow context={context} label="Directory" value={preview.directory} />
      </box>
      <box flexDirection="column">
        <text fg={theme().text.feedback.info.base} attributes={TextAttributes.BOLD}>Commits to push</text>
        <text fg={theme().text.base} wrapMode="word">{preview.commits}</text>
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
