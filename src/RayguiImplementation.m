// RayguiImplementation.m — the ONLY translation unit that defines
// RAYGUI_IMPLEMENTATION (AGENTS.md §2.1). Defining it in two files produces
// duplicate-symbol linker errors.
//
// Include order matters: raylib.h must come before raygui.h (AGENTS.md §2.2).
//
// This file also hosts the @implementation of the RGGui facade class itself.
// The wrapper splits RGGui's methods across categories (RGGControls.m,
// RGGContainers.m, RGGAdvanced.m, RGGState.m); on the GNUstep runtime a
// class referenced only from categories emits an undefined
// __objc_class_name_RGGui at link time, so the base @implementation must
// live in exactly one TU — this one.

#include "raylib.h"
#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

#import "RayguiObjC.h"

//----------------------------------------------------------------------------------
// Compile-time guard: every wrapper constant must match the pinned raygui 5.0
// (raygui.h is included above). Catches wrong values and upstream renumbering
// at compile time instead of silently styling the wrong property.
//----------------------------------------------------------------------------------
// RGGResult <-> GuiResult
_Static_assert((int)RGGResultNone == (int)RESULT_NONE,     "RGGResultNone != RESULT_NONE");
_Static_assert((int)RGGResultPressed == (int)RESULT_PRESSED,  "RGGResultPressed != RESULT_PRESSED");
_Static_assert((int)RGGResultChanged == (int)RESULT_CHANGED,  "RGGResultChanged != RESULT_CHANGED");
_Static_assert((int)RGGResultTabClose == (int)RESULT_TAB_CLOSE, "RGGResultTabClose != RESULT_TAB_CLOSE");

// RGGState <-> GuiState
_Static_assert((int)RGGStateNormal == (int)STATE_NORMAL,   "RGGStateNormal != STATE_NORMAL");
_Static_assert((int)RGGStateFocused == (int)STATE_FOCUSED,  "RGGStateFocused != STATE_FOCUSED");
_Static_assert((int)RGGStatePressed == (int)STATE_PRESSED,  "RGGStatePressed != STATE_PRESSED");
_Static_assert((int)RGGStateDisabled == (int)STATE_DISABLED, "RGGStateDisabled != STATE_DISABLED");

// RGGControl <-> GuiControl
_Static_assert((int)RGGControlDefault == (int)DEFAULT,      "RGGControlDefault != DEFAULT");
_Static_assert((int)RGGControlLabel == (int)LABEL,        "RGGControlLabel != LABEL");
_Static_assert((int)RGGControlButton == (int)BUTTON,       "RGGControlButton != BUTTON");
_Static_assert((int)RGGControlToggle == (int)TOGGLE,       "RGGControlToggle != TOGGLE");
_Static_assert((int)RGGControlSlider == (int)SLIDER,       "RGGControlSlider != SLIDER");
_Static_assert((int)RGGControlProgressBar == (int)PROGRESSBAR,  "RGGControlProgressBar != PROGRESSBAR");
_Static_assert((int)RGGControlCheckBox == (int)CHECKBOX,     "RGGControlCheckBox != CHECKBOX");
_Static_assert((int)RGGControlComboBox == (int)COMBOBOX,     "RGGControlComboBox != COMBOBOX");
_Static_assert((int)RGGControlDropdownBox == (int)DROPDOWNBOX,  "RGGControlDropdownBox != DROPDOWNBOX");
_Static_assert((int)RGGControlTextBox == (int)TEXTBOX,      "RGGControlTextBox != TEXTBOX");
_Static_assert((int)RGGControlValueBox == (int)VALUEBOX,     "RGGControlValueBox != VALUEBOX");
_Static_assert((int)RGGControlTabBar == (int)TABBAR,       "RGGControlTabBar != TABBAR");
_Static_assert((int)RGGControlListView == (int)LISTVIEW,     "RGGControlListView != LISTVIEW");
_Static_assert((int)RGGControlColorPicker == (int)COLORPICKER,  "RGGControlColorPicker != COLORPICKER");
_Static_assert((int)RGGControlScrollBar == (int)SCROLLBAR,    "RGGControlScrollBar != SCROLLBAR");
_Static_assert((int)RGGControlStatusBar == (int)STATUSBAR,    "RGGControlStatusBar != STATUSBAR");

