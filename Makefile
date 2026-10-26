# Makefile — cross-platform build: macOS (Cocoa Foundation) and Linux (GNUstep).
#
# NOTE: GNU make prefers `GNUmakefile` over `Makefile`, so on BOTH platforms
# `make` may pick up either file. To make that harmless, `Makefile` and
# `GNUmakefile` are intentionally identical: each dispatches on `uname -s`,
# so whichever file `make` reads, the right platform flags are used.
#   macOS:  make            (clang, Cocoa Foundation, no ARC)
#   Linux:  make            (GNUstep Foundation, no ARC)  — or: make -f GNUmakefile
#
# Prerequisites:
#   1. sh scripts/init-submodules.sh
#      (initializes vendor/raylib @ 6.0 and vendor/raygui @ 5.0, and applies
#       the hue-bar fix patch to the raygui working tree)
#   2. Build raylib statically:
#      cd vendor/raylib && cmake -B build -DCMAKE_BUILD_TYPE=Release \
#        -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF && cmake --build build
#      cd ../..
#   3. make            # builds examples/demo/demo
#
# raygui is header-only: src/RayguiImplementation.m is the single TU that
# defines RAYGUI_IMPLEMENTATION (AGENTS.md §2.1). Each .m is compiled to .o
# separately so that `-x objective-c` applies only to sources; the link step
# has no `-x`, so libraylib.a is treated as a library, not as source.

UNAME_S := $(shell uname -s)

CC      ?= cc
CFLAGS  ?= -Wall -O2
LDFLAGS ?=
INCLUDES = -Isrc -Ivendor/raygui/src -Ivendor/raylib/src
RAYLIB_A = vendor/raylib/build/raylib/libraylib.a

SRC = src/RayguiImplementation.m src/RGGControls.m src/RGGContainers.m \
      src/RGGAdvanced.m src/RGGState.m
DEMO = examples/demo/main.m
OUT = examples/demo/demo
OBJ = $(SRC:.m=.o) $(DEMO:.m=.o)

ifeq ($(UNAME_S),Darwin)
  # macOS: clang, Cocoa Foundation, no ARC.
  # raylib 6.0 on macOS (Desktop/GLFW): miniaudio runtime-links CoreAudio,
  # so only these frameworks are needed at link time.
  OBJCFLAGS = -x objective-c -fno-objc-arc -std=c11 $(CFLAGS)
  LIBS = $(RAYLIB_A) -framework Foundation -framework Cocoa -framework IOKit \
         -framework CoreFoundation -framework OpenGL
else
  # Linux: GNUstep Foundation, no ARC.
  # System packages (Debian/Ubuntu): gnustep-devel libx11-dev libxrandr-dev
  #   libxinerama-dev libxcursor-dev libxi-dev libxext-dev libgl-dev
  #   libasound2-dev libpulse-dev (audio backends for raylib's miniaudio)
  GNUSTEP_CONFIG ?= gnustep-config
  OBJCFLAGS = -x objective-c $(shell $(GNUSTEP_CONFIG) --objc-flags) \
              -fno-objc-arc -std=c11 $(CFLAGS)
  LIBS = $(RAYLIB_A) \
         -lX11 -lXrandr -lXinerama -lXcursor -lXi -lXext -lGL -lrt -lm -lpthread -ldl \
         $(shell $(GNUSTEP_CONFIG) --base-libs)
endif

.PHONY: all clean run

all: $(OUT)

# Compile: -x objective-c applies per-source-file here.
%.o: %.m
	$(CC) $(OBJCFLAGS) $(INCLUDES) -c $< -o $@

# Link: no -x flag, so libraylib.a is linked as a static library.
$(OUT): $(OBJ) $(RAYLIB_A)
	$(CC) $(OBJ) $(LIBS) $(LDFLAGS) -o $(OUT)

run: $(OUT)
	./$(OUT)

clean:
	rm -f $(OUT) $(OBJ)
