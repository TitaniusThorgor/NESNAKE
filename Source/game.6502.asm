;GAME
;implementation of gamestates

;GAME STATE PLAYING
_gameStatePlaying:
	;snakeLastInput
	;convert input to two bytes
	LDA playerOneInput
	;let's make this easy for us

	CMP #%00001000
	BNE _snakePersistantInputUpDone
	LDX #$00
	STX snakeLastInput
_snakePersistantInputUpDone:

	CMP #%00000100
	BNE _snakePersistantInputDownDone
	LDX #$01
	STX snakeLastInput
_snakePersistantInputDownDone:

	CMP #$00000010
	BNE _snakePersistantInputLeftDone
	LDX #$02
	STX snakeLastInput
_snakePersistantInputLeftDone:

	CMP #$00000001
	BNE _snakePersistantInputRightDone
	LDX #$03
_snakePersistantInputRightDone:
;;;;;;;;;;

	LDX snakeTicks
	INX
	CPX snakeFramesToMove
	BNE _afterTick


;Tick
;loop through snake

;some general stuff:
	;begin with head: read input, update position x and y, store value into X?

;NESASM3 user defined function
;in this case, it performs one tile of the snake
;SCR_ADDR .func (\1) + ((\2) << 5)


;head
	LDA snakeLastInput
	;ROR
	BNE _snakeHeadAfterUp	;when snakeLastInput is up
	;update X
	LDX snakePos_Y
	DEX
	STX snakePos_Y
_snakeHeadAfterUp:

	CMP #$01
	BNE _snakeHeadAfterDown
	LDX snakePos_Y
	INX
	STX snakePos_Y
_snakeHeadAfterDown:

	LDX snakePos_X

	CMP #$02
	BNE _snakeHeadAfterLeft
	DEX
	STX snakePos_X
_snakeHeadAfterLeft:

	CMP #$03
	BNE _snakeHeadAfterRight
	INX
	STX snakePos_X
_snakeHeadAfterRight:


	;snakeLastInput in A
	LDA snakeInputs
	STA snakeInputsTemp
	ASL A
	ASL A
	EOR snakeLastInput
	STA snakeInputs

;update visuals
;write to nametable in PPU memory; write PPU memory adress to $2006
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ;write the high byte of $2000 address (start of nametable 0 in PPU memory)
	LDA #$00
	STA $2006             ;write the low byte of $2000 address
;set relevant memory to:  + snakePos_Y * (WALL_RIGHT - WALL_LEFT) + snakePos_X

;HERE; HERE; HERE, JUST LOAD THE FUCKING SNAKE POSITION: snakePos_X and snakePos_Y
	


;SNAKE_BUFFER_LENGTH
	LDA #LOW (snakeInputs)
	STA backgroundPtr_lo
	LDA #HIGH (snakeInputs)
	STA backgroundPtr_hi
	LDY #$00
_snakeLoop:
	;do the thing 4 times than iterate
	LDA [backgroundPtr_lo], y	;takes many machine cycles, transfer to x instead of reading 4 times
	TAX  ;76543210
	AND #%00000011


	INY
	CPY SNAKE_BUFFER_LENGTH
	BNE _snakeLoop

;;;;


_afterTick:
;do things such as updating sprites, 0 and 1, 4-byte offset

	RTS


;GAME STATE TITLE
_gameStateTitle:
	LDA GAME_STATE_PLAYING
	STA gameState

	RTS


;GAME STATE GAME OVER
_gameStateGameOver:
	RTS