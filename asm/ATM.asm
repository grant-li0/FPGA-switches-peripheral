; ATM Sample Program

; User inserts their card and loads their balance (sswPos)
; ATM only allows users to withdraw different amounts of money each time (sswChange)
; ATM withdraws selected amount from user account and updates balance (sswNeg)
; ATM has overdraft protection and alert.
; ATM has a screen that displays balance (right, Hex0) and withdrawal (left, Hex1)
; KEY0 to remove card from ATM

ORG 0
; User inserts card (load balance)
InitCard:
	OUT		Timer
	CALL	TimerWait
    IN		sswPos
	STORE	Balance
    OUT		Hex0
	
; ATM baseline configuration (account balance)
Start:
	IN		sswPos
	OUT		sswChange	; Store current switch state in sswChange to compare with withdrawal

; Withdrawal from ATM
AtmLoop:
	IN		sswChange
	JZERO	AtmLoop		; If withdrawal amount is not changed, try again
	OUT		Timer
	CALL	TimerWait

	IN		sswPos
	OUT		sswChange	; Save new withdrawal amount then display on left
	OUT		Hex1
	
	IN		sswNeg
	ADD 	Balance
	JNEG	Overdraft
	
	STORE	Balance		; No overdraft, update balance
	OUT		Hex0
	Jump	AtmLoop

; Withdrawal exceeds balance (overdraft)
Overdraft:
	LOADI	1
	STORE	InOverdraft	; Set flag to loclk LEDs in alert mode
	
	LOAD	AllLeds
	OUT		LEDs		; Withdrawal error -- light all LEDs (wait 3 seconds then try again)
	OUT		Timer
	CALL	TimerWait
	
	; Reset overdraft flag
	LOADI	0
	STORE	InOverdraft
	OUT		LEDs
	JUMP	AtmLoop

; Timer to wait 3 seconds
TimerWait:
	LOAD	InOverdraft
	JNZ		TimeLoop	; If overdraft, then LEDs will all be lit
	
	; Normal Mode: Update LEDs live to show ATM user actions
	IN		sswPos
	OUT		LEDs

TimeLoop:
	IN		Timer
	SUB		Ticks
	JNEG	TimerWait
	RETURN
    
; Useful Values
Balance:		DW	0
Ticks:			DW	30		; 30 ticks at 10 Hz = 3.0s
InOverdraft:	DW	0		; 0  = Normal LEDs, 1 = Overdraft alert
AllLeds:		DW	&B0000001111111111

; Peripheral Addresses
LEDs:		EQU &H001
Timer:		EQU &H002
Hex0:		EQU	&H004
Hex1:		EQU &H005

; SSW
sswPos:		EQU	&H060
sswNeg:		EQU	&H061
sswUp:		EQU	&H062
sswDown:	EQU &H063
sswMSB:		EQU &H064
sswLSB:		EQU &H065
sswChange:	EQU &H066