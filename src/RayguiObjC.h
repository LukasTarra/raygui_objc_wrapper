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
// - In/out scalars are passed by C pointer (no NSNumber round-trips). In/out
//   pointers must be non-NULL (NSParameterAssert); text:/title:/items:/buttons:
//   and a few optional out-parameters accept nil (marked nullable below).
// - Result semantics: raygui 5.0 controls return an int result
//   (GuiResult: RESULT_NONE=0, RESULT_PRESSED=1, RESULT_CHANGED=2,
//   RESULT_TAB_CLOSE=4). The wrapper exposes this as RGGResult. Every
//   interactive control has a BOOL convenience method (YES = the control
//   reports an interaction: pressed and/or changed) and a `...Raw` variant
//   returning the raw RGGResult. The `...Raw` variant is the single mechanism
//   applied uniformly across all interactive controls. Display-only controls
//   (label, groupBox, panel, line, progressBar) return void; scrollPanel
//   returns the visible Rectangle.
// - raygui parameters the wrapper hard-wires to NULL (sliders' right-hand text,
//   the label arguments of value box/spinner/color controls, tab-bar scroll and
//   focus) are noted per method.
// - Main thread only: raygui keeps global mutable state and static buffers.

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
    // Control-specific extended properties. Values 16+ are per-control slots:
    // the meaning of a value depends on the RGGControl it is set on (the
    // comment names the target). Values verified against the pinned raygui 5.0
    // (see the _Static_assert block in RayguiImplementation.m).
    RGGGroupPadding        = 16,  // TOGGLE: GROUP_PADDING
    RGGGroupWidthFull      = 17,  // TOGGLE: GROUP_WIDTH_FULL
    RGGSliderWidth         = 16,  // SLIDER: SLIDER_WIDTH
    RGGSliderPadding       = 17,  // SLIDER: SLIDER_PADDING
    RGGProgressPadding     = 16,  // PROGRESSBAR: PROGRESS_PADDING
    RGGProgressSide        = 17,  // PROGRESSBAR: PROGRESS_SIDE
    RGGCheckPadding        = 16,  // CHECKBOX: CHECK_PADDING
    RGGComboButtonWidth    = 16,  // COMBOBOX: COMBO_BUTTON_WIDTH
    RGGComboButtonSpacing  = 17,  // COMBOBOX: COMBO_BUTTON_SPACING
    RGGArrowPadding        = 16,  // DROPDOWNBOX: ARROW_PADDING
    RGGDropdownItemsSpacing = 17, // DROPDOWNBOX: DROPDOWN_ITEMS_SPACING
    RGGDropdownArrowHidden = 18,  // DROPDOWNBOX: DROPDOWN_ARROW_HIDDEN
    RGGDropdownRollUp      = 19,  // DROPDOWNBOX: DROPDOWN_ROLL_UP (0-down, 1-up)
    RGGTextReadonly        = 16,  // TEXTBOX: TEXT_READONLY (0-editable, 1-read-only)
    RGGSpinnerButtonWidth  = 16,  // VALUEBOX/SPINNER: SPINNER_BUTTON_WIDTH
    RGGSpinnerButtonSpacing = 17, // VALUEBOX/SPINNER: SPINNER_BUTTON_SPACING
    RGGTabItemsWidth       = 16,  // TABBAR: TAB_ITEMS_WIDTH
    RGGTabCloseButton      = 17,  // TABBAR: TAB_CLOSE_BUTTON (0-none, 1-shown)
    RGGTabLineSide         = 18,  // TABBAR: TAB_LINE_SIDE (0-bottom, 1-top)
    RGGListItemsHeight     = 16,  // LISTVIEW: LIST_ITEMS_HEIGHT
    RGGListItemsSpacing    = 17,  // LISTVIEW: LIST_ITEMS_SPACING
    RGGScrollBarWidth      = 18,  // LISTVIEW: SCROLLBAR_WIDTH
    RGGScrollBarSide       = 19,  // LISTVIEW: SCROLLBAR_SIDE (0-left, 1-right)
    RGGListItemsBorderNormal = 20, // LISTVIEW: LIST_ITEMS_BORDER_NORMAL
    RGGListItemsBorderWidth  = 21, // LISTVIEW: LIST_ITEMS_BORDER_WIDTH
    RGGScrollSpeed         = 21,  // SCROLLBAR: SCROLL_SPEED
    RGGColorSelectorSize   = 16,  // COLORPICKER: COLOR_SELECTOR_SIZE
    RGGColorHueBarWidth    = 17,  // COLORPICKER: HUEBAR_WIDTH
    RGGColorHueBarPadding  = 18,  // COLORPICKER: HUEBAR_PADDING
    RGGColorHueBarSelectorHeight = 19, // COLORPICKER: HUEBAR_SELECTOR_HEIGHT
    RGGColorHueBarSelectorOverflow = 20  // COLORPICKER: HUEBAR_SELECTOR_OVERFLOW
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

