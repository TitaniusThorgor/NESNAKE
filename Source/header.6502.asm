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

GAME_STATE_TITLE = $01		;gamestates
GAME_STATE_PLAYING = $02
GAME_STATE_GAMEOVER = $03

WALL_TOP = $04				;in tiles
WALL_BOTTOM = $2A			;26
WALL_LEFT = $04
WALL_RIGHT = $2A



;don't need a 16 bit value, (32*32)/4=256, very convenient, just under that (maximum: 32*30)
SNAKE_BUFFER_LENGTH = (WALL_BOTTOM - WALL_TOP) * (WALL_RIGHT - WALL_LEFT) / 4

;0-31
;0-29
WALL_TOP = $04				;in tiles
WALL_BOTTOM = $2A			;26
WALL_LEFT = $04
WALL_RIGHT = $2A

SNAKE_FRAMES_TO_MOVE_START = 60		;when 60, it moves 1 tile per frame

SNAKE_STARTING_POS_X = $10
SNAKE_STARTING_POS_Y = $10


;POINTERS
	.rsset $0000			;zero page

backgroundPtr_lo	.rs 1
backgroundPtr_hi	.rs 1

backgroundPtr1_lo	.rs 1
backgroundPtr1_hi	.rs 1

snakeInputCounter_lo	.rs 1
snakeInputCounter_hi	.rs 1


;VARIABLES
	.rsset $0300			;prevous to this: sprite DMA

playerOneInput		.rs 1		;use functions together with a bitwise AND to get input
playerTwoInput		.rs 1		; A   B   Select   Start   Up   Down   Left   Right
nmiDone				.rs 1
gameState			.rs 1		;use states defined as constants

;ticks in this case: frames between that the snake moves
snakeFramesToMove 	.rs 1
snakeTicks			.rs 1

;snake inputs/buffer, takes up a lot of RAM
snakeInputs 		.rs (WALL_BOTTOM - WALL_TOP) * (WALL_RIGHT - WALL_LEFT) / 4 ;(WALL_BOTTOM - WALL_TOP)*(WALL_RIGHT - WALL_LEFT)
snakeInputsTemp		.rs 1
snakeLastInput      .rs 1

;position, if tiles more than 16x16; two bytes
snakePos_X          .rs 1
snakePos_Y          .rs 1

;increases after eating fruits
snakeLength_lo		.rs 1
snakeLength_hi		.rs 1