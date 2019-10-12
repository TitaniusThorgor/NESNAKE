;iNES HEADER
	.inesprg 1	;1x 16KB bank of PRG code
	.ineschr 1	;1x 8KB bank of CHR data
	.inesmap 0	;no bank swapping at the time
	.inesmir 1	;enabels background mirroring

;NAMING
;variables: camelCasing
;pointers: camelCasing_lo and camelCasing_hi
;data structures: camelCasing
;temporary labels e.g. for loops: _camelCasing
;subroutines/functions: PascalCasing
;constants: SNAKE_CASING (with all-capital letters)
;graphics adresses: SNAKE_CASING_sp and SNAKE_CASING_ba
;interrupts: SNAKE_CASING (same here)




;CONSTANTS

GAME_STATE_TITLE = $00		;gamestates
GAME_STATE_PLAYING = $01
GAME_STATE_GAMEOVER = $02

WALL_TOP = $02				;in tiles
WALL_BOTTOM = $19			;26
WALL_LEFT = $02
WALL_RIGHT = $1B

;don't need a 16 bit value, (32*32)/4=256, very convenient, just under that (maximum: 32*30)
SNAKE_BUFFER_LENGTH = (WALL_BOTTOM - WALL_TOP) * (WALL_RIGHT - WALL_LEFT) / 4

SNAKE_FRAMES_TO_MOVE_START = 60		;when 60, it moves 1 tile per frame

;the snake CHR row, index from this with the order: up, down, left, right beginning with head than tail then body
SNAKE_CHR_HEAD_ROW = $40
SNAKE_CHR_TAIL_ROW = $44
SNAKE_CHR_BODY_ROW = $48
SNAKE_CHR_EMPTY_TILE = $30


;POINTERS
	.rsset $0000			;zero page

backgroundPtr_lo	.rs 1
backgroundPtr_hi	.rs 1



;BACKGROUND BUFFER: OneTileNamBuffer
;this buffer format favours standout tile changes
;instead of setting VRAM in game code, prepare a buffer in main RAM (for example, use unused parts of the stack at $0100-$019F) before vblank
;and then copy from that buffer into VRAM during vblank
;it's important that as much of the computation is moved out of NMI as possible, the adress is an adress, not an x and y value
	.rsset $0100

	;first byte: tells how many elements there are to copy over (this means one element is 3 bytes), if 0, no bytes will be read (if namBuffer is 4 then there are 4 elements in the buffer)
	;rest of buffer, three bytes are read for each change in background; 0: tile index, 2: low-byte, 1: high-byte, this is because it is read backwards
namBuffer			.rs $9F



;VARIABLES
;don't forget to add setup when needed
generalVar			.rsset $0300			;prevous to this: sprite DMA

;background directives
backgroundDir_lo	.rs 1
backgroundDir_hi	.rs 1

;general
playerOneInput		.rs 1		;use functions together with a bitwise AND to get input
playerTwoInput		.rs 1		; A   B   Select   Start   Up   Down   Left   Right
nmiDone				.rs 1
gameState			.rs 1		;use states defined as constants

;ticks in this case: frames between that the snake moves
snakeFramesToMove 	.rs 1
snakeTicks			.rs 1

;position, if tiles more than 16x16; two bytes
snakePos_X          .rs 1
snakePos_Y          .rs 1
snakeTempPos_X		.rs 1
snakeTempPos_Y		.rs 1
snakeLastInput      .rs 1
snakeLastInputTemp	.rs 1
snakeLastTickInput	.rs 1

;snake inputs/buffer, takes up a lot of RAM, can still use an 8-bit indexer
snakeInputs 		.rs (WALL_BOTTOM - WALL_TOP) * (WALL_RIGHT - WALL_LEFT) / 4
snakeInputsTemp				.rs 1
snakeInputsTempTemp			.rs 1
snakeInputsLastElements		.rs 1
snakeInputsAllBytes			.rs 1
snakeInputsDummy			.rs 1

;snake length, update this when snake eats a fruit
;use this to loop the correct amount of snake inputs every tick
snakeLength_lo			.rs 1
snakeLength_hi			.rs 1