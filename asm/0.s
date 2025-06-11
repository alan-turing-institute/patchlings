
.section __TEXT,__text
.global _take_turn
.p2align 2


// ----- Functions: ---------
// args passed in x0 -> x7
// x0 -> x18 can be used for scratch (caller-saved)
// put result in x0 and then 'ret'

action_of_idx:
    // args:
    //   idx: uint,

    // prologue
    stp x29, x30, [sp, #-16]!
    mov x29, sp


    adrp x1, actions@PAGE        // load page-aligned address of 'actions'
    add  x1, x1, actions@PAGEOFF // add the low 12-bit offset

    ldrb w0, [x1, w0, uxtw] // w0 = actions[w0], load 1 byte

    // epilogue
    ldp x29, x30, [sp], #16
    ret

at_byte_idx:
    // args:
    //   x: u64,
    //   idx: uint,

    // prologue
    stp x29, x30, [sp, #-16]! // store pair of registers, fp and lr. Store them in the 16 bytes below where sp is now. The ! then updates sp to include the offset. (stack grows downwards)
    mov x29, sp // set the frame pointer (will point to the start of this stack frame for the duration of the function, even if sp decrements (e.g. with new variables put onto the stack).

    mov x3, #8 // 8 bit offset
    mul x2, x1, x3 // idx - 8
    mov x4, #56
    sub x1, x4, x2 // desired bitshift is now in x1

    mov x2, #0xFF // bit mask
    lsl x3, x2, x1 // shift the bit mask
    and x4, x0, x3 // extract the byte from the input
    lsr x0, x4, x1 // bit shift the extracted byte

    // epilogue
    ldp x29, x30, [sp], #16
    ret

_take_turn:
    // args:
    // x0 surrounding: u64,
    // x1 underfoot: u64,

    // prologue
    stp x29, x30, [sp, #-16]!
    mov x29, sp 

    // caller-save the inputs
    mov x19, x0 // surrounding
    mov x20, x1 // underfoot

    // save underfoot tile in x21
    mov x0, x20 // input bytes
    mov x1, #0 // idx
    bl at_byte_idx // x0=selected_byte
    mov x21, x0

    // stand still if on forest
    cmp x21, #'F'
    b.eq still

    // look for forest
    mov x22, #0 // idx start
    mov x23, #8 // idx end (exclusive)
loop:
    cmp x22, x23
    b.ge loop_end

    mov x0, x19 // surrounding in x0
    mov x1, x22 // idx
    bl at_byte_idx
    cmp x0, #'F'
    b.eq found_forest

    add x22, x22, #1
    b loop

found_forest:
    mov x0, x22
    bl action_of_idx
    b exit

loop_end:
    // can't find forest, move south
    mov x0, #'S'
    b exit


still:
    mov x0, #'.'
    b exit

exit:
    // epilogue
    ldp x29, x30, [sp], #16
    ret


.section __DATA,__data
actions:
    .ascii "XWTSFEON"

