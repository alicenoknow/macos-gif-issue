**Title:** Animated GIFs only show their first frame on macOS

### Environment

```markdown
react-native-macos: 0.83.0 (also reproduced on main @ 39431293dc)
Architecture: New Architecture (Fabric). Paper should be affected too, since both use RCTUIImageViewAnimated (not tested).
macOS: 14+ (reproduced on 26.6.2, 25G83)
Xcode: 27.2 (27B52)
```

### Steps to reproduce the bug

1. Render any animated GIF with `<Image>`:
   ```tsx
   <Image source={require('./animated.gif')} style={{width: 200, height: 200}} />
   ```
   Or open RNTester → Image → **Animated GIF**.
2. Check the GIF.

### Expected Behavior

The GIF animates, and stops after its loop count if it has one.

### Actual Behavior

The first frame stays on screen. `onLoad` fires and no error is reported.

### Reproducible Demo

RNTester → Image → **Animated GIF**.

On `main` this example is hidden by an unrelated RNTester bug: `RNTesterModuleContainer` hides an example when
`Platform.OS !== platform`, and this example uses `platform: ['ios', 'macos']`, which never equals a string. That is fixed in #3164. To see the example:

1. Check out #3164 (`gh pr checkout 3164`), or in `packages/rn-tester/js/components/RNTesterModuleContainer.js` change
   ```js
   if (platform != null && Platform.OS !== platform) {
   ```
   to
   ```js
   if (platform != null && !(Array.isArray(platform) ? platform.includes(Platform.OS) : Platform.OS === platform)) {
   ```
2. Run RNTester-macOS, open **Image**, and type "gif" in the filter.

The card "Animated GIF (ios,macos only)" shows the first frame of the GIF and never changes.

<before.mp4>

