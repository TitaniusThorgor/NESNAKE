;GAME STARTUP

    LDA GAME_STATE_PLAYING
    STA gameState
;snake psosition
    LDA SNAKE_STARTING_POS_X
    STA snakePos_X

    LDA SNAKE_STARTING_POS_Y
    STA snakePos_Y

;amount of frames to move
    LDA #$20
    STA snakeFramesToMove

;snake last input
    LDA #$03    ;right, facing right in the beginning
    STA snakeLastInput

;snake length
	LDA #$04
	STA snakeLength_lo
	LDA #$00
	STA snakeLength_hi

;snake inputs/buffer
    LDA #$FF            ;right in all elements (snake tiles, two bits per tile)
    STA snakeInputs     ;we start with the length of four