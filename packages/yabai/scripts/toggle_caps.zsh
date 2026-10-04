#!/usr/bin/env zsh
set -euo pipefail

# Directory to store the compiled helper binary
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/yabai"
BIN="$CACHE_DIR/caps_toggle"

# Auto-compile the IOKit helper on first run
if [[ ! -x "$BIN" ]]; then
    mkdir -p "$CACHE_DIR"
    /usr/bin/clang -O2 \
        -framework IOKit \
        -framework CoreFoundation \
        -x c - -o "$BIN" << 'EOF'
#include <stdio.h>
#include <stdbool.h>
#include <mach/mach_port.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/IOHIDShared.h>

#ifndef kIOHIDCapsLockState
#define kIOHIDCapsLockState 0x00000001
#endif

#ifndef kIOHIDParamConnectType
#define kIOHIDParamConnectType 1
#endif

int main(void) {
    io_service_t service = IOServiceGetMatchingService(
        MACH_PORT_NULL,
        IOServiceMatching(kIOHIDSystemClass)
    );
    if (!service) return 1;

    io_connect_t connect;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), kIOHIDParamConnectType, &connect);
    IOObjectRelease(service);
    if (kr != KERN_SUCCESS) return 2;

    bool state = false;
    kr = IOHIDGetModifierLockState(connect, kIOHIDCapsLockState, &state);
    if (kr != KERN_SUCCESS) {
        IOServiceClose(connect);
        return 3;
    }

    bool newState = !state;
    kr = IOHIDSetModifierLockState(connect, kIOHIDCapsLockState, newState);
    IOServiceClose(connect);

    if (kr != KERN_SUCCESS) return 4;

    printf("Caps Lock %s\n", newState ? "ON" : "OFF");
    return 0;
}
EOF
fi

# Execute the compiled binary
exec "$BIN"