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

// Use a custom color palette
SET A, 0x0002
SET B, PALETTE
HWI [LEM1802]

// Set the clock to trigger 60 / B times per second
SET A, 0x0000
SET B, 0x0005
HWI [CLOCK]

// Set the clock to trigger interrupt on ticks
SET A, 0x0002
SET B, 0xFFFF // Message not used
HWI [CLOCK]

// ----------------------------------------------------------------
// Do nothing while waiting for interrupts
// ----------------------------------------------------------------

HANG:
	SET PC, HANG

// ----------------------------------------------------------------
// Interrupt handler: Draw the frame
// ----------------------------------------------------------------

INTERRUPT_HANDLER:

SET I, 0x0000
SET X, 0x8028

SET Y, 0x00A0
MUL Y, [CURRENT_FRAME]
ADD Y, FRAME0

SET A, 0x0000
SET B, 0x0000

LOOP:
	SET [X], [Y]

	ADD X, 0x0001
	ADD Y, 0x0001
	ADD I, 0x0001
	ADD A, 0x0001

	IFN A, 0x0010
		SET PC, SKIP

	SET A, 0x0000
	ADD B, 0x0001

	SET C, B
	MUL C, 0x0020
	ADD C, 0x8028

	SET X, C

	SKIP:
	IFL I, 0x00A0
		SET PC, LOOP

	ADD [CURRENT_FRAME], 0x0001
	IFE [CURRENT_FRAME], 0x0004
		SET [CURRENT_FRAME], 0x0000

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

CURRENT_FRAME:
	DAT 0x0000

PALETTE:
	DAT 0x0999, 0x0041, 0x00B5, 0x00F7, 0x0000, 0x0851, 0x0F82, 0x0FC9, 0x0D93, 0x0FD6, 0x0FFF, 0x0307, 0x062F, 0x096F, 0x0000, 0x0000

FRAME0:
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x011F, 0x011F, 0x131F, 0x131F, 0x131F, 0x191F, 0x131F, 0x011F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x011F, 0x121F, 0x331F, 0x321F, 0x221F, 0x241F, 0x841F, 0x941F, 0xA41F, 0x141F, 0x041F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x111F, 0x271F, 0x241F, 0x241F, 0x441F, 0x461F, 0x441F, 0x461F, 0x441F, 0x461F, 0x401F, 0x401F, 0x401F, 0x001F
	DAT 0x001F, 0x111F, 0x761F, 0x551F, 0x771F, 0x441F, 0x641F, 0x771F, 0x471F, 0x771F, 0x471F, 0x771F, 0x571F, 0x571F, 0x051F, 0x001F
	DAT 0x001F, 0x101F, 0x441F, 0x641F, 0x761F, 0x461F, 0x771F, 0x741F, 0x441F, 0x641F, 0x641F, 0x641F, 0x641F, 0x641F, 0x501F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x401F, 0x511F, 0x521F, 0x651F, 0x651F, 0x651F, 0x451F, 0x4B1F, 0x401F, 0x401F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x111F, 0x251F, 0x251F, 0x351F, 0xCC1F, 0xCA1F, 0xDA1F, 0xDD1F, 0xBA1F, 0x0B1F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x551F, 0xAA1F, 0xAA1F, 0xA51F, 0x5C1F, 0xAC1F, 0xAC1F, 0xDD1F, 0xAD1F, 0xBB1F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x501F, 0xA51F, 0xA51F, 0x551F, 0xC51F, 0xC41F, 0xB51F, 0xC41F, 0xB01F, 0x001F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0x441F, 0x541F, 0x541F, 0x541F, 0x941F, 0x441F, 0x941F, 0x441F, 0x001F, 0x001F, 0x001F, 0x001F

FRAME1:
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x011F, 0x011F, 0x131F, 0x131F, 0x131F, 0x191F, 0x131F, 0x011F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x011F, 0x121F, 0x331F, 0x321F, 0x221F, 0x241F, 0x841F, 0x941F, 0xA41F, 0x141F, 0x041F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x111F, 0x271F, 0x241F, 0x241F, 0x441F, 0x461F, 0x441F, 0x461F, 0x441F, 0x461F, 0x401F, 0x401F, 0x401F, 0x001F
	DAT 0x001F, 0x111F, 0x761F, 0x551F, 0x771F, 0x441F, 0x641F, 0x771F, 0x471F, 0x771F, 0x471F, 0x771F, 0x571F, 0x571F, 0x051F, 0x001F
	DAT 0x001F, 0x101F, 0x441F, 0x641F, 0x761F, 0x461F, 0x771F, 0x741F, 0x441F, 0x641F, 0x641F, 0x641F, 0x641F, 0x641F, 0x501F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x451F, 0x521F, 0x651F, 0x651F, 0x651F, 0x651F, 0x451F, 0x4B1F, 0x401F, 0x401F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x041F, 0x551F, 0x2A1F, 0x2A1F, 0x3A1F, 0x551F, 0xCA1F, 0xDA1F, 0xDD1F, 0xBA1F, 0x0B1F, 0x041F, 0x041F, 0x001F
	DAT 0x001F, 0x441F, 0x551F, 0x551F, 0xAA1F, 0xAA1F, 0x551F, 0xCC1F, 0xAC1F, 0xAC1F, 0xDD1F, 0xAB1F, 0x441F, 0x951F, 0x441F, 0x441F
	DAT 0x001F, 0x441F, 0x551F, 0xB91F, 0x541F, 0x501F, 0xCB1F, 0xCB1F, 0xCB1F, 0xCB1F, 0xB01F, 0x441F, 0x551F, 0x441F, 0x441F, 0x001F
	DAT 0x001F, 0x001F, 0x401F, 0x401F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x401F, 0x401F, 0x001F, 0x001F

