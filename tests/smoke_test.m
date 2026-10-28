// tests/smoke_test.m — headless smoke test: opens a hidden window, runs a few
// frames calling every wrapped control (plus the state/style API), and exits
// non-zero on crash. Skips gracefully when there is no display.
// Built and run by `make test`.

#import <Foundation/Foundation.h>
#include <stdio.h>
#include "raylib.h"
#import "RayguiObjC.h"

int main(void) {
    @autoreleasepool {
        SetConfigFlags(FLAG_WINDOW_HIDDEN);
        InitWindow(320, 240, "smoke");
        if (!IsWindowReady()) {
            fprintf(stderr, "smoke_test: no display, skipping\n");
            return 0;
        }
        SetTargetFPS(60);

        // Bound state for every control
        BOOL checked = NO, active = NO, editMode = NO, secret = NO, ddEdit = NO;
        float fval = 0.5f, alpha = 1.0f, hue = 180.0f;
        int ival = 5, selected = 0, scroll = 0, tabActive = 0, btn = 0;
        NSMutableString *text = [NSMutableString stringWithString:@"smoke"];
        NSMutableString *ftext = [NSMutableString stringWithString:@"0.5"];
        Color color = RGGColorMake(200, 100, 50, 255);
        Vector3 hsv = { 180.0f, 0.5f, 0.5f };
        Vector2 cell = { 0, 0 }, panelScroll = { 0, 0 };
        NSArray *items = @[@"a", @"b", @"c"];
        NSMutableArray *manyItems = [NSMutableArray arrayWithCapacity:130];
        for (int i = 0; i < 130; i++) {
            [manyItems addObject:[NSString stringWithFormat:@"item %d", i]];
        }

        for (int frame = 0; frame < 3; frame++) {
            @autoreleasepool {
                BeginDrawing();
                    ClearBackground(RAYWHITE);

                    // Containers
                    [RGGui windowBox:RGRectMake(4, 4, 104, 104) title:@"smoke"];
                    [RGGui groupBox:RGRectMake(114, 4, 100, 60) text:@"group"];
                    [RGGui panel:RGRectMake(114, 70, 100, 30) text:nil];
                    [RGGui line:RGRectMake(4, 112, 104, 8) text:@"line"];
                    Rectangle view = [RGGui scrollPanel:RGRectMake(114, 190, 100, 46)
                                                    text:@"panel"
                                                 content:RGRectMake(0, 0, 200, 200)
                                                  scroll:&panelScroll];
                    BeginScissorMode((int)view.x, (int)view.y, (int)view.width, (int)view.height);
                        [RGGui label:RGRectMake(view.x + 4, view.y + 4, 100, 20) text:@"in panel"];
                    EndScissorMode();
                    [RGGui statusBar:RGRectMake(0, 220, 320, 20) text:@"smoke"];

                    // Basic controls
                    [RGGui label:RGRectMake(4, 124, 100, 16) text:@"label"];
                    [RGGui button:RGRectMake(4, 144, 60, 16) text:@"button"];
                    [RGGui labelButton:RGRectMake(70, 144, 60, 16) text:@"label"];
                    [RGGui toggle:RGRectMake(4, 24, 60, 16) text:@"toggle" active:&active];
                    [RGGui toggleGroup:RGRectMake(70, 24, 120, 16) items:items active:&selected];
                    [RGGui toggleSlider:RGRectMake(70, 44, 120, 16) items:items active:&selected];
                    [RGGui checkBox:RGRectMake(4, 44, 16, 16) text:@"check" checked:&checked];
                    [RGGui slider:RGRectMake(70, 64, 100, 16) text:@"slider"
                            value:&fval minValue:0.0f maxValue:1.0f];
                    [RGGui sliderBar:RGRectMake(70, 84, 100, 16) text:nil
                               value:&fval minValue:0.0f maxValue:1.0f];
                    [RGGui progressBar:RGRectMake(70, 104, 100, 10) value:fval minValue:0.0f maxValue:1.0f];
                    [RGGui textBox:RGRectMake(180, 24, 100, 16) text:text maxLength:32 editMode:(frame == 0)];
                    [RGGui valueBox:RGRectMake(180, 44, 100, 16) value:&ival minValue:0 maxValue:100 editMode:editMode];
                    [RGGui valueBoxFloat:RGRectMake(180, 64, 100, 16) textValue:ftext value:&fval editMode:editMode];
                    [RGGui comboBox:RGRectMake(180, 84, 100, 16) items:items selected:&selected];
                    // NOTE: dropdown must be drawn after controls it could cover
                    [RGGui dropdownBox:RGRectMake(180, 104, 100, 16) items:items selected:&selected editMode:ddEdit];
                    [RGGui spinner:RGRectMake(180, 124, 100, 16) value:&ival minValue:0 maxValue:100 editMode:editMode];
                    [RGGui dummyRec:RGRectMake(4, 164, 60, 40) text:nil];
                    [RGGui grid:RGRectMake(70, 164, 60, 40) spacing:10 subdivs:3 mouseCell:&cell];

                    // Advanced controls
                    [RGGui listView:RGRectMake(220, 4, 96, 60) items:manyItems
                          selected:&selected scrollIndex:&scroll];
                    tabActive = [RGGui tabBar:RGRectMake(220, 70, 96, 16) items:items active:tabActive];
                    [RGGui colorPicker:RGRectMake(220, 90, 96, 60) color:&color];
                    [RGGui colorPanel:RGRectMake(220, 154, 60, 40) color:&color];
                    [RGGui colorBarAlpha:RGRectMake(4, 208, 100, 10) alpha:&alpha];
                    [RGGui colorBarHue:RGRectMake(114, 208, 100, 10) hue:&hue];
                    [RGGui colorPickerHSV:RGRectMake(290, 154, 26, 40) colorHsv:&hsv];
                    [RGGui colorPanelHSV:RGRectMake(290, 198, 26, 20) colorHsv:&hsv];

                    // Dialogs (drawn last, on top). Frame 1 exercises the
                    // secretView:NULL pass-through path of textInputDialogRaw.
                    (void)[RGGui messageBox:RGRectMake(40, 40, 120, 60)
                                        title:@"t" message:@"m" buttons:@[@"OK", @"Cancel"]];
                    [RGGui messageBoxRaw:RGRectMake(170, 40, 120, 60)
                                    title:@"t" message:@"m" buttons:@[@"OK"] pressedButton:&btn];
                    BOOL *secretPtr = (frame == 1) ? NULL : &secret;
                    [RGGui textInputDialogRaw:RGRectMake(40, 110, 120, 80)
                                          title:@"t" message:@"m" buttons:@[@"OK"]
                                           text:text secretView:secretPtr pressedButton:&btn];

                    // State / style API
                    [RGGui setStyle:RGGControlButton property:RGGBaseColorFocused value:0xCC2222FF];
                    (void)[RGGui style:RGGControlButton property:RGGBaseColorFocused];
                    [RGGui setStyle:RGGControlListView property:RGGScrollBarWidth value:20];
                    [RGGui setStyle:RGGControlTabBar property:RGGTabCloseButton value:1];
                    [RGGui setAlpha:1.0f];
                    [RGGui enableTooltip];
                    [RGGui setTooltip:@"smoke"];
                    [RGGui disableTooltip];
                    [RGGui setIconScale:1];
                    (void)[RGGui iconText:1 text:@"icon"];
                    (void)[RGGui textWidth:@"smoke"];
                    [RGGui setFont:[RGGui font]];
                    [RGGui loadStyleDefault];
                    [RGGui disable];
                    [RGGui enable];
                    [RGGui lock];
                    [RGGui unlock];
                    (void)[RGGui isLocked];
                    [RGGui setState:RGGStateNormal];
                    (void)[RGGui state];
                EndDrawing();
            }
        }

        CloseWindow();
        printf("SMOKE OK\n");
    }
    return 0;
}
