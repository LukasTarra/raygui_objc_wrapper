// minifoundation_test.m — exercises the MiniFoundation surface the wrapper uses.
// Build + run under node; prints ALL MINIFOUNDATION TESTS PASSED on success.

#import <Foundation/Foundation.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>

static int gDeallocCount = 0;

@interface TestObject : NSObject {
@public
    int tag;
}
@end

@implementation TestObject
- (void)dealloc {
    gDeallocCount++;
    object_dispose(self);
}
@end

int main(void) {
    // --- NSObject: alloc/retain/release/autorelease, ivar after isa ---
    @autoreleasepool {
        TestObject *t = [[TestObject alloc] init];
        assert(t != nil);
        assert([t retainCount] == 1);
        [t retain];
        assert([t retainCount] == 2);
        t->tag = 42;
        assert(t->tag == 42);
        assert(object_getClass(t) == objc_getClass("TestObject")); // isa intact
        [t release];
        assert([t retainCount] == 1);
        [t autorelease];
        assert(gDeallocCount == 0); // not yet drained
    }
    assert(gDeallocCount == 1); // pool drain released it

    @autoreleasepool {
        // --- NSString ---
        NSString *s = [NSString stringWithUTF8String:"hello"];
        assert(s != nil);
        assert(strcmp([s UTF8String], "hello") == 0);
        assert([s lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 5);
        assert([s length] == 5);
        NSString *bad = [NSString stringWithUTF8String:"\xC3\x28"]; // invalid UTF-8
        assert(bad == nil);

        // --- stringWithFormat: ---
        NSString *f = [NSString stringWithFormat:@"%d %.2f %@ %s %% %lu", 42, 3.14159, @"obj", "str", 7UL];
        assert(strcmp([f UTF8String], "42 3.14 obj str % 7") == 0);

        // --- NSMutableString ---
        NSMutableString *m = [NSMutableString stringWithString:@"abc"];
        [m appendString:@"def"];
        assert(strcmp([m UTF8String], "abcdef") == 0);
        [m setString:@"xyz"];
        assert(strcmp([m UTF8String], "xyz") == 0);
        NSMutableString *cap = [NSMutableString stringWithCapacity:100];
        [cap appendString:@"q"];
        assert(strcmp([cap UTF8String], "q") == 0);
        assert([m lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 3);

        // --- NSArray (@[] literal) ---
        NSArray *a = @[@"one", @"two", @"three"];
        assert([a count] == 3);
        assert(strcmp([[a objectAtIndex:1] UTF8String], "two") == 0);
        assert([a objectAtIndex:99] == nil);

        // --- NSConstantString: ASCII and UTF-16 literals ---
        NSString *ascii = @"plain ascii";
        assert(strcmp([ascii UTF8String], "plain ascii") == 0);
        assert([ascii lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 11);
        NSString *uni = @"em—dash"; // non-ASCII => UTF-16 constant
        assert(strcmp([uni UTF8String], "em—dash") == 0);
        assert([uni lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 9);
        assert([uni length] == 7); // UTF-16 code units

        // retain/release/autorelease on constant strings: no-op, no crash
        [ascii retain];
        [ascii release];
        [ascii autorelease];

        // --- NSLog ---
        NSLog(@"test NSLog: %d %@", 7, @"done");
    }

    printf("ALL MINIFOUNDATION TESTS PASSED\n");
    return 0;
}
