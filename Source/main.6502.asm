;MAIN FILE
;RESET, NMI, general functions

	.include "header.6502.asm"

;RESET
	.bank 0
	.org $C000
RESET:			;CPU starts reading here
	SEI			;disable IRQ interrupts, external interrupts
	CLD			;disable decimal mode, something the NES 6502 chip does not have
	LDX #$40
	STX $4017	;disable APU IRQs
	LDX #$FF
	TXS			;set up stack
	INX			;now x = 0
	;(2000)
	;76543210
	;| ||||||
	;| ||||++- Base nametable address
	;| ||||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
	;| |||+--- VRAM address increment per CPU read/write of PPUDATA
	;| |||     (0: increment by 1, going across; 1: increment by 32, going down)
	;| ||+---- Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000)
	;| |+----- Background pattern table address (0: $0000; 1: $1000)
	;| +------ Sprite size (0: 8x8; 1: 8x16)
	;|
	;+-------- Generate an NMI at the start of the
	;            vertical blanking interval vblank (0: off; 1: on)
	STX	$2000	;disable NMI for now
	;(2001)
	;76543210
	;||||||||
	;|||||||+- Grayscale (0: normal color; 1: AND all palette entries
	;|||||||   with 0x30, effectively producing a monochrome display;
	;|||||||   note that colour emphasis STILL works when this is on!)
	;||||||+-- Disable background clipping in leftmost 8 pixels of screen
	;|||||+--- Disable sprite clipping in leftmost 8 pixels of screen
	;||||+---- Enable background rendering
	;|||+----- Enable sprite rendering
	;||+------ Intensify reds (and darken other colors)
	;|+------- Intensify greens (and darken other colors)
	;+-------- Intensify blues (and darken other colors)
	STX $2001	;disable rendering
	STX $4010	;disable DMC IRQs
	
	JSR VBlankWait


;CLEAR MEMORY, MOVE SPRITES
_clearMem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x

	LDA $FE
	STA $0200, x	;move all sprites off screen
	INX
	BNE _clearMem	;when x turns from $FF to $00 the zero flag is set
	
	JSR VBlankWait

;LOAD PALETTS
	;PPU: palett recognition to adress $3F00
	LDA $2002	;read PPU status to reset the high/low latch to high
	LDA #$3F	;load the high byte
	STA $2006	;write the high byte
	LDA #$00	;load the low byte
	STA $2006	;write the low byte
	;that code tells the PPU to set its address to $3F10, now the PPU data port at $2007 is ready to accept data
	;loop with x and feed PPU, use this method if the whole palette is changed, otherwise use $3F10 and 32 bytes up
	LDX #$00
_loadPalettsLoop:
	LDA palette, x
	STA $2007			;write the color one by one to the same adress
	INX					;increment x
	CPX #$20			;compare x with $20 = 32, which is the size of both paletts combined
	BNE _loadPalettsLoop	;Branch if Not Equal
	
	
;LOAD BACKGROUND
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ;write the high byte of $2000 address (start of nametable 0 in PPU memory)
	LDA #$00
	STA $2006             ;write the low byte of $2000 address

	LDA #LOW (background)
	STA backgroundPtr_lo
	LDA #HIGH (background)	;some NESASM3 exclusive features
	STA backgroundPtr_hi

	LDX #$00
	LDY #$00
_loadStartupBackgroundLoop:
	LDA [backgroundPtr_lo], y
	STA $2007

	INY
	BNE _loadStartupBackgroundLoop	;let it loop, let it loop, when zero

	INC backgroundPtr_hi	;increment memory (makes the pointer as a whole go up 256 bytes)
	INX

	CPX #$04	;make the 256 loop four times
	BNE _loadStartupBackgroundLoop
	
	
;LOAD ATTRIBUTE TABLE
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$23
	STA $2006             ;write the high byte of $23C0 address
	LDA #$C0
	STA $2006             ;write the low byte of $23C0 address
	LDX #$00
