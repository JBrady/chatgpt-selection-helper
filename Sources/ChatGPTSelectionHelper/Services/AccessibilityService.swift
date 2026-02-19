import AppKit
import ApplicationServices
import Foundation

final class AccessibilityService {
    func selectedTextFromFocusedElement() -> (String, CapturePath)? {
        let system = AXUIElementCreateSystemWide()
        guard let focused = copyAXElementAttribute(kAXFocusedUIElementAttribute as CFString, from: system) else {
            return nil
        }

        if let selected = copyStringAttribute(kAXSelectedTextAttribute as CFString, from: focused),
           !selected.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            return (selected, .axSelectedText)
        }

        guard let selectedRangeRaw = copyAttribute(kAXSelectedTextRangeAttribute as CFString, from: focused),
              let fullValue = copyStringAttribute(kAXValueAttribute as CFString, from: focused)
        else {
            return nil
        }
        let selectedRangeValue = selectedRangeRaw as! AXValue
        guard AXValueGetType(selectedRangeValue) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(selectedRangeValue, .cfRange, &range) else {
            return nil
        }

        guard range.length > 0,
              range.location >= 0,
              range.location + range.length <= fullValue.utf16.count
        else {
            return nil
        }

        let nsValue = fullValue as NSString
        let substring = nsValue.substring(with: NSRange(location: range.location, length: range.length))
        if substring.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            return nil
        }
        return (substring, .axRange)
    }

    func isFocusedElementEditable(in app: NSRunningApplication?) -> Bool {
        guard let focused = focusedElement(in: app) else {
            return false
        }
        return isEditableElement(focused)
    }

    func focusedEditableValueLength(in app: NSRunningApplication?) -> Int? {
        guard let focused = focusedElement(in: app), isEditableElement(focused) else {
            return nil
        }

        if let text = copyStringAttribute(kAXValueAttribute as CFString, from: focused) {
            return text.count
        }

        guard let attributed = copyAttribute(kAXValueAttribute as CFString, from: focused) as? NSAttributedString else {
            return nil
        }
        return attributed.string.count
    }

    func focusLikelyInputField(in app: NSRunningApplication) -> Bool {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        if let focused = copyAXElementAttribute(kAXFocusedUIElementAttribute as CFString, from: appElement),
           isEditableElement(focused) {
            return setFocusedAttribute(on: focused)
        }

        guard let windows = copyAXElementArrayAttribute(kAXWindowsAttribute as CFString, from: appElement) else {
            return false
        }

        for window in windows {
            if let input = findFirstEditableElement(in: window, depth: 0, maxDepth: 8) {
                return setFocusedAttribute(on: input)
            }
        }
        return false
    }

    private func findFirstEditableElement(in element: AXUIElement, depth: Int, maxDepth: Int) -> AXUIElement? {
        if depth > maxDepth {
            return nil
        }
        if isEditableElement(element) {
            return element
        }

        guard let children = copyAXElementArrayAttribute(kAXChildrenAttribute as CFString, from: element) else {
            return nil
        }
        for child in children {
            if let found = findFirstEditableElement(in: child, depth: depth + 1, maxDepth: maxDepth) {
                return found
            }
        }
        return nil
    }

    private func isEditableElement(_ element: AXUIElement) -> Bool {
        let role = copyStringAttribute(kAXRoleAttribute as CFString, from: element)
        let editableRoles: Set<String> = [kAXTextFieldRole as String, kAXTextAreaRole as String]
        guard let role, editableRoles.contains(role) else {
            return false
        }

        if let enabled = copyBoolAttribute(kAXEnabledAttribute as CFString, from: element) {
            return enabled
        }
        return true
    }

    private func setFocusedAttribute(on element: AXUIElement) -> Bool {
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue) == .success
    }

    private func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            return nil
        }
        return value
    }

    private func copyAXElementAttribute(_ attribute: CFString, from element: AXUIElement) -> AXUIElement? {
        guard let value = copyAttribute(attribute, from: element) else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private func copyAXElementArrayAttribute(_ attribute: CFString, from element: AXUIElement) -> [AXUIElement]? {
        copyAttribute(attribute, from: element) as? [AXUIElement]
    }

    private func copyStringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        copyAttribute(attribute, from: element) as? String
    }

    private func copyBoolAttribute(_ attribute: CFString, from element: AXUIElement) -> Bool? {
        copyAttribute(attribute, from: element) as? Bool
    }

    private func focusedElement(in app: NSRunningApplication?) -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        guard let focused = copyAXElementAttribute(kAXFocusedUIElementAttribute as CFString, from: system) else {
            return nil
        }

        if let app {
            var pid: pid_t = 0
            AXUIElementGetPid(focused, &pid)
            if pid != app.processIdentifier {
                return nil
            }
        }
        return focused
    }
}
