;iNES header, this tell emulaotrs and such the layout of the file 
	.inesprg 1	;1x 16KB bank of PRG code
	.ineschr 1	;1x 8KB bank of CHR data
	.inesmap 0	;no bank swapping at the time
	.inesmir 1	;enabels background mirroring
	
;implementation of RESET
	.bank 0
	.org $C000
RESET:
	SEI			;disable IRQ interrupts, external interrupts
	CLD			;disable decimal mode, something the NES 6502 chip does not have
	LDX #$40
	STX $4017	;disable APU IRQs or something
	LDX #$FF
	TXS			;set up stack
	INX			;now x = 0
	STX	$2000	;disable NMI for now
	STX $2001	;disable rendering
	STX $4010	;disable DMC IRQs
	
vBlankWait1
	BIT $2002		;BIT loads bit 7 into N, the bit apperently tells when the vBlank is done
	BPL vBlankWait1	;BPL, Branch on PLus, checks the N register if it's 0
	
	
	LDA #$00
clearMem
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x    ;move all sprites off screen
	INX
	BNE clearMem	;when x turns from $FF to $00 the zero flag is set
	
vblankwait2:      ; Second wait for vblank, PPU is ready after this
	BIT $2002
	BPL vblankwait2
	
;LOAD PALLETS
	;PPU: pallet recognition to adress $3F00
	LDA $2002	;read PPU status to reset the high/low latch to high
	LDA #$3F	;load the high byte
	STA $2006	;write the high byte
	LDA #$00	;load the low byte
	STA $2006	;write the low byte
	;that code tells the PPU to set its address to $3F10, now the PPU data port at $2007 is ready to accept data
	
	;loop with x and feed PPU, use this method if the whole palette is changed, otherwise use $3F10 and 32 bytes up
	LDX #$00
loadPalletsLoop:
	LDA PaletteData, x	;this syntax is very important, "load a with palette data with the offset of x: the index"
	STA $2007			;write the color one by one to the same adress
	INX					;increment x
	CPX #$20			;compare x with $20 = 32, which is the size of both pallets combined
	BNE loadPalletsLoop	;Branch if Not Equal
	
;LOAD BACKGROUND
LoadBackground:
	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ; write the high byte of $2000 address
	LDA #$00
	STA $2006             ; write the low byte of $2000 address
	LDX #$00              ; start out at 0
LoadBackgroundLoop:
	LDA background, x     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
	BNE LoadBackgroundLoop
	
	
;LOAD TEST META SPRITE
	LDX #$00
loadFirstMetaSpriteLoop:
	LDA TestSpriteData, x	;loads the data table to the sprite table in memory
	STA $0200, x
	INX
	CPX #$10
	BNE loadFirstMetaSpriteLoop
	
	;sprite data: $0200 - 0240 with 4 bytes interval
	;sprite data layout: 
	;1 - Y Position - vertical position of the sprite on screen. $00 is the top of the screen. Anything above $EF is off the bottom of the screen.
	;2 - Tile Number - this is the tile number (0 to 256) for the graphic to be taken from a Pattern Table.
	;3 - Attributes - this byte holds color and displaying information:
	;  76543210
	;  ||||||||
	;  |||   ++- Color Palette of sprite.  Choose which set of 4 from the 16 colors to use
	;  |||
	;  ||+------ Priority (0: in front of background; 1: behind background)
	;  |+------- Flip sprite horizontally
	;  +-------- Flip sprite vertically
	;4 - X Position - horizontal position on the screen. $00 is the left side, anything above $F9 is off screen

	
	;enable NMI, sprites from pattern table table 0
	LDA #%10000000
	STA $2000
	
	;enable sprites
	LDA #%00010000
	STA $2001
	
	;Controller setup
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	
	
	
Forever:
	JMP Forever		;infinite loop
	
;Subroutines goes here

	
;NMI: graphics interrupt, the only "time indicator". Expected to be 60 fps, (50) for PAL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NMI:
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;sprite setup, it seems this has to be done every NMI interrupt, 64 in the pattern table
	;sprite DMA setup (direct memory access), typically $0200-02FF (internal RAM) is used for this, which it is in this case
	LDA #$00	;low byte of $0200
	STA $2003
	LDA #$02
	STA $4014	;sets the high byte
	
;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Input
	;prepare buttons to send out signals
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	
	LDX #$00
input1Loop:
	LDA $4016
	AND #%00000001
	STA $07F0, x
	INX
	CPX #$08
	BNE input1Loop
input2Loop:
	LDA $4017
	AND #%00000001
	STA $07F0, x
	INX
	CPX #$10
	BNE input2Loop
	
;player1A
;	LDA $4016
;	AND #%00000001
;	BEQ read1ADone	;branch
;	
;	LDA $0203       ; load sprite X position
;	CLC             ; make sure the carry flag is clear
;	ADC #$01        ; A = A + 1
;	STA $0203       ; save sprite X position
;read1ADone:

;player1B
;	LDA $4016
;	AND #%00000001
;	BEQ read1BDone
;	
;	LDA $0203
;	SEC
;	SBC #$01
;	STA $0203
;read1BDone:
	
	;try to move the meta sprite
	LDA $07F4
	BEQ afterUp
	LDX $0200
	DEX
	STX $0200
afterUp:

	LDA $07F5
	BEQ afterDown
	LDX $0200
	INX
	STX $0200
afterDown:

	LDA $07F6
	BEQ afterLeft
	LDX $0203
	DEX
	STX $0203
afterLeft:

	LDA $07F7
	BEQ afterRight
	LDX $0203
	INX
	STX $0203
afterRight:
	
;;;;;;;;;;;;;;;;;;;;;;;;
	
	RTI	;ReTurn from Interrupt
	
;;;;;;;;;;;;;;;;;;;;;;;;
	
	.bank 1
	
	.org $E000
PaletteData:
	.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette data
	.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ;sprite palette data
	
TestSpriteData:
	.db $80, $32, $00, $80   ;sprite 0
	.db $80, $33, $00, $88   ;sprite 1
	.db $88, $34, $00, $80   ;sprite 2
	.db $88, $35, $00, $88   ;sprite 3
	
;;;;;;;;;;;;;;;;;;;;;

	;vectors/interrupts
	.org $FFFA	;this is where the adresses to the actual "functions" are being stored, I think. F - A + 1 = 6
	.dw NMI 	;"Update" vector, processor starts to read code here each graphics cycle if enabled
	.dw RESET	;the processor will start exicuting here when the program starst as well as when the reset button is pressed 
	.dw 0		;IRQs won't be used
	
	.bank 2		;graphics bank
	.org $0000
	.incbin "mario.chr"		;includes 8KB graphics file