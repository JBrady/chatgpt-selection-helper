# Manual QA Checklist

## Core Path

- Highlight text in Safari -> trigger hotkey -> ChatGPT comes front -> text inserted.
- Highlight text in Notes -> trigger -> text inserted.
- Highlight text in VS Code -> trigger -> text inserted.

## Capture Fallback

- Validate at least one app/state where pasteboard capture is empty and AX fallback succeeds.

## Clipboard Safety

- Set clipboard with plain text before run; confirm it is restored after run.
- Set clipboard with rich/non-text content before run; confirm it is restored after run.
- During helper flow, manually copy new text in another app; confirm restore outcome is `skipped_user_changed` and clipboard is not overwritten.

## Prompt Focus

- ChatGPT prompt already focused: first paste path works.
- ChatGPT prompt not focused: AX focus fallback path succeeds.

## Permissions UX

- Remove Accessibility permission and trigger flow.
- Confirm permission alert appears and Open Settings opens the Accessibility pane.

## Guardrails

- Select >20k chars and trigger.
- Confirm truncation toast appears and text is truncated with `[truncated]` marker.

## Telemetry / Debug

- Perform a run, click `Copy Debug Info`, paste into a text editor.
- Confirm fields present: capture_path, capture_len, focus_path, paste_attempts, paste_result, restore_outcome, error_code.
- Confirm no selected text content appears in debug output.