FRAME2:
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x011F, 0x011F, 0x131F, 0x131F, 0x131F, 0x191F, 0x131F, 0x011F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x011F, 0x121F, 0x331F, 0x321F, 0x221F, 0x241F, 0x841F, 0x941F, 0xA41F, 0x141F, 0x041F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x111F, 0x271F, 0x241F, 0x241F, 0x441F, 0x461F, 0x441F, 0x461F, 0x441F, 0x461F, 0x401F, 0x401F, 0x401F, 0x001F
	DAT 0x001F, 0x111F, 0x761F, 0x551F, 0x771F, 0x441F, 0x641F, 0x771F, 0x471F, 0x771F, 0x471F, 0x771F, 0x571F, 0x571F, 0x051F, 0x001F
	DAT 0x001F, 0x101F, 0x441F, 0x641F, 0x761F, 0x461F, 0x771F, 0x741F, 0x441F, 0x641F, 0x641F, 0x641F, 0x641F, 0x641F, 0x501F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x401F, 0x5B1F, 0x5C1F, 0x651F, 0x651F, 0x651F, 0x451F, 0x451F, 0x511F, 0x5A1F, 0x551F, 0x051F, 0x051F
	DAT 0x001F, 0x001F, 0x001F, 0xBB1F, 0xCC1F, 0xCC1F, 0x111F, 0x321F, 0x321F, 0x321F, 0x321F, 0x111F, 0xAA1F, 0xAA1F, 0xAA1F, 0x551F
	DAT 0x001F, 0x001F, 0x001F, 0xBB1F, 0xCC1F, 0xCC1F, 0xCC1F, 0x1C1F, 0x1C1F, 0x1C1F, 0x1D1F, 0x1D1F, 0x5B1F, 0x501F, 0x501F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0xB41F, 0xC51F, 0xC51F, 0xC51F, 0xC41F, 0xB51F, 0xC41F, 0xB01F, 0x001F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0x441F, 0x541F, 0x541F, 0x541F, 0x941F, 0x441F, 0x941F, 0x441F, 0x001F, 0x001F, 0x001F, 0x001F

FRAME3:
	DAT 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x011F, 0x011F, 0x131F, 0x131F, 0x131F, 0x191F, 0x131F, 0x011F, 0x001F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x011F, 0x121F, 0x331F, 0x321F, 0x221F, 0x241F, 0x841F, 0x941F, 0xA41F, 0x141F, 0x041F, 0x001F, 0x001F
	DAT 0x001F, 0x001F, 0x111F, 0x271F, 0x241F, 0x241F, 0x441F, 0x461F, 0x441F, 0x461F, 0x441F, 0x461F, 0x401F, 0x401F, 0x401F, 0x001F
	DAT 0x001F, 0x111F, 0x761F, 0x551F, 0x771F, 0x441F, 0x641F, 0x771F, 0x471F, 0x771F, 0x471F, 0x771F, 0x571F, 0x571F, 0x051F, 0x001F
	DAT 0x001F, 0x101F, 0x441F, 0x641F, 0x761F, 0x461F, 0x771F, 0x741F, 0x441F, 0x641F, 0x641F, 0x641F, 0x641F, 0x641F, 0x501F, 0x001F
	DAT 0x001F, 0x001F, 0x001F, 0x401F, 0x5B1F, 0x651F, 0x651F, 0x651F, 0x651F, 0x451F, 0x451F, 0x511F, 0x5A1F, 0x551F, 0x051F, 0x051F
	DAT 0x001F, 0x001F, 0x041F, 0xBB1F, 0xBC1F, 0xCC1F, 0x111F, 0x321F, 0x321F, 0x321F, 0x321F, 0x111F, 0xAA1F, 0xAA1F, 0xAA1F, 0x551F
	DAT 0x001F, 0x441F, 0x551F, 0xBB1F, 0xCC1F, 0xCC1F, 0xCC1F, 0x1C1F, 0x1C1F, 0x1C1F, 0x1D1F, 0x141F, 0x551F, 0x541F, 0x541F, 0x001F
	DAT 0x001F, 0x441F, 0x551F, 0x591F, 0xB41F, 0xB01F, 0xCB1F, 0xCB1F, 0xCB1F, 0xCB1F, 0xB01F, 0x441F, 0x551F, 0x441F, 0x441F, 0x001F
	DAT 0x001F, 0x001F, 0x401F, 0x401F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x001F, 0x401F, 0x401F, 0x001F, 0x001F