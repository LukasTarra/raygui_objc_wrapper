// RGGAdvanced.m — advanced controls: list view, color controls, dialogs, tab bar.

#import "RayguiObjC.h"
#include "raygui.h"
#include <stdio.h>

@implementation RGGui (Advanced)

+ (RGGResult)listViewRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected scrollIndex:(int *)scroll {
    return (RGGResult)GuiListView(bounds, [RGGJoinItems(items) UTF8String], scroll, selected);
}

+ (BOOL)listView:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected scrollIndex:(int *)scroll {
    return ([self listViewRaw:bounds items:items selected:selected scrollIndex:scroll] == RGGResultChanged);
}

+ (RGGResult)colorPickerRaw:(Rectangle)bounds color:(Color *)color {
    return (RGGResult)GuiColorPicker(bounds, NULL, color);
}

+ (BOOL)colorPicker:(Rectangle)bounds color:(Color *)color {
    return ([self colorPickerRaw:bounds color:color] != RGGResultNone);
}

+ (RGGResult)colorPanelRaw:(Rectangle)bounds color:(Color *)color {
    return (RGGResult)GuiColorPanel(bounds, NULL, color);
}

+ (BOOL)colorPanel:(Rectangle)bounds color:(Color *)color {
    return ([self colorPanelRaw:bounds color:color] != RGGResultNone);
}

+ (RGGResult)colorBarAlphaRaw:(Rectangle)bounds alpha:(float *)alpha {
    return (RGGResult)GuiColorBarAlpha(bounds, NULL, alpha);
}

+ (BOOL)colorBarAlpha:(Rectangle)bounds alpha:(float *)alpha {
    return ([self colorBarAlphaRaw:bounds alpha:alpha] == RGGResultChanged);
}

+ (RGGResult)colorBarHueRaw:(Rectangle)bounds hue:(float *)hue {
    return (RGGResult)GuiColorBarHue(bounds, NULL, hue);
}

+ (BOOL)colorBarHue:(Rectangle)bounds hue:(float *)hue {
    return ([self colorBarHueRaw:bounds hue:hue] == RGGResultChanged);
}

+ (RGGResult)colorPickerHSVRaw:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv {
    return (RGGResult)GuiColorPickerHSV(bounds, NULL, colorHsv);
}

+ (BOOL)colorPickerHSV:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv {
    return ([self colorPickerHSVRaw:bounds colorHsv:colorHsv] != RGGResultNone);
}

+ (RGGResult)colorPanelHSVRaw:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv {
    return (RGGResult)GuiColorPanelHSV(bounds, NULL, colorHsv);
}

+ (BOOL)colorPanelHSV:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv {
    return ([self colorPanelHSVRaw:bounds colorHsv:colorHsv] == RGGResultChanged);
}

+ (RGGResult)messageBoxRaw:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
                   buttons:(NSArray<NSString *> *)buttons pressedButton:(int *)pressedButton {
    int btnActive = 0;
    RGGResult result = (RGGResult)GuiMessageBox(bounds, [title UTF8String],
                                                [message UTF8String],
                                                [RGGJoinItems(buttons) UTF8String],
                                                &btnActive);
    if (pressedButton != NULL) *pressedButton = btnActive;
    return result;
}

+ (int)messageBox:(Rectangle)bounds title:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttons {
    int pressedButton = 0;
    [self messageBoxRaw:bounds title:title message:message buttons:buttons pressedButton:&pressedButton];
    return pressedButton;
}

+ (RGGResult)textInputDialogRaw:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
                        buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text
                      secretView:(BOOL *)secretView pressedButton:(int *)pressedButton {
    char buffer[RGGTextMaxLength + 1];
    snprintf(buffer, sizeof(buffer), "%s", [[text description] UTF8String]);
    bool secret = (secretView != NULL && *secretView != NO);
    int btnActive = 0;
    RGGResult result = (RGGResult)GuiTextInputBox(bounds, [title UTF8String],
                                                   [message UTF8String], buffer,
                                                   RGGTextMaxLength + 1,
                                                   [RGGJoinItems(buttons) UTF8String],
                                                   &btnActive, &secret);
    [text setString:[NSString stringWithUTF8String:buffer]];
    if (secretView != NULL) *secretView = (secret ? YES : NO);
    if (pressedButton != NULL) *pressedButton = btnActive;
    return result;
}

+ (int)textInputDialog:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
               buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text
            secretView:(BOOL *)secretView {
    int pressedButton = 0;
    [self textInputDialogRaw:bounds title:title message:message buttons:buttons
                       text:text secretView:secretView pressedButton:&pressedButton];
    return pressedButton;
}

+ (int)textInputDialog:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
               buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text {
    return [self textInputDialog:bounds title:title message:message buttons:buttons text:text secretView:NULL];
}

+ (RGGResult)tabBarRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return (RGGResult)GuiTabBar(bounds, [RGGJoinItems(items) UTF8String], NULL, active);
}

+ (int)tabBar:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int)active {
    int activeTab = active;
    [self tabBarRaw:bounds items:items active:&activeTab];
    return activeTab;
}

@end
