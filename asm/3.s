.text
.global _take_turn
.p2align 2

_take_turn:
    ; Write, 0x5857545346454f4e, which is the string "XWTSFEON", to x3. These are the proposed actions, in the same order as the input in x0.
    movz x3, 0x4f4e, lsl #0
    movk x3, 0x4645, lsl #16
    movk x3, 0x5453, lsl #32
    movk x3, 0x5857, lsl #48
    b step

step:
    and x2, x0, 0xFF ; Load the last byte of x0 to x2
    cmp x2, #'F' ; If x2 is #'F' or #'P' jump to finish
    beq finish
    cmp x2, #'P'
    beq finish
    lsr x0, x0, 8 ; If this direction was not safe, shift by a byte, bringing the next candidate direction to the last byte
    lsr x3, x3, 8 ; Do the same shift for both the input and for the suggested directions.
    cmp x3, 0 ; If the suggested directions is zero. We're all out, now direction is safe.
    bne step ; If that is _not_ the case, call step again.
    mov x0, #'.' ; Otherwise return #'.'.
    ret

finish:
    and x0, x3, 0xFF ; Return the last byte of x3.
    ret
