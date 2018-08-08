;       Arkos Tracker 2 Lightweight player.
;       This code is specific to the SHARP MZ 700 hardware and a PSG running at 894886 Hz (see http://www.maroon.dti.ne.jp/youkan/mz700/pg/sound.html).
;       Only one channel is used, no noise, no hardware envelope, no volume! The sound is stopped when the "sound" is set to off.

;   	This is a generic player, but much simpler and using only the most used features, so that the music and players are both
;   	lightweight. The player supports sound effects.

;       Though the player is optimized in speed, it is much slower than the AKY player.
;       With effects used at the same time, it may reach 35 scanlines on a CPC, plus some few more if you are using sound effects.

;       PLEASE NOTE: this player comes from the CPC, which manages three channels. The management of channel 2 and 3 have been removed, but
;       the structure hasn't changed: the code could be optimized more (IX and IY are still used to point on various structures), but
;       I didn't want to write a new player once again. Please let me know if you need more speed, I'll see what I can do.

;       Some severe optimizations of CPU/memory can be used according to the song:
;       - No need of sound effects? Set the PLY_LW_MANAGE_SOUND_EFFECTS to 0.
;       - Reset the PLY_LW_MANAGE_EFFECTS flag to remove the effects management. Effective, but no track effects at all will be managed!
;       - Reset the PLY_LW_MANAGE_PITCH_IN_INSTRUMENT flag to remove the pitch management in the Instrument. You won't gain much though.
;       - If you have only one song and that it doesn't need to be reset, the PLY_LW_Init code can be optimized.
;       - No transposition? Remove the test and code before PLY_LW_LinkerAfterNewTranspositions.


        
PLY_LW_MANAGE_SOUND_EFFECTS: equ 0                      ;Sound effects handled? Most of the time 0, unless you're working on a game. It requires the PLY_LW_MANAGE_HARDWARE_SOUND flag set to 1.
PLY_LW_MANAGE_EFFECTS: equ 1                            ;Effects handled? 0 to save a lot of CPU and memory, but lose the effects capabilities!
PLY_LW_MANAGE_PITCH_IN_INSTRUMENT: equ 1                ;Pitch in Instrument? May be removed if using effects, or instead, used if effects are removed.

        ;Hooks for external calls. Can be removed if not needed.
        jp PLY_LW_Init          ;Player + 0.
        jp PLY_LW_Play          ;Player + 3.
	jp PLY_LW_Stop          ;Player + 6.

;Initializes the song. MUST be called before actually playing the song.
;IN:    HL = Address of the song.
;       A = Index of the subsong to play (>=0).
PLY_LW_Init:
        ;Reads the Song data.
        ;Skips the tag and format number.
        ld de,5
        add hl,de

        ;Reads the pointers to the various index tables.
        ld de,PLY_LW_PtInstruments + 1
        ldi
        ldi
        if PLY_LW_MANAGE_EFFECTS
                ld de,PLY_LW_PtArpeggios + 1
                ldi
                ldi
                ld de,PLY_LW_PtPitches + 1
                ldi
                ldi
        else
                ld de,4
                add hl,de
        endif

        ;Finds the address of the Subsong.
        ;HL points on the table, adds A * 2.
        ;Optimization possible: possible to set the Subsong directly.
        ld e,a
        ld d,0
        add hl,de
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (PLY_LW_Linker + 1),de

        ;Can be removed if there is no need to reset the song.
        xor a
        ld (PLY_LW_TickCounter + 1),a
        ld (PLY_LW_PatternRemainingHeight + 1),a
        inc a
        ld (PLY_LW_Speed + 1),a

        ;A big LDIR to erase all the data blocks. Optimization: can be removed if there is no need to reset the song.
        ld hl,PLY_LW_Track1_Data
        ld de,PLY_LW_Track1_Data + 1
        ld bc,PLY_LW_Track1_Data_End - PLY_LW_Track1_Data - 1
        ld (hl),0
        ldir

        ;Reads the first instrument, the empty one, and set-ups the pointers to the instrument to read.
        ;Optimization: needed if the song doesn't start with an instrument on all the channels. Else, it can be removed.
        ld hl,(PLY_LW_PtInstruments + 1)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc de          ;Skips the header.
        ld (PLY_LW_Track1_PtInstrument),de
        ret


;Cuts the channels, stopping all sounds.	
PLY_LW_Stop:
	ld a,%00111111
	jp PLY_LW_SendPsg

;Plays one frame of the song. It MUST have been initialized before.
;The stack is saved and restored, but is diverted, so watch out for the interruptions.
PLY_LW_Play:
        ;Reads a new line?
PLY_LW_TickCounter: ld a,0
        inc a
PLY_LW_Speed: cp 1                       ;Speed (>0).
        jp nz,PLY_LW_TickCounterManaged

        ;A new line must be read. But have we reached the end of the Pattern?
PLY_LW_PatternRemainingHeight: ld a,0              ;Height. If 0, end of the pattern.
        sub 1
        jr c,PLY_LW_Linker
        ;Pattern not ended. No need to read the Linker.
        ld (PLY_LW_PatternRemainingHeight + 1),a
        jr PLY_LW_ReadLine

        ;New pattern. Reads the Linker.
PLY_LW_Linker: ld hl,0
PLY_LW_LinkerPostPt:
        ;Resets the possible empty cell counter of each Track.
        xor a
        ld (PLY_LW_Track1_WaitEmptyCell),a

        ;Reads the state byte of the pattern.
        ld a,(hl)
        inc hl
        rra
        jr c,PLY_LW_LinkerNotEndOfSongOk
        ;End of song.
        ld a,(hl)               ;Reads where to loop in the Linker.
        inc hl
        ld h,(hl)
        ld l,a
        jr PLY_LW_LinkerPostPt

PLY_LW_LinkerNotEndOfSongOk:
        rra
        ld b,a
        ;New speed?
        jr nc,PLY_LW_LinkerAfterSpeed
        ld a,(hl)
        inc hl
        ld (PLY_LW_Speed + 1),a
PLY_LW_LinkerAfterSpeed:

        ;New height?
        rr b
        jr nc,PLY_LW_LinkerUsePreviousHeight
        ld a,(hl)
        inc hl
        ld (PLY_LW_LinkerPreviousRemainingHeight + 1),a
        jr PLY_LW_LinkerSetRemainingHeight
        ;The same height is used. It was stored before.
PLY_LW_LinkerUsePreviousHeight:
PLY_LW_LinkerPreviousRemainingHeight: ld a,0
PLY_LW_LinkerSetRemainingHeight:
        ld (PLY_LW_PatternRemainingHeight + 1),a

        ;New transpositions?
        rr b
        jr nc,PLY_LW_LinkerAfterNewTranspositions
        ;New transpositions.
        ld de,PLY_LW_Track1_Transposition
        ldi
        inc hl          ;Skips channel 2 and 3, not present Sharp.
        inc hl
PLY_LW_LinkerAfterNewTranspositions:

        ;Reads the 3 track pointers.
        ld de,PLY_LW_Track1_PtTrack
        ldi
        ldi
        inc hl          ;Skips channel 2 and 3, not present Sharp.
        inc hl
        inc hl
        inc hl
        ld (PLY_LW_Linker + 1),hl

;Reads the Tracks.
;---------------------------------
PLY_LW_ReadLine:

        ld ix,PLY_LW_Track1_Data
        call PLY_LW_ReadTrack

        xor a
PLY_LW_TickCounterManaged:
        ld (PLY_LW_TickCounter + 1),a



;Plays the sound stream.
;---------------------------------
        ld c,%11100000          ;Register 7, shifted of 2 to the left. Bits 2 and 5 will be possibly changed by each iteration.

        ld ix,PLY_LW_Track1_Data
        if PLY_LW_MANAGE_EFFECTS
                call PLY_LW_ManageEffects
        endif
        ld iy,PLY_LW_Track1_Registers
        call PLY_LW_PlaySoundStream

        srl c                   ;Not RR, because we have to make sure the b6 is 0, else no more keyboard (on CPC)!
        srl c

        ld a,c

;Plays the sound effects, if desired.
;-------------------------------------------
        if PLY_LW_MANAGE_SOUND_EFFECTS
                        call PLY_LW_PlaySoundEffectsStream
        endif



;Sends the values to the PSG.
;---------------------------------
;IN:    A = mixer (0 or on, 1 = off).
PLY_LW_SendPsg:

        ;Is there a sound? Checks the Mixer.
        and %1          ;0 for Channel 1 open.
        xor 1           ;But Sharp wants a 1 if open!
        ld hl,#e008
	ld (hl),a
        
        ;No sound? Then stops.
        or a
        ret z

        ;Sound. Sends the period.
        ld hl,#e004
        ld a,(PLY_LW_Track1_SoftwarePeriodLSB)
        ld b,a
        sla a
        sla a
        sla a
        sla a
        ld (hl),a

        srl b
        srl b
        srl b
        srl b

        ld a,(PLY_LW_Track1_SoftwarePeriodMSB)
        sla a
        sla a
        sla a
        sla a
        add a,b
        ld (hl),a

        ret










;Reads a Track.
;IN:    IX = Data block of the Track.
PLY_LW_ReadTrack:
        ;Are there any empty lines to wait?
        ld a,(ix + PLY_LW_Data_OffsetWaitEmptyCell)
        sub 1
        jr c,PLY_LW_RT_NoEmptyCell
        ;Wait!
        ld (ix + PLY_LW_Data_OffsetWaitEmptyCell),a
        ret

PLY_LW_RT_NoEmptyCell:
        ;Reads the Track pointer.
        ld l,(ix + PLY_LW_Data_OffsetPtTrack + 0)
        ld h,(ix + PLY_LW_Data_OffsetPtTrack + 1)
        ld a,(hl)
        inc hl
        ld b,a
        and %111111     ;Keeps only the note.
        sub 60
        jr c,PLY_LW_RT_NoteMaybeEffect
        if PLY_LW_MANAGE_EFFECTS
                jr z,PLY_LW_RT_ReadEffect       ;No note, but effect.
        endif
        dec a
        jr z,PLY_LW_RT_WaitLong
        dec a
        jr z,PLY_LW_RT_WaitShort
        ;63: Escape code for a note, because octave <2 or >5.
        ;Reads the note.
        ld a,(hl)
        inc hl
        ;The rest is exactly as the "note maybe effect", as B contains the flag to know about the possible
        ;New Instrument and/or Effect?.
        jr PLY_LW_RT_NMB_AfterOctaveCompensation

PLY_LW_RT_NoteMaybeEffect:
        ;A is the note from octave 2, and 60 to compensate the sub above.
        ;Then adds the transposition.
        add a,12 * 2 + 60
PLY_LW_RT_NMB_AfterOctaveCompensation:
        add a,(ix + PLY_LW_Data_OffsetTransposition)
        ld (ix + PLY_LW_Data_OffsetBaseNote),a

        ;New Instrument?
        rl b
        jr c,PLY_LW_RT_NME_NewInstrument
        ;Same Instrument. Retrieves the address previously stored.
        ld a,(ix + PLY_LW_Data_OffsetPtBaseInstrument + 0)
        ld (ix + PLY_LW_Data_OffsetPtInstrument + 0),a
        ld a,(ix + PLY_LW_Data_OffsetPtBaseInstrument + 1)
        ld (ix + PLY_LW_Data_OffsetPtInstrument + 1),a
        jr PLY_LW_RT_NME_AfterInstrument

PLY_LW_RT_NME_NewInstrument:
        ;New Instrument, reads it.
        ld a,(hl)
        inc hl
        exx
                ;Gets the address of the Instrument.
                ld l,a  ;No need to *2, it is already encoded like that.
                ld h,0
PLY_LW_PtInstruments: ld de,0
                add hl,de       ;Adds to the Instrument Table.
                ld c,(hl)
                inc hl
                ld b,(hl)
                ;Reads the header of the Instrument.
                ld a,(bc)       ;Speed.
                ld (ix + PLY_LW_Data_OffsetInstrumentSpeed),a
                inc bc
                ;Stores the pointer on the data of the Instrument.
                ld (ix + PLY_LW_Data_OffsetPtInstrument + 0),c
                ld (ix + PLY_LW_Data_OffsetPtInstrument + 1),b
                ld (ix + PLY_LW_Data_OffsetPtBaseInstrument + 0),c              ;Useful to store the base Instrument address to retrieve it when
                ld (ix + PLY_LW_Data_OffsetPtBaseInstrument + 1),b              ;there is a new instrument, without providing its number (optimization).
        exx
PLY_LW_RT_NME_AfterInstrument:
        ;Resets the step on the Instrument.
        ld (ix + PLY_LW_Data_OffsetInstrumentCurrentStep),0

        ;Resets the Track pitch.
        if PLY_LW_MANAGE_EFFECTS
        xor a
        ld (ix + PLY_LW_Data_OffsetIsPitchUpDownUsed),a
        ld (ix + PLY_LW_Data_OffsetTrackPitchInteger + 0),a
        ld (ix + PLY_LW_Data_OffsetTrackPitchInteger + 1),a
        ;ld (ix + PLY_LW_Data_OffsetTrackPitchDecimal),a                ;Shouldn't be needed, the difference shouldn't be noticeable.
        ;Resets the offset on Arpeggio and Pitch tables.
        ld (ix + PLY_LW_Data_OffsetPtArpeggioOffset),a
        ld (ix + PLY_LW_Data_OffsetPtPitchOffset),a
        endif

        ;Any effect? If no, stop.
        rl b
        jr nc,PLY_LW_RT_CellRead
        ;Effect present.
        ;jr PLY_LW_RT_ReadEffect

        if PLY_LW_MANAGE_EFFECTS
PLY_LW_RT_ReadEffect:
        ;Reads effect number and possible data.
        ld a,(hl)
        inc hl
        ld b,a
        exx
                rra
                rra
                rra
                rra
                and %1110
                ld iy,PLY_LW_EffectTable
                ld c,a
                ld b,0
                add iy,bc
        exx
        jp (iy)
        endif ;PLY_LW_MANAGE_EFFECTS

PLY_LW_RT_WaitLong:
        ;A 8-bit byte is encoded just after.
        ld a,(hl)
        inc hl
        ld (ix + PLY_LW_Data_OffsetWaitEmptyCell),a
        jr PLY_LW_RT_CellRead
PLY_LW_RT_WaitShort:
        ;Only a 2-bit value is encoded.
        ld a,b
        rla                     ;Transfers the bit 7/6 to 1/0.
        rla
        rla
        and %11
        ;inc a
        ld (ix + PLY_LW_Data_OffsetWaitEmptyCell),a
        ;jr PLY_LW_RT_CellRead
;Jumped to after the Cell has been read.
;IN:    HL = new value of the Track pointer. Must point after the read Cell.
PLY_LW_RT_CellRead:
        ld (ix + PLY_LW_Data_OffsetPtTrack + 0),l
        ld (ix + PLY_LW_Data_OffsetPtTrack + 1),h
        ret


;Manages the effects, if any. For the activated effects, modifies the internal data for the Track which data block is given.
;IN:    IX = data block of the Track.
;OUT:   IX, IY = unmodified.
;       C must NOT be modified!
        if PLY_LW_MANAGE_EFFECTS
PLY_LW_ManageEffects:
        ;Pitch up/down used?
        ld a,(ix + PLY_LW_Data_OffsetIsPitchUpDownUsed)
        or a
        jr z,PLY_LW_ME_PitchUpDownFinished

        ;Adds the LSB of integer part and decimal part, using one 16 bits operation.
        ld l,(ix + PLY_LW_Data_OffsetTrackPitchDecimal)
        ld h,(ix + PLY_LW_Data_OffsetTrackPitchInteger + 0)

        ld e,(ix + PLY_LW_Data_OffsetTrackPitchSpeed + 0)
        ld d,(ix + PLY_LW_Data_OffsetTrackPitchSpeed + 1)

        ld a,(ix + PLY_LW_Data_OffsetTrackPitchInteger + 1)

        ;Negative pitch?
        bit 7,d
        jr nz,PLY_LW_ME_PitchUpDown_NegativeSpeed

PLY_LW_ME_PitchUpDown_PositiveSpeed:
        ;Positive speed. Adds it to the LSB of the integer part, and decimal part.
        add hl,de

        ;Carry? Transmits it to the MSB of the integer part.
        adc 0
        jr PLY_LW_ME_PitchUpDown_Save
PLY_LW_ME_PitchUpDown_NegativeSpeed:
        ;Negative speed. Resets the sign bit. The encoded pitch IS positive.
        ;Subtracts it to the LSB of the integer part, and decimal part.
        res 7,d

        or a
        sbc hl,de

        ;Carry? Transmits it to the MSB of the integer part.
        sbc 0

PLY_LW_ME_PitchUpDown_Save:
        ld (ix + PLY_LW_Data_OffsetTrackPitchInteger + 1),a

        ld (ix + PLY_LW_Data_OffsetTrackPitchDecimal),l
        ld (ix + PLY_LW_Data_OffsetTrackPitchInteger + 0),h

PLY_LW_ME_PitchUpDownFinished:


        ;Manages the Arpeggio Table effect, if any.
        ld a,(ix + PLY_LW_Data_OffsetIsArpeggioTableUsed)
        or a
        jr z,PLY_LW_ME_ArpeggioTableFinished
        ;Reads the Arpeggio Table. Adds the Arpeggio base address to an offset.
        ld e,(ix + PLY_LW_Data_OffsetPtArpeggioTable + 0)
        ld d,(ix + PLY_LW_Data_OffsetPtArpeggioTable + 1)
        ld l,(ix + PLY_LW_Data_OffsetPtArpeggioOffset)
PLY_LW_ME_ArpeggioTableReadAgain: ld h,0
        add hl,de
        ld a,(hl)
        ;End of the Arpeggio?
        sra a
        jr nc,PLY_LW_ME_ArpeggioTableEndNotReached
        ;End of the Arpeggio. The loop offset is now in A.
        ld l,a  ;And read the next value!
        ld (ix + PLY_LW_Data_OffsetPtArpeggioOffset),a
        jr PLY_LW_ME_ArpeggioTableReadAgain

PLY_LW_ME_ArpeggioTableEndNotReached:
        ;Not the end. A = arpeggio note.
        ld (ix + PLY_LW_Data_OffsetCurrentArpeggioValue),a
        ;Increases the offset for next time.
        inc (ix + PLY_LW_Data_OffsetPtArpeggioOffset)
PLY_LW_ME_ArpeggioTableFinished:


        ;Manages the Pitch Table effect, if any.
        ld a,(ix + PLY_LW_Data_OffsetIsPitchTableUsed)
        or a
        ret z
        ;Reads the Pitch Table. Adds the Pitch base address to an offset.
        ld e,(ix + PLY_LW_Data_OffsetPtPitchTable + 0)
        ld d,(ix + PLY_LW_Data_OffsetPtPitchTable + 1)
        ld l,(ix + PLY_LW_Data_OffsetPtPitchOffset)
PLY_LW_ME_PitchTableReadAgain: ld h,0
        add hl,de
        ld a,(hl)
        ;End of the Pitch?
        sra a
        jr nc,PLY_LW_ME_PitchTableEndNotReached
        ;End of the Pitch. The loop offset is now in A.
        ld l,a  ;And read the next value!
        ld (ix + PLY_LW_Data_OffsetPtPitchOffset),a
        jr PLY_LW_ME_PitchTableReadAgain

PLY_LW_ME_PitchTableEndNotReached:
        ;Not the end. A = pitch note. It is converted to 16 bits.
        ld h,0
        or a
        jp p,PLY_LW_ME_PitchTableEndNotReached_Positive
        dec h
PLY_LW_ME_PitchTableEndNotReached_Positive:
        ld (ix + PLY_LW_Data_OffsetCurrentPitchTableValue + 0),a
        ld (ix + PLY_LW_Data_OffsetCurrentPitchTableValue + 1),h
        ;Increases the offset for next time.
        inc (ix + PLY_LW_Data_OffsetPtPitchOffset)
        ret

        endif ;PLY_LW_MANAGE_EFFECTS







;---------------------------------------------------------------------
;Sound stream.
;---------------------------------------------------------------------

;Plays the sound stream, filling the PSG registers table (but not playing it).
;The Instrument pointer must be updated as it evolves inside the Instrument.
;IN:    IX = Data block of the Track.
;       IY = Points at the beginning of the register structure related to the channel.
;       C = R7. Only bit 2 (sound) must be *set* to cut the sound if needed, and bit 5 (noise) must be *reset* if there is noise.
PLY_LW_PlaySoundStream:
        ;Gets the pointer on the Instrument, from its base address and the offset.
        ld l,(ix + PLY_LW_Data_OffsetPtInstrument + 0)
        ld h,(ix + PLY_LW_Data_OffsetPtInstrument + 1)

        ;Reads the first byte of the cell of the Instrument. What type?
PLY_LW_PSS_ReadFirstByte:
        ld a,(hl)
        ld b,a
        inc hl
        rra
        jr c,PLY_LW_PSS_SoftOrSoftAndHard

        ;NoSoftNoHard or SoftwareToHardware
        rra

        ;No software no hardware, or end of sound (loop)!
        ;End of sound?
        rra
        jr nc,PLY_LW_PSS_NSNH_NotEndOfSound
        ;The sound loops/ends. Where?
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ;As a sound always has at least one cell, we should safely be able to read its bytes without storing the instrument pointer.
        ;However, we do it anyway to remove the overhead of the Speed management: if looping, the same last line will be read,
        ;if several channels do so, it will be costly. So...
        ld (ix + PLY_LW_Data_OffsetPtInstrument + 0),l
        ld (ix + PLY_LW_Data_OffsetPtInstrument + 1),h
        jr PLY_LW_PSS_ReadFirstByte

PLY_LW_PSS_NSNH_NotEndOfSound:
        ;No software, no hardware.
        ;-------------------------
        ;Stops the sound.
        set 2,c

        ;Volume. A now contains the volume on b0-3. --> Ignored on the Sharp.

        ;Read noise? Not on Sharp. The shift is still needed though.
        rl b
        jr PLY_LW_PSS_Shared_StoreInstrumentPointer

        ;Software sound, or Software and Hardware.
PLY_LW_PSS_SoftOrSoftAndHard:
        rra


        ;Software sound.
        ;-----------------
        ;A is the volume. Already shifted twice, so it can be used directly. --> Ignored on the Sharp.

        ;Arp and/or noise?
        ld d,0          ;Default arpeggio.
        rl b
        jr nc,PLY_LW_PSS_S_AfterArpAndOrNoise
        ld a,(hl)
        inc hl
        ;Noise?
        sra a
        ;A is now the signed Arpeggio. It must be kept.
        ld d,a
        ;Now takes care of the noise, if there is a Carry. -> Not on Sharp.
PLY_LW_PSS_S_AfterArpAndOrNoise:

        ld a,d          ;Gets the instrument arpeggio, if any.
        call PLY_LW_CalculatePeriodForBaseNote

        ;Read pitch?
        rl b
        if PLY_LW_MANAGE_PITCH_IN_INSTRUMENT
                call c,PLY_LW_ReadPitchAndAddToPeriod
        endif

        ;Stores the new period of this channel.
        exx
                ld (iy + PLY_LW_Registers_OffsetSoftwarePeriodLSB),l
                ld (iy + PLY_LW_Registers_OffsetSoftwarePeriodMSB),h
        exx

        ;The code below is mutualized!
        ;Stores the new instrument pointer, if Speed allows it.
        ;--------------------------------------------------
PLY_LW_PSS_Shared_StoreInstrumentPointer:
        ;Checks the Instrument speed, and only stores the Instrument new pointer if the speed is reached.
        ld a,(ix + PLY_LW_Data_OffsetInstrumentCurrentStep)
        cp (ix + PLY_LW_Data_OffsetInstrumentSpeed)
        jr z,PLY_LW_PSS_S_SpeedReached
        ;Increases the current step.
        inc (ix + PLY_LW_Data_OffsetInstrumentCurrentStep)
        ret
PLY_LW_PSS_S_SpeedReached:
        ;Stores the Instrument new pointer, resets the speed counter.
        ld (ix + PLY_LW_Data_OffsetPtInstrument + 0),l
        ld (ix + PLY_LW_Data_OffsetPtInstrument + 1),h
        ld (ix + PLY_LW_Data_OffsetInstrumentCurrentStep),0
        ret


;Calculates the period according to the base note and put it in BC'.
;IN:    A = instrument arpeggio (0 if not used).
;OUT:   HL' = period.
;MOD:   A
PLY_LW_CalculatePeriodForBaseNote:
        ;Gets the period from the current note.
        exx
                ld h,0
                add a,(ix + PLY_LW_Data_OffsetBaseNote)                         ;Adds the instrument Arp to the base note (including the transposition).
                if PLY_LW_MANAGE_EFFECTS
                        add (ix + PLY_LW_Data_OffsetCurrentArpeggioValue)       ;Adds the Arpeggio effect.
                endif
                ld l,a
                sla l                   ;Note encoded on 7 bits, so should be fine.
                ld de,PLY_LW_PeriodTable
                add hl,de
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a                  ;HL' = period.

                ;Adds the Pitch Table value, if used.
                if PLY_LW_MANAGE_EFFECTS
                        ld a,(ix + PLY_LW_Data_OffsetIsPitchTableUsed)
                        or a
                        jr z,PLY_LW_CalculatePeriodForBaseNote_NoPitchTable
                        ld c,(ix + PLY_LW_Data_OffsetCurrentPitchTableValue + 0)
                        ld b,(ix + PLY_LW_Data_OffsetCurrentPitchTableValue + 1)
                        add hl,bc
PLY_LW_CalculatePeriodForBaseNote_NoPitchTable:
                        ;Adds the Track Pitch.
                        ld c,(ix + PLY_LW_Data_OffsetTrackPitchInteger + 0)
                        ld b,(ix + PLY_LW_Data_OffsetTrackPitchInteger + 1)
                        add hl,bc
                endif
        exx
        ret

        if PLY_LW_MANAGE_PITCH_IN_INSTRUMENT
;Reads the pitch in the Instruments (16 bits) and adds it to HL', which should contain the software period.
;IN:    HL = points on the pitch value.
;OUT:   HL = points after the pitch.
;MOD:   A, BC', HL' updated.
PLY_LW_ReadPitchAndAddToPeriod:
        ;Reads 2 * 8 bits for the pitch. Slow...
        ld a,(hl)
        inc hl
        exx
                ld c,a                  ;Adds the read pitch to the note period.
        exx
        ld a,(hl)
        inc hl
        exx
        ld b,a
        add hl,bc
    exx
        ret
        endif ;PLY_LW_MANAGE_PITCH_IN_INSTRUMENT













;---------------------------------------------------------------------
;Effect management.
;---------------------------------------------------------------------

        if PLY_LW_MANAGE_EFFECTS

;IN:    HL = points after the first byte.
;               B = data of the first byte on bits 0-4 (will probably needed to be ANDed, as bits 5-7 are undetermined).
;               DE'= Instrument Table (not useful here). Do not modify!
;               IX = data block of the Track.
;OUT:   HL = points after the data of the effect (maybe nothing to do).
;               Each effect must jump to PLY_LW_RT_CellRead.

;Clears all the effects (volume, pitch table, arpeggio table).
PLY_LW_EffectReset:
        ;Inverted volume. --> Ignored on Sharp.
        
        xor a
        ld (ix + PLY_LW_Data_OffsetIsPitchUpDownUsed),a
        ld (ix + PLY_LW_Data_OffsetIsArpeggioTableUsed),a
        ld (ix + PLY_LW_Data_OffsetCurrentArpeggioValue),a      ;Contrary to the Pitch, the value must be reset.
        ld (ix + PLY_LW_Data_OffsetIsPitchTableUsed),a
        jp PLY_LW_RT_CellRead

;Changes the volume. Possibly changes the Track pitch.
PLY_LW_EffectVolumeAndPitchUpDown:
        ;Stores the new inverted volume. -> Ignored on Sharp.

        ;Pitch? Warning, the code below is shared with the PitchUp/Down effect.
        bit 4,b
        jp z,PLY_LW_RT_CellRead
        ;Pitch present. Reads and stores its 16 bits value (integer/decimal).
PLY_LW_EffectPitchUpDown_Activated:
        ;Code shared with the effect above.
        ;Activates the effect.
        ld (ix + PLY_LW_Data_OffsetIsPitchUpDownUsed),255
        ld a,(hl)
        inc hl
        ld (ix + PLY_LW_Data_OffsetTrackPitchSpeed + 0),a
        ld a,(hl)
        inc hl
        ld (ix + PLY_LW_Data_OffsetTrackPitchSpeed + 1),a

        jp PLY_LW_RT_CellRead


;Effect table. Each entry jumps to an effect management code.
;Put after the code above so that the JR are within bound.
PLY_LW_EffectTable:
        jr PLY_LW_EffectReset                                   ;000
        jr PLY_LW_EffectArpeggioTable                           ;001
        jr PLY_LW_EffectPitchTable                              ;010
        jr PLY_LW_EffectPitchUpDown                             ;011
        jr PLY_LW_EffectVolumeAndPitchUpDown                    ;100
        jr PLY_LW_EffectVolumeArpeggioTable                     ;101
        jr PLY_LW_EffectResetArpeggioTable                      ;110
        ;111 Unused.



;Pitch up/down effect, activation or stop.
PLY_LW_EffectPitchUpDown:
        rr b    ;Pitch present or pitch stop?
        jr c,PLY_LW_EffectPitchUpDown_Activated
        ;Pitch stop.
        ld (ix + PLY_LW_Data_OffsetIsPitchUpDownUsed),0
        jp PLY_LW_RT_CellRead

;Arpeggio table effect, activation or stop.
PLY_LW_EffectArpeggioTable:
        ld a,b
        and %11111
PLY_LW_EffectArpeggioTable_AfterMask:
        ld (ix + PLY_LW_Data_OffsetIsArpeggioTableUsed),a       ;Sets to 0 if the Arpeggio is stopped, or any other value if it starts.
        jr z,PLY_LW_EffectArpeggioTable_Stop

        ;Gets the Arpeggio address.
        add a,a
        exx
                ld l,a
                ld h,0
PLY_LW_PtArpeggios: ld bc,0
                add hl,bc
                ld a,(hl)
                inc hl
                ld (ix + PLY_LW_Data_OffsetPtArpeggioTable + 0),a
                ld a,(hl)
                inc hl
                ld (ix + PLY_LW_Data_OffsetPtArpeggioTable + 1),a
        exx

        ;Resets the offset of the Arpeggio, to force a restart.
        xor a
        ld (ix + PLY_LW_Data_OffsetPtArpeggioOffset),a
        jp PLY_LW_RT_CellRead
PLY_LW_EffectArpeggioTable_Stop:
        ;Contrary to the Pitch, the Arpeggio must also be set to 0 when stopped.
        ld (ix + PLY_LW_Data_OffsetCurrentArpeggioValue),a
        jp PLY_LW_RT_CellRead

;Pitch table effect, activation or stop.
;This is exactly the same code as for the Arpeggio, but I can't find a way to share it...
PLY_LW_EffectPitchTable:
        ld a,b
        and %11111
PLY_LW_EffectPitchTable_AfterMask:
        ld (ix + PLY_LW_Data_OffsetIsPitchTableUsed),a  ;Sets to 0 if the Pitch is stopped, or any other value if it starts.
        jp z,PLY_LW_RT_CellRead

        ;Gets the Pitch address.
        add a,a
        exx
                ld l,a
                ld h,0
PLY_LW_PtPitches: ld bc,0
                add hl,bc
                ld a,(hl)
                inc hl
                ld (ix + PLY_LW_Data_OffsetPtPitchTable + 0),a
                ld a,(hl)
                inc hl
                ld (ix + PLY_LW_Data_OffsetPtPitchTable + 1),a
        exx

        ;Resets the offset of the Pitch, to force a restart.
        xor a
        ld (ix + PLY_LW_Data_OffsetPtPitchOffset),a

        jp PLY_LW_RT_CellRead



;Volume, and Arpeggio Table, activation or stop.
PLY_LW_EffectVolumeArpeggioTable:
        ;Stores the new inverted volume. -> Ignored on Sharp.

        ;Manages the Arpeggio, encoded just after.
        ld a,(hl)
        inc hl
        or a            ;Required, else a volume of 0 will disturb the flag test after the jump!
        jr PLY_LW_EffectArpeggioTable_AfterMask

;Reset, and Arpeggio Table (activation only).
PLY_LW_EffectResetArpeggioTable:
        ;Resets effects and read volume.
        ;A bit of loss of CPU because we're going to set the Arpeggio just after, AND the effect pointer is stored!
        ;Oh well, less memory taken this way.
        call PLY_LW_EffectReset

        ;Reads the Arpeggio.
        ld a,(hl)
        inc hl
        or a            ;Required, else a volume of 0 will disturb the flag test after the jump!
        jp PLY_LW_EffectArpeggioTable_AfterMask         ;No need to use the mask, the value is clean.



        endif ;PLY_LW_MANAGE_EFFECTS




        ;Includes the sound effects player, if wanted.
        if PLY_LW_MANAGE_SOUND_EFFECTS
		include "PlayerLightWeight_SoundEffects_SHARPMZ700.asm"
        endif




;---------------------------------------------------------------------
;Data blocks for the three channels. Make sure NOTHING is added between, as the init clears everything!
;---------------------------------------------------------------------

;Data block for channel 1.
PLY_LW_Track1_Data:
PLY_LW_Track1_WaitEmptyCell: db 0                       ;How many empty cells have to be waited. 0 = none.
PLY_LW_Track1_Transposition: db 0
PLY_LW_Track1_PtTrack: dw 0                             ;Points on the next Cell of the Track to read. Evolves.
PLY_LW_Track1_BaseNote: db 0                            ;Base note, such as the note played. The transposition IS included.
PLY_LW_Track1_PtInstrument: dw 0                        ;Points on the Instrument, evolves.
PLY_LW_Track1_PtBaseInstrument: dw 0                    ;Points on the base of the Instrument, does not evolve.
PLY_LW_Track1_InstrumentCurrentStep: db 0               ;The current step on the Instrument (>=0, till it reaches the Speed).
PLY_LW_Track1_InstrumentSpeed: db 0                     ;The Instrument speed (>=0).
        if PLY_LW_MANAGE_EFFECTS
PLY_LW_Track1_IsPitchUpDownUsed: db 0                   ;>0 if a Pitch Up/Down is currently in use.
PLY_LW_Track1_TrackPitchInteger: dw 0                   ;The integer part of the Track pitch. Evolves as the pitch goes up/down.
PLY_LW_Track1_TrackPitchDecimal: db 0                   ;The decimal part of the Track pitch. Evolves as the pitch goes up/down.
PLY_LW_Track1_TrackPitchSpeed: dw 0                     ;The integer and decimal part of the Track pitch speed. Is added to the Track Pitch every frame.
PLY_LW_Track1_IsArpeggioTableUsed: db 0                 ;>0 if an Arpeggio Table is currently in use.
PLY_LW_Track1_PtArpeggioTable: dw 0                     ;Point on the base of the Arpeggio table, does not evolve.
PLY_LW_Track1_PtArpeggioOffset: db 0                    ;Increases over the Arpeggio.
PLY_LW_Track1_CurrentArpeggioValue: db 0                ;Value from the Arpeggio to add to the base note. Read even if the Arpeggio effect is deactivated.
PLY_LW_Track1_IsPitchTableUsed: db 0                    ;>0 if a Pitch Table is currently in use.
PLY_LW_Track1_PtPitchTable: dw 0                        ;Points on the base of the Pitch table, does not evolve.
PLY_LW_Track1_PtPitchOffset: db 0                       ;Increases over the Pitch.
PLY_LW_Track1_CurrentPitchTableValue: dw 0              ;16 bit value from the Pitch to add to the base note. Not read if the Pitch effect is deactivated.
        endif ;PLY_LW_MANAGE_EFFECTS
PLY_LW_Track1_Data_End:

PLY_LW_Track1_Data_Size: equ PLY_LW_Track1_Data_End - PLY_LW_Track1_Data

PLY_LW_Data_OffsetWaitEmptyCell:                equ PLY_LW_Track1_WaitEmptyCell - PLY_LW_Track1_Data
PLY_LW_Data_OffsetTransposition:                equ PLY_LW_Track1_Transposition - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtTrack:                      equ PLY_LW_Track1_PtTrack - PLY_LW_Track1_Data
PLY_LW_Data_OffsetBaseNote:                     equ PLY_LW_Track1_BaseNote - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtInstrument:                 equ PLY_LW_Track1_PtInstrument - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtBaseInstrument:             equ PLY_LW_Track1_PtBaseInstrument - PLY_LW_Track1_Data
PLY_LW_Data_OffsetInstrumentCurrentStep:        equ PLY_LW_Track1_InstrumentCurrentStep - PLY_LW_Track1_Data
PLY_LW_Data_OffsetInstrumentSpeed:              equ PLY_LW_Track1_InstrumentSpeed - PLY_LW_Track1_Data
        if PLY_LW_MANAGE_EFFECTS
PLY_LW_Data_OffsetIsPitchUpDownUsed:            equ PLY_LW_Track1_IsPitchUpDownUsed - PLY_LW_Track1_Data
PLY_LW_Data_OffsetTrackPitchInteger:            equ PLY_LW_Track1_TrackPitchInteger - PLY_LW_Track1_Data
PLY_LW_Data_OffsetTrackPitchDecimal:            equ PLY_LW_Track1_TrackPitchDecimal - PLY_LW_Track1_Data
PLY_LW_Data_OffsetTrackPitchSpeed:              equ PLY_LW_Track1_TrackPitchSpeed - PLY_LW_Track1_Data
PLY_LW_Data_OffsetIsArpeggioTableUsed:          equ PLY_LW_Track1_IsArpeggioTableUsed - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtArpeggioTable:              equ PLY_LW_Track1_PtArpeggioTable - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtArpeggioOffset:             equ PLY_LW_Track1_PtArpeggioOffset - PLY_LW_Track1_Data
PLY_LW_Data_OffsetCurrentArpeggioValue:         equ PLY_LW_Track1_CurrentArpeggioValue - PLY_LW_Track1_Data
PLY_LW_Data_OffsetIsPitchTableUsed:             equ PLY_LW_Track1_IsPitchTableUsed - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtPitchTable:                 equ PLY_LW_Track1_PtPitchTable - PLY_LW_Track1_Data
PLY_LW_Data_OffsetCurrentPitchTableValue:       equ PLY_LW_Track1_CurrentPitchTableValue - PLY_LW_Track1_Data
PLY_LW_Data_OffsetPtPitchOffset:                equ PLY_LW_Track1_PtPitchOffset - PLY_LW_Track1_Data
        endif ;PLY_LW_MANAGE_EFFECTS



;---------------------------------------------------------------------
;Register block for the channel.
;---------------------------------------------------------------------

PLY_LW_Track1_Registers:
PLY_LW_Track1_Volume: db 0
PLY_LW_Track1_SoftwarePeriodLSB: db 0
PLY_LW_Track1_SoftwarePeriodMSB: db 0




PLY_LW_Registers_OffsetVolume: equ PLY_LW_Track1_Volume - PLY_LW_Track1_Registers
PLY_LW_Registers_OffsetSoftwarePeriodLSB: equ PLY_LW_Track1_SoftwarePeriodLSB - PLY_LW_Track1_Registers
PLY_LW_Registers_OffsetSoftwarePeriodMSB: equ PLY_LW_Track1_SoftwarePeriodMSB - PLY_LW_Track1_Registers

;The period table for each note (from 0 to 127 included).
PLY_LW_PeriodTable:
        ;PSG running to 894886 Hz.
	dw 3420, 3229, 3047, 2876, 2715, 2562, 2419, 2283, 2155, 2034, 1920, 1812	; Octave 0
	dw 1710, 1614, 1524, 1438, 1357, 1281, 1209, 1141, 1077, 1017, 960, 906	; Octave 1
	dw 855, 807, 762, 719, 679, 641, 605, 571, 539, 508, 480, 453	; Octave 2
	dw 428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226	; Octave 3
	dw 214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113	; Octave 4
	dw 107, 101, 95, 90, 85, 80, 76, 71, 67, 64, 60, 57	; Octave 5
	dw 53, 50, 48, 45, 42, 40, 38, 36, 34, 32, 30, 28	; Octave 6
	dw 27, 25, 24, 22, 21, 20, 19, 18, 17, 16, 15, 14	; Octave 7
	dw 13, 13, 12, 11, 11, 10, 9, 9, 8, 8, 7, 7	; Octave 8
	dw 7, 6, 6, 6, 5, 5, 5, 4, 4, 4, 4, 4	; Octave 9

        
PLY_LW_End: