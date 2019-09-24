;GAME STATE PLAYING
_gameStatePlaying:
	LDX snakeTicks
	INX
	CPX snakeTicksToMove
	BNE _afterTick


;Tick
;loop and update nametable depending on the snake
;at each tile within the range
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ;write the high byte of $2000 address (start of nametable 0 in PPU memory)
	LDA #$00
	STA $2006             ;write the low byte of $2000 address

	LDA #$00
	STA backgroundPtr_lo
	LDA #HIGH (background)	;some NESASM3 exclusive features
	STA backgroundPtr_hi
	
	LDX #$00
	LDY #$00
_loadBackgroundLoop:
    ;checking if inside bounds
    

	LDA [backgroundPtr_lo], y
	STA $2007

	INY
	BNE _loadBackgroundLoop	;let it loop, let it loop, when zero

	INC backgroundPtr_hi	;increment memory (makes the pointer as a whole go up 256 bytes)
	INX

	CPX #$04	;make the 256 loop four times
	BNE _loadBackgroundLoop
	;;;;;;


_afterTick:
	;do things such as updating sprites

	RTS


;GAME STATE TITLE
_gameStateTitle:
	LDA GAME_STATE_PLAYING
	STA gameState

	RTS


;GAME STATE GAME OVER
_gameStateGameOver:
	RTS

