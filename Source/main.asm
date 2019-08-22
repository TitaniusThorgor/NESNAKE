;iNES header, this tell emulaotrs and such the layout of the file 
	.inesprg 1	;1x 16KB bank of PRG code
	.ineschr 1	;1x 8KB bank of CHR data
	.inesmap 0	;no bank swapping at the time
	.inesmir 1	;enabels background mirroring
	
;banking
	.bank 0		;code bank 0
	.org $C000
	
	.bank 1		;code bank 1
	.org $E000
	
	.bank 2		;graphics bank
	.org $0000
	
	.bank 2
	.org $0000
	.incbin "mario.chr"		;includes 8KB graphics file
	
;vectors/interrupts
	.bank 1
	.org $FFFA	;this is where the adresses to the actual "functions" are being stored, I think. F - A + 1 = 6
	.dw NMI 	;"Update" vector, processor starts to read code here each graphics cycle if enabled
	.dw RESET	;the processor will start exicuting here when the program starst as well as when the reset button is pressed 
	.dw 0		;IRQ won't be used for now
	
;implementation of RESET
	.bank 0
	.org $C000
RESET:
	SEI		;disable IRQ interrupts
	CLD		;disable decimal mode, something the NES 6502 chip does not have
	
	;graphics setup
	LDA %00100000	;intensify
	STA $2001
	
	;PPU: pallet recognition to adress $3F10
	LDA $2002	;read PPU status to reset the hight/low latch to high
	LDA #$3F	;load the high byte
	STA $2006	;write the high byte
	LDA #$10	;load the low byte
	STA $2006	;write the low byte
	;that code tells the PPU to set its address to $3F10, now the PPU data port at $2007 is ready to accept data
	
PaletteData:
	.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette data
	.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ;sprite palette data
	
	;loop with x and feed PPU, use this method if the whole palette is changed, otherwise use $3F10 and 32 bytes up
	LDX #$00
LoadPalletsLoop:
	LDA PaletteData, x	;this syntax is very important, "load a with palette data with the offset of x: the index"
	STA #$2007			;write the color one by one to the same adress
	INX					;increment x
	CPX #$20			;compare x with $20 = 32, which is the size of both pallets combined
	BNE LoadPalletsLoop	;Branch if Not Equal
	
	
Forever:
	JMP Forever		;infinite loop
	
;NMI: graphics "update"
NMI:
	JMP Forever