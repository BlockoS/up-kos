org #1200

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

PALETTE = 9
WIDTH = 25
HEIGHT = 25
FRAME_COUNT = 64
    
hblnk = 0xe008
vblnk = 0xe002

macro bump_pallete.load index
    ld hl, bump_palette+({index}*9)
    ld de, bump_palette
    ld bc, 9
    ldir
    mend

main:
    di
    im 1

    ld hl, histogram.blue
    ld (fill_color), hl
    call fill_screen

    ld hl, histogram.color
    ld (fill_color), hl

PRESS_SPACE_OFFSET = 12*SCREEN_WIDTH + SCREEN_WIDTH/2 - 6

    ld hl, press_space
    ld de, 0xd000+PRESS_SPACE_OFFSET
    ld bc, 12
    ldir
    
    ld hl, 0xd800+PRESS_SPACE_OFFSET
    ld (hl), 0x70
    ld de, 0xd801+PRESS_SPACE_OFFSET
    ld bc, 11
    ldir

wait_key:
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key
    
    ld hl, song
    xor a
    
    call PLY_LW_Init

    ld hl, vblnk
    ld a, 0x7f
@wait_0:
    cp (hl)
    jp nc, @wait_0
@wait_1:
    cp (hl)
    jp c, @wait_1

    ld hl, _irq_vector
    ld (0x1039),hl

	ld hl, 0xe007               ;Counter 2.
	ld (hl), 0xb0
	dec hl
	ld (hl),1
	ld (hl),0

	ld hl, 0xe007               ;100 Hz (plays the music at 50hz).
	ld (hl), 0x74
	ld hl, 0xe005
ifdef EMU
    ld (hl), 156
else
	ld (hl), 110
endif
	ld (hl), 0

	ld hl, 0xe008 ;sound on
	ld (hl), 0x01
    
    ei
    
test_loop:

	ld hl, kings
	ld de, 0xd000
	ld bc, 40*25
	ldir
	ld hl, kings+40*25
	ld de, 0xd800
	ld bc, 40*25
	ldir

    ld de, 500
kings_display:
    ld hl, vblnk
    ld a, 0x7f
@wait_6:
    cp (hl)
    jp nc, @wait_6
@wait_7:
    cp (hl)
    jp c, @wait_7

    dec de
    ld a,d
    or e
    jp nz, kings_display

    ld hl, histogram.black
    ld (fill_color), hl
    call fill_screen

    ld hl, histogram.color
    ld (fill_color), hl

    ld hl, frame00
    ld (load_bump_border.addr), hl  
    call load_bump_border.anim

    ld hl, up
    ld (bump.normal), hl
   
    ld iyl, 240
    call bump

    ld hl, frame00+1
    ld (load_bump_border.addr.1), hl
    call load_bump_border.anim.1

    bump_pallete.load 1

    ld hl, frame01
    ld (load_bump_border.addr), hl  
    call load_bump_border.anim

    ld hl, _20
    ld (bump.normal), hl

    ld iyl, 239
    call bump

    ld hl, frame01+1
    ld (load_bump_border.addr.1), hl
    call load_bump_border.anim.1

    bump_pallete.load 2

    ld hl, frame02
    ld (load_bump_border.addr), hl  
    call load_bump_border.anim

    ld hl, normal
    ld (bump.normal), hl

    ld iyl, 239
    call bump

    ld hl, frame02+1
    ld (load_bump_border.addr.1), hl
    call load_bump_border.anim.1

    bump_pallete.load 3
    
    ld hl, frame03
    ld (load_bump_border.addr), hl  
    call load_bump_border.anim

    ld hl, skull2
    ld (bump.normal), hl

    ld iyl, 239                                         ; [todo] adjust
    call bump

    ld hl, frame03+1
    ld (load_bump_border.addr.1), hl
    call load_bump_border.anim.1

    call fill_screen.h

    ld hl, histogram.black
    ld (fill_color), hl
    call fill_screen

    di
    call PLY_LW_Stop

	ld hl, cards
	ld de, 0xd000
	ld bc, 40*25
	ldir
	ld hl, cards+40*25
	ld de, 0xd800
	ld bc, 40*25
	ldir

    ld hl, 960
    ld (frame), hl
    call twister
    ei

    call fill_screen.h

    ld hl, texture.0
    call tunnel_tex.load
    ld iyl, 162
    call tunnel

    call fill_screen

    ld hl, texture.1
    call tunnel_tex.load
    ld iyl, 162
    call tunnel

    call fill_screen

    ld hl, texture.2
    call tunnel_tex.load
    ld iyl, 162
    call tunnel

    call fill_screen.h
    call fill_screen

    di
    call PLY_LW_Stop
            
    ld hl, credit0000_bg
	ld de, 0xd000
	ld bc, 40*25
	ldir
	ld hl, credit0000_bg+40*25
	ld de, 0xd800
	ld bc, 40*25
	ldir
	
    ld hl, att_00
    ld (display_bitmap.attribute), hl
    ld hl, txt_00
    ld (display_bitmap.text), hl
    call display_bitmap

    ld hl, credit0001_bg
	ld de, 0xd000
	ld bc, 40*25
	ldir
	ld hl, credit0001_bg+40*25
	ld de, 0xd800
	ld bc, 40*25
	ldir

    ld hl, att_01
    ld (display_bitmap.attribute), hl
    ld hl, txt_01
    ld (display_bitmap.text), hl
    call display_bitmap

    ei

	ld hl, groquick
	ld de, 0xd000
	ld bc, 40*25
	ldir
	ld hl, groquick+40*25
	ld de, 0xd800
	ld bc, 40*25
	ldir

