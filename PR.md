**Title:** fix(macos): animated images (GIF) freeze on first frame

## Summary:

Fixes #3165.

On macOS, animated GIFs in `<Image>` show only their first frame.

`RCTUIImageViewAnimated` gets its display link from `+[RCTDisplayWeakRefreshable displayLinkWithWeakRefreshable:]`,
which makes a weak proxy the link's target. On iOS that is needed because `CADisplayLink` retains its target. On macOS,
`RCTPlatformDisplayLink` holds its target weakly, so nothing owns the proxy. It is freed as soon as the method
returns, and the link's ticks go to `nil`.

**Fix:** on macOS, make the view itself the link's target. The link already holds it weakly, so there is no retain
cycle. iOS is unchanged.

## Test Plan:

RNTester (macOS, Fabric) → Image → Animated GIF. On `main` that example is hidden by an RNTester bug that #3164 fixes.

<before-after.mp4>

- Before: the GIF stays on its first frame. After: it animates.