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

	CMP #%00000010
	BNE _snakePersistantInputLeftDone
	LDX #$02
	STX snakeLastInput
_snakePersistantInputLeftDone:

	CMP #%00000001
	BNE _snakePersistantInputRightDone
	LDX #$03
	STX snakeLastInput
_snakePersistantInputRightDone:
;;;;;;;;;;

	LDX snakeTicks
	INX
	STX snakeTicks
	CPX snakeFramesToMove
	BNE _tickDone
	JSR _tick
_tickDone:
;do things that need to be done every frame, such as updating sprites

;return from gamestate playing
	RTS


;keep this structure, as I could to add a state where the snake is not moving
;reads snakePos and updates namBuffer
;usage: load A with x of the position and X with y of the position, load Y with tile index
UpdateNamPos:
	;A has loaded snakePos_X
	;X has loaded snakePos_Y
	STA backgroundDir_lo
	LDA #$00
	STA backgroundDir_hi
	INX
_snakeUpdateHeadHighLoop:
	DEX
	BEQ _snakeUpdateHeadHighLoopDone
	LDA backgroundDir_lo
	CLC
	ADC #$20
	STA backgroundDir_lo
	LDA backgroundDir_hi
	ADC #$00
	STA backgroundDir_hi
	JMP _snakeUpdateHeadHighLoop
_snakeUpdateHeadHighLoopDone:
	;add to namBuffer, A (which contains the tileIndex in the function) will be loaded with the starting point in CHR, than added with the direction directly
	TYA
	;backgroundDir lo and hi are loaded with the correct adresses, minus $2000, A contains tile index
	JSR NamAdd

	RTS
;;;;;;;;;


;load X with x and Y with y, they will be updated depending on the dir in A (0 up, 1 down, 2 left, 3 right)
UpdatePos:
	;A is loaded with direction
	CMP #$00
	BNE _updatePosUpDone
	DEY
_updatePosUpDone:
	CMP #$01
	BNE _updatePosDownDone
	INY
_updatePosDownDone:
	CMP #$02
	BNE _updatePosLeftDone
	DEX
_updatePosLeftDone:
	CMP #$03
	BNE _updatePosDone
	INX
_updatePosDone:
	RTS
	

;Tick
_tick:
	LDA #$00
	STA snakeTicks

	;display a body tile in the previous tick's head's position
	LDA snakeInputs
	AND #%00000011
	CLC
	ADC #SNAKE_CHR_BODY_ROW
	TAY
	LDA snakePos_X
	LDX snakePos_Y
	JSR UpdateNamPos

;update the position
;when updated, the loop that goes through the rest of the snake can check for snake interception
;update pos as well as bouns checking with walls
	;update pos, check for wall collision
	LDA snakeLastInput
	LDX snakePos_X
	LDY snakePos_Y
	JSR UpdatePos

	STX snakePos_X
	STY snakePos_Y

	CPY #WALL_TOP
	BEQ _bumped
	CPY #WALL_BOTTOM
	BEQ _bumped
	CPX #WALL_LEFT
	BEQ _bumped
	CPX #WALL_RIGHT
	BNE _snakePosDone

_bumped:
	LDA #$01
	STA snakeBumped
	;LDA GAME_STATE_GAMEOVER
	;STA gameState
_snakePosDone:
	;update namBuffer through UpdateNamPos
	LDA #SNAKE_CHR_HEAD_ROW
	CLC
	ADC snakeLastInput
	TAY
	LDA snakePos_X
	LDX snakePos_Y
	JSR UpdateNamPos
	;now to the 2 remaining elements to be updated
	
	;loop to update snakeInputs buffer and to check for collisions with the current position
	;temp position variable for comparasions
	LDA snakePos_X
	STA snakeTempPos_X
	LDA snakePos_Y
	STA snakeTempPos_Y

	;translate the 16-bit length to an 8-bit indexer, this indexer covers up to 3 unnessesary elements, don't read these

;when outer is at the last index, use another inner loop
;first create the outer loop's index, then use the % of the 16-bit value to get the last inner loop counter (this can be done later)

_snakeInputsLoop:
	LDA snakeInputs, X
	LDY #$03
_snakeInputsInnerLoop:
	AND #%00000011
	DEY
	BNE _snakeInputsInnerLoop
	INX
	;CPX with some number


;return from tick
	RTS
;;;;


;GAME STATE TITLE
_gameStateTitle:
	LDA #GAME_STATE_PLAYING
	STA gameState

	RTS


;GAME STATE GAME OVER
_gameStateGameOver:
	LDA #GAME_STATE_PLAYING
	STA gameState

	RTS