// Nullability markers. RGG_NULLABLE marks parameters that legitimately accept
// nil; RGG_ASSUME_NONNULL_BEGIN/END mark everything else in a region as
// non-NULL (matching the NSParameterAssert contract). Both degrade to nothing
// on compilers without nullability support (e.g. gcc), so the same header
// builds under clang (Cocoa and GNUstep) and gcc.
#if defined(__clang__)
#define RGG_NULLABLE _Nullable
#define RGG_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define RGG_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#else
#define RGG_NULLABLE
#define RGG_ASSUME_NONNULL_BEGIN
#define RGG_ASSUME_NONNULL_END
#endif

//----------------------------------------------------------------------------------
// RGGui — facade class. All methods are class methods; no instances needed.
//----------------------------------------------------------------------------------
RGG_ASSUME_NONNULL_BEGIN
@interface RGGui : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end
RGG_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------
// RGGui (Controls) — basic controls
//----------------------------------------------------------------------------------
RGG_ASSUME_NONNULL_BEGIN
@interface RGGui (Controls)

// Label control (never interacts)
+ (void)label:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Button control — convenience: YES on RESULT_PRESSED
+ (BOOL)button:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;
+ (RGGResult)buttonRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Label button control — convenience: YES on RESULT_PRESSED
+ (BOOL)labelButton:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;
+ (RGGResult)labelButtonRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Toggle button — convenience: YES when *active changed (RESULT_CHANGED)
+ (BOOL)toggle:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text active:(BOOL *)active;
+ (RGGResult)toggleRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text active:(BOOL *)active;

// Toggle group: items joined with ';' per raygui convention — YES when *active changed
+ (BOOL)toggleGroup:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items active:(int *)active;
+ (RGGResult)toggleGroupRaw:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items active:(int *)active;

// Toggle slider: items joined with ';' — YES when *active changed
+ (BOOL)toggleSlider:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items active:(int *)active;
+ (RGGResult)toggleSliderRaw:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items active:(int *)active;

// Check box — convenience: YES when *checked changed (RESULT_CHANGED)
+ (BOOL)checkBox:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text checked:(BOOL *)checked;
+ (RGGResult)checkBoxRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text checked:(BOOL *)checked;

// Slider — convenience: YES when *value changed (RESULT_CHANGED).
// raygui's right-hand text parameter is hard-wired to NULL.
+ (BOOL)slider:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text
         value:(float *)value minValue:(float)min maxValue:(float)max;
+ (RGGResult)sliderRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text
                 value:(float *)value minValue:(float)min maxValue:(float)max;

// Slider bar — YES when *value changed
+ (BOOL)sliderBar:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text
            value:(float *)value minValue:(float)min maxValue:(float)max;
+ (RGGResult)sliderBarRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text
                    value:(float *)value minValue:(float)min maxValue:(float)max;

// Progress bar (display-only, returns void; AGENTS.md §3.1). value is passed
// by value. raygui draws no text on it — use your own label if you want one.
+ (void)progressBar:(Rectangle)bounds value:(float)value minValue:(float)min maxValue:(float)max;

// Text box — copies text into a fixed C buffer, calls, writes edits back.
// maxLength must be <= 1023 (RGGTextMaxLength). YES on RESULT_PRESSED
// (click into/out of the box toggles edit mode).
+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength;
+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode;
+ (RGGResult)textBoxRaw:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength editMode:(BOOL)editMode;

// Value box — YES on RESULT_PRESSED (edit interactions); *value is the bound int.
// raygui's label parameter is hard-wired to NULL.
+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max;
+ (BOOL)valueBox:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;
+ (RGGResult)valueBoxRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;

// Value box float — textValue is the editable string representation of *value
+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value;
+ (BOOL)valueBoxFloat:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode;
+ (RGGResult)valueBoxFloatRaw:(Rectangle)bounds textValue:(NSMutableString *)textValue value:(float *)value editMode:(BOOL)editMode;

// Combo box — items joined with ';' — YES when *selected changed (RESULT_CHANGED)
+ (BOOL)comboBox:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected;
+ (RGGResult)comboBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected;

// Dropdown box — items joined with ';' — convenience: YES on any interaction
// (opened, closed, selection changed)
+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected;
+ (BOOL)dropdownBox:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected editMode:(BOOL)editMode;
+ (RGGResult)dropdownBoxRaw:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected editMode:(BOOL)editMode;

// Spinner — YES on RESULT_PRESSED (button interactions); *value is the bound int.
// raygui's label parameter is hard-wired to NULL.
+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max;
+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;
+ (RGGResult)spinnerRaw:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max editMode:(BOOL)editMode;

// Dummy rectangle placeholder — YES on RESULT_PRESSED
+ (BOOL)dummyRec:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;
+ (RGGResult)dummyRecRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Grid — YES on RESULT_PRESSED; *mouseCell receives the hovered cell
+ (BOOL)grid:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell;
+ (RGGResult)gridRaw:(Rectangle)bounds spacing:(float)spacing subdivs:(int)subdivs mouseCell:(Vector2 *)mouseCell;

@end
RGG_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------
// RGGui (Containers) — group box, window box, panel, line, scroll panel, status bar
//----------------------------------------------------------------------------------
RGG_ASSUME_NONNULL_BEGIN
@interface RGGui (Containers)

// Window box — YES on RESULT_PRESSED (close button clicked). Not draggable;
// dragging is the app's job.
+ (BOOL)windowBox:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title;
+ (RGGResult)windowBoxRaw:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title;

// Group box (never interacts)
+ (void)groupBox:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Panel (never interacts)
+ (void)panel:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Line separator, may contain text (never interacts)
+ (void)line:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

// Scroll panel — returns the visible view rectangle; *scroll is the in/out
// scroll offset (pass NULL for a read-only offset)
+ (Rectangle)scrollPanel:(Rectangle)bounds content:(Rectangle)content scroll:(Vector2 * RGG_NULLABLE)scroll;
+ (Rectangle)scrollPanel:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text content:(Rectangle)content scroll:(Vector2 * RGG_NULLABLE)scroll;

// Status bar — YES on RESULT_PRESSED
+ (BOOL)statusBar:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;
+ (RGGResult)statusBarRaw:(Rectangle)bounds text:(NSString * RGG_NULLABLE)text;

@end
RGG_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------
// RGGui (Advanced) — list view, color controls, dialogs, tab bar
//----------------------------------------------------------------------------------
RGG_ASSUME_NONNULL_BEGIN
@interface RGGui (Advanced)

// List view — items joined with ';' — YES when *selected changed (RESULT_CHANGED)
+ (BOOL)listView:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected scrollIndex:(int *)scroll;
+ (RGGResult)listViewRaw:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items selected:(int *)selected scrollIndex:(int *)scroll;

// Color controls — raygui's label parameter is hard-wired to NULL.
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

// Message box — returns the pressed button index (1-based), 0 if none (also 0
// when the window's X button is pressed — use the Raw variant to tell apart).
// buttons joined with ';' per raygui convention (e.g. @"OK" or @"Yes;No;Cancel")
+ (int)messageBox:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title message:(NSString * RGG_NULLABLE)message
           buttons:(NSArray<NSString *> * RGG_NULLABLE)buttons;
