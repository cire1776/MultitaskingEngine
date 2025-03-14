//
//  pointer_utilities_bridge.h
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/6/25.
//
#ifndef PointerUtilities_h
#define PointerUtilities_h

#include <stdint.h>

/// ✅ Convert `void *` to `uint64_t`
static inline uint64_t pointerToUInt64(void *ptr) {
    return (uint64_t)(uintptr_t)ptr;
}

/// ✅ Convert `uint64_t` back to `void *`
static inline void *uint64ToPointer(uint64_t value) {
    return (void *)(uintptr_t)value;
}

#endif /* PointerUtils_h */
