// ----------------------------------------------------------------
// Initialize the display
// ----------------------------------------------------------------

SET I, 0x0000
SET J, 0x0000

DRAW_STRIPES:
	SET A, I
	MOD A, 0x0010
	SHL A, 0x000C // Color bits offset
	BOR A, 0x001B // Solid foreground character

	DRAW_STRIPES_INNER:
	SET B, J
	MUL B, 0x0020
	ADD B, I
	SET [0x8000 + B], A
	ADD J, 0x0001

	IFN J, 0x000C
		SET PC, DRAW_STRIPES_INNER

	SET J, 0x0000
	ADD I, 0x0001
	IFN I, 0x0020
		SET PC, DRAW_STRIPES

// ----------------------------------------------------------------
// Find the LEM1802 and Generic Clock handles
// ----------------------------------------------------------------

// LEM1802
SET PUSH, 0xF615
SET PUSH, 0x7349
SET PUSH, 0x1802
SET PUSH, 0x8B36
SET PUSH, 0x1C6C
JSR FIND_DEVICE
SET [LEM1802], A

// LEM1802 not attached
IFE A, 0xFFFF
	SET PC, HANG

// Generic Clock
SET PUSH, 0xB402
SET PUSH, 0x12D0
SET PUSH, 0x0001
SET PUSH, 0x0000
SET PUSH, 0x0000
JSR FIND_DEVICE
SET [CLOCK], A

// Generic Clock not attached
IFE A, 0xFFFF
	SET PC, HANG

// ----------------------------------------------------------------
// Configure LEM1802 and Generic Clock
// ----------------------------------------------------------------

IAS INTERRUPT_HANDLER

// Set the clock to trigger 60 / B times per second
SET A, 0x0000
SET B, 0x0006 // 10 times per second
HWI [CLOCK]

// Set the clock to trigger an interrupt on ticks
SET A, 0x0002
SET B, 0xFFFF // Message not used
HWI [CLOCK]

// ----------------------------------------------------------------
// Do nothing while waiting for interrupts
// ----------------------------------------------------------------

HANG:
	SET PC, HANG

// ----------------------------------------------------------------
// Interrupt Handler: Shift the color palette
// ----------------------------------------------------------------

INTERRUPT_HANDLER:

// Set the LEM1802 color palette
SET A, 0x0002
SET B, PALETTE
ADD B, [PALETTE_OFFSET]
HWI [LEM1802]

ADD [PALETTE_OFFSET], 0x0001
IFE [PALETTE_OFFSET], 0x000F
	SET [PALETTE_OFFSET], 0x0000

RFI A

// ----------------------------------------------------------------
// Function: Find the handle to a specific device
// ----------------------------------------------------------------

// Expects hardware details to be pushed on the stack:
//
// Hardware ID (LOW)
// Hardware ID (HIGH)
// Version
// Manufacturer (LOW)
// Manufacturer (HIGH)
//
// The function will pop these values off the stack before exiting
//
// Returns the device handle or 0xFFFF if it isn't found

FIND_DEVICE:
	HWN Z

	FIND_DEVICE_LOOP:
		IFE Z, 0x0000
			SET PC, FIND_DEVICE_RETURN

		SUB Z, 0x0001
		HWQ Z

		IFN PICK 0x0005, A
			SET PC, FIND_DEVICE_LOOP

		IFN PICK 0x0004, B
			SET PC, FIND_DEVICE_LOOP

		IFN PICK 0x0003, C
			SET PC, FIND_DEVICE_LOOP

		IFN PICK 0x0002, X
			SET PC, FIND_DEVICE_LOOP

		IFN PICK 0x0001, Y
			SET PC, FIND_DEVICE_LOOP

	FIND_DEVICE_RETURN:
		SET B, POP

		SET A, POP
		SET A, POP
		SET A, POP
		SET A, POP
		SET A, POP

		SET A, Z

		SET PC, B

// ----------------------------------------------------------------
// DATA
// ----------------------------------------------------------------

LEM1802:
	DAT 0xFFFF

CLOCK:
	DAT 0xFFFF

PALETTE_OFFSET:
	DAT 0x0000

PALETTE:
	DAT 0x0000, 0x000a, 0x00a0, 0x00aa, 0x0a00, 0x0a0a, 0x0a50, 0x0aaa, 0x0555, 0x055f, 0x05f5, 0x05ff, 0x0f55, 0x0f5f, 0x0ff5, 0x0fff
	DAT 0x0000, 0x000a, 0x00a0, 0x00aa, 0x0a00, 0x0a0a, 0x0a50, 0x0aaa, 0x0555, 0x055f, 0x05f5, 0x05ff, 0x0f55, 0x0f5f, 0x0ff5, 0x0fff
