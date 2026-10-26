// RGGState.m — global state: enable/disable/lock, alpha, state, font,
// style, tooltips, icons.

#import "RayguiObjC.h"
#include "raygui.h"
#include <stdio.h>

@implementation RGGui (State)

+ (void)enable {
    GuiEnable();
}

+ (void)disable {
    GuiDisable();
}

+ (void)lock {
    GuiLock();
}

+ (void)unlock {
    GuiUnlock();
}

+ (BOOL)isLocked {
    return (GuiIsLocked() ? YES : NO);
}

+ (void)setAlpha:(float)alpha {
    GuiSetAlpha(alpha);
}

+ (void)setState:(RGGState)state {
    GuiSetState((int)state);
}

+ (RGGState)state {
    return (RGGState)GuiGetState();
}

+ (void)setFont:(Font)font {
    GuiSetFont(font);
}

+ (Font)font {
    return GuiGetFont();
}

+ (void)setStyle:(RGGControl)control property:(RGGProperty)property value:(int)value {
    GuiSetStyle((int)control, (int)property, value);
}

+ (int)style:(RGGControl)control property:(RGGProperty)property {
    return GuiGetStyle((int)control, (int)property);
}

+ (BOOL)loadStyleAtPath:(NSString *)path {
    if (path == nil) return NO;
    // GuiLoadStyle() returns void and silently TRACELOGs on failure, so
    // verify the file opens first (fopen failure => GuiLoadStyle would bail).
    FILE *file = fopen([path UTF8String], "rt");
    if (file == NULL) return NO;
    fclose(file);
    GuiLoadStyle([path UTF8String]);
    return YES;
}

+ (void)loadStyleDefault {
    GuiLoadStyleDefault();
}

+ (void)enableTooltip {
    GuiEnableTooltip();
}

+ (void)disableTooltip {
    GuiDisableTooltip();
}

+ (void)setTooltip:(NSString *)tooltip {
    GuiSetTooltip([tooltip UTF8String]);
}

+ (NSString *)iconText:(int)iconId text:(NSString *)text {
    // GuiIconText() returns a pointer to a static buffer — copy immediately
    // (AGENTS.md §2.5: never store the returned C pointer).
    const char *result = GuiIconText(iconId, [text UTF8String]);
    if (result == NULL) return text;
    return [NSString stringWithUTF8String:result];
}

+ (void)setIconScale:(int)scale {
    GuiSetIconScale(scale);
}

+ (int)textWidth:(NSString *)text {
    return GuiGetTextWidth([text UTF8String]);
}

@end
