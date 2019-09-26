;GAME STARTUP

;snake "speed"
	LDA SNAKE_FRAMES_TO_MOVE_START
	STA snakeFramesToMove

;snake psosition
    LDA SNAKE_STARTING_POS_X
    STA snakePos_X

    LDA SNAKE_STARTING_POS_Y
    STA snakePos_Y

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