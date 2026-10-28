// examples/demo/main.m — RayguiObjC acceptance harness.
//
// Opens a window and, per frame (between BeginDrawing/EndDrawing), exercises:
//   - a label, a button that toggles a checkbox, a checkbox, a toggle
//   - a slider bound to a float, a spinner, a combo box, an editable text box
//   - a group box with a progress bar, a toggle group, a list view
//   - a modal message box (locked background, Raw variant so X works)
//   - a style file load at startup (if a .rgs is passed as argv[1])
//   - a per-frame autorelease pool (the wrapper allocates per call)
//
// Ported from raygui's own examples/controls_test_suite structure so behavior
// can be compared visually. raylib is called directly (unwrapped by design).

#import <Foundation/Foundation.h>
#include "raylib.h"
#import "RayguiObjC.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        const int screenWidth = 800;
        const int screenHeight = 450;

        InitWindow(screenWidth, screenHeight, "RayguiObjC demo");
        if (!IsWindowReady()) {
            // Headless / no display: raylib logs the GLFW error; exit cleanly
            // instead of segfaulting inside the frame loop.
            fprintf(stderr, "demo: window failed to initialize (no display?)\n");
            return 1;
        }
        SetTargetFPS(60);

        // Optional: load a .rgs style file passed as the first argument
        if (argc > 1) {
            NSString *stylePath = [NSString stringWithUTF8String:argv[1]];
            if ([RGGui loadStyleAtPath:stylePath]) {
                printf("Loaded style: %s\n", argv[1]);
            } else {
                printf("Failed to load style: %s\n", argv[1]);
            }
        }

        // Bound state (the wrapper holds none — this is the caller's job)
        BOOL checkEnabled = NO;
        BOOL toggleActive = NO;
        float volume = 0.5f;
        int spinnerValue = 5;
        BOOL spinnerEditMode = NO;
        int comboSelected = 0;
        NSMutableString *name = [NSMutableString stringWithString:@"RayguiObjC"];
        BOOL nameEditMode = NO;
        int modeActive = 0;
        int listSelected = -1;
        int listScroll = 0;
        BOOL showAbout = NO;
        int aboutChoice = 0;

        NSArray *comboItems = @[@"Item 1", @"Item 2", @"Item 3"];
        NSArray *modeItems = @[@"Mode A", @"Mode B", @"Mode C"];
        NSArray *listItems = @[@"Charmander", @"Bulbasaur", @"Squirtle", @"Pikachu", @"Eevee"];

        while (!WindowShouldClose()) {
            @autoreleasepool {
                //----------------------------------------------------------------------------------
                // Update (immediate mode: raygui reads raylib input state here, inside the frame)
                //----------------------------------------------------------------------------------
                if (IsKeyPressed(KEY_SPACE)) toggleActive = !toggleActive;

                //----------------------------------------------------------------------------------
                // Draw
                //----------------------------------------------------------------------------------
                BeginDrawing();
                    ClearBackground(RAYWHITE);

                    // Modal dialog: the background controls draw but take no input
                    if (showAbout) [RGGui lock];

                    [RGGui label:RGRectMake(20, 20, 300, 24) text:@"RayguiObjC demo — Foundation only"];

                    // Button toggles the checkbox below
                    if ([RGGui button:RGRectMake(20, 56, 160, 30) text:@"Toggle checkbox"]) {
                        checkEnabled = !checkEnabled;
                        NSLog(@"button: checkbox now %d", checkEnabled);
                    }
                    if ([RGGui checkBox:RGRectMake(200, 56, 24, 24) text:@"Enabled" checked:&checkEnabled]) {
                        NSLog(@"checkbox changed: %d", checkEnabled);
                    }

                    [RGGui toggle:RGRectMake(20, 100, 160, 30) text:@"Toggle" active:&toggleActive];

                    // Slider bound to a float (label drawn left of the bar)
                    [RGGui slider:RGRectMake(90, 144, 190, 24) text:@"Volume"
                            value:&volume minValue:0.0f maxValue:1.0f];
                    [RGGui label:RGRectMake(290, 144, 120, 24)
                            text:[NSString stringWithFormat:@"%.2f", volume]];

                    // Spinner bound to an int, editable via keyboard
                    if ([RGGui spinner:RGRectMake(20, 180, 140, 30) value:&spinnerValue
                               minValue:0 maxValue:100 editMode:spinnerEditMode]) {
                        spinnerEditMode = !spinnerEditMode;
                    }

                    [RGGui comboBox:RGRectMake(20, 224, 160, 30) items:comboItems selected:&comboSelected];

                    // Text box bound to an NSMutableString, editable
                    if ([RGGui textBox:RGRectMake(20, 268, 260, 30) text:name maxLength:64 editMode:nameEditMode]) {
                        nameEditMode = !nameEditMode;
                    }

                    // Right column: more controls inside a group box
                    [RGGui groupBox:RGRectMake(340, 20, 420, 240) text:@"More controls"];

                    [RGGui label:RGRectMake(360, 44, 80, 20) text:@"Progress:"];
                    [RGGui progressBar:RGRectMake(450, 42, 290, 20) value:volume minValue:0.0f maxValue:1.0f];

                    [RGGui toggleGroup:RGRectMake(360, 76, 90, 30) items:modeItems active:&modeActive];

                    [RGGui listView:RGRectMake(360, 116, 340, 80) items:listItems
                          selected:&listSelected scrollIndex:&listScroll];

                    if ([RGGui button:RGRectMake(360, 206, 120, 28) text:@"About"]) {
                        showAbout = YES;
                    }

                    [RGGui statusBar:RGRectMake(0, (float)screenHeight - 24, (float)screenWidth, 24)
                               text:[NSString stringWithFormat:@"checkbox=%d toggle=%d spinner=%d combo=%d mode=%d list=%d",
                                     checkEnabled, toggleActive, spinnerValue, comboSelected, modeActive, listSelected]];

                    if (showAbout) [RGGui unlock];

                    // Modal dialog (Raw variant: the X button reports 0, buttons 1+)
                    if (showAbout) {
                        DrawRectangle(0, 0, screenWidth, screenHeight, Fade(RAYWHITE, 0.8f));
                        int btn = 0;
                        RGGResult r = [RGGui messageBoxRaw:RGRectMake(250, 160, 300, 120)
                                                      title:@"About"
                                                    message:@"RayguiObjC demo — raygui 5.0 controls in Objective-C."
                                                    buttons:@[@"OK"]
                                              pressedButton:&btn];
                        if (r == RGGResultPressed) {
                            showAbout = NO;
                            aboutChoice = btn;
                            NSLog(@"about dialog dismissed (button %d)", aboutChoice);
                        }
                    }
                EndDrawing();
            }
        }

        CloseWindow();
    }
    return 0;
}
