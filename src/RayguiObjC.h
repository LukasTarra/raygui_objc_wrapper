// RayguiObjC.h — public header for the RayguiObjC wrapper (raygui 5.0).
//
// One facade class `RGGui` (class methods, no instances) plus categories per
// control group. The `RG` prefix avoids collisions with NS/GNUstep classes.
//
// raylib structs (Rectangle, Color, Vector2, Font) pass through unwrapped at
// the boundary — that is the entire point of this approach. Foundation only:
// no AppKit types, so the same source links under Cocoa and GNUstep.
//
// Conventions (AGENTS.md §3.1):
// - Every wrapped control is called once per frame between BeginDrawing() and
//   EndDrawing(). The wrapper holds no per-control state.
// - Every method takes `Rectangle bounds` first. Use RGRectMake() for
//   readability (mirrors NSRectMake).
// - Strings are NSString, converted with UTF8String per call. Never store the
//   returned C pointer.
// - In/out scalars are passed by C pointer (no NSNumber round-trips).
// - Result semantics: raygui 5.0 controls return an int result
//   (GuiResult: RESULT_NONE=0, RESULT_PRESSED=1, RESULT_CHANGED=2,
//   RESULT_TAB_CLOSE=4, >2 control-specific). The wrapper exposes this as
//   RGGResult. Every control has a BOOL convenience method (YES = the control
//   reports an interaction: pressed and/or changed) and a `...Raw` variant
//   returning the raw RGGResult. The `...Raw` variant is the single mechanism
//   applied uniformly across all controls.

#ifndef RAYGUI_OBJC_H
#define RAYGUI_OBJC_H

#import <Foundation/Foundation.h>
#include "raylib.h"   // Rectangle, Color, Vector2, Font pass through unwrapped

