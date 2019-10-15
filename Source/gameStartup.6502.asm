;GAME STARTUP

;set namBuffer
	LDA #$00
	STA namBuffer

;PRNG, should be tied to a counter at the title
    LDA #$01
    STA seed

;start game state
    LDA #GAME_STATE_TITLE
    STA gameState

;snakeInputs
    LDA #$FF
    LDX #$00
_setSnakeInputs:
    STA snakeInputs, X
    INX
    CPX #SNAKE_BUFFER_LENGTH
    BNE _setSnakeInputs

;snake psosition
    LDA #$10
    STA snakePos_X
    LDA #$10
    STA snakePos_Y

;amount of frames to move
    LDA #$0C
    STA snakeFramesToMove

;snake last input
    LDA #$03    ;right, facing right in the beginning
    STA snakeLastInput
    STA snakeLastInputTemp

;snake length, snake is this +1 long
	LDA #$03
	STA snakeLength_lo
	LDA #$00
	STA snakeLength_hi

;snake inputs/buffer
    LDA #$FF            ;right in all elements (snake tiles, two bits per tile)
    STA snakeInputs     ;we start with the length of 4

;fruit position
    LDA #$05
    STA fruitPos_X
    STA fruitPos_Y