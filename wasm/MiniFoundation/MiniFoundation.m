// MiniFoundation.m — minimal Foundation for WebAssembly (libobjc2, gnustep-2.0 ABI).
// See Foundation/Foundation.h for the surface. Manual retain/release throughout.

#import <Foundation/Foundation.h>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//----------------------------------------------------------------------------------
// UTF-8 / UTF-16 helpers
//----------------------------------------------------------------------------------

// Validate a byte sequence as UTF-8. Returns YES if valid.
static BOOL RGGUTF8Valid(const char *s, size_t len) {
    size_t i = 0;
    while (i < len) {
        unsigned char c = (unsigned char)s[i];
        if (c < 0x80) { i++; continue; }
        int extra; uint32_t cp;
        if ((c & 0xE0) == 0xC0) { extra = 1; cp = c & 0x1F; if (cp < 2) return NO; }
        else if ((c & 0xF0) == 0xE0) { extra = 2; cp = c & 0x0F; }
        else if ((c & 0xF8) == 0xF0) { extra = 3; cp = c & 0x07; if (cp > 4) return NO; }
        else return NO;
        if (i + (size_t)extra >= len) return NO; // not enough bytes for the sequence
        for (int k = 1; k <= extra; k++) {
            unsigned char cc = (unsigned char)s[i + k];
            if ((cc & 0xC0) != 0x80) return NO;
            cp = (cp << 6) | (cc & 0x3F);
        }
        // reject overlong encodings and surrogates and > U+10FFFF
        if ((extra == 2 && cp < 0x800) || (extra == 3 && cp < 0x10000)) return NO;
        if (cp >= 0xD800 && cp <= 0xDFFF) return NO;
        if (cp > 0x10FFFF) return NO;
        i += (size_t)extra + 1;
    }
    return YES;
}

// Number of UTF-16 code units needed for a UTF-8 string.
static uint32_t RGGUTF8CountUTF16(const char *s, size_t len) {
    uint32_t units = 0;
    for (size_t i = 0; i < len;) {
        unsigned char c = (unsigned char)s[i];
        if (c < 0x80) { i += 1; units += 1; }
        else if ((c & 0xE0) == 0xC0) { i += 2; units += 1; }
        else if ((c & 0xF0) == 0xE0) { i += 3; units += 1; }
        else { i += 4; units += 2; } // surrogate pair
    }
    return units;
}

// Append one Unicode code point as UTF-8. Returns bytes written.
static size_t RGGAppendUTF8(char *out, uint32_t cp) {
    if (cp < 0x80) { out[0] = (char)cp; return 1; }
    if (cp < 0x800) {
        out[0] = (char)(0xC0 | (cp >> 6));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp < 0x10000) {
        out[0] = (char)(0xE0 | (cp >> 12));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }
    out[0] = (char)(0xF0 | (cp >> 18));
    out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
}

// Convert UTF-16 (with surrogate pairs) to a freshly malloc'd NUL-terminated
// UTF-8 string. *outLen receives the byte length (excluding NUL).
static char *RGGUTF16ToUTF8(const uint16_t *u16, uint32_t units, size_t *outLen) {
    char *buf = malloc((size_t)units * 3 + 1); // worst case 3 bytes per unit
    size_t n = 0;
    for (uint32_t i = 0; i < units; i++) {
        uint32_t cp = u16[i];
        if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < units) {
            uint32_t lo = u16[i + 1];
            if (lo >= 0xDC00 && lo <= 0xDFFF) {
                cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                i++;
            }
        }
        n += RGGAppendUTF8(buf + n, cp);
    }
    buf[n] = '\0';
    if (outLen) *outLen = n;
    return buf;
}

// Single-slot cache for UTF8String on UTF-16 constant strings. Safe here
// because callers consume the returned pointer immediately (the wrapper never
// stores a UTF8String result across calls).
static const char *RGGUTF16ToUTF8Cached(const uint16_t *u16, uint32_t units) {
    static char *buf;
    free(buf); // previous conversion is dead by contract
    buf = RGGUTF16ToUTF8(u16, units, NULL);
    return buf;
}

//----------------------------------------------------------------------------------
// NSObject
//----------------------------------------------------------------------------------

// Defined with NSLog at the bottom of this file.
@class NSMutableString;
static void RGGFormatAppend(NSMutableString *out, NSString *format, va_list ap);

static Class RGGConstantStringClass(void) {
    static Class cls;
    if (cls == Nil) cls = objc_getClass("NSConstantString");
    return cls;
}

