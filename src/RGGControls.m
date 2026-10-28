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
    // raygui's GuiTextSplit() copies the joined string into a static 1024-byte
    // buffer holding at most 128 items; longer input is silently truncated.
    NSUInteger byteLength = [joined lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if ([items count] > 128 || byteLength > 1023) {
        TraceLog(LOG_WARNING, "RAYGUI: item list truncated: %d items, %d bytes (limits: 128 items, 1023 bytes)",
                 (int)[items count], (int)byteLength);
    }
    return joined;
}

// Copy an NSString into a fixed C buffer, clamped to bufferSize-1.
// AGENTS.md §8: snprintf, never sprintf.
// The clamp is at a UTF-8 boundary: snprintf truncates at a byte boundary,
// which can split a multibyte character and leave invalid UTF-8 in the buffer.
void RGGCopyToBuffer(NSString *string, char *buffer, int bufferSize) {
    if (string == nil) {
        buffer[0] = '\0';
        return;
    }
    snprintf(buffer, (size_t)bufferSize, "%s", [string UTF8String]);
    size_t len = strnlen(buffer, (size_t)bufferSize - 1);
    if (len > 0) {
        size_t end = len;
        while (end > 0 && (((unsigned char)buffer[end - 1] & 0xC0) == 0x80)) end--;  // continuation bytes
        if (end > 0) {
            unsigned char lead = (unsigned char)buffer[end - 1];
            size_t expected = (lead < 0x80) ? 1 : (lead < 0xE0) ? 2 : (lead < 0xF0) ? 3 : 4;
            if ((end - 1) + expected > len) buffer[end - 1] = '\0';  // truncated sequence: drop the lead byte
        }
    }
}

// Write a C buffer back into an NSMutableString. stringWithUTF8String: returns
// nil for invalid UTF-8 and setString:nil would raise — keep the previous
// text instead of letting an exception escape the frame loop.
BOOL RGGSetStringFromBuffer(NSMutableString *string, const char *buffer) {
    NSString *updated = [NSString stringWithUTF8String:buffer];
    if (updated == nil) return NO;
    [string setString:updated];
    return YES;
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
    NSParameterAssert(active != NULL);
    bool a = (*active != NO);
    RGGResult result = (RGGResult)GuiToggle(bounds, [text UTF8String], &a);
    *active = (a ? YES : NO);
    return result;
}

+ (BOOL)toggle:(Rectangle)bounds text:(NSString *)text active:(BOOL *)active {
    return ([self toggleRaw:bounds text:text active:active] == RGGResultChanged);
}

+ (RGGResult)toggleGroupRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    NSParameterAssert(active != NULL);
    return (RGGResult)GuiToggleGroup(bounds, [RGGJoinItems(items) UTF8String], active);
}

+ (BOOL)toggleGroup:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return ([self toggleGroupRaw:bounds items:items active:active] == RGGResultChanged);
}

+ (RGGResult)toggleSliderRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    NSParameterAssert(active != NULL);
    return (RGGResult)GuiToggleSlider(bounds, [RGGJoinItems(items) UTF8String], active);
}

+ (BOOL)toggleSlider:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active {
    return ([self toggleSliderRaw:bounds items:items active:active] != RGGResultNone);
}

+ (RGGResult)checkBoxRaw:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked {
    NSParameterAssert(checked != NULL);
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
    NSParameterAssert(value != NULL);
    return (RGGResult)GuiSlider(bounds, [text UTF8String], NULL, value, min, max);
}

+ (BOOL)slider:(Rectangle)bounds text:(NSString *)text
         value:(float *)value minValue:(float)min maxValue:(float)max {
    return ([self sliderRaw:bounds text:text value:value minValue:min maxValue:max] == RGGResultChanged);
}

+ (RGGResult)sliderBarRaw:(Rectangle)bounds text:(NSString *)text
                    value:(float *)value minValue:(float)min maxValue:(float)max {
    NSParameterAssert(value != NULL);
    return (RGGResult)GuiSliderBar(bounds, [text UTF8String], NULL, value, min, max);
}

