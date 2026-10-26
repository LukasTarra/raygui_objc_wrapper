// RGGControls.m — basic controls: label, button, label button, toggle,
// toggle group, toggle slider, check box, slider, slider bar, progress bar,
// text box, value box, combo box, dropdown box, spinner, dummy rec, grid.

#import "RayguiObjC.h"
#include "raygui.h"
#include <stdio.h>
#include <string.h>

const int RGGTextMaxLength = 1023;

NSString *RGGJoinItems(NSArray<NSString *> *items) {
    if (items == nil || [items count] == 0) return @"";
    NSMutableString *joined = [NSMutableString stringWithCapacity:64];
    for (NSUInteger i = 0; i < [items count]; i++) {
        if (i > 0) [joined appendString:@";"];
        [joined appendString:[items objectAtIndex:i]];
    }
    return joined;
}

// Copy an NSString into a fixed C buffer, clamped to bufferSize-1.
// AGENTS.md §8: snprintf, never sprintf.
static void RGGCopyToBuffer(NSString *string, char *buffer, int bufferSize) {
    if (string == nil) {
        buffer[0] = '\0';
        return;
    }
    snprintf(buffer, (size_t)bufferSize, "%s", [string UTF8String]);
}

@implementation RGGui (Controls)

+ (void)label:(Rectangle)bounds text:(NSString *)text {
    GuiLabel(bounds, [text UTF8String]);
}

+ (RGGResult)buttonRaw:(Rectangle)bounds text:(NSString *)text {
    return (RGGResult)GuiButton(bounds, [text UTF8String]);
}

+ (BOOL)button:(Rectangle)bounds text:(NSString *)text {
    return ([self buttonRaw:bounds text:text] == RGGResultPressed);
}

+ (RGGResult)labelButtonRaw:(Rectangle)bounds text:(NSString *)text {
    return (RGGResult)GuiLabelButton(bounds, [text UTF8String]);
}

+ (BOOL)labelButton:(Rectangle)bounds text:(NSString *)text {
    return ([self labelButtonRaw:bounds text:text] == RGGResultPressed);
}

+ (RGGResult)toggleRaw:(Rectangle)bounds text:(NSString *)text active:(BOOL *)active {
    bool a = (*active != NO);
    RGGResult result = (RGGResult)GuiToggle(bounds, [text UTF8String], &a);
    *active = (a ? YES : NO);
    return result;
}

+ (BOOL)toggle:(Rectangle)bounds text:(NSString *)text active:(BOOL *)active {
    return ([self toggleRaw:bounds text:text active:active] == RGGResultChanged);
}

+ (RGGResult)toggleGroupRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return (RGGResult)GuiToggleGroup(bounds, [RGGJoinItems(items) UTF8String], active);
}

+ (BOOL)toggleGroup:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return ([self toggleGroupRaw:bounds items:items active:active] == RGGResultChanged);
}

+ (RGGResult)toggleSliderRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return (RGGResult)GuiToggleSlider(bounds, [RGGJoinItems(items) UTF8String], active);
}

+ (BOOL)toggleSlider:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return ([self toggleSliderRaw:bounds items:items active:active] != RGGResultNone);
}

+ (RGGResult)checkBoxRaw:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked {
    bool c = (*checked != NO);
    RGGResult result = (RGGResult)GuiCheckBox(bounds, [text UTF8String], &c);
    *checked = (c ? YES : NO);
    return result;
}

+ (BOOL)checkBox:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked {
    return ([self checkBoxRaw:bounds text:text checked:checked] == RGGResultChanged);
}

+ (RGGResult)sliderRaw:(Rectangle)bounds text:(NSString *)text
                 value:(float *)value minValue:(float)min maxValue:(float)max {
    return (RGGResult)GuiSlider(bounds, [text UTF8String], NULL, value, min, max);
}

+ (BOOL)slider:(Rectangle)bounds text:(NSString *)text
         value:(float *)value minValue:(float)min maxValue:(float)max {
    return ([self sliderRaw:bounds text:text value:value minValue:min maxValue:max] == RGGResultChanged);
}

+ (RGGResult)sliderBarRaw:(Rectangle)bounds text:(NSString *)text
                    value:(float *)value minValue:(float)min maxValue:(float)max {
    return (RGGResult)GuiSliderBar(bounds, [text UTF8String], NULL, value, min, max);
}

