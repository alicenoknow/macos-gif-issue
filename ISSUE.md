**Title:** Animated GIFs only show their first frame on macOS

### Environment

```markdown
react-native-macos: 0.83.0 (also reproduced on main @ 39431293dc)
Architecture: New Architecture (Fabric). Paper is affected too, since both use RCTUIImageViewAnimated.
macOS: 14+ (reproduced on 26.6)
Xcode: <fill in>
```

### Steps to reproduce the bug

1. Render any animated GIF with `<Image>`:
   ```tsx
   <Image source={require('./animated.gif')} style={{width: 200, height: 200}} />
   ```
   Or open RNTester → Image → **Animated GIF**.
2. Watch the image.

### Expected Behavior

The GIF animates, and stops after its loop count if it has one.

### Actual Behavior

The first frame stays on screen. `onLoad` fires and no error is reported.

### Reproducible Demo

- RNTester → Image → Animated GIF
- Standalone native repro (no app build needed): <link to gist with `repro/native`>. It compiles the real
  `RCTPlatformDisplayLink.m` and `RCTDisplayWeakRefreshable.mm` and counts display-link callbacks.
  The count is **0** on `main` and `0.83-stable`.

### Additional context

Decoding is fine: `RCTGIFImageDecoder` returns an `RCTAnimatedImage` with the correct frame count and
durations. The per-frame callback never reaches `RCTUIImageViewAnimated`:

- `RCTUIImageViewAnimated` creates its link with `+[RCTDisplayWeakRefreshable displayLinkWithWeakRefreshable:self]`.
- That method allocates an `RCTDisplayWeakRefreshable` proxy as a local and passes it as the link's target.
- On iOS, `CADisplayLink` retains its target, so the proxy lives as long as the link.
- On macOS, `RCTPlatformDisplayLink` stores `__weak id _target`. Nothing owns the proxy, so it is
  deallocated when `displayLinkWithWeakRefreshable:` returns.
- The `CVDisplayLink` keeps firing, but `-tick` messages `nil`, so the view never moves past frame 0.

The weak `_target` dates from 2019 (5c0c3d40849) and the proxy from 2020 (efc221bd10c), so this has
probably been broken on macOS since the proxy was introduced. Issue #507 / PR #724 enabled GIF
decoding on macOS but didn't touch the display link.
