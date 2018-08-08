macro raster_update    
    ld sp, ix
    pop bc
    pop de
    pop hl
    exx
    pop bc
    pop de
    pop hl
    
    ld sp, iy
    push hl
    push de
    push bc
    exx
    push hl
    push de
    push bc
    
    ld bc, 12
    add ix, bc
mend

display_bitmap:
    ld (.sp_save), sp

    ld hl, 640
    ld (frame), hl
        
    ld iy, 0xd800+27
.attribute equ $+2
    ld ix, 0x0000

    ld a, att_height
.draw_attributes:
    raster_update   

    ld  c, 40
    add iy, bc

	dec a
	jp nz, .draw_attributes


    ld hl, vblnk
    ld a, 0x7f
.wait_0:
    cp (hl)
    jp nc, .wait_0
.wait_1:
    cp (hl)
    jp c, .wait_1

    xor a
.loop:
    ld iy, 0xd000+27
.text equ $+2
    ld ix, 0x0000

    raster_update
    
    ld hl, vblnk
    ld a, 0x7f
.wait:
    cp (hl)
    jp nc, .wait

    ld a, 25
    jp .line1
    
.line0:
    raster_update
.line1:
    raster_update
.line2:
    raster_update
.line3:
    raster_update
.line4:
    raster_update
.line5:
    raster_update
.line6:
    raster_update
.line7:
    raster_update   

    ld  c, 40
    add iy, bc

	dec a
	jp nz, .line0
    
    ld hl, frame
    dec (hl)
    jp nz, .loop

    inc hl
    dec (hl)
    jp nz, .loop
    
.sp_save equ $+1
    ld sp, 0x0000

    ret
    
txt_width = 12
txt_height = 200

att_width = 12
att_height = 25

txt_00:
incbin "data/credit0000_txt.bin"
att_00:
incbin "data/credit0000_att.bin"
txt_01:
incbin "data/credit0001_txt.bin"
att_01:
incbin "data/credit0001_att.bin"