+ (RGGResult)messageBoxRaw:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title message:(NSString * RGG_NULLABLE)message
                    buttons:(NSArray<NSString *> * RGG_NULLABLE)buttons pressedButton:(int * RGG_NULLABLE)pressedButton;

// Text input dialog — returns the pressed button index (1-based), 0 if none.
// text is bound in/out (max 1023 bytes). secretView toggles password masking;
// pass NULL for no masking toggle.
+ (int)textInputDialog:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title message:(NSString * RGG_NULLABLE)message
               buttons:(NSArray<NSString *> * RGG_NULLABLE)buttons text:(NSMutableString *)text;
+ (int)textInputDialog:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title message:(NSString * RGG_NULLABLE)message
               buttons:(NSArray<NSString *> * RGG_NULLABLE)buttons text:(NSMutableString *)text secretView:(BOOL * RGG_NULLABLE)secretView;
+ (RGGResult)textInputDialogRaw:(Rectangle)bounds title:(NSString * RGG_NULLABLE)title message:(NSString * RGG_NULLABLE)message
                        buttons:(NSArray<NSString *> * RGG_NULLABLE)buttons text:(NSMutableString *)text
                      secretView:(BOOL * RGG_NULLABLE)secretView pressedButton:(int * RGG_NULLABLE)pressedButton;

// Tab bar — items joined with ';' — returns the active tab index, clamped to
// the item range (-1 only when the item list is empty). Raw result:
// RESULT_CHANGED on tab switch, RESULT_TAB_CLOSE on close request (middle
// click, or the tab's close button when RGGTabCloseButton is styled on).
// raygui's scroll/focus parameters are hard-wired to NULL.
+ (int)tabBar:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items active:(int)active;
+ (RGGResult)tabBarRaw:(Rectangle)bounds items:(NSArray<NSString *> * RGG_NULLABLE)items active:(int *)active;

@end
RGG_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------
// RGGui (State) — enable/disable/lock, alpha, state, font, style, tooltips, icons
//----------------------------------------------------------------------------------
RGG_ASSUME_NONNULL_BEGIN
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
+ (void)setTooltip:(NSString * RGG_NULLABLE)tooltip;

// Icon-prefixed text: returns an autoreleased NSString of the form "#001#text"
// suitable for passing to any control's text parameter. iconId is 0-255.
+ (NSString * RGG_NULLABLE)iconText:(int)iconId text:(NSString * RGG_NULLABLE)text;

+ (void)setIconScale:(int)scale;

// Text width considering gui style and icon size
+ (int)textWidth:(NSString * RGG_NULLABLE)text;

@end
RGG_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------
// Constants
//----------------------------------------------------------------------------------

// Maximum text length for textBox / textInputDialog buffers (AGENTS.md §8:
// maxLength must stay below the stack buffer size)
extern const int RGGTextMaxLength;   // 1023

// Fixed stack-buffer size used for text editing (RGGTextMaxLength + 1).
// An enum constant, so array declarations using it are not VLAs.
enum { RGGTextBufferSize = 1024 };

RGG_ASSUME_NONNULL_BEGIN

// Join an NSArray of NSString items with ';' per raygui convention.
// Returns an autoreleased NSString. Exposed for testing.
NSString *RGGJoinItems(NSArray<NSString *> * RGG_NULLABLE items);

// Copy an NSString into a fixed C buffer, clamped to bufferSize-1 and to a
// UTF-8 boundary (a multibyte character is never split). Exposed for testing.
void RGGCopyToBuffer(NSString * RGG_NULLABLE string, char *buffer, int bufferSize);

// Write a C buffer back into an NSMutableString. Returns NO and leaves the
// string unchanged if the buffer is not valid UTF-8 (instead of throwing on
// setString:nil). Exposed for testing.
BOOL RGGSetStringFromBuffer(NSMutableString *string, const char *buffer);

RGG_ASSUME_NONNULL_END

#endif // RAYGUI_OBJC_H