// @"..." literals are static globals with no room for a retain count — they are
// immortal. (libobjc2 also flags the class permanent_instances by name, which
// covers the runtime's own objc_release path; this guard covers direct
// message sends from our own -retain/-release/-autorelease.)
static BOOL RGGIsConstantString(id obj) {
    return object_getClass(obj) == RGGConstantStringClass();
}

@implementation NSObject

+ (id)alloc {
    // One extra word after the instance holds the manual-retain/release count.
    id obj = class_createInstance(self, sizeof(unsigned long));
    if (obj != nil) {
        *(unsigned long *)((char *)obj + class_getInstanceSize(self)) = 1;
    }
    return obj;
}

- (id)init { return self; }

// Retain count lives in the extra bytes past the instance (see +alloc).
- (unsigned long *)rggRetainCountSlot {
    return (unsigned long *)((char *)self + class_getInstanceSize(object_getClass(self)));
}

- (id)retain {
    if (RGGIsConstantString(self)) return self;
    (*[self rggRetainCountSlot])++;
    return self;
}

- (oneway void)release {
    if (RGGIsConstantString(self)) return;
    if (--(*[self rggRetainCountSlot]) == 0) [self dealloc];
}

- (id)autorelease {
    if (RGGIsConstantString(self)) return self;
    return objc_autorelease(self);
}

- (NSUInteger)retainCount {
    if (RGGIsConstantString(self)) return (NSUInteger)-1;
    return *[self rggRetainCountSlot];
}

// Terminal dealloc. Subclasses free their own ivars and call object_dispose
// directly rather than messaging super (deterministic on this runtime).
- (void)dealloc {
    object_dispose(self);
}

@end

//----------------------------------------------------------------------------------
// NSString
//----------------------------------------------------------------------------------

// Internal byte-level accessors on NSMutableString (declared here so NSString's
// factory methods and NSLog can drive them without touching @private ivars).
@interface NSMutableString (RGGInternal)
- (void)rggReplaceBytes:(const char *)bytes length:(NSUInteger)len;
- (void)rggAppendBytes:(const char *)bytes length:(NSUInteger)len;
@end

@implementation NSString

// NSString itself is never instantiated (no storage ivars); the concrete
// subclasses implement the primitives. These fallbacks keep the class complete.

+ (id)stringWithUTF8String:(const char *)bytes {
    if (bytes == NULL) return nil;
    size_t len = strlen(bytes);
    if (!RGGUTF8Valid(bytes, len)) return nil; // wrapper relies on nil for bad UTF-8
    NSMutableString *s = [[NSMutableString alloc] init];
    [s rggReplaceBytes:bytes length:len];
    return [s autorelease];
}

+ (id)stringWithFormat:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSMutableString *s = [[NSMutableString alloc] init];
    RGGFormatAppend(s, format, ap);
    va_end(ap);
    return [s autorelease];
}

- (const char *)UTF8String { return NULL; }
- (NSUInteger)length { return 0; }
- (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)encoding { (void)encoding; return 0; }

@end

//----------------------------------------------------------------------------------
// NSConstantString — @"..." literals
//----------------------------------------------------------------------------------

@implementation NSConstantString

- (const char *)UTF8String {
    uint32_t enc = flags & 3;
    if (enc == 0 || enc == 1) return data; // ASCII / UTF-8 stored as-is
    if (enc == 2) return RGGUTF16ToUTF8Cached((const uint16_t *)data, length);
    return data; // UTF-32: not produced by clang for literals; pass through
}

- (NSUInteger)length {
    return length; // UTF-16 code units (ABI field)
}

- (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)encoding {
    if (encoding == NSUTF8StringEncoding) {
        uint32_t enc = flags & 3;
        if (enc == 0 || enc == 1) return size;
        const char *u8 = [self UTF8String];
        return u8 ? (NSUInteger)strlen(u8) : 0;
    }
    return size;
}

@end

//----------------------------------------------------------------------------------
// NSMutableString
//----------------------------------------------------------------------------------

@implementation NSMutableString

+ (id)stringWithString:(NSString *)string {
    NSMutableString *s = [NSMutableString stringWithCapacity:64];
    if (string != nil) [s setString:string];
    return s;
}

+ (id)stringWithCapacity:(NSUInteger)capacity {
    NSMutableString *s = [[NSMutableString alloc] init];
    NSUInteger cap = capacity ? capacity : 16;
    s->data = malloc(cap);
    s->capacity = cap;
    s->length = 0;
    s->data[0] = '\0';
    return [s autorelease];
}

- (void)rggReplaceBytes:(const char *)bytes length:(NSUInteger)len {
    if (len + 1 > capacity) {
        NSUInteger newCap = capacity ? capacity : 16;
        while (newCap < len + 1) newCap *= 2;
        char *nd = realloc(data, newCap);
        if (!nd) return; // out of memory: keep previous contents
        data = nd;
        capacity = newCap;
    }
    if (len > 0) memcpy(data, bytes, len);
    data[len] = '\0';
    length = len;
}

