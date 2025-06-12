// Smart Danger Avoider - ARM64 Assembly for macOS
// Intelligently avoids Ocean ('O') and Lava ('L') while seeking safe tiles

.data
.align 3
turn_count:         .word 0
danger_encounters:  .word 0
last_move:          .byte 46    // '.' = Stay
survival_mode:      .byte 0     // 0 = normal, 1 = emergency avoidance

.text
.global _take_turn
.p2align 2

_take_turn:
    // Save registers
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    
    // Increment turn counter
    adrp x2, turn_count@PAGE
    add x2, x2, turn_count@PAGEOFF
    ldr w3, [x2]
    add w3, w3, #1
    str w3, [x2]
    
    // Extract environment bytes (same as forest explorer)
    // Position mapping:
    // 0=NW  1=N   2=NE
    // 3=W   4=C   5=E
    // 6=SW  7=S   8=SE
    
    mov x10, x0
    lsr x10, x10, #56   // Byte 0 (NW)
    and w20, w10, #0xFF
    
    mov x10, x0
    lsr x10, x10, #48   // Byte 1 (N)
    and w21, w10, #0xFF
    
    mov x10, x0
    lsr x10, x10, #40   // Byte 2 (NE)
    and w22, w10, #0xFF
    
    mov x10, x0
    lsr x10, x10, #32   // Byte 3 (W)
    and w23, w10, #0xFF
    
    mov x10, x0
    lsr x10, x10, #24   // Byte 4 (Center - our current position)
    and w24, w10, #0xFF
    
    mov x10, x0
    lsr x10, x10, #16   // Byte 5 (E)
    and w25, w10, #0xFF
    
    mov x10, x0
    lsr x10, x10, #8    // Byte 6 (SW)
    and w26, w10, #0xFF
    
    mov x10, x0         // Byte 7 (S)
    and w27, w10, #0xFF
    
    mov x10, x1
    lsr x10, x10, #56   // Byte 8 (SE)
    and w28, w10, #0xFF
    
    // First, check if we're currently in danger
    cmp w24, #'O'       // Ocean
    beq emergency_mode
    cmp w24, #'L'       // Lava
    beq emergency_mode
    b normal_analysis
    
emergency_mode:
    // We're in immediate danger! Find ANY safe direction
    adrp x2, survival_mode@PAGE
    add x2, x2, survival_mode@PAGEOFF
    mov w3, #1
    strb w3, [x2]
    
    // Increment danger counter
    adrp x2, danger_encounters@PAGE
    add x2, x2, danger_encounters@PAGEOFF
    ldr w3, [x2]
    add w3, w3, #1
    str w3, [x2]
    
    // Try cardinal directions first for emergency escape
    bl check_safe_north
    cbnz w0, go_north
    
    bl check_safe_east
    cbnz w0, go_east
    
    bl check_safe_south
    cbnz w0, go_south
    
    bl check_safe_west
    cbnz w0, go_west
    
    // Try diagonals if no cardinal direction is safe
    bl check_safe_northeast
    cbnz w0, go_northeast
    
    bl check_safe_southeast
    cbnz w0, go_southeast
    
    bl check_safe_southwest
    cbnz w0, go_southwest
    
    bl check_safe_northwest
    cbnz w0, go_northwest
    
    // No safe move found - stay and hope for the best
    mov w0, #'.'
    b done

normal_analysis:
    // Normal mode - be smart about movement
    adrp x2, survival_mode@PAGE
    add x2, x2, survival_mode@PAGEOFF
    mov w3, #0
    strb w3, [x2]
    
    // Score each direction based on safety and desirability
    mov w19, #0         // Best direction (default: stay)
    mov w20, #-100      // Best score (very low default)
    
    // Analyze North
    mov w0, w21         // North cell
    mov w1, #'N'        // Direction character
    bl score_direction
    cmp w0, w20
    ble check_east
    mov w20, w0         // New best score
    mov w19, #'N'       // New best direction
    
check_east:
    mov w0, w25         // East cell
    mov w1, #'E'
    bl score_direction
    cmp w0, w20
    ble check_south
    mov w20, w0
    mov w19, #'E'
    
