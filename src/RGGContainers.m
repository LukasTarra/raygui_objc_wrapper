// RGGContainers.m — containers: window box, group box, panel, line,
// scroll panel, status bar.

#import "RayguiObjC.h"
#include "raygui.h"

@implementation RGGui (Containers)

+ (RGGResult)windowBoxRaw:(Rectangle)bounds title:(NSString *)title {
    return (RGGResult)GuiWindowBox(bounds, [title UTF8String]);
}

+ (BOOL)windowBox:(Rectangle)bounds title:(NSString *)title {
    return ([self windowBoxRaw:bounds title:title] == RGGResultPressed);
}

+ (void)groupBox:(Rectangle)bounds text:(NSString *)text {
    GuiGroupBox(bounds, [text UTF8String]);
}

+ (void)panel:(Rectangle)bounds text:(NSString *)text {
    GuiPanel(bounds, [text UTF8String]);
}

+ (void)line:(Rectangle)bounds text:(NSString *)text {
    GuiLine(bounds, [text UTF8String]);
}

+ (Rectangle)scrollPanel:(Rectangle)bounds content:(Rectangle)content scroll:(Vector2 *)scroll {
    return [self scrollPanel:bounds text:nil content:content scroll:scroll];
}

+ (Rectangle)scrollPanel:(Rectangle)bounds text:(NSString *)text content:(Rectangle)content scroll:(Vector2 *)scroll {
    Rectangle view = { 0 };
    GuiScrollPanel(bounds, [text UTF8String], content, scroll, &view);
    return view;
}

+ (RGGResult)statusBarRaw:(Rectangle)bounds text:(NSString *)text {
    return (RGGResult)GuiStatusBar(bounds, [text UTF8String]);
}

+ (BOOL)statusBar:(Rectangle)bounds text:(NSString *)text {
    return ([self statusBarRaw:bounds text:text] == RGGResultPressed);
}

@end
