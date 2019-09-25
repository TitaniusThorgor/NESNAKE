;GAME STATE PLAYING
_gameStatePlaying:
	LDX snakeTicks
	INX
	CPX snakeFramesToMove
	BNE _afterTick


;Tick
;loop through snake, write to nametable in PPU memory; write PPU memory adress to $2006
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ;write the high byte of $2000 address (start of nametable 0 in PPU memory)
	LDA #$00
	STA $2006             ;write the low byte of $2000 address


;;;;;;


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