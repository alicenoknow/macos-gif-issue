// Standalone repro: compiles the real RCTPlatformDisplayLink.m + RCTDisplayWeakRefreshable.mm
// from the react-native-macos checkout and checks whether the refreshable ever gets a callback.
#import <Foundation/Foundation.h>
#import <React/RCTDisplayWeakRefreshable.h>

@interface FakeAnimatedImageView : NSObject <RCTDisplayRefreshable>
@property (nonatomic, strong) RCTPlatformDisplayLink *displayLink; // owned, like RCTUIImageViewAnimated
@property (nonatomic, assign) NSUInteger ticks;
@end

static BOOL gViewDeallocated = NO;

@implementation FakeAnimatedImageView
- (instancetype)init
{
  if (self = [super init]) {
    // Same as RCTUIImageViewAnimated -displayLink
    _displayLink = [RCTDisplayWeakRefreshable displayLinkWithWeakRefreshable:self];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }
  return self;
}
- (void)displayDidRefresh:(RCTPlatformDisplayLink *)displayLink { _ticks++; }
- (void)dealloc
{
  [_displayLink invalidate]; // same as RCTUIImageViewAnimated -dealloc
  gViewDeallocated = YES;
}
@end

int main(void)
{
  @autoreleasepool {
    __weak RCTPlatformDisplayLink *weakLink = nil;
    NSUInteger ticks = 0;
    @autoreleasepool {
      FakeAnimatedImageView *view = [FakeAnimatedImageView new];
      weakLink = view.displayLink;
      [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
      ticks = view.ticks;
      view = nil; // unmount
    }
    // Let any already-queued tick blocks drain after the view is gone (must not crash).
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    printf("ticks in 0.5s:           %lu  (%s)\n", (unsigned long)ticks, ticks > 0 ? "OK, animating" : "BUG, frozen on first frame");
    printf("view deallocated:        %s\n", gViewDeallocated ? "yes" : "NO (leak / retain cycle)");
    printf("display link deallocated: %s\n", weakLink == nil ? "yes" : "NO (leak)");
    return (ticks > 0 && gViewDeallocated && weakLink == nil) ? 0 : 1;
  }
}
