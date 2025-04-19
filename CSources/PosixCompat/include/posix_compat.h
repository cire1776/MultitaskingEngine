//
//  posix_campat.h
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/13/25.
//

#ifndef posix_compat_h
#define posix_compat_h

#include <sys/select.h>

static inline void swift_fd_zero(fd_set *set) {
    FD_ZERO(set);
}

static inline void swift_fd_set(int fd, fd_set *set) {
    FD_SET(fd, set);
}
#endif
