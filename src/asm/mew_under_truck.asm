SECTION "Main",ROM0 ; D66C

; Patch the current room script every time we load another room
ld hl,$D36F
ld de,$D66B
ld a,[hld]
cp $80
jr nc,alreadyPatchedScript
ld [de],a
dec de
ld a,[hl]
ld [de],a
alreadyPatchedScript:

ld [hl],$83
inc hl
ld [hl],$D6

ld a, $C3 ; important for DMARoutine
ret

SECTION "Main",ROM0[$0017] ; D683

; Patch hram code to always call the code at D66C
ld hl,$ff80
ld [hl],$18 ; jr 78 (to FFFA)
inc hl
ld [hl],$78
ld hl,$FFFA
ld [hl],$CD ; call $D66C
inc hl
ld [hl],$6C
inc hl
ld [hl],$D6
inc hl
ld [hl],$18 ; jr 83 (to FF82)
inc hl
ld [hl],$83

ld a,[$d35e] ; current map
cp $5E
jr z,vermilionDocks
cp $EF
jr z,tradeCenter

returnFromRoomSpecificScript:

; return to to normal script for the room.
ld hl,$D66A
ld a,[hli]
ld h,[hl]
ld l,a
jp [hl]
;;;end


vermilionDocks:
ld hl,$A000
jr loadExtraCodeFromSram

tradeCenter:
ld hl,$A200

loadExtraCodeFromSram:
ld a,$0A
ld [$0000],a ;enable sram
ld a,$01
ld [$4000],a ;choose sram bank

ld de,$C800
ld bc,$0200
call $00B5 ; CopyData
ld h,$00
ld [hl],h ; disable sram
call $C800
jr returnFromRoomSpecificScript

SECTION "Main",ROM0[$0200] ; sram 2000

ld b,%11
waitForNonHBlank:
ldh a, ($41)
and b
jr z, waitForNonHBlank
waitForHBlank:
ldh a, ($41)
and b
jr nz, waitForHBlank

ld a,[$8142]
cp $3B
jr z,dontFixMewGraphics
; fix mew graphics
ld de,$C940
ld hl,$80C0
ld c,4
call $1848 ; CopyVideoData
ld de,$C940
ld hl,$8140
ld c,4
call $1848 ; CopyVideoData
dontFixMewGraphics:

ld hl,$C1FF
ld a,[hl]
cp $02
ret z ; have fought mew AND done the mew cleanup
and a
jr z,haventFoughtMewYet

inc [hl]

xor a
ld [$d4e1],a ; wNumSprites
ld [$C110],a

haventFoughtMewYet:

ld hl,$d36c ; text ptr
ld [hl],$20
inc hl
ld [hl],$C9

ld a,[$c1fe]
and a
jr z,dontNeedToMoveTruckAfterReload

ld hl,$c731
ld a,[hl]
cp $0C
jr z,dontNeedToMoveTruckAfterReload

ld a,$0C
ld [hl],a ; remove truck

ld a,3
ld [$d09f],a ; wNewTileBlockID
ld bc, $000B ; coords to right of truck
ld a,$17 ; ReplaceTileBlock
call $3E6D ; Predef
ret

dontNeedToMoveTruckAfterReload:

ld a,[$D362] ; X pos
cp $13
ret nz
ld a,[$D728] ;strength
and $01
ret z
ld a,[$CFC6] ; tile in front of player = left side of truck
cp $58
ret nz
ld a,[$D528] ; pushing right
cp $01
ret nz

ld hl,$c1fe
inc [hl] ; flag truck as pushed

ld a,$02 ; dust
ld [$cd60],a

ld a, $A8; SFX_PUSH_BOULDER
call $23B1 ; PlaySound

ld de,$C980 ; copy truck graphics into sprite reachable area
ld hl,$8900
ld c,8
call $1848 ; CopyVideoData

ld a,$0C
ld [$d09f],a ; wNewTileBlockID
ld bc, $000A ; coords to truck
ld a,$17 ; ReplaceTileBlock
call $3E6D ; Predef

ld e,$58
truckDelayLoop:
ld hl,$c360
ld b,$50
ld d,$90
ld c,e
truckLoop:
ld [hl],b
inc hl
ld [hl],c
ld a,c
add a,$08
ld c,a
inc hl
ld [hl],d
inc d
inc hl
ld [hl],$10
inc hl
ld a,d
cp $94
jr nz,notSecondRow
ld b,$58
ld c,e
notSecondRow:
cp $98
jr nz,truckLoop
inc e
call $20AF ; DelayFrame
ld a,e
cp $79
jr nz,truckDelayLoop

ld a,1
ld [$d4e1],a; wNumSprites
ld [$c110],a
ld hl,$C214
ld [hl],$04
inc hl
ld [hl],$19
inc hl
ld [hl],$FF
ld hl,$c21e
ld [hl],$02

ld hl, $C056 ;mess with music
ld a,$FF
ld [hli],a
ld [hl],a
ld l,$e9
ld [hl],$70

ld a,3
ld [$d09f],a ; wNewTileBlockID
ld bc, $000B ; coords to right of truck
ld a,$17 ; ReplaceTileBlock
call $3E6D ; Predef

ret

SECTION "Main",ROM0[$0320] ; 2120

DB $22,$C9 ; pointer to this text
DB $00,$8C,$A4,$B6,$E7,$50,$08 ; Mew!, terminator, asm
ld a, $15 ; Mew
ld [$d059], a ; wCurOpponent
call $13D0 ; PlayCry
call $3748 ; WaitForSoundToFinish
ld a, 50
ld [$d127], a ; wCurEnemyLVL
ld hl,$c1ff
inc [hl]
jp $24D7; TextScriptEnd


