# Repro: animated GIFs freeze on first frame (react-native-macos)

There are three ways to reproduce the bug, from cheapest to most realistic.

## 1. Native harness (about 5 s, no app build needed)

`native/` compiles the **real** `RCTPlatformDisplayLink.m` and `RCTDisplayWeakRefreshable.mm` from a
react-native-macos checkout. It then drives them the same way `RCTUIImageViewAnimated` does:
the view owns the link, `-dealloc` invalidates it, and the link is added to the main run loop in
common modes. The harness counts `displayDidRefresh:` callbacks over 0.5 s.

```sh
./native/run.sh /path/to/react-native-macos
```

Unpatched `main` (39431293dc) and `0.83-stable`:

```
ticks in 0.5s:           0  (BUG, frozen on first frame)
view deallocated:        yes
display link deallocated: yes
```

With the fix:

```
ticks in 0.5s:           60  (OK, animating)
view deallocated:        yes
display link deallocated: yes
```

The exit code is 0 only if the view ticks **and** both the view and the link are freed, so the
harness also catches a fix that leaks.

## 2. RNTester

RNTester (macOS) → **Image** → **Animated GIF**. The GIF shows its first frame and never advances.

## 3. Fresh app

Use `App.tsx` in this folder as the root component of a new react-native-macos app.