.forever:
    jp .forever

press_space:
    defb 0x10,0x12,0x05,0x13,0x13,0x00,0x00,0x13,0x10,0x01,0x03,0x05

; bump -------------------------------------------------------------------------
bump:
.loop:    
    push iy
    
    ld a, (frame)
    
    ld l, a
    ld h, 0x00
    ld bc, light_y
    add hl, bc
    ld c, (hl)
    ld ixh, c

    ld l, a
    ld h, light_x>>8
    ld c, (hl)
    ld hl, x_coord
    ld (hl), c
        
    inc a
    and 63
    ld (frame), a

    ld b, HEIGHT
bump.normal equ $+2
    ld iy, normal
    exx
    ld de, 0xd800 + (SCREEN_WIDTH-24)/2
    exx

.loop_y:

x_coord equ $+2
    ld ixl, 0x04
    
    ld c, 12
.loop_x:
    exx
    
    ld c,(iy)
    ld b,(iy+1)
    inc iy
    inc iy
    ld h, 0x00
    ld a, ixl
    add a,c
    cp 0x1f
    jp nc, .skip.0
    
    ld c, a
    
    ld a, ixh
    add a,b
    cp 0x1f
    jr nc, .skip.0
        ld l, a
        add hl, hl
        add hl, hl
        add hl, hl
        add hl, hl
        add hl, hl
        ld a, c
        or l
        ld l, a
        ld bc, light_map        
        add hl, bc

        ld a, (hl)
        ld b, bump_palette>>8
        ld c, a
        ld a, (bc)
        ld h, a
.skip.0:
    ld a, h
    ld (de), a
    inc de
    
    inc ixl
    
    ld c,(iy)
    ld b,(iy+1)
    inc iy
    inc iy
    ld h, 0x00
    ld a, ixl
    add a,c
    cp 0x1f
    jp nc, .skip.1
    
    ld c, a
    
    ld a, ixh
    add a, b
    cp 0x1f
    jr nc, .skip.1
        ld l, a
        add hl, hl
        add hl, hl
        add hl, hl
        add hl, hl
        add hl, hl
        ld a, c
        or l
        ld l, a
        ld bc, light_map        
        add hl, bc

        ld a, (hl)
        ld b, bump_palette>>8
        ld c, a
        ld a, (bc)
        ld h, a
.skip.1:
    ld a, h
    ld (de), a
    inc de
    
    inc ixl

    exx
        
    dec c
    jp nz, .loop_x
    
    exx
    ld hl, SCREEN_WIDTH-24
    add hl, de
    ex de, hl
    inc iy
    inc iy
    exx

    inc ixh
    
    dec b
    jp nz, .loop_y

    pop iy
    dec iyl
    jp nz, .loop

    ret
    
frame: defw 0

light_map: incbin "data/light_map.bin"