// RGGProperty <-> GuiControlProperty (base properties)
_Static_assert((int)RGGBorderColorNormal == (int)BORDER_COLOR_NORMAL,   "RGGBorderColorNormal != BORDER_COLOR_NORMAL");
_Static_assert((int)RGGBaseColorNormal == (int)BASE_COLOR_NORMAL,     "RGGBaseColorNormal != BASE_COLOR_NORMAL");
_Static_assert((int)RGGTextColorNormal == (int)TEXT_COLOR_NORMAL,     "RGGTextColorNormal != TEXT_COLOR_NORMAL");
_Static_assert((int)RGGBorderColorFocused == (int)BORDER_COLOR_FOCUSED,  "RGGBorderColorFocused != BORDER_COLOR_FOCUSED");
_Static_assert((int)RGGBaseColorFocused == (int)BASE_COLOR_FOCUSED,    "RGGBaseColorFocused != BASE_COLOR_FOCUSED");
_Static_assert((int)RGGTextColorFocused == (int)TEXT_COLOR_FOCUSED,    "RGGTextColorFocused != TEXT_COLOR_FOCUSED");
_Static_assert((int)RGGBorderColorPressed == (int)BORDER_COLOR_PRESSED,  "RGGBorderColorPressed != BORDER_COLOR_PRESSED");
_Static_assert((int)RGGBaseColorPressed == (int)BASE_COLOR_PRESSED,    "RGGBaseColorPressed != BASE_COLOR_PRESSED");
_Static_assert((int)RGGTextColorPressed == (int)TEXT_COLOR_PRESSED,    "RGGTextColorPressed != TEXT_COLOR_PRESSED");
_Static_assert((int)RGGBorderColorDisabled == (int)BORDER_COLOR_DISABLED, "RGGBorderColorDisabled != BORDER_COLOR_DISABLED");
_Static_assert((int)RGGBaseColorDisabled == (int)BASE_COLOR_DISABLED,   "RGGBaseColorDisabled != BASE_COLOR_DISABLED");
_Static_assert((int)RGGTextColorDisabled == (int)TEXT_COLOR_DISABLED,   "RGGTextColorDisabled != TEXT_COLOR_DISABLED");
_Static_assert((int)RGGBorderWidth == (int)BORDER_WIDTH,          "RGGBorderWidth != BORDER_WIDTH");
_Static_assert((int)RGGTextPadding == (int)TEXT_PADDING,          "RGGTextPadding != TEXT_PADDING");
_Static_assert((int)RGGTextAlignment == (int)TEXT_ALIGNMENT,        "RGGTextAlignment != TEXT_ALIGNMENT");

// RGGProperty <-> GuiDefaultProperty (extended DEFAULT properties)
_Static_assert((int)RGGTextSize == (int)TEXT_SIZE,              "RGGTextSize != TEXT_SIZE");
_Static_assert((int)RGGTextSpacing == (int)TEXT_SPACING,           "RGGTextSpacing != TEXT_SPACING");
_Static_assert((int)RGGLineColor == (int)LINE_COLOR,             "RGGLineColor != LINE_COLOR");
_Static_assert((int)RGGBackgroundColor == (int)BACKGROUND_COLOR,       "RGGBackgroundColor != BACKGROUND_COLOR");
_Static_assert((int)RGGTextLineSpacing == (int)TEXT_LINE_SPACING,      "RGGTextLineSpacing != TEXT_LINE_SPACING");
_Static_assert((int)RGGTextAlignVertical == (int)TEXT_ALIGNMENT_VERTICAL, "RGGTextAlignVertical != TEXT_ALIGNMENT_VERTICAL");
_Static_assert((int)RGGTextWrapMode == (int)TEXT_WRAP_MODE,         "RGGTextWrapMode != TEXT_WRAP_MODE");