- (void)rggAppendBytes:(const char *)bytes length:(NSUInteger)len {
    if (len == 0) return;
    if (length + len + 1 > capacity) {
        NSUInteger newCap = capacity ? capacity : 16;
        while (newCap < length + len + 1) newCap *= 2;
        char *nd = realloc(data, newCap);
        if (!nd) return;
        data = nd;
        capacity = newCap;
    }
    memcpy(data + length, bytes, len);
    length += len;
    data[length] = '\0';
}

- (void)appendString:(NSString *)string {
    if (string == nil) return;
    const char *bytes = [string UTF8String];
    if (bytes == NULL) return;
    [self rggAppendBytes:bytes length:strlen(bytes)];
}

- (void)setString:(NSString *)string {
    if (string == nil) {
        [self rggReplaceBytes:"" length:0];
        return;
    }
    const char *bytes = [string UTF8String];
    if (bytes == NULL) return;
    [self rggReplaceBytes:bytes length:strlen(bytes)];
}

- (const char *)UTF8String {
    return data ? data : "";
}

- (NSUInteger)length {
    return RGGUTF8CountUTF16(data, length); // UTF-16 code units
}

- (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)encoding {
    if (encoding == NSUTF8StringEncoding) return length;
    return length;
}

- (void)dealloc {
    free(data);
    object_dispose(self);
}

@end

//----------------------------------------------------------------------------------
// NSArray
//----------------------------------------------------------------------------------

@implementation NSArray

+ (id)arrayWithObjects:(const id *)objects count:(NSUInteger)cnt {
    NSArray *a = [[NSArray alloc] init];
    a->items = malloc((cnt ? cnt : 1) * sizeof(id));
    a->count = cnt;
    for (NSUInteger i = 0; i < cnt; i++) {
        a->items[i] = [objects[i] retain];
    }
    return [a autorelease];
}

- (NSUInteger)count { return count; }

- (id)objectAtIndex:(NSUInteger)index {
    return (index < count) ? items[index] : nil;
}

- (void)dealloc {
    for (NSUInteger i = 0; i < count; i++) [items[i] release];
    free(items);
    object_dispose(self);
}

@end

//----------------------------------------------------------------------------------
// NSLog + mini formatter
//----------------------------------------------------------------------------------