align 256
light_x: incbin "data/light_x.bin"
light_y: incbin "data/light_y.bin"

normal: incbin "data/normal.bin"
skull2: incbin "data/skull2.bin"
_20: incbin "data/20.bin"
up: incbin "data/up.bin"

; bump border ------------------------------------------------------------------
load_bump_border:
    push iy    
    ld bc, 0xdbdc
    add iy, bc
    call load_bump_border.ex

    pop iy
    ld bc, 0xd3dc
    add iy, bc
    call load_bump_border.ex

    ret

load_bump_border.ex:
    ld (load_bump_border.sp_backup), sp

load_bump_border.h equ $+1
    ld a, 25
@bump_loop:

    di
    exx
    ld sp, ix
load_bump_border.dx0 equ $+1
    ld bc, 10
    add ix, bc   

    pop hl
    pop bc
    pop de
    exx

	pop de
    ld sp, interrupt_stack.start
    ei
    
    di
    ld sp, iy
right_offset equ $+1
    ld bc, -40+8+24
    add iy, bc

    push de

    exx
	push de
	push bc
    push hl
    exx
    ld sp, interrupt_stack.start
    ei
    
    di
    exx
    ld sp, ix
load_bump_border.dx1 equ $+1
    ld bc, 8
    add ix, bc   

    pop hl
    pop bc
    pop de
    exx

	pop de
    ld sp, interrupt_stack.start
    ei
    
    di
    ld sp, iy
left_offset equ $+1
    ld bc, -8-24
    add iy, bc

    push de

    exx
	push de
	push bc
    push hl
    exx
    ld sp, interrupt_stack.start
    ei
    
	dec a
	jp nz, @bump_loop
	
load_bump_border.sp_backup equ $+1
    ld sp, 0x0000

    ret

load_bump_border.anim:
    ld hl, -40+8+24
    ld (right_offset), hl

    ld hl, -8-24
    ld (left_offset), hl

    ld hl, 10
    ld (load_bump_border.dx0), hl

    ld hl, 8
    ld (load_bump_border.dx1), hl

    ld iy, 0
    ld bc, 0
.border_anim:
    ld hl, vblnk
    ld a, 0x7f
.wait_0:
    cp (hl)
    jp nc, .wait_0
.wait_1:
    cp (hl)
    jp c, .wait_1
    
    push iy
    
load_bump_border.addr equ $+2
    ld ix, frame00  
    call load_bump_border

    pop iy

    ld hl, right_offset
    ld c, (hl)
    inc hl
    ld b, (hl)

    ld hl, -2
    add hl, bc
    ld (right_offset), hl
    
    ld hl, left_offset
    ld c, (hl)
    inc hl
    ld b, (hl)

    ld hl, 2
    add hl, bc
    ld (left_offset), hl

    inc iy
    ld a, 12
    cp iyl
    jp nz, .border_anim

    ret

load_bump_border.anim.1:
    ld hl, -40+8+2
    ld (right_offset), hl

    ld hl, -8-2
    ld (left_offset), hl

    ld hl, 8
    ld (load_bump_border.dx0), hl

    ld hl, 10
    ld (load_bump_border.dx1), hl

    ld iy, 11
    ld bc, 0
.border_anim.1:
    ld hl, vblnk
    ld a, 0x7f
.wait_0:
    cp (hl)
    jp nc, .wait_0
.wait_1:
    cp (hl)
    jp c, .wait_1
    
    push iy
    
load_bump_border.addr.1 equ $+2
    ld ix, frame00  

    push iy    
    ld bc, 0xdbdc
    add iy, bc
    call load_bump_border.ex

    pop iy
    ld bc, 0xd3dc
    add iy, bc
    call load_bump_border.ex

    pop iy

    ld hl, right_offset
    ld c, (hl)
    inc hl
    ld b, (hl)

    ld hl, 2
    add hl, bc
    ld (right_offset), hl
    
    ld hl, left_offset
    ld c, (hl)
    inc hl
    ld b, (hl)

    ld hl, -2
    add hl, bc
    ld (left_offset), hl

    dec iy
    ld a, 0xff
    cp iyl
    jp nz, .border_anim.1

    ret
    
