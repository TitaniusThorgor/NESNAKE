;iNES HEADER
	.inesprg 1	;1x 16KB bank of PRG code
	.ineschr 1	;1x 8KB bank of CHR data
	.inesmap 0	;no bank swapping at the time
	.inesmir 1	;enabels background mirroring

;NAMING
;variables: camelCasing
;pointers: _camelCasing_lo and _camelCasing_hi
;data structures: camelCasing
;temporary labels e.g. for loops: _camelCasing
;subroutines/functions: PascalCasing
;constants: SNAKE_CASING (with all-capital letters)
;graphics adresses: SNAKE_CASING_sp and SNAKE_CASING_ba
;interrupts: SNAKE_CASING (same here)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;CONSTANTS

GAME_STATE_TITLE = $01		;gamestates
GAME_STATE_PLAYING = $02
GAME_STATE_GAMEOVER = $03

SNAKE_SPEED_START = $01		;when 60, it moves 1 tile per frame
WALL_TOP = $02				;in tiles
WALL_BOTTOM = $12
WALL_LEFT = $02
WALL_RIGHT = $12
SNAKE_LENGHT = $20

	.include "Constants/backgroundConstants.6502.asm"
	.include "Constants/backgroundConstants.6502.asm"

;POINTERS
	.rsset $0000			;zero page

_backgroundPtr_lo	.rs 1
_backgroundPtr_hi	.rs 1


;VARIABLES
	.rsset $0300			;prevous to this: sprite DMA

nmiDone				.rs 1
playerOneInput		.rs 1		;use functions together with a bitwise AND to get input
playerTwoInput		.rs 1		; A   B   Select   Start   Up   Down   Left   Right
gameState			.rs 1		;use states defined as constants

;ticks in this case: frames between that the snake moves
snakeTicksToMove 	.rs 1
snakeTicks			.rs 1

;3bits for one input, 1bit for who knows what
snakeInputs 		.rs (SNAKE_LENGHT/2) ;(WALL_BOTTOM - WALL_TOP)*(WALL_RIGHT - WALL_LEFT)

;increases after eating fruits
snakeLength_lo		.rs 1
snakeLength_hi		.rs 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;RESET
	.bank 0
	.org $C000
RESET:			;CPU starts reading here
	SEI			;disable IRQ interrupts, external interrupts
	CLD			;disable decimal mode, something the NES 6502 chip does not have
	LDX #$40
	STX $4017	;disable APU IRQs or something
	LDX #$FF
	TXS			;set up stack
	INX			;now x = 0
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
	LDA #$FE		   ;move all sprites off screen
	STA $0200, x
	INX
	BNE _clearMem	;when x turns from $FF to $00 the zero flag is set
	
	JSR VBlankWait
	

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
_loadPalletsLoop:
	LDA paletteData, x
	STA $2007			;write the color one by one to the same adress
	INX					;increment x
	CPX #$20			;compare x with $20 = 32, which is the size of both pallets combined
	BNE _loadPalletsLoop	;Branch if Not Equal
	
	
;LOAD BACKGROUND
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ;write the high byte of $2000 address (start of nametable 0 in PPU memory)
	LDA #$00
	STA $2006             ;write the low byte of $2000 address

	LDA #$00
	STA _backgroundPtr_lo
	LDA #HIGH (background)	;some NESASM3 exclusive features
	STA _backgroundPtr_hi

	LDX #$00
	LDY #$00
_loadBackgroundLoop:
	LDA [_backgroundPtr_lo], y
	STA $2007

	INY
	CPY #$00
	BNE _loadBackgroundLoop	;let it loop, let it loop

	INC _backgroundPtr_hi	;increment memory (makes the pointer as a whole go up 256 bytes)
	INX

	CPX #$04	;make the 256 loop four times
	BNE _loadBackgroundLoop
	
	
;LOAD ATTRIBUTE TABLE
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$23
	STA $2006             ;write the high byte of $23C0 address
	LDA #$C0
	STA $2006             ;write the low byte of $23C0 address
	LDX #$00
_loadAttributeLoop:
	LDA attribute, x
	STA $2007             ;write to PPU
	INX
	CPX #$20              ;8*4= $20 which is 32 in dec
	BNE _loadAttributeLoop
	
	
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
	BEQ _gameStatePlaying

	CMP GAME_STATE_TITLE
	BEQ _gameStateTitle

	CMP _gameStateGameOver
	BEQ _gameStateGameOver

	JMP Forever


_gameStatePlaying:
	LDX snakeTicks
	INX
	CPX snakeTicksToMove
	BNE AfterTick

	;Tick, if snake moves
	;snakeInputs
	
	;loop through the 16 bit array/ array of arrays
_snakeInputsLoopCounter	.rs 1
	LDX #$00
	LDY snakeInputs	;store until end of the loop
_snakeInputsLoop:
	;compare high and low individually
	;CPX #HIGH ()
	;;;;;
	LDA snakeInputs, X

	;two checks
	INX
	BEQ _snakeInputsLoop
	LDA _snakeInputsLoopCounter
	CLC
	ADC #$01

	JMP _snakeInputsLoop



AfterTick:
	;do things such as updating sprites

	JMP Forever


_gameStateTitle:
	LDA GAME_STATE_PLAYING
	STA gameState

	JMP Forever


_gameStateGameOver:
	JMP RESET		;I don't know if this will work


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;FUNCTIONS

Forever:
	LDA nmiDone
	BNE _gameLoop
	JMP Forever

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
	
	
;MOVEMENT OF THE TEST META SPRITE
	LDA playerOneInput
	AND #%00001000
	BEQ _afterUp
	LDX $0200
	DEX
	STX $0200
_afterUp:

	LDA playerOneInput
	AND #%00000100
	BEQ _afterDown
	LDX $0200
	INX
	STX $0200
_afterDown:

	LDA playerOneInput
	AND #%00000010
	BEQ _afterLeft
	LDX $0203
	DEX
	STX $0203
_afterLeft:

	LDA playerOneInput
	AND #%00000001
	BEQ _afterRight
	LDX $0203
	INX
	STX $0203
_afterRight:


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
paletteData:
	.incbin "Palettes/persistant.pal"
	;.db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;background palette
	;.db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;sprite palette

;save nametables and attributes in different files
background:
	.incbin "Backgrounds/snake.nam"
;	.db $24,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$24,$24,$24,$24,$24,$24  ;;row 1
;	.db $66,$66,$56,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
;
;	.db $88,$31,$98,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
;	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
;
;	.db $78,$20,$80,$76,$66,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3
;	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops
;
;	.db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4
;	.db $69,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms

attribute:
	.incbin "Backgrounds/snake.atr"
;	.db %00000011, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000
;
;	.db $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms


testSpriteData:
	.db $80, $32, $00, $80   ;sprite 0
	.db $80, $33, $00, $88   ;sprite 1
	.db $88, $34, $00, $80   ;sprite 2
	.db $88, $35, $00, $88   ;sprite 3


;INTERRUPTS OR VECTORS
	.org $FFFA
	.dw NMI 	;"Update" vector, processor starts to read code here each graphics cycle if enabled
	.dw RESET	;the processor will start exicuting here when the program starst as well as when the reset button is pressed 
	.dw 0		;IRQs won't be used
	
;GRAPHICS BANKS
	.bank 2		;graphics bank
	.org $0000
	.incbin "main.chr"		;includes 8KB graphics file