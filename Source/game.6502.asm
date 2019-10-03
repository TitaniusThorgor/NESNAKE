;GAME
;implementation of gamestates

;GAME STATE PLAYING
_gameStatePlaying:

;TESTING
	;LDY snakeInputsTemp
	LDY snakeInputsTemp
	INY
	STY snakeInputsTemp
	LDA #$00
	LDX #$02
	JSR UpdateNamPos



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
	LDA snakeLastInput
	CMP #$00
	BNE _snakePosUpDone

	;up 
	LDY snakePos_Y
	DEY
	STY snakePos_Y
	CPY #WALL_TOP
	BEQ _bumped
	JMP _snakePosDone
_snakePosUpDone:
	CMP #$01
	BNE _snakePosDownDone

	;down
	LDY snakePos_Y
	INY
	STY snakePos_Y
	CPY #WALL_BOTTOM
	BEQ _bumped
	JMP _snakePosDone
_snakePosDownDone:
	CMP #$02
	BNE _snakePosLeftDone

	;left
	LDY snakePos_X
	DEY
	STY snakePos_X
	CPY #WALL_LEFT
	BEQ _bumped
	JMP _snakePosDone
_snakePosLeftDone:
	
	;can only be right
	LDY snakePos_X
	INY
	STY snakePos_X
	CPY #WALL_RIGHT
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
	;now to the 3 remaining elements to be updated
	
	

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