frame00: incbin "data/frame00.bg"
frame01: incbin "data/frame01.bg"
frame02: incbin "data/frame02.bg"
frame03: incbin "data/frame03.bg"

align 256
bump_palette
    defb 0x00,0x20,0x22,0x32,0x33,0x63,0x66,0x76,0x77
    defb 0x00,0x40,0x44,0x54,0x55,0x65,0x66,0x76,0x77 
    defb 0x00,0x10,0x11,0x51,0x55,0x65,0x66,0x76,0x77 
    defb 0x00,0x40,0x44,0x54,0x55,0x65,0x66,0x76,0x77 

; music ------------------------------------------------------------------------
player: include "PlayerLightweight_SHARPMZ700.asm"
song: include "data/ouagadougou.asm"

_irq_vector:
    di

    push af
    push hl
    push bc
    push de
    push ix
    push iy
    exx
    push af
    push hl
    push bc
    push de
    push ix
    push iy
    
    ld hl, 0xe006
    ld a,1
    ld (hl), a
    xor a
    ld (hl), a
    
    call PLY_LW_Play        
    
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af
    exx
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af

    ei
    reti
    
; clear screen animation -------------------------------------------------------
fill_screen:
    ld iy, 25
    ld ix, 0xd000+40

@fill_screen.loop
    ld bc, 0
    
@fill_line:

    ld hl, vblnk
    ld a, 0x7f
@wait_2:
    cp (hl)
    jp nc, @wait_2
@wait_3:
    cp (hl)
    jp c, @wait_3

    di

    ld (transition_sp_save), sp

    ld sp, ix
    
    ld hl, histogram.attr
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a

    repeat 20
    push hl
    rend
        
    ld hl, 0x828
    add hl, sp
    ld sp, hl
    
fill_color equ $+1
    ld hl, histogram.color
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a
    repeat 20
    push hl
    rend
    
transition_sp_save equ $+1
    ld sp, 0x0000

    ei
        
    inc c
    ld a, 7
    cp c
    jp nz, @fill_line

    ld de,0x28
    add ix,de
    
    dec iyl
    jp nz, @fill_screen.loop
    
    ret
    
histogram.attr:
    defb 0x70,0x36,0x7a,0x7e,0x3e,0x3c,0x7a
histogram.color:
    defb 0x70,0x70,0x70,0x07,0x07,0x07,0x77
histogram.blue:
    defb 0x01,0x01,0x01,0x10,0x10,0x10,0x00
histogram.black:
    defb 0x07,0x07,0x07,0x70,0x70,0x70,0x00

; clear screen animation horizontally ------------------------------------------
fill_screen.h:
    ld ix, 0xd000

    exx
    ld de, 40
    exx
    
@fill_screen.h.loop:
    
    ld bc, 6
@fill_column:

    ld hl, vblnk
    ld a, 0x7f
@wait_4:
    cp (hl)
    jp nc, @wait_4
@wait_5:
    cp (hl)
    jp c, @wait_5
    
    ld hl, histogram.h.attr
    add hl, bc
    ld a, (hl)

    exx
    ld c, ixl   
    ld h, 0xd0
    ld l, c
    repeat 25
    ld (hl), a 
    add hl, de
    rend
    exx
    
fill.h_color equ $+1
    ld hl, histogram.h.color
    add hl, bc
    ld a, (hl)

    exx
    ld h, 0xd8
    ld l, c
    repeat 25    
    ld (hl), a 
    add hl, de
    rend
    exx
        
    dec c
    jp p, @fill_column
    
    inc ixl
    ld a, 40
    cp ixl
    jp nz, @fill_screen.h.loop
    
    ret

histogram.h.attr:
    defb 0x7a,0x3d,0x3f,0x7f,0x7b,0x37,0x71
histogram.h.color:
    defb 0x77,0x07,0x07,0x07,0x70,0x70,0x70
histogram.h.black:
    defb 0x00,0x70,0x70,0x07,0x07,0x07,0x07

; tunnel -----------------------------------------------------------------------
tunnel: 
;    ld hl, vblnk
;    ld a, 0x7f
;@wait:
;    cp (hl)
;    jp nc, @wait

    ld bc, 0x03e7
    ld hl, 0xdbe7