+ (BOOL)sliderBar:(Rectangle)bounds text:(NSString *)text
            value:(float *)value minValue:(float)min maxValue:(float)max {
    return ([self sliderBarRaw:bounds text:text value:value minValue:min maxValue:max] != RGGResultNone);
}

+ (void)progressBar:(Rectangle)bounds value:(float)value minValue:(float)min maxValue:(float)max {
    // Display-only control (AGENTS.md §3.1): value by value, no result.
    (void)GuiProgressBar(bounds, NULL, NULL, &value, min, max);
}

+ (RGGResult)textBoxRaw:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode {
    NSParameterAssert(text != NULL);
    char buffer[RGGTextBufferSize];
    RGGCopyToBuffer(text, buffer, (int)sizeof(buffer));
    if (maxLength > RGGTextMaxLength) maxLength = RGGTextMaxLength;  // AGENTS.md §8: clamp
    RGGResult result = (RGGResult)GuiTextBox(bounds, buffer, maxLength + 1, (editMode != NO));
    RGGSetStringFromBuffer(text, buffer);
    return result;
}

+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode {
    return ([self textBoxRaw:bounds text:text maxLength:maxLength editMode:editMode] == RGGResultPressed);
}

+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength {
    return [self textBox:bounds text:text maxLength:maxLength editMode:NO];
}

+ (RGGResult)valueBoxRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    NSParameterAssert(value != NULL);
    return (RGGResult)GuiValueBox(bounds, NULL, value, min, max, (editMode != NO));
}

+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    return ([self valueBoxRaw:bounds value:value minValue:min maxValue:max editMode:editMode] == RGGResultPressed);
}

+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max {
    return [self valueBox:bounds value:value minValue:min maxValue:max editMode:NO];
}

+ (RGGResult)valueBoxFloatRaw:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode {
    NSParameterAssert(textValue != NULL);
    NSParameterAssert(value != NULL);
    char buffer[RGGTextBufferSize];
    RGGCopyToBuffer(textValue, buffer, (int)sizeof(buffer));
    RGGResult result = (RGGResult)GuiValueBoxFloat(bounds, NULL, buffer, value, (editMode != NO));
    RGGSetStringFromBuffer(textValue, buffer);
    return result;
}

+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode {
    return ([self valueBoxFloatRaw:bounds textValue:textValue value:value editMode:editMode] == RGGResultPressed);
}

+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value {
    return [self valueBoxFloat:bounds textValue:textValue value:value editMode:NO];
}

+ (RGGResult)comboBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected {
    NSParameterAssert(selected != NULL);
    return (RGGResult)GuiComboBox(bounds, [RGGJoinItems(items) UTF8String], selected);
}

+ (BOOL)comboBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected {
    return ([self comboBoxRaw:bounds items:items selected:selected] == RGGResultChanged);
}

+ (RGGResult)dropdownBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected editMode:(BOOL)editMode {
    NSParameterAssert(selected != NULL);
    return (RGGResult)GuiDropdownBox(bounds, [RGGJoinItems(items) UTF8String], selected, (editMode != NO));
}

+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected editMode:(BOOL)editMode {
    return ([self dropdownBoxRaw:bounds items:items selected:selected editMode:editMode] != RGGResultNone);
}

+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected {
    return [self dropdownBox:bounds items:items selected:selected editMode:NO];
}

+ (RGGResult)spinnerRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode {
    NSParameterAssert(value != NULL);
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
    NSParameterAssert(mouseCell != NULL);
    return (RGGResult)GuiGrid(bounds, NULL, spacing, subdivs, mouseCell);
}

+ (BOOL)grid:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell {
    return ([self gridRaw:bounds spacing:spacing subdivs:subdivs mouseCell:mouseCell] == RGGResultPressed);
}

@end