SECTION "Main",ROM0[$0400] ; sram 2200

ld hl,$d730
res 2,[hl] ; enable use of A button

ld hl,$D361
ld a,[hli] ; X pos
cp $04
ret nz
ld a,[hl]
cp $03
jr z,dontRet
cp $06
ret nz
dontRet:

ld hl,$d730
set 2,[hl] ; disable use of A button (for interacting with game boy)

ldh a,($AA) ; check direction
xor $03 ; switch 1 and 2
ld hl,$d52a
cp [hl]
ret nz

ldh a,($B3) ; check a pressed
dec a
ret nz

ld a,$08
ldh ($B8),a
ld a,$22 ; just a moment
call $3EF5 ; PrintPredefTextID

ld a,$02
ld [$d12b],a ; link state = trade

dec a ; $01
ldh ($BA),a ; enable continuous WRAM to VRAM transfer each V-blank
call $3DD7 ; Delay3
xor a
ldh ($B0),a ; put the window on the screen

ld a,$01
ld h,$20
ld [hl],a
ldh ($B8),a ; change bank

ld hl,$D141
ld bc,$17FD
setUpFD:
ld [hl],c
inc hl
dec b
jr nz,setUpFD

ld hl,$d164
ld bc,$0161
findFirstFF:
ld a,[hli]
dec bc
inc a
jr nz,findFirstFF
dec hl
fillWithE3:
ld a,$E3
ld [hli],a
dec bc
ld a,b
or c
jr nz,fillWithE3
ld [hl],$FC ; glitch pokemon name for blue that points to rng bytes

ld a,$3B
fillWithCE:
inc hl
ld [hl],$CE ; send red to CBD7
dec a
jr nz,fillWithCE

ld hl,$CBD7
ld [hl],$C3 ; jp $C8E0
inc hl
ld [hl],$E0
inc hl
ld [hl],$C8

ld hl,$C508
ld a,$FD
ld [hli],a
ld [hli],a
ld [hli],a
ld a,$FF
ld [hli],a
ld [hli],a
xor a
ld [hli],a
ld [hli],a
ld [hli],a
ld [hli],a

ld d,h
ld e,l
ld hl,$C920
ld bc,$0080
call $00B5 ; CopyData

ld hl,$D148
ld [hl],$C3 ; jp $C5D8
inc hl
ld [hl],$D8
inc hl
ld [hl],$C5
inc hl
;next bytes - landing anywhere in this sequence will jump you back to the jp $C5DF
ld [hl],$18 ; jr -5
inc hl
ld [hl],$FB
inc hl
ld [hl],$00 ; nop
inc hl
ld [hl],$18 ; jr -5
inc hl
ld [hl],$FB
inc hl
ld [hl],$18 ; jr -10
inc hl
ld [hl],$F6

call $190F ; ClearScreen
call $2429 ; UpdateSprites
call $3680 ; LoadFontTilePatterns
call $5AE6 ; LoadTrainerInfoTextBoxTiles
ld hl,$C443
ld bc,$020C
call $5AB3 ; CableClub_TextBoxBorder
ld hl,$C46C
ld de,$550F
call $1955 ; PlaceString

pop bc
jp $53B5 ; CableClub_DoBattleOrTrade - from "call Serial_SyncAndExchangeNybble"

SECTION "Main",ROM0[$04E0] ; sram 22E0
;code for red

ld sp,$DFF9 ; fix broken stack

ld h,$0A
ld [hl],h ;enable sram

ld a,$A0

loopVirus:
push af
ld h,a
ld l,$00
ld de,$c700
ld bc,$0100
call $00B5 ; CopyData

call $227F ; Serial_SyncAndExchangeNybble
call $3DD7 ; Delay3

ld hl,$c6FF
ld [hl],$FD
ld de,$c6e8
ld bc,$0110
ld a,$08
ldh ($FF),a
call $216F ; Serial_ExchangeBytes (216F)
ld a,$0D
ldh ($FF),a
pop af
inc a
cp $A4
jr nz,loopVirus

ld a,$51 ; LoadSAV2 - reload our corrupted party data. also disables sram
call $3E6D ; Predef

jp $5345 ; CableClub_DoBattleOrTradeAgain

SECTION "Main",ROM0[$0520] ; sram 2320
;code for blue

ld sp,$DFE7 ; fix broken stack

ld h,$0A
ld [hl],h ;enable sram
ld h,$40
ld [hl],$01 ;choose sram bank

ld a,$A0

loopVictim:
push af

call $227F ; Serial_SyncAndExchangeNybble
call $3DD7 ; Delay3

ld hl,$0316
ld de,$C800
push de
ld bc,$0110
ld a,$08
ldh ($FF),a
call $216F ; Serial_ExchangeBytes (216F)
ld a,$0D
ldh ($FF),a


pop hl
checkForFD:
ld a,[hli]
cp $FD
jr z,checkForFD
dec hl

pop af
push af
ld d,a
ld e,$00
ld bc,$0100
call $00B5 ; CopyData
pop af
inc a
cp $A4
jr nz,loopVictim

ld hl,$A61A
ld de,$A916
ld a,[hl]
ld [hl],$83
ld [de],a
inc hl
inc de
ld a,[hl]
ld [hl],$D6
ld [de],a
inc de

ld hl,$A39B
ld bc,$0065
call $00B5 ; CopyData

ld a,$1C
ld [$2000],a
ldh ($B8),a
ld hl, $A598
ld bc, $0F8B
call $7856 ; SAVCheckSum
ld [$b523], a

ld h,$00
ld [hl],h ;disable sram

ld a,$01
ld [$2000],a
ldh ($B8),a
jp $5345 ; CableClub_DoBattleOrTradeAgain