+ (BOOL)sliderBar:(Rectangle)bounds text:(NSString *)text
            value:(float *)value minValue:(float)min maxValue:(float)max {
    return ([self sliderBarRaw:bounds text:text value:value minValue:min maxValue:max] != RGGResultNone);
}

+ (RGGResult)progressBarRaw:(Rectangle)bounds text:(NSString *)text
                      value:(float *)value minValue:(float)min maxValue:(float)max {
    return (RGGResult)GuiProgressBar(bounds, [text UTF8String], NULL, value, min, max);
}

+ (BOOL)progressBar:(Rectangle)bounds text:(NSString *)text
              value:(float *)value minValue:(float)min maxValue:(float)max {
    return ([self progressBarRaw:bounds text:text value:value minValue:min maxValue:max] == RGGResultChanged);
}

+ (RGGResult)textBoxRaw:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode {
    char buffer[RGGTextMaxLength + 1];
    RGGCopyToBuffer(text, buffer, (int)sizeof(buffer));
    if (maxLength > RGGTextMaxLength) maxLength = RGGTextMaxLength;  // AGENTS.md §8: clamp
    RGGResult result = (RGGResult)GuiTextBox(bounds, buffer, maxLength + 1, (editMode != NO));
    [text setString:[NSString stringWithUTF8String:buffer]];
    return result;
}

+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode {
    return ([self textBoxRaw:bounds text:text maxLength:maxLength editMode:editMode] == RGGResultPressed);
}

+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength {
    return [self textBox:bounds text:text maxLength:maxLength editMode:NO];
}

+ (RGGResult)valueBoxRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    return (RGGResult)GuiValueBox(bounds, NULL, value, min, max, (editMode != NO));
}

+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    return ([self valueBoxRaw:bounds value:value minValue:min maxValue:max editMode:editMode] == RGGResultPressed);
}

+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max {
    return [self valueBox:bounds value:value minValue:min maxValue:max editMode:NO];
}

+ (RGGResult)valueBoxFloatRaw:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode {
    char buffer[RGGTextMaxLength + 1];
    RGGCopyToBuffer(textValue, buffer, (int)sizeof(buffer));
    RGGResult result = (RGGResult)GuiValueBoxFloat(bounds, NULL, buffer, value, (editMode != NO));
    [textValue setString:[NSString stringWithUTF8String:buffer]];
    return result;
}

+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode {
    return ([self valueBoxFloatRaw:bounds textValue:textValue value:value editMode:editMode] == RGGResultPressed);
}

+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value {
    return [self valueBoxFloat:bounds textValue:textValue value:value editMode:NO];
}

+ (RGGResult)comboBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected {
    return (RGGResult)GuiComboBox(bounds, [RGGJoinItems(items) UTF8String], selected);
}

+ (BOOL)comboBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected {
    return ([self comboBoxRaw:bounds items:items selected:selected] == RGGResultChanged);
}

+ (RGGResult)dropdownBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected editMode:(BOOL)editMode {
    return (RGGResult)GuiDropdownBox(bounds, [RGGJoinItems(items) UTF8String], selected, (editMode != NO));
}

+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected editMode:(BOOL)editMode {
    return ([self dropdownBoxRaw:bounds items:items selected:selected editMode:editMode] != RGGResultNone);
}

+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected {
    return [self dropdownBox:bounds items:items selected:selected editMode:NO];
}

+ (RGGResult)spinnerRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    return (RGGResult)GuiSpinner(bounds, NULL, value, min, max, (editMode != NO));
}

+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    return ([self spinnerRaw:bounds value:value minValue:min maxValue:max editMode:editMode] == RGGResultPressed);
}

+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max {
    return [self spinner:bounds value:value minValue:min maxValue:max editMode:NO];
}

+ (RGGResult)dummyRecRaw:(Rectangle)bounds text:(NSString *)text {
    return (RGGResult)GuiDummyRec(bounds, [text UTF8String]);
}

+ (BOOL)dummyRec:(Rectangle)bounds text:(NSString *)text {
    return ([self dummyRecRaw:bounds text:text] == RGGResultPressed);
}

+ (RGGResult)gridRaw:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell {
    return (RGGResult)GuiGrid(bounds, NULL, spacing, subdivs, mouseCell);
}

+ (BOOL)grid:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell {
    return ([self gridRaw:bounds spacing:spacing subdivs:subdivs mouseCell:mouseCell] == RGGResultPressed);
}

@end
