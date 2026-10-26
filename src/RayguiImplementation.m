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

@implementation RGGui
@end
