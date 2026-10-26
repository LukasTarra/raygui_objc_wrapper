// examples/demo/main.m — RayguiObjC acceptance harness.
//
// Opens a window and, per frame (between BeginDrawing/EndDrawing), exercises:
//   - a label
//   - a button that toggles a checkbox
//   - a slider bound to a float
//   - a text box bound to an NSMutableString
//   - a style file load at startup (if a .rgs is passed as argv[1])
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
        int comboSelected = 0;
        NSMutableString *name = [NSMutableString stringWithString:@"RayguiObjC"];

        NSArray *comboItems = @[@"Item 1", @"Item 2", @"Item 3"];

        while (!WindowShouldClose()) {
            //----------------------------------------------------------------------------------
            // Update (immediate mode: raygui reads raylib input state here, inside the frame)
            //----------------------------------------------------------------------------------
            if (IsKeyPressed(KEY_SPACE)) toggleActive = !toggleActive;

            //----------------------------------------------------------------------------------
            // Draw
            //----------------------------------------------------------------------------------
            BeginDrawing();
                ClearBackground(RAYWHITE);

                [RGGui label:RGRectMake(20, 20, 300, 24) text:@"RayguiObjC demo — Foundation only"];

                // Button toggles the checkbox below
                if ([RGGui button:RGRectMake(20, 56, 160, 30) text:@"Toggle checkbox"]) {
                    checkEnabled = !checkEnabled;
                }
                [RGGui checkBox:RGRectMake(200, 56, 24, 24) text:@"Enabled" checked:&checkEnabled];

                [RGGui toggle:RGRectMake(20, 100, 160, 30) text:@"Toggle" active:&toggleActive];

                // Slider bound to a float
                [RGGui slider:RGRectMake(20, 144, 220, 24) text:@"Volume"
                        value:&volume minValue:0.0f maxValue:1.0f];
                [RGGui label:RGRectMake(250, 144, 200, 24)
                        text:[NSString stringWithFormat:@"%.2f", volume]];

                [RGGui spinner:RGRectMake(20, 180, 140, 30) value:&spinnerValue minValue:0 maxValue:100];

                [RGGui comboBox:RGRectMake(20, 224, 160, 30) items:comboItems selected:&comboSelected];

                // Text box bound to an NSMutableString
                [RGGui textBox:RGRectMake(20, 268, 260, 30) text:name maxLength:64];

                [RGGui statusBar:RGRectMake(0, (float)screenHeight - 24, (float)screenWidth, 24)
                           text:[NSString stringWithFormat:@"checkbox=%d toggle=%d spinner=%d combo=%d",
                                 checkEnabled, toggleActive, spinnerValue, comboSelected]];

            EndDrawing();
        }

        CloseWindow();
    }
    return 0;
}
