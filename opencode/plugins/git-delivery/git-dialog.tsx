import type { Plugin } from "@opencode/plugin/tui"
import { TextAttributes, type ScrollBoxRenderable } from "@opentui/core"
import { useKeyboard, useTerminalDimensions } from "@opentui/solid"
import { Show, type JSX } from "solid-js"

type GitDialogOptions = {
  title: string
  action?: string
  tone?: "success" | "error"
}

function GitDialog(props: GitDialogOptions & {
  context: Plugin.Context
  finish: (confirmed: boolean) => void
  children: JSX.Element
}) {
  const dimensions = useTerminalDimensions()
  const theme = () => props.context.theme.surface("dialog")
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
      <text fg={props.tone ? theme().text.feedback[props.tone].base : theme().text.base}
        attributes={TextAttributes.BOLD}>{props.title}</text>

      <scrollbox ref={(box) => { body = box }} maxHeight={Math.max(3, dimensions().height - 14)}
        flexShrink={1} scrollX={false}>
        <box flexDirection="column" gap={1} paddingRight={1}>{props.children}</box>
      </scrollbox>

      <box flexDirection="row" gap={1} justifyContent="flex-end" flexShrink={0}>
        <Show when={props.action}>
          <box paddingX={1} backgroundColor={theme().background.action.secondary.base}
            onMouseUp={(event) => { if (event.button === 0) props.finish(false) }}>
            <text fg={theme().text.action.secondary.base}>Esc Cancel</text>
          </box>
        </Show>
        <box paddingX={1} backgroundColor={theme().background.action.primary.base}
          onMouseUp={(event) => { if (event.button === 0) props.finish(true) }}>
          <text fg={theme().text.action.primary.base} attributes={TextAttributes.BOLD}>Enter {props.action ?? "Close"}</text>
        </box>
      </box>
    </box>
  )
}

export function GitDialogRow(props: {
  context: Plugin.Context
  label: string
  value: string
  highlight?: boolean
}) {
  const theme = () => props.context.theme.surface("dialog")
  return (
    <box flexDirection="row" gap={1}>
      <text width={9} flexShrink={0} fg={theme().text.muted}>{props.label}</text>
      <text minWidth={0} flexGrow={1} wrapMode="char"
        fg={props.highlight ? theme().text.feedback.info.base : theme().text.base}>{props.value}</text>
    </box>
  )
}

export function showGitDialog(context: Plugin.Context, options: GitDialogOptions, render: () => JSX.Element) {
  return new Promise<boolean>((resolve) => {
    const dialog = context.ui.dialog
    dialog.show(
      () => (
        <GitDialog {...options} context={context} finish={(confirmed) => {
          resolve(confirmed)
          dialog.clear()
        }}>
          {render()}
        </GitDialog>
      ),
      () => resolve(false),
    )
    dialog.set({ size: "large", centered: true })
  })
}
