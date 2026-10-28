// tests/test_wrapper.m — window-free unit tests for the wrapper's C helpers
// and constants. Built and run by `make test`.

#import <Foundation/Foundation.h>
#import "RayguiObjC.h"
#include <stdio.h>
#include <string.h>

static int failures = 0;

static void check(BOOL condition, const char *message) {
    if (condition) {
        printf("ok: %s\n", message);
    } else {
        printf("FAIL: %s\n", message);
        failures++;
    }
}

int main(void) {
    @autoreleasepool {
        // RGGJoinItems
        check([RGGJoinItems(nil) isEqualToString:@""], "RGGJoinItems(nil) is empty");
        check([RGGJoinItems(@[]) isEqualToString:@""], "RGGJoinItems(empty) is empty");
        check([RGGJoinItems(@[@"a"]) isEqualToString:@"a"], "RGGJoinItems(one)");
        check([RGGJoinItems(@[@"a", @"b", @"c"]) isEqualToString:@"a;b;c"],
              "RGGJoinItems(many) joins with ';'");
        check([RGGJoinItems(@[@"a;b"]) isEqualToString:@"a;b"],
              "RGGJoinItems keeps ';' inside an item (raygui will split it)");

        // RGGCopyToBuffer: clamps to the buffer size and to a UTF-8 boundary
        char buf[8];
        RGGCopyToBuffer(nil, buf, (int)sizeof(buf));
        check(buf[0] == '\0', "RGGCopyToBuffer(nil) is empty");
        RGGCopyToBuffer(@"hello", buf, (int)sizeof(buf));
        check(strcmp(buf, "hello") == 0, "RGGCopyToBuffer copies plain text");
        RGGCopyToBuffer(@"hello world", buf, 8);   // 11 bytes + NUL > 8
        check(strcmp(buf, "hello w") == 0, "RGGCopyToBuffer clamps to buffer size");

        char mb[4];
        RGGCopyToBuffer(@"héllo", mb, (int)sizeof(mb));   // h + é(2 bytes) = 3 bytes + NUL = 4: fits
        check(strcmp(mb, "h\xC3\xA9") == 0, "RGGCopyToBuffer keeps a complete multibyte character");
        char mb2[3];
        RGGCopyToBuffer(@"héllo", mb2, (int)sizeof(mb2)); // h + partial é -> clamped to "h"
        check(strcmp(mb2, "h") == 0, "RGGCopyToBuffer never splits a multibyte character");

        // RGGSetStringFromBuffer: nil-guards invalid UTF-8 instead of throwing
        NSMutableString *text = [NSMutableString stringWithString:@"previous"];
        check(RGGSetStringFromBuffer(text, "valid text") == YES,
              "RGGSetStringFromBuffer updates on valid UTF-8");
        check([text isEqualToString:@"valid text"], "RGGSetStringFromBuffer wrote the text");
        check(RGGSetStringFromBuffer(text, "bad \xC3 tail") == NO,
              "RGGSetStringFromBuffer rejects invalid UTF-8");
        check([text isEqualToString:@"valid text"],
              "RGGSetStringFromBuffer keeps the old text on invalid UTF-8");
        check(RGGSetStringFromBuffer(text, "h\xC3\xA9llo") == YES,
              "RGGSetStringFromBuffer accepts multibyte UTF-8");
        check([text isEqualToString:@"héllo"], "RGGSetStringFromBuffer wrote multibyte text");

        // Constants
        check(RGGTextMaxLength == 1023, "RGGTextMaxLength is 1023");
        check(RGGTextBufferSize == 1024, "RGGTextBufferSize is 1024");
        // All enum values are pinned to raygui by _Static_assert in
        // RayguiImplementation.m; spot-check the ones that were wrong before
        // the WRAPPER_REVIEW.md fix.
        check(RGGScrollBarWidth == 18, "RGGScrollBarWidth is SCROLLBAR_WIDTH (18)");
        check(RGGScrollBarSide == 19, "RGGScrollBarSide is SCROLLBAR_SIDE (19)");
        check(RGGScrollSpeed == 21, "RGGScrollSpeed is SCROLL_SPEED (21)");
        check(RGGTabCloseButton == 17, "RGGTabCloseButton is TAB_CLOSE_BUTTON (17)");
    }

    if (failures == 0) {
        printf("ALL TESTS PASSED\n");
        return 0;
    }
    printf("%d TEST(S) FAILED\n", failures);
    return 1;
}