// Append the formatted expansion of `format` to `out`. Supports the common
// conversions: %@ %d %i %u %x %X %o %c %s %p %f %g %e %% with flags, width,
// precision and h/hh/l/ll/z/t length modifiers. va_arg is used directly (a
// single va_list cannot be re-scanned by repeated vsnprintf calls on wasm).
static void RGGFormatAppend(NSMutableString *out, NSString *format, va_list ap) {
    const char *fmt = [format UTF8String];
    if (fmt == NULL) return;
    const char *p = fmt;
    char buf[1024];
    while (*p) {
        if (*p != '%') {
            const char *start = p;
            while (*p && *p != '%') p++;
            [out rggAppendBytes:start length:(NSUInteger)(p - start)];
            continue;
        }
        p++; // consume '%'
        if (*p == '%') { [out rggAppendBytes:"%" length:1]; p++; continue; }

        // flags
        char flags[8]; int nf = 0;
        while (*p && strchr("-+ #0'", *p) && nf < 7) flags[nf++] = *p++;
        flags[nf] = '\0';
        // width
        int width = -1;
        if (*p == '*') { width = va_arg(ap, int); p++; }
        else if (isdigit((unsigned char)*p)) {
            width = 0;
            while (isdigit((unsigned char)*p)) { width = width * 10 + (*p - '0'); p++; }
        }
        // precision
        int prec = -1;
        if (*p == '.') {
            p++;
            if (*p == '*') { prec = va_arg(ap, int); p++; }
            else {
                prec = 0;
                while (isdigit((unsigned char)*p)) { prec = prec * 10 + (*p - '0'); p++; }
            }
        }
        // length modifier (h hh l ll L q z t j)
        char lenmod = 0;
        if (*p && strchr("hlLqztj", *p)) {
            lenmod = *p++;
            if ((lenmod == 'h' || lenmod == 'l') && *p == lenmod) {
                lenmod = (lenmod == 'h') ? 'H' : 'L'; // hh / ll
                p++;
            }
        }
        char conv = *p;
        if (conv == '\0') break;
        p++;

        switch (conv) {
            case '@': {
                id obj = va_arg(ap, id);
                const char *s = obj ? [obj UTF8String] : NULL;
                if (s == NULL) s = "(nil)";
                [out rggAppendBytes:s length:strlen(s)];
                break;
            }
            case 's': {
                const char *s = va_arg(ap, const char *);
                if (s == NULL) s = "(null)";
                size_t l = strlen(s);
                if (prec >= 0 && (size_t)prec < l) l = (size_t)prec;
                if (width > (int)l) {
                    for (int i = 0; i < width - (int)l; i++) [out rggAppendBytes:" " length:1];
                }
                [out rggAppendBytes:s length:l];
                break;
            }
            case 'c': {
                char c = (char)va_arg(ap, int);
                [out rggAppendBytes:&c length:1];
                break;
            }
            case 'd': case 'i': {
                long long v;
                switch (lenmod) {
                    case 'L': v = va_arg(ap, long long); break;
                    case 'l': v = (long long)va_arg(ap, long); break;
                    case 'z': v = (long long)va_arg(ap, size_t); break;
                    case 't': v = (long long)va_arg(ap, ptrdiff_t); break;
                    case 'H': v = (signed char)va_arg(ap, int); break;
                    case 'h': v = (short)va_arg(ap, int); break;
                    default:  v = (long long)va_arg(ap, int); break;
                }
                char spec[64]; int si = 0;
                spec[si++] = '%';
                memcpy(spec + si, flags, (size_t)nf); si += nf;
                if (width >= 0) si += snprintf(spec + si, sizeof(spec) - si, "%d", width);
                if (prec >= 0) si += snprintf(spec + si, sizeof(spec) - si, ".%d", prec);
                memcpy(spec + si, "lld", 3); si += 3; spec[si] = '\0';
                snprintf(buf, sizeof(buf), spec, v);
                [out rggAppendBytes:buf length:strlen(buf)];
                break;
            }
            case 'u': case 'x': case 'X': case 'o': {
                unsigned long long v;
                switch (lenmod) {
                    case 'L': v = va_arg(ap, unsigned long long); break;
                    case 'l': v = (unsigned long long)va_arg(ap, unsigned long); break;
                    case 'z': v = (unsigned long long)va_arg(ap, size_t); break;
                    case 't': v = (unsigned long long)va_arg(ap, ptrdiff_t); break;
                    case 'H': v = (unsigned char)va_arg(ap, int); break;
                    case 'h': v = (unsigned short)va_arg(ap, int); break;
                    default:  v = (unsigned long long)va_arg(ap, unsigned int); break;
                }
                char spec[64]; int si = 0;
                spec[si++] = '%';
                memcpy(spec + si, flags, (size_t)nf); si += nf;
                if (width >= 0) si += snprintf(spec + si, sizeof(spec) - si, "%d", width);
                if (prec >= 0) si += snprintf(spec + si, sizeof(spec) - si, ".%d", prec);
                const char *suffix = (conv == 'u') ? "llu" : (conv == 'x') ? "llx" : (conv == 'X') ? "llX" : "llo";
                size_t sl = strlen(suffix);
                memcpy(spec + si, suffix, sl); si += (int)sl; spec[si] = '\0';
                snprintf(buf, sizeof(buf), spec, v);
                [out rggAppendBytes:buf length:strlen(buf)];
                break;
            }
            case 'f': case 'g': case 'e': case 'F': case 'G': case 'E': case 'a': case 'A': {
                double v = va_arg(ap, double);
                char spec[64]; int si = 0;
                spec[si++] = '%';
                memcpy(spec + si, flags, (size_t)nf); si += nf;
                if (width >= 0) si += snprintf(spec + si, sizeof(spec) - si, "%d", width);
                if (prec >= 0) si += snprintf(spec + si, sizeof(spec) - si, ".%d", prec);
                spec[si++] = conv; spec[si] = '\0';
                snprintf(buf, sizeof(buf), spec, v);
                [out rggAppendBytes:buf length:strlen(buf)];
                break;
            }
            case 'p': {
                void *v = va_arg(ap, void *);
                snprintf(buf, sizeof(buf), "%p", v);
                [out rggAppendBytes:buf length:strlen(buf)];
                break;
            }
            default:
                // Unknown conversion: emit it verbatim.
                [out rggAppendBytes:"%" length:1];
                [out rggAppendBytes:&conv length:1];
                break;
        }
    }
}

void NSLog(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSMutableString *msg = [[NSMutableString alloc] init];
    RGGFormatAppend(msg, format, ap);
    va_end(ap);
    const char *text = [msg UTF8String];
    fprintf(stderr, "%s\n", text ? text : "(nil)");
    fflush(stderr);
    [msg release];
}