// RGGProperty <-> per-control extended properties
_Static_assert((int)RGGGroupPadding == (int)GROUP_PADDING,           "RGGGroupPadding != GROUP_PADDING");
_Static_assert((int)RGGGroupWidthFull == (int)GROUP_WIDTH_FULL,        "RGGGroupWidthFull != GROUP_WIDTH_FULL");
_Static_assert((int)RGGSliderWidth == (int)SLIDER_WIDTH,            "RGGSliderWidth != SLIDER_WIDTH");
_Static_assert((int)RGGSliderPadding == (int)SLIDER_PADDING,          "RGGSliderPadding != SLIDER_PADDING");
_Static_assert((int)RGGProgressPadding == (int)PROGRESS_PADDING,        "RGGProgressPadding != PROGRESS_PADDING");
_Static_assert((int)RGGProgressSide == (int)PROGRESS_SIDE,           "RGGProgressSide != PROGRESS_SIDE");
_Static_assert((int)RGGCheckPadding == (int)CHECK_PADDING,           "RGGCheckPadding != CHECK_PADDING");
_Static_assert((int)RGGComboButtonWidth == (int)COMBO_BUTTON_WIDTH,      "RGGComboButtonWidth != COMBO_BUTTON_WIDTH");
_Static_assert((int)RGGComboButtonSpacing == (int)COMBO_BUTTON_SPACING,    "RGGComboButtonSpacing != COMBO_BUTTON_SPACING");
_Static_assert((int)RGGArrowPadding == (int)ARROW_PADDING,           "RGGArrowPadding != ARROW_PADDING");
_Static_assert((int)RGGDropdownItemsSpacing == (int)DROPDOWN_ITEMS_SPACING, "RGGDropdownItemsSpacing != DROPDOWN_ITEMS_SPACING");
_Static_assert((int)RGGDropdownArrowHidden == (int)DROPDOWN_ARROW_HIDDEN,   "RGGDropdownArrowHidden != DROPDOWN_ARROW_HIDDEN");
_Static_assert((int)RGGDropdownRollUp == (int)DROPDOWN_ROLL_UP,        "RGGDropdownRollUp != DROPDOWN_ROLL_UP");
_Static_assert((int)RGGTextReadonly == (int)TEXT_READONLY,           "RGGTextReadonly != TEXT_READONLY");
_Static_assert((int)RGGSpinnerButtonWidth == (int)SPINNER_BUTTON_WIDTH,    "RGGSpinnerButtonWidth != SPINNER_BUTTON_WIDTH");
_Static_assert((int)RGGSpinnerButtonSpacing == (int)SPINNER_BUTTON_SPACING, "RGGSpinnerButtonSpacing != SPINNER_BUTTON_SPACING");
_Static_assert((int)RGGTabItemsWidth == (int)TAB_ITEMS_WIDTH,          "RGGTabItemsWidth != TAB_ITEMS_WIDTH");
_Static_assert((int)RGGTabCloseButton == (int)TAB_CLOSE_BUTTON,        "RGGTabCloseButton != TAB_CLOSE_BUTTON");
_Static_assert((int)RGGTabLineSide == (int)TAB_LINE_SIDE,           "RGGTabLineSide != TAB_LINE_SIDE");
_Static_assert((int)RGGListItemsHeight == (int)LIST_ITEMS_HEIGHT,       "RGGListItemsHeight != LIST_ITEMS_HEIGHT");
_Static_assert((int)RGGListItemsSpacing == (int)LIST_ITEMS_SPACING,      "RGGListItemsSpacing != LIST_ITEMS_SPACING");
_Static_assert((int)RGGScrollBarWidth == (int)SCROLLBAR_WIDTH,         "RGGScrollBarWidth != SCROLLBAR_WIDTH");
_Static_assert((int)RGGScrollBarSide == (int)SCROLLBAR_SIDE,          "RGGScrollBarSide != SCROLLBAR_SIDE");
_Static_assert((int)RGGListItemsBorderNormal == (int)LIST_ITEMS_BORDER_NORMAL, "RGGListItemsBorderNormal != LIST_ITEMS_BORDER_NORMAL");
_Static_assert((int)RGGListItemsBorderWidth == (int)LIST_ITEMS_BORDER_WIDTH, "RGGListItemsBorderWidth != LIST_ITEMS_BORDER_WIDTH");
_Static_assert((int)RGGScrollSpeed == (int)SCROLL_SPEED,            "RGGScrollSpeed != SCROLL_SPEED");
_Static_assert((int)RGGColorSelectorSize == (int)COLOR_SELECTOR_SIZE,     "RGGColorSelectorSize != COLOR_SELECTOR_SIZE");
_Static_assert((int)RGGColorHueBarWidth == (int)HUEBAR_WIDTH,            "RGGColorHueBarWidth != HUEBAR_WIDTH");
_Static_assert((int)RGGColorHueBarPadding == (int)HUEBAR_PADDING,          "RGGColorHueBarPadding != HUEBAR_PADDING");
_Static_assert((int)RGGColorHueBarSelectorHeight == (int)HUEBAR_SELECTOR_HEIGHT, "RGGColorHueBarSelectorHeight != HUEBAR_SELECTOR_HEIGHT");
_Static_assert((int)RGGColorHueBarSelectorOverflow == (int)HUEBAR_SELECTOR_OVERFLOW, "RGGColorHueBarSelectorOverflow != HUEBAR_SELECTOR_OVERFLOW");

@implementation RGGui
@end
