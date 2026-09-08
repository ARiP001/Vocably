# Foundation Models Follow-up Notes

## Observed runtime error

Foundation Model requests currently produce errors similar to:

```text
DecodingError.keyNotFound: Key 'thoughtContents' not found
SensitiveContentAnalysisML Code 15
The model com.apple.fm.language.instruct_300m.safety is missing
```

This appears to be an Apple Foundation Models runtime/model-asset problem, not a vocabulary JSON decoding problem. The app's request reaches the framework, but the required safety model is unavailable or incomplete.

## Current impact

- Definition selection may fail.
- Domain-specific example generation may fail.
- Indonesian translation may fail.
- The Mission Detail can fall back to the original English definitions.
- Generated examples and translations may be empty.
- Repeated requests can produce the same system error and unnecessary delays.

## Fixes to add later

### 1. Improve availability handling

- Do not rely only on `SystemLanguageModel.default.isAvailable`.
- Confirm that the required Foundation Model assets are actually usable before starting generation.
- Handle unsupported devices, simulators, missing assets, and model-download states separately.
- Test on a supported physical Apple Intelligence device and the target iOS version.

### 2. Add a single personalization service result

Return an explicit state instead of silently returning empty arrays:

```text
ready
unavailable
modelError
invalidResponse
timedOut
```

The UI should use this state to decide whether to show generated content, fallback content, or a retry action.

### 3. Add a session-level failure circuit breaker

- If Foundation Models fails once with a missing safety/model asset error, stop starting additional requests during that app session.
- Avoid logging the same framework error for every definition and translation request.
- Fall back immediately to local dictionary content after the first confirmed model failure.
- Provide a manual “Try again” action instead of retrying automatically on every screen appearance.

### 4. Make fallback content complete

When AI is unavailable, Mission Detail should still show:

- The original dictionary definitions.
- The original dictionary examples.
- The existing pronunciation and speech controls.
- A clear but user-friendly indication that personalized content is unavailable, if needed.

The fallback should never leave an empty examples section.

### 5. Add loading and retry UI

- Show a local loading state while personalization is being prepared.
- Do not expose raw Foundation Models or `SensitiveContentAnalysisML` errors to users.
- Add a retry button for recoverable failures.
- Keep the basic vocabulary card immediately usable while AI content loads.

### 6. Validate generated output

Before displaying model output:

- Confirm exactly two selected definitions.
- Reject duplicate definition indexes.
- Confirm generated examples are non-empty and limited to two per definition.
- Confirm Indonesian translation arrays match the number of definitions and examples.
- Reject malformed or empty translations and use fallback content.

### 7. Add caching after the POC

Store successful personalized content in SwiftData using a key such as:

```text
word + domain + promptVersion + modelVersion
```

Cache:

- Selected definition indexes.
- Indonesian translations.
- Generated domain examples.
- Generation timestamp.
- Prompt/model version.
- Failure state, if useful for avoiding immediate retries.

### 8. Test matrix

Test the Mission flow with:

- Foundation Models available.
- Foundation Models unavailable.
- Missing safety model assets.
- Model request timeout.
- Malformed model output.
- Empty generated examples.
- Empty Indonesian translation.
- General domain.
- Each supported specific domain.
- Simulator and supported physical device.

## Environment checks before debugging app code

1. Confirm the device and iOS version support Foundation Models.
2. Confirm Apple Intelligence/model assets are enabled and downloaded.
3. Retry on a supported physical device instead of only the simulator.
4. Update iOS/Xcode if the issue persists.
5. Reinstall or refresh model assets if the operating system reports them as missing.

## Priority

1. Make the local fallback complete and reliable.
2. Add a model failure circuit breaker to stop repeated errors.
3. Add explicit loading/error/retry states.
4. Validate Foundation Model output.
5. Add SwiftData caching and prefetching after the POC is stable.

This note intentionally does not cover the item 14 clean-architecture refactor.
