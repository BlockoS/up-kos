height = 8*25
   
macro twister_raster line,index
    ex af,af'
    ld a,(theta+1)
    and 31*8
    ld e, a
    xor d
    ld hl,pattern_{line}
    add hl,de
    ex af,af'
    
    ld sp,hl
    pop bc
    pop de
    pop hl
    exx
    pop bc
    
    ld sp, iy
    push bc
    exx
    push hl
    push de
    push bc

dt_{index} = $ + 1
    ld de, 0x0000
    ld hl, (theta)
    add hl, de
    ld (theta), hl
mend
    
twister:
    ld (twister.sp), sp
    
    ld iy, 0xd800+27

    ld a, 4
    ld hl, twister_height
    ld ix, twister_color
@attribute:

    ex af, af'
    ld a, (hl)

    ld e, (ix)
    ld d, e
    xor b
@attribute_line:

    ld sp, iy
    push de
    push de
    push de
    push de

    ld  c, 40
    add iy, bc

    dec a
	jp nz, @attribute_line

    ex af, af'

    inc hl
    inc ix
    
    dec a        
    jp nz, @attribute


    ld ix, 0x00

    ld hl, vblnk
    ld a, 0x7f
@twister.wait0:
    cp (hl)
    jp nc, @twister.wait0
@twister.wait1:
    cp (hl)
    jp c, @twister.wait1

@twister.loop:    
    ld a, (angle)
    add a, 8
    ld (angle), a
    ld (theta+1), a
    xor a
    ld (theta), a
    
    ld hl,cos_table
    ld e,ixl
    xor d
    add hl,de
    inc ixl
    ld a,(hl)
    ld (dt_0),a
    ld (dt_1),a
    ld (dt_2),a
    ld (dt_3),a
    ld (dt_4),a
    ld (dt_5),a
    ld (dt_6),a
    ld (dt_7),a
    ld (dt_8),a
    
    ld iy, 0xd000+27
    twister_raster 0,0

    ld hl, vblnk
    ld a, 0x7f
@twister.wait:
    cp (hl)
    jp nc, @twister.wait

    ld a, 25
    jp @line1
            
@line0:
    twister_raster 0,1
@line1:
    twister_raster 1,2
@line2:
    twister_raster 2,3
@line3:
    twister_raster 3,4
@line4:
    twister_raster 4,5
@line5:
    twister_raster 5,6
@line6:
    twister_raster 6,7
@line7:
    twister_raster 7,8

    ld  bc, 40
    add iy, bc
    
	dec a
	jp nz, @line0
    
    ld hl, frame
    dec (hl)
    jp nz, @twister.loop
    inc hl
    dec (hl)
    jp nz, @twister.loop
    
    ; clear attributes
    ld hl, 0xd800+27
    ld bc, 40
    ld a, 25
    ld de, 0x00
@clear:
    ld sp, hl
    push de
    push de
    push de
    push de
    add hl, bc

    dec a
	jp nz, @clear

twister.sp equ $+1
    ld sp, 0x0000
    ret
    
angle: defb 0
theta: defb 0,0,0

twister_color: defb 0xf0, 0xe0, 0xd0, 0x90
twister_height: defb 10, 8, 5, 2

pattern_0: incbin "data/pattern00.bin"
pattern_1: incbin "data/pattern01.bin"
pattern_2: incbin "data/pattern02.bin"
pattern_3: incbin "data/pattern03.bin"
pattern_4: incbin "data/pattern04.bin"
pattern_5: incbin "data/pattern05.bin"
pattern_6: incbin "data/pattern06.bin"
pattern_7: incbin "data/pattern07.bin"
align 256
cos_table: incbin "data/cos.bin"