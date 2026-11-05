**Title:** fix(macos): animated images (GIF) freeze on first frame

## Summary:

Fixes #<issue>.

On macOS, an animated GIF rendered by `<Image>` shows only its first frame. This happens on both Fabric and Paper,
because both go through `RCTUIImageViewAnimated`.

`RCTUIImageViewAnimated` gets its display link from `+[RCTDisplayWeakRefreshable displayLinkWithWeakRefreshable:]`.
That method wraps the view in an `RCTDisplayWeakRefreshable` proxy and makes the proxy the link's target.
The proxy exists because `CADisplayLink` **retains** its target: without it, view → link → view would be a retain cycle.

`RCTPlatformDisplayLink`, the macOS stand-in for `CADisplayLink`, holds its target **weakly** (`__weak id _target`).
On macOS nothing owns the proxy, so it is deallocated as soon as `displayLinkWithWeakRefreshable:` returns.
The `CVDisplayLink` keeps firing, but `-tick` messages `nil`, and the view never advances past frame 0.

**Fix:** on macOS, make the refreshable itself the link's target and skip the proxy. `RCTPlatformDisplayLink`
already gives the weak reference the proxy was meant to provide, so the proxy only adds an object nobody owns.

- No retain cycle: the view owns the link strongly, and the link refers to the view weakly.
- The view's `-dealloc` still calls `[_displayLink invalidate]`. Any tick queued after that hits a nil weak target and does nothing.
- The iOS path is unchanged; the change is behind `TARGET_OS_OSX`.

### Alternatives considered

- **Retain the proxy** (for example, as an associated object of the link). This works, but keeps an extra
  object and an `objc/runtime` dependency only to recreate a weak reference that `RCTPlatformDisplayLink` already provides.
- **Make `RCTPlatformDisplayLink._target` strong**, which matches `CADisplayLink`. This would create retain cycles in
  every caller that passes `self` and relies on the weak reference today (`RCTDisplayLink`, `RCTNativeAnimatedNodesManager`,
  `RCTPerfMonitor`, `RCTAnimatedModuleProvider`). That is a wider behaviour change than this bug needs.

## Test Plan:

**Standalone native repro** (<link to gist>). It compiles the real `RCTPlatformDisplayLink.m` and
`RCTDisplayWeakRefreshable.mm`, uses them the same way `RCTUIImageViewAnimated` does, counts
`displayDidRefresh:` calls over 0.5 s, and then releases the view.

| | ticks / 0.5 s | view freed | link freed |
|---|---|---|---|
| before | 0 | yes | yes |
| after | 60 (120 Hz display) | yes | yes |

**iOS:** the patched file compiles for `arm64-apple-ios15.0-simulator`, and the `!TARGET_OS_OSX` branch is byte-for-byte the old code.

**RNTester (macOS):**
- [ ] Image → Animated GIF animates (it was frozen before).
- [ ] A GIF with a finite loop count stops after its last loop. A GIF with `NETSCAPE2.0` loop count 0 keeps looping.
- [ ] Leaving the Image screen frees `RCTUIImageViewAnimated` and `RCTPlatformDisplayLink` (Xcode Memory Graph), and the CVDisplayLink stops.
- [ ] Static images create no display link (`-displayLink` returns early when `_animatedImage` is nil; this is unchanged).
