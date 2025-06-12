// Forest Explorer - ARM64 Assembly for macOS
// Seeks out forests and tries to visit new ones

.data
.align 3
turn_count:     .word 0
last_move:      .byte 46    // '.' = Stay

.text
.global _take_turn
.p2align 2

_take_turn:
    // Save link register
    stp x29, x30, [sp, #-16]!
    
    // Increment turn counter
    adrp x2, turn_count@PAGE
    add x2, x2, turn_count@PAGEOFF
    ldr w3, [x2]
    add w3, w3, #1
    str w3, [x2]
    
    // x0 contains first 8 bytes (big-endian)
    // x1 contains last byte in MSB
    
    // Extract environment bytes
    // Position mapping:
    // 0=NW  1=N   2=NE
    // 3=W   4=C   5=E
    // 6=SW  7=S   8=SE
    
    // Extract each cell value
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
    lsr x10, x10, #24   // Byte 4 (Center)
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
    
    // Priority: Look for forests first, then safe cells
    // Check cardinal directions first
    
    // North
    cmp w21, #'F'       // Is it a forest?
    beq go_north
    
    // East  
    cmp w25, #'F'
    beq go_east
    
    // South
    cmp w27, #'F'
    beq go_south
    
    // West
    cmp w23, #'F'
    beq go_west
    
    // No forests in cardinal directions, check diagonals
    cmp w22, #'F'       // NE
    beq go_northeast
    
    cmp w28, #'F'       // SE
    beq go_southeast
    
    cmp w26, #'F'       // SW
    beq go_southwest
    
    cmp w20, #'F'       // NW
    beq go_northwest
    
    // No forests found, look for safe open land in cardinal directions
    cmp w21, #'P'       // North open?
    beq go_north
    
    cmp w25, #'P'       // East open?
    beq go_east
    
    cmp w27, #'P'       // South open?
    beq go_south
    
    cmp w23, #'P'       // West open?
    beq go_west
    
    // Try diagonals for open land
    cmp w22, #'P'       // NE open?
    beq go_northeast
    
    cmp w28, #'P'       // SE open?
    beq go_southeast
    
    cmp w26, #'P'       // SW open?
    beq go_southwest
    
    cmp w20, #'P'       // NW open?
    beq go_northwest
    
    // No safe moves, stay put
    mov w0, #'.'
    b done

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
    
    // Restore and return
    ldp x29, x30, [sp], #16
    ret
