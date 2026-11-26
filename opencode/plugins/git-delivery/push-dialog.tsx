import type { Plugin } from "@opencode/plugin/tui"
import { TextAttributes } from "@opentui/core"
import { For, Show } from "solid-js"
import { GitDialogRow, showGitDialog } from "./git-dialog"

type PushTarget = {
  branch: string
  upstream: string
}

export type PushDestination = {
  name: string
  status: "updated" | "created" | "unchanged" | "rejected"
  summary: string
}

const destinationStatuses = {
  updated: { label: "Updated", tone: "success" },
  created: { label: "New branch", tone: "success" },
  unchanged: { label: "Up to date", tone: "info" },
  rejected: { label: "Rejected", tone: "error" },
} as const

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

function PushTargetDetails(props: { context: Plugin.Context; target: PushTarget; directory?: string }) {
  const theme = () => props.context.theme.surface("dialog")
  return (
    <box flexDirection="column">
      <text fg={theme().text.feedback.info.base} attributes={TextAttributes.BOLD}>Push target</text>
      <GitDialogRow context={props.context} label="Branch" value={props.target.branch} />
      <GitDialogRow context={props.context} label="Upstream" value={props.target.upstream} highlight />
      <Show when={props.directory}>{(directory) => (
        <GitDialogRow context={props.context} label="Directory" value={directory()} />
      )}</Show>
    </box>
  )
}

export function confirmPush(context: Plugin.Context, preview: PushTarget & {
  directory: string
  commits: string
}) {
  const theme = () => context.theme.surface("dialog")
  const headingColor = () => theme().text.feedback.info.base
  const groups = outgoingGroups(preview.commits)
  const idWidth = Math.min(12, Math.max(6, ...groups.flatMap(({ entries }) => entries.map(({ id }) => id.length))))

  return showGitDialog(context, { title: "Push branch?", action: "Push" }, () => (
    <>
      <PushTargetDetails context={context} target={preview} directory={preview.directory} />
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
  tone: "success" | "error" | "warning"
  target?: PushTarget
  destinations?: PushDestination[]
  details?: string
}) {
  const theme = () => context.theme.surface("dialog")
  const headingColor = () => theme().text.feedback.info.base

  await showGitDialog(context, { title: options.title, tone: options.tone }, () => (
    <>
      <Show when={options.target}>{(target) => (
        <PushTargetDetails context={context} target={target()} />
      )}</Show>
      <Show when={options.destinations?.length}>
        <box flexDirection="column" gap={1}>
          <text fg={headingColor()} attributes={TextAttributes.BOLD}>Destination status</text>
          <For each={options.destinations}>{(destination) => {
            const status = destinationStatuses[destination.status]
            const statusColor = () => theme().text.feedback[status.tone].base
            return (
              <box flexDirection="column" paddingX={1} border={["left"]}
                borderColor={statusColor()} backgroundColor={theme().background.raised.base}>
                <text fg={theme().text.base} wrapMode="char">{destination.name}</text>
                <box flexDirection="row" gap={2} alignItems="flex-start">
                  <text fg={statusColor()} flexShrink={0} attributes={TextAttributes.BOLD}>{status.label}</text>
                  <text fg={theme().text.muted} minWidth={0} flexGrow={1} wrapMode="word">{destination.summary}</text>
                </box>
              </box>
            )
          }}</For>
        </box>
      </Show>
      <Show when={options.details}>
        <box flexDirection="column">
          <text fg={headingColor()} attributes={TextAttributes.BOLD}>Git details</text>
          <text fg={theme().text.base} wrapMode="word">{options.details}</text>
        </box>
      </Show>
    </>
  ))
}
