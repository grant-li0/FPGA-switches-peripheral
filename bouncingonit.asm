; IODemo.asm
; Produces a "bouncing" animation on the LEDs.
; The LED pattern is initialized on switch 2
ORG 0
    ; Get and store the switch values
	loadi &B0000000100
	out LEDs
    waitFor2: IN Switches
    Sub Bit2
    JNZ waitFor2
    IN     Switches
    OUT    LEDs
    STORE  Pattern

Left:
In sswUp
out Hex0
	; Slow down the loop so humans can watch it.
	CALL   Delay

	; Check if the left place is 1 and if so, switch direction
    IN     sswMSB
    STORE  MaskCount
    CALL   PosToMask
    STORE  UpperMask

    LOAD   Pattern
    AND    UpperMask
    JNZ    Right

    LOAD   Pattern
    SHIFT  1
    STORE  Pattern
    OUT    LEDs
    JUMP   Left

Right:
    CALL   Delay

	; Slow down the loop so humans can watch it.
;	CALL   Delay

	; Check if the right place is 1 and if so, switch direction
    IN     sswLSB
    STORE  MaskCount
    CALL   PosToMask
    STORE  LowerMask

    LOAD   Pattern
    AND    LowerMask
    JNZ    Left

    LOAD   Pattern
    SHIFT  -1
    STORE  Pattern
    OUT    LEDs
    JUMP   Right

Delay:
    OUT    Timer
WaitingLoop:
In sswUp
out Hex0
    IN     Timer
    ADDI   -5
    JNEG   WaitingLoop
    RETURN


; PosToMask: converts a position (0-9), pre-loaded into
; MaskCount, into a one-hot bitmask. Returns the mask in AC.

PosToMask:
    LOAD   One
    STORE  MaskVal          ; MaskVal starts at 0000000001

PosToMaskLoop:
    LOAD   MaskCount
    JNZ    PosToMaskStep
    JUMP   PosToMaskDone

PosToMaskStep:
    ADDI   -1
    STORE  MaskCount        ; decrement remaining shifts
    LOAD   MaskVal
    SHIFT  1
    STORE  MaskVal
    JUMP   PosToMaskLoop

PosToMaskDone:
    LOAD   MaskVal
    RETURN

; Variables
Pattern:    DW 0
UpperMask:  DW &B1000000000   ; overwritten each pass by PosToMask
LowerMask:  DW &B0000000001   ; overwritten each pass by PosToMask
MaskCount:  DW 0
MaskVal:    DW 0
One:        DW 1

; Useful values
Bit0:      DW &B0000000001
Bit9:      DW &B1000000000
Bit2:      DW &B0000000100

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
sswPos:    EQU &H060
sswNeg:    EQU &H061
sswUp:     EQU &H062
sswDown:   EQU &H063
sswMSB:    EQU &H064
sswLSB:    EQU &H065
sswChange: EQU &H066