check_south:
    mov w0, w27         // South cell
    mov w1, #'S'
    bl score_direction
    cmp w0, w20
    ble check_west
    mov w20, w0
    mov w19, #'S'
    
check_west:
    mov w0, w23         // West cell
    mov w1, #'W'
    bl score_direction
    cmp w0, w20
    ble check_diagonals
    mov w20, w0
    mov w19, #'W'
    
check_diagonals:
    // Check diagonal directions (lower priority)
    mov w0, w22         // Northeast
    mov w1, #'O'
    bl score_direction
    sub w0, w0, #1      // Slight penalty for diagonal
    cmp w0, w20
    ble check_se
    mov w20, w0
    mov w19, #'O'
    
check_se:
    mov w0, w28         // Southeast
    mov w1, #'F'
    bl score_direction
    sub w0, w0, #1
    cmp w0, w20
    ble check_sw
    mov w20, w0
    mov w19, #'F'
    
check_sw:
    mov w0, w26         // Southwest
    mov w1, #'T'
    bl score_direction
    sub w0, w0, #1
    cmp w0, w20
    ble check_nw
    mov w20, w0
    mov w19, #'T'
    
check_nw:
    mov w0, w20         // Northwest
    mov w1, #'X'
    bl score_direction
    sub w0, w0, #1
    cmp w0, w20
    ble make_move
    mov w20, w0
    mov w19, #'X'
    
make_move:
    // If no good move found, stay
    cmp w20, #-50
    bgt 1f
    mov w19, #'.'
    
1:
    mov w0, w19
    b done

// Subroutine: score_direction
// Input: w0 = cell type, w1 = direction char
// Output: w0 = score (-100 to 100)
score_direction:
    // Danger tiles get very negative scores
    cmp w0, #'O'        // Ocean
    beq danger_tile
    cmp w0, #'L'        // Lava
    beq danger_tile
    
    // Safe tiles get positive scores
    cmp w0, #'F'        // Forest
    beq forest_tile
    cmp w0, #'P'        // Open land
    beq open_tile
    
    // Unknown/invalid tile
    mov w0, #-50
    ret
    
danger_tile:
    mov w0, #-100       // Very bad
    ret
    
forest_tile:
    mov w0, #10         // Good
    ret
    
open_tile:
    mov w0, #5          // Decent
    ret

// Safety check subroutines for emergency mode
check_safe_north:
    cmp w21, #'O'
    beq unsafe
    cmp w21, #'L'
    beq unsafe
    mov w0, #1
    ret
unsafe:
    mov w0, #0
    ret

check_safe_east:
    cmp w25, #'O'
    beq unsafe
    cmp w25, #'L'
    beq unsafe
    mov w0, #1
    ret

check_safe_south:
    cmp w27, #'O'
    beq unsafe
    cmp w27, #'L'
    beq unsafe
    mov w0, #1
    ret

check_safe_west:
    cmp w23, #'O'
    beq unsafe
    cmp w23, #'L'
    beq unsafe
    mov w0, #1
    ret

check_safe_northeast:
    cmp w22, #'O'
    beq unsafe
    cmp w22, #'L'
    beq unsafe
    mov w0, #1
    ret

check_safe_southeast:
    cmp w28, #'O'
    beq unsafe
    cmp w28, #'L'
    beq unsafe
    mov w0, #1
    ret

check_safe_southwest:
    cmp w26, #'O'
    beq unsafe
    cmp w26, #'L'
    beq unsafe
    mov w0, #1
    ret

check_safe_northwest:
    cmp w20, #'O'
    beq unsafe
    cmp w20, #'L'
    beq unsafe
    mov w0, #1
    ret

// Direction return labels
go_north:
    mov w0, #'N'
    b done
    
go_east:
    mov w0, #'E'
    b done
    
go_south:
    mov w0, #'S'
    b done
    
go_west:
    mov w0, #'W'
    b done
    
go_northeast:
    mov w0, #'O'
    b done
    
go_southeast:
    mov w0, #'F'
    b done
    
go_southwest:
    mov w0, #'T'
    b done
    
go_northwest:
    mov w0, #'X'
    b done

done:
    // Store last move
    adrp x2, last_move@PAGE
    add x2, x2, last_move@PAGEOFF
    strb w0, [x2]
    
    // Restore registers and return
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret