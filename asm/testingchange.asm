
loop:
OUT sswChange
call Delay

jump loop

Delay:
	OUT    Timer
WaitingLoop:
	in sswChange
	Out LEDs
	IN     Timer
	ADDI   -10
	JNEG   WaitingLoop
	RETURN

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