// ----------------------------------------------------------------
// Clear the screen
// ----------------------------------------------------------------

SET I, 0x0000

CLEAR:
	SET [0x8000 + I], 0x0F20
	ADD I, 0x0001
	IFN I, 0x0180
		SET PC, CLEAR

// ----------------------------------------------------------------
// Print the text
// ----------------------------------------------------------------

SET A, LINE0
SET B, 0x8040
SET C, 0x0F00
JSR PRINT_LINE

SET A, LINE1
SET B, 0x8080
SET C, 0x0F00
JSR PRINT_LINE

SET A, LINE2
SET B, 0x80A0
SET C, 0x9F00
JSR PRINT_LINE

HANG:
	SET PC, HANG

// ----------------------------------------------------------------
// Print a line of text
// ----------------------------------------------------------------

// A: The string to print
// B: The location to write to
// C: The font color

PRINT_LINE:
	SET X, [A]

	IFE X, 0x0000
		SET PC, POP

	BOR X, C

	SET [B], X

	ADD A, 0x0001
	ADD B, 0x0001

	SET PC, PRINT_LINE

// ----------------------------------------------------------------
// DATA
// ----------------------------------------------------------------

LINE0:
	DAT "     Thank you for looking!", 0x0000

LINE1:
	DAT "      More of my stuff at:", 0x0000

LINE2:
	DAT "    http://andrewkersten.com", 0x0000
