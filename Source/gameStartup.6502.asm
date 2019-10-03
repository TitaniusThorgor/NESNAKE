;GAME STARTUP

;start game state
    LDA #GAME_STATE_PLAYING
    STA gameState

;snake psosition
    LDA #$10
    STA snakePos_X

    LDA #$10
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