#ifdef __cplusplus
extern "C" {
#endif

// raygui 5.0 control result (mirrors GuiResult in raygui.h)
typedef NS_ENUM(int, RGGResult) {
    RGGResultNone      = 0,    // RESULT_NONE: no interaction
    RGGResultPressed   = 1,    // RESULT_PRESSED: control activated (clicked/confirmed)
    RGGResultChanged   = 2,    // RESULT_CHANGED: bound value changed
    RGGResultTabClose  = 4     // RESULT_TAB_CLOSE: GuiTabBar tab close request
};

// raygui 5.0 global control state (mirrors GuiState in raygui.h)
typedef NS_ENUM(int, RGGState) {
    RGGStateNormal   = 0,      // STATE_NORMAL
    RGGStateFocused  = 1,      // STATE_FOCUSED
    RGGStatePressed  = 2,      // STATE_PRESSED
    RGGStateDisabled = 3       // STATE_DISABLED
};

// raygui 5.0 style targets (mirrors GuiControl in raygui.h)
typedef NS_ENUM(int, RGGControl) {
    RGGControlDefault     = 0,   // DEFAULT: populates to all controls when set
    RGGControlLabel       = 1,   // LABEL (also LABELBUTTON)
    RGGControlButton      = 2,   // BUTTON
    RGGControlToggle      = 3,   // TOGGLE (also TOGGLEGROUP)
    RGGControlSlider      = 4,   // SLIDER (also SLIDERBAR, TOGGLESLIDER)
    RGGControlProgressBar = 5,   // PROGRESSBAR
    RGGControlCheckBox    = 6,   // CHECKBOX
    RGGControlComboBox    = 7,   // COMBOBOX
    RGGControlDropdownBox = 8,   // DROPDOWNBOX
    RGGControlTextBox     = 9,   // TEXTBOX
    RGGControlValueBox    = 10,  // VALUEBOX
    RGGControlTabBar      = 11,  // TABBAR
    RGGControlListView    = 12,  // LISTVIEW
    RGGControlColorPicker = 13,  // COLORPICKER
    RGGControlScrollBar   = 14,  // SCROLLBAR
    RGGControlStatusBar   = 15   // STATUSBAR
};

// raygui 5.0 base style properties (mirrors GuiControlProperty in raygui.h)
typedef NS_ENUM(int, RGGProperty) {
    RGGBorderColorNormal   = 0,   // BORDER_COLOR_NORMAL
    RGGBaseColorNormal     = 1,   // BASE_COLOR_NORMAL
    RGGTextColorNormal     = 2,   // TEXT_COLOR_NORMAL
    RGGBorderColorFocused  = 3,   // BORDER_COLOR_FOCUSED
    RGGBaseColorFocused    = 4,   // BASE_COLOR_FOCUSED
    RGGTextColorFocused    = 5,   // TEXT_COLOR_FOCUSED
    RGGBorderColorPressed  = 6,   // BORDER_COLOR_PRESSED
    RGGBaseColorPressed    = 7,   // BASE_COLOR_PRESSED
    RGGTextColorPressed    = 8,   // TEXT_COLOR_PRESSED
    RGGBorderColorDisabled = 9,   // BORDER_COLOR_DISABLED
    RGGBaseColorDisabled   = 10,  // BASE_COLOR_DISABLED
    RGGTextColorDisabled   = 11,  // TEXT_COLOR_DISABLED
    RGGBorderWidth         = 12,  // BORDER_WIDTH
    RGGTextPadding         = 13,  // TEXT_PADDING
    RGGTextAlignment       = 14,  // TEXT_ALIGNMENT: 0-left, 1-center, 2-right
    // Extended (DEFAULT control, global) properties
    RGGTextSize            = 16,  // TEXT_SIZE
    RGGTextSpacing         = 17,  // TEXT_SPACING
    RGGLineColor           = 18,  // LINE_COLOR
    RGGBackgroundColor     = 19,  // BACKGROUND_COLOR
    RGGTextLineSpacing     = 20,  // TEXT_LINE_SPACING
    RGGTextAlignVertical   = 21,  // TEXT_ALIGNMENT_VERTICAL: 0-top, 1-middle, 2-bottom
    RGGTextWrapMode        = 22,  // TEXT_WRAP_MODE: 0-none, 1-char, 2-word
    // Control-specific extended properties
    RGGGroupPadding        = 16,  // TOGGLE/TOGGLEGROUP: GROUP_PADDING
    RGGGroupWidthFull      = 17,  // TOGGLE/TOGGLEGROUP: GROUP_WIDTH_FULL
    RGGSliderWidth         = 16,  // SLIDER: SLIDER_WIDTH
    RGGSliderPadding       = 17,  // SLIDER: SLIDER_PADDING
    RGGProgressPadding     = 16,  // PROGRESSBAR: PROGRESS_PADDING
    RGGProgressSide        = 17,  // PROGRESSBAR: PROGRESS_SIDE
    RGGScrollBarWidth      = 16,  // SCROLLBAR/LISTVIEW: SCROLLBAR_WIDTH
    RGGScrollBarSide       = 17,  // SCROLLBAR/LISTVIEW: SCROLLBAR_SIDE
    RGGScrollSpeed         = 18,  // SCROLLBAR/LISTVIEW: SCROLL_SPEED
    RGGCheckPadding        = 16   // CHECKBOX: CHECK_PADDING
};

// Rectangle helper mirroring NSRectMake (AGENTS.md §3.1)
static inline Rectangle RGRectMake(float x, float y, float w, float h) {
    Rectangle r = { x, y, w, h };
    return r;
}

// Color helper mirroring raylib's Color literal, from 0-255 components
static inline Color RGGColorMake(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    Color c = { r, g, b, a };
    return c;
}

#ifdef __cplusplus
}
#endif

//----------------------------------------------------------------------------------
// RGGui — facade class. All methods are class methods; no instances needed.
//----------------------------------------------------------------------------------
@interface RGGui : NSObject
@end

//----------------------------------------------------------------------------------
// RGGui (Controls) — basic controls
//----------------------------------------------------------------------------------
@interface RGGui (Controls)

// Label control (never interacts)
+ (void)label:(Rectangle)bounds text:(NSString *)text;

// Button control — convenience: YES on RESULT_PRESSED
+ (BOOL)button:(Rectangle)bounds text:(NSString *)text;
+ (RGGResult)buttonRaw:(Rectangle)bounds text:(NSString *)text;

// Label button control — convenience: YES on RESULT_PRESSED
+ (BOOL)labelButton:(Rectangle)bounds text:(NSString *)text;
+ (RGGResult)labelButtonRaw:(Rectangle)bounds text:(NSString *)text;

// Toggle button — convenience: YES when *active changed (RESULT_CHANGED)
+ (BOOL)toggle:(Rectangle)bounds text:(NSString *)text active:(BOOL *)active;
+ (RGGResult)toggleRaw:(Rectangle)bounds text:(NSString *)text active:(BOOL *)active;

// Toggle group: items joined with ';' per raygui convention — YES when *active changed
+ (BOOL)toggleGroup:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active;
+ (RGGResult)toggleGroupRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active;

// Toggle slider: items joined with ';' — YES when *active changed
+ (BOOL)toggleSlider:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active;
+ (RGGResult)toggleSliderRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active;

