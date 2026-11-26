import type { Plugin } from "@opencode/plugin/tui"
import { GitDialogRow, showGitDialog } from "./git-dialog"

export function confirmPush(context: Plugin.Context, preview: {
  branch: string
  upstream: string
  directory: string
}) {
  return showGitDialog(context, { title: "Push branch?", action: "Push" }, () => (
    <box flexDirection="column">
      <GitDialogRow context={context} label="Branch" value={preview.branch} />
      <GitDialogRow context={context} label="Upstream" value={preview.upstream} highlight />
      <GitDialogRow context={context} label="Directory" value={preview.directory} />
    </box>
  ))
}

export async function showPushResult(context: Plugin.Context, output: string, tone: "success" | "error") {
  await showGitDialog(context, { title: tone === "success" ? "Push complete" : "Push failed", tone }, () => (
    <text fg={context.theme.surface("dialog").text.base} wrapMode="word">{output}</text>
  ))
}
