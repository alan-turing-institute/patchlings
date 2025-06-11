// example.s — for Apple Silicon (macOS ARM64)
.global _take_turn
.p2align 2

// uint32_t take_turn(uint32_t input)
_take_turn:
    // input is in w0, return also in w0
    add w0, w0, #7
    ret