// Check box — convenience: YES when *checked changed (RESULT_CHANGED)
+ (BOOL)checkBox:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked;
+ (RGGResult)checkBoxRaw:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked;

// Slider — convenience: YES when *value changed (RESULT_CHANGED)
+ (BOOL)slider:(Rectangle)bounds text:(NSString *)text
         value:(float *)value minValue:(float)min maxValue:(float)max;
+ (RGGResult)sliderRaw:(Rectangle)bounds text:(NSString *)text
                 value:(float *)value minValue:(float)min maxValue:(float)max;

// Slider bar — YES when *value changed
+ (BOOL)sliderBar:(Rectangle)bounds text:(NSString *)text
            value:(float *)value minValue:(float)min maxValue:(float)max;
+ (RGGResult)sliderBarRaw:(Rectangle)bounds text:(NSString *)text
                    value:(float *)value minValue:(float)min maxValue:(float)max;

// Progress bar (value is read-only here) — YES when *value changed
+ (BOOL)progressBar:(Rectangle)bounds text:(NSString *)text
              value:(float *)value minValue:(float)min maxValue:(float)max;
+ (RGGResult)progressBarRaw:(Rectangle)bounds text:(NSString *)text
                      value:(float *)value minValue:(float)min maxValue:(float)max;

// Text box — copies text into a fixed C buffer, calls, writes edits back.
// maxLength must be <= 1023 (RGGTextMaxLength). YES on RESULT_PRESSED
// (click into/out of the box toggles edit mode).
+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength;
+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode;
+ (RGGResult)textBoxRaw:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode;

// Value box — YES on RESULT_PRESSED (edit interactions); *value is the bound int
+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max;
+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;
+ (RGGResult)valueBoxRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;

// Value box float — textValue is the editable string representation of *value
+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value;
+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode;
+ (RGGResult)valueBoxFloatRaw:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode;

// Combo box — items joined with ';' — YES when *selected changed (RESULT_CHANGED)
+ (BOOL)comboBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected;
+ (RGGResult)comboBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected;

// Dropdown box — items joined with ';' — raw result is 1 when an item is selected/opened
+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected;
+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected editMode:(BOOL)editMode;
+ (RGGResult)dropdownBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected editMode:(BOOL)editMode;

// Spinner — YES on RESULT_PRESSED (button interactions); *value is the bound int
+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max;
+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;
+ (RGGResult)spinnerRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;

// Dummy rectangle placeholder — YES on RESULT_PRESSED
+ (BOOL)dummyRec:(Rectangle)bounds text:(NSString *)text;
+ (RGGResult)dummyRecRaw:(Rectangle)bounds text:(NSString *)text;

// Grid — YES on RESULT_PRESSED; *mouseCell receives the hovered cell
+ (BOOL)grid:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell;
+ (RGGResult)gridRaw:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell;

@end

//----------------------------------------------------------------------------------
// RGGui (Containers) — group box, window box, panel, line, scroll panel, status bar
//----------------------------------------------------------------------------------
@interface RGGui (Containers)

// Window box — YES on RESULT_PRESSED (close button clicked)
+ (BOOL)windowBox:(Rectangle)bounds title:(NSString *)title;
+ (RGGResult)windowBoxRaw:(Rectangle)bounds title:(NSString *)title;

// Group box (never interacts)
+ (void)groupBox:(Rectangle)bounds text:(NSString *)text;

// Panel (never interacts)
+ (void)panel:(Rectangle)bounds text:(NSString *)text;

// Line separator, may contain text (never interacts)
+ (void)line:(Rectangle)bounds text:(NSString *)text;

// Scroll panel — returns the visible view rectangle; *scroll is the in/out scroll offset
+ (Rectangle)scrollPanel:(Rectangle)bounds content:(Rectangle)content scroll:(Vector2 *)scroll;
+ (Rectangle)scrollPanel:(Rectangle)bounds text:(NSString *)text content:(Rectangle)content scroll:(Vector2 *)scroll;

// Status bar — YES on RESULT_PRESSED
+ (BOOL)statusBar:(Rectangle)bounds text:(NSString *)text;
+ (RGGResult)statusBarRaw:(Rectangle)bounds text:(NSString *)text;

@end

//----------------------------------------------------------------------------------
// RGGui (Advanced) — list view, color controls, dialogs, tab bar
//----------------------------------------------------------------------------------
@interface RGGui (Advanced)

// List view — items joined with ';' — YES when *selected changed (RESULT_CHANGED)
+ (BOOL)listView:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected scrollIndex:(int *)scroll;
+ (RGGResult)listViewRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected scrollIndex:(int *)scroll;

// Color picker — YES when *color changed
+ (BOOL)colorPicker:(Rectangle)bounds color:(Color *)color;
+ (RGGResult)colorPickerRaw:(Rectangle)bounds color:(Color *)color;

// Color panel — YES when *color changed
+ (BOOL)colorPanel:(Rectangle)bounds color:(Color *)color;
+ (RGGResult)colorPanelRaw:(Rectangle)bounds color:(Color *)color;

// Color bar alpha — YES when *alpha changed (0.0-1.0)
+ (BOOL)colorBarAlpha:(Rectangle)bounds alpha:(float *)alpha;
+ (RGGResult)colorBarAlphaRaw:(Rectangle)bounds alpha:(float *)alpha;

// Color bar hue — YES when *hue changed (0-360)
+ (BOOL)colorBarHue:(Rectangle)bounds hue:(float *)hue;
+ (RGGResult)colorBarHueRaw:(Rectangle)bounds hue:(float *)hue;

// Color picker HSV — YES when *colorHsv changed
+ (BOOL)colorPickerHSV:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv;
+ (RGGResult)colorPickerHSVRaw:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv;

// Color panel HSV — YES when *colorHsv changed
+ (BOOL)colorPanelHSV:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv;
+ (RGGResult)colorPanelHSVRaw:(Rectangle)bounds colorHsv:(Vector3 *)colorHsv;

// Message box — returns the pressed button index (1-based), 0 if none.
// buttons joined with ';' per raygui convention (e.g. @"OK" or @"Yes;No;Cancel")
+ (int)messageBox:(Rectangle)bounds title:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttons;
+ (RGGResult)messageBoxRaw:(Rectangle)bounds title:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttons pressedButton:(int *)pressedButton;

// Text input dialog — returns the pressed button index (1-based), 0 if none.
// text is bound in/out (max 1023 chars). secretView toggles password masking.
+ (int)textInputDialog:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
               buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text;
+ (int)textInputDialog:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
               buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text secretView:(BOOL *)secretView;
+ (RGGResult)textInputDialogRaw:(Rectangle)bounds title:(NSString *)title message:(NSString *)message
                        buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text
                      secretView:(BOOL *)secretView pressedButton:(int *)pressedButton;

// Tab bar — items joined with ';' — returns the active tab index.
// Returns -1 while no tab is active. Raw result: RESULT_CHANGED on tab switch,
// RESULT_TAB_CLOSE on close request.
+ (int)tabBar:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int)active;
+ (RGGResult)tabBarRaw:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int *)active;

@end

//----------------------------------------------------------------------------------
// RGGui (State) — enable/disable/lock, alpha, state, font, style, tooltips, icons
//----------------------------------------------------------------------------------
@interface RGGui (State)

+ (void)enable;
+ (void)disable;
+ (void)lock;
+ (void)unlock;
+ (BOOL)isLocked;
+ (void)setAlpha:(float)alpha;              // 0.0 - 1.0
+ (void)setState:(RGGState)state;
+ (RGGState)state;

+ (void)setFont:(Font)font;
+ (Font)font;

+ (void)setStyle:(RGGControl)control property:(RGGProperty)property value:(int)value;
+ (int)style:(RGGControl)control property:(RGGProperty)property;

// Load a .rgs style file from disk. Returns YES on success.
+ (BOOL)loadStyleAtPath:(NSString *)path;
+ (void)loadStyleDefault;

+ (void)enableTooltip;
+ (void)disableTooltip;
+ (void)setTooltip:(NSString *)tooltip;

// Icon-prefixed text: returns an autoreleased NSString of the form "#001#text"
// suitable for passing to any control's text parameter. iconId is 0-255.
+ (NSString *)iconText:(int)iconId text:(NSString *)text;

+ (void)setIconScale:(int)scale;

// Text width considering gui style and icon size
+ (int)textWidth:(NSString *)text;

@end

//----------------------------------------------------------------------------------
// Constants
//----------------------------------------------------------------------------------

// Maximum text length for textBox / textInputDialog buffers (AGENTS.md §8:
// maxLength must stay below the stack buffer size)
extern const int RGGTextMaxLength;   // 1023

// Join an NSArray of NSString items with ';' per raygui convention.
// Returns an autoreleased NSString. Exposed for testing.
NSString *RGGJoinItems(NSArray<NSString *> *items);

#endif // RAYGUI_OBJC_H
