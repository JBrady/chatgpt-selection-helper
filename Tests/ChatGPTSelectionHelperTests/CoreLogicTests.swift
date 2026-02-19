import Testing
@testable import ChatGPTSelectionHelper

struct CoreLogicTests {
    @Test
    func quotedContextFormatting() {
        let formatted = formatSelection("hello", mode: .quotedContext)
        #expect(formatted == "Quoted context:\n\"\"\"\nhello\n\"\"\"")
    }

    @Test
    func truncatesAtConfiguredLength() {
        let input = String(repeating: "a", count: 25)
        let result = truncateSelection(input, maxChars: 20)
        #expect(result.truncated)
        #expect(result.output.hasSuffix("[truncated]"))
        #expect(result.output.count > 20)
    }

    @Test
    func noTruncationWhenUnderLimit() {
        let result = truncateSelection("abc", maxChars: 20)
        #expect(!result.truncated)
        #expect(result.output == "abc")
    }

    @Test
    func restoreDecisionRestored() {
        let outcome = restoreOutcomeDecision(currentChangeCount: 5, initialChangeCount: 2, latestFlowChangeCount: 5)
        #expect(outcome == .restored)
    }

    @Test
    func restoreDecisionSkippedUserChanged() {
        let outcome = restoreOutcomeDecision(currentChangeCount: 9, initialChangeCount: 2, latestFlowChangeCount: 5)
        #expect(outcome == .skippedUserChanged)
    }

    @Test
    func restoreDecisionNotNeeded() {
        let outcome = restoreOutcomeDecision(currentChangeCount: 2, initialChangeCount: 2, latestFlowChangeCount: 5)
        #expect(outcome == .notNeeded)
    }

    @Test
    func pasteDeltaSuccessWhenLengthIncreases() {
        let success = pasteValueDeltaSucceeded(beforeLength: 10, afterLength: 24)
        #expect(success == true)
    }

    @Test
    func pasteDeltaFailureWhenLengthDoesNotIncrease() {
        let success = pasteValueDeltaSucceeded(beforeLength: 10, afterLength: 8)
        #expect(success == false)
    }

    @Test
    func pasteDeltaUnknownWhenValuesUnreadable() {
        let success = pasteValueDeltaSucceeded(beforeLength: nil, afterLength: 5)
        #expect(success == nil)
    }
}