tunnel.update_0:
        ld ix, sqrt_tab_0
        add ix, bc

        ld a, (frame)
        rrca
        add a, (ix+0)
        rrca
        and 0x07
        ld d, a
        
        ld ix, angle_tab_0
        add ix, bc
        
        ld a, (frame)
        add a, a
        add a, a
        add a, (ix+0)
        and 0x38
        add a, d

        ld (tunnel.fg_0), a
tunnel.fg_0 equ $+1
        ld a, (texture)
        add a, a
        add a, a
        add a, a
        add a, a
        ld e, a

        ld ix, sqrt_tab_1
        add ix, bc

        ld a, (frame)
        rrca
        add a, (ix+0)
        rrca
        and 0x07
        ld d, a
        
        ld ix, angle_tab_1
        add ix, bc
        
        ld a, (frame)
        add a, a
        add a, a
        add a, (ix+0)
        and 0x38
        add a, d

        ld (tunnel.bg_0), a
tunnel.bg_0 equ $+1
        ld a, (texture)

        add a, e
        ld (hl), a
        
        dec hl
        dec bc
        
        ld a, 0xff
        cp b
        jp nz, tunnel.update_0
        
    ld hl, frame
    inc (hl)

    dec iyl
    jp nz, tunnel
    
    ret
    
tunnel_tex.load:
    ld (tunnel_tex.sp), sp

    ld iy, texture+64
    ld a, 8
    ld de, 8
tunnel_tex.loop:

    di
    ld sp, hl
    add hl, de
    pop bc
    exx
    pop hl
    pop de
    pop bc

    ld sp, iy
    push bc
    push de
    push hl
    exx
    push bc
    
    ld bc, -8
    add iy, bc
    
    ld sp, interrupt_stack.start
    ei

    dec a
    jp nz, tunnel_tex.loop

tunnel_tex.sp equ $+1
    ld sp, 0x0000
    
    ret

sqrt_tab_0: incbin "data/sqrt_tab_0.bin"
angle_tab_0: incbin "data/angle_tab_0.bin"
sqrt_tab_1: incbin "data/sqrt_tab_1.bin"
angle_tab_1: incbin "data/angle_tab_1.bin"

kings: incbin "data/kings.bg"
cards: incbin "data/cards.bg"
credit0000_bg: incbin "data/credit0000_bg.bin"
credit0001_bg: incbin "data/credit0001_bg.bin"
groquick: incbin "data/groquick.bin"

align 256
texture:
    defs 64
texture.0:
    defb 0, 2, 3, 4, 5, 6, 0, 0
    defb 1, 2, 3, 4, 5, 0, 0, 0
    defb 1, 2, 3, 4, 0, 0, 0, 7
    defb 1, 2, 3, 0, 0, 0, 2, 7
    defb 1, 2, 0, 0, 0, 6, 2, 7
    defb 1, 0, 0, 0, 5, 6, 2, 7
    defb 0, 0, 0, 4, 5, 6, 2, 7
    defb 0, 0, 3, 4, 5, 6, 2, 0
texture.1:
    defb 4, 7, 7, 7, 1, 1, 1, 0
    defb 4, 6, 6, 6, 0, 0, 0, 0
    defb 4, 5, 5, 5, 1, 1, 1, 0
    defb 4, 4, 4, 4, 2, 2, 2, 0
    defb 4, 5, 5, 5, 3, 3, 3, 0
    defb 4, 6, 6, 6, 0, 0, 0, 0
    defb 4, 7, 7, 7, 3, 3, 3, 0
    defb 4, 4, 4, 4, 2, 2, 2, 0
texture.2:
    defb 0, 1, 2, 3, 4, 5, 6, 7
    defb 7, 0, 1, 2, 3, 4, 5, 6
    defb 6, 7, 0, 1, 2, 3, 4, 5
    defb 5, 6, 7, 0, 1, 2, 3, 4
    defb 4, 5, 6, 7, 0, 1, 2, 3
    defb 3, 4, 5, 6, 7, 0, 1, 2
    defb 2, 3, 4, 5, 6, 7, 0, 1
    defb 1, 2, 3, 4, 5, 6, 7, 0

include "twister.asm"
include "bitmap.asm"

interrupt_stack:
    defs 256
interrupt_stack.start:
