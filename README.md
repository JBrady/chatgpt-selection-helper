# chatgpt-selection-helper

Standalone macOS menubar helper app that sends selected text from any app into the ChatGPT macOS prompt.

## Features (MVP)

- Global hotkey trigger (default: Cmd+Shift+Space)
- Menubar actions:
  - Send Selection to ChatGPT
  - Copy Debug Info
  - Settings
  - Quit
- Capture strategy:
  - Primary: synthetic Cmd+C + pasteboard read
  - Fallback: Accessibility (`AXSelectedText`, then selected range)
- Clipboard safety:
  - Full snapshot of all pasteboard items/UTIs/data
  - Conditional restore using `changeCount`
  - Restore outcomes: `restored`, `skipped_user_changed`, `not_needed`
- Delivery strategy:
  - Activate/launch ChatGPT (`com.openai.chat` by default)
  - Paste attempt assuming focus
  - AX focus fallback then second paste
- Guardrails:
  - Max char cap (default 20,000) with truncation marker
  - Permission UX for missing Accessibility access
- Lightweight telemetry:
  - `os.Logger` metadata-only run reports
  - Copy recent run summaries for bug reports

## Build and Run (Xcode App Target)

Prerequisite:

```bash
brew install xcodegen
```

Generate/open the Xcode project:

```bash
xcodegen generate
open ChatGPTSelectionHelperApp.xcodeproj
```

Build from CLI:

```bash
xcodebuild -project ChatGPTSelectionHelperApp.xcodeproj -scheme ChatGPTSelectionHelper -configuration Debug build
```

Run from CLI:

```bash
xcodebuild -project ChatGPTSelectionHelperApp.xcodeproj -scheme ChatGPTSelectionHelper -configuration Debug -destination 'platform=macOS' build
open ~/Library/Developer/Xcode/DerivedData/ChatGPTSelectionHelperApp-*/Build/Products/Debug/ChatGPTSelectionHelper.app
```

Run from Xcode:

1. Open `ChatGPTSelectionHelperApp.xcodeproj`
2. Select scheme `ChatGPTSelectionHelper`
3. Press Run (`Cmd+R`)

Stable bundle ID: `com.johnbrady.chatgpt-selection-helper`

Code signing is configured as Automatic (Sign to Run Locally by default).

## Build and Run (SwiftPM)

```bash
swift build
swift run
```

## Test

```bash
swift test
```

## Permissions

Grant Accessibility permission for the helper app in:

`System Settings -> Privacy & Security -> Accessibility`

Without it, capture/focus/paste automation will fail.

## Privacy

Logs intentionally exclude selected text and clipboard payload content. Only metadata is recorded.
