// Foundation/Foundation.h — MiniFoundation for WebAssembly.
//
// A minimal Foundation implementation covering exactly what RayguiObjC uses,
// built on the GNUstep Objective-C runtime (libobjc2, clang's gnustep-2.0 ABI).
// It exists so the wrapper and demo compile and run unmodified under emscripten
// without pulling in all of gnustep-base.
//
// Provided:
//   NSObject            alloc/init/retain/release/autorelease/retainCount/dealloc
//   NSString            stringWithUTF8String: (nil on invalid UTF-8),
//                       stringWithFormat:, UTF8String, length,
//                       lengthOfBytesUsingEncoding:
//   NSConstantString    @"..." literals (layout fixed by the compiler ABI)
//   NSMutableString     stringWithString:, stringWithCapacity:, appendString:,
//                       setString:
//   NSArray             arrayWithObjects:count: (backs @[] literals), count,
//                       objectAtIndex:
//   NSLog               NSLog(NSString *format, ...)
//   NS_ENUM, NS_UNAVAILABLE, NSUInteger, NSInteger, NSStringEncoding,
//   NSUTF8StringEncoding
//
// Memory management is manual retain/release (no ARC), matching the wrapper.
// Class layouts follow the libobjc2 non-fragile ABI: root classes declare
// `Class isa;` explicitly; subclass ivars start after the superclass's
// instance_size; constant strings use the ABI-fixed struct nsstr layout.

#ifndef MINIFOUNDATION_FOUNDATION_H
#define MINIFOUNDATION_FOUNDATION_H

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/objc-arc.h>

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

typedef unsigned long NSUInteger;
typedef long NSInteger;
typedef unsigned long NSStringEncoding;

enum {
    NSUTF8StringEncoding = 4
};

// NS_ENUM / NS_UNAVAILABLE (Apple-compatible definitions)
#if (__cplusplus && __cplusplus >= 201103L && (__has_extension(cxx_strong_enums) || __has_feature(objc_fixed_enum))) || (!__cplusplus && __has_feature(objc_fixed_enum))
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#else
#define NS_ENUM(_type, _name) _type _name; enum
#endif

#ifndef NS_UNAVAILABLE
#define NS_UNAVAILABLE __attribute__((unavailable))
#endif

#include <stdio.h>
#include <stdlib.h>

// No exception machinery in this shim: a failed parameter assertion is a
// programmer error — log and abort (matches the debug behavior of raising
// NSInvalidArgumentException closely enough for a demo harness).
#ifndef NSParameterAssert
#define NSParameterAssert(condition) \
    do { \
        if (!(condition)) { \
            fprintf(stderr, "*** NSParameterAssertion failure: %s (%s:%d)\n", \
                    #condition, __FILE__, __LINE__); \
            abort(); \
        } \
    } while (0)
#endif

@interface NSObject {
@private
    // Root classes in the libobjc2 non-fragile ABI declare isa explicitly;
    // it occupies offset 0 and is included in instance_size.
    Class isa;
}
+ (id)alloc;
- (id)init;
- (id)retain;
- (oneway void)release;
- (id)autorelease;
- (NSUInteger)retainCount;
- (void)dealloc;
@end

@interface NSString : NSObject
+ (id)stringWithUTF8String:(const char *)bytes;
+ (id)stringWithFormat:(NSString *)format, ...;
- (const char *)UTF8String;
- (NSUInteger)length;
- (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)encoding;
@end

// Instances are produced by the compiler for @"..." literals. The ivar layout
// is fixed by the ABI (libobjc2 loader.c, struct nsstr): isa@0, flags@4
// (low 2 bits: 0=ASCII 1=UTF-8 2=UTF-16 3=UTF-32), length@8 (UTF-16 code units),
// size@12 (bytes of data), hash@16, data@20. Do not redeclare or reorder.
@interface NSConstantString : NSString {
@private
    uint32_t flags;
    uint32_t length;
    uint32_t size;
    uint32_t hash;
    const char *data;
}
@end

@interface NSMutableString : NSString {
@private
    char *data;        // null-terminated UTF-8
    NSUInteger length; // bytes in data (excluding NUL)
    NSUInteger capacity;
}
+ (id)stringWithString:(NSString *)string;
+ (id)stringWithCapacity:(NSUInteger)capacity;
- (void)appendString:(NSString *)string;
- (void)setString:(NSString *)string;
@end

@interface NSArray<__covariant ObjectType> : NSObject {
@private
    id *items;
    NSUInteger count;
}
+ (id)arrayWithObjects:(const ObjectType *)objects count:(NSUInteger)count;
- (NSUInteger)count;
- (ObjectType)objectAtIndex:(NSUInteger)index;
@end

void NSLog(NSString *format, ...);

#endif // MINIFOUNDATION_FOUNDATION_H