_loadStartupAttributeLoop:
	LDA attribute, x
	STA $2007             ;write to PPU
	INX
	CPX #$20              ;8*4= $20 which is 32 in dec
	BNE _loadStartupAttributeLoop
	
	
;LOAD TEST META SPRITE
	LDX #$00
_loadFirstMetaSpriteLoop:
	LDA testSpriteData, x	;loads the data table to the sprite table in memory
	STA $0200, x
	INX
	CPX #$10
	BNE _loadFirstMetaSpriteLoop
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
	
	.include "gameStartup.6502.asm"

	;enable NMI, sprites from pattern table table 0
	LDA #%10000000
	STA $2000
	
	;enable sprites
	LDA #%00010000
	STA $2001


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GAME LOOP

_gameLoop:
	LDA #$00
	STA nmiDone

	;Here, do the actual game

	;states
	LDA gameState

	CMP GAME_STATE_PLAYING
	BNE Forever
	JSR _gameStatePlaying

	CMP GAME_STATE_TITLE
	BNE Forever
	JSR _gameStateTitle

	CMP GAME_STATE_GAMEOVER
	BNE Forever
	JSR _gameStateGameOver

Forever:
	LDA nmiDone
	BNE _gameLoop
	JMP Forever


;IMPLEMENTATION OF GAME STATES
	.include "game.6502.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;FUNCTIONS

VBlankWait:
	BIT $2002		;BIT loads bit 7 into N, the bit apperently tells when the vBlank is done
	BPL VBlankWait	;BPL, Branch on PLus, checks the N register if it's 0
	RTS				;ReTurn from Subroutine



;NMI
;graphics interrupt, the only "time indicator". Expected to be 60 fps, (50) for PAL
NMI:
	;sprite setup, it seems this has to be done every NMI interrupt, 64 in the pattern table
	;sprite DMA setup (direct memory access), typically $0200-02FF (internal RAM) is used for this, which it is in this case
;SPRITE NMI
	LDA #$00	;low byte of $0200
	STA $2003
	LDA #$02
	STA $4014	;sets the high byte


;INPUT
	;latch buttons, prepare buttons to send out signals
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	
	LDX #$08
_input1Loop:
	LDA $4016
	LSR A
	ROL playerOneInput
	DEX
	BNE _input1Loop

	LDX #$08
_input2Loop:
	LDA $4017
	LSR A
	ROL playerTwoInput
	DEX
	BNE _input2Loop


;PPU CLEAN UP
	LDA #%10010000	;enable NMI, sprites from pattern table 0, background from pattern table 1
	STA $2000
	LDA #%00011110
	STA $2001		;enable sprites and background, no clipping on left side
	LDA #$00
	STA $2005		;tells PPU there is no background scrolling
	STA $2005


	LDA #$01
	STA nmiDone
	RTI	;ReTurn from Interrupt



;PRG DATA
;use camel-casing
	.bank 1
	.org $E000
palette:
	.incbin "Palettes/persistant.pal"
	;0 of the 4 colors in one pallete: beginning of the sprite table
	.incbin "Palettes/persistant.pal"
	
background:
	.incbin "Backgrounds/snake.nam"

	.rsset background + 960
attribute	.rs 0


testSpriteData:
	.db $80, $00, $00, $80   ;sprite 0
	.db $80, $00, $00, $88   ;sprite 1
	.db $88, $00, $00, $80   ;sprite 2
	.db $88, $00, $00, $88   ;sprite 3


;INTERRUPTS OR VECTORS
	.org $FFFA
	.dw NMI 	;"Update" vector, processor starts to read code here each graphics cycle if enabled
	.dw RESET	;the processor will start exicuting here when the program starst as well as when the reset button is pressed 
	.dw 0		;IRQs won't be used
	
;GRAPHICS BANKS
	.bank 2		;graphics bank
	.org $0000
	.incbin "main.chr"		;includes 8KB graphics file