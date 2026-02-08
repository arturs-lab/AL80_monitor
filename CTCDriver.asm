CTC_INIT_ALL: push af
		call CTC_TC_INIT
		call CTC0_INIT
		call CTC1_INIT
		call CTC2_INIT
		call CTC3_INIT
		pop af
		ret

; init CH0
; CH0 divides on CLK/TRG0 clock providing a clock signal at TO0.
; it drives SIO channel A
; TRG0 is drivven from 1.8432MHz oscillator
CTC0_INIT: ld a,CTCV+0	; load CTC interrupt vector
	out (CTC_CH0),a		; set CTC T0 to that vector
	ld a,(CTC_CH0_CNF)	; interrupt off, counter mode, prescaler=256 (doesn't matter), ext. start,
					; start upon loading time constant, time constant follows,sw reset, command word
	out (CTC_CH0),a
	ld A,(CTC_CH0_TC)	; time constant 56d
	out (CTC_CH0),a		; loaded into channel 2
	ret


; init CH1
; CH1 divides CLK/TRG1 clock providing a clock signal at TO1.
; it drives SIO channel B
; TRG1 is drivven from 1.8432MHz oscillator
CTC1_INIT: ld a,CTCV+2	; load CTC interrupt vector
	out (CTC_CH1),a		; set CTC T1 to that vector
	ld a,(CTC_CH1_CNF)	; interrupt off, counter mode, prescaler=256 (doesn't matter), ext. start,
					; start upon loading time constant, time constant follows,sw reset, command word
	out (CTC_CH1),a
	ld A,(CTC_CH1_TC)	; time constant 56d
	out (CTC_CH1),a		; loaded into channel 3
	ret

; CH2 divides SIOCLK CLK by (16*CTC_CH2_TC) providing a clock signal at TO2.
; it also generates interrupt for millisecond timer at SYSTMR0-3
; TRG2 can be drivven from CPUCLK, 1.8432MHz oscillator or external source
CTC2_INIT: ld a,CTCV+4	; load CTC interrupt vector
	out (CTC_CH2),a		; set CTC T2 to that vector
	ld a,(CTC_CH2_CNF)	; interrupt off; timer mode; prescaler=256; don't care ext; automatic trigger;
					; time constant follows; cont. operation; command word
	out (CTC_CH2),a
	ld a,(CTC_CH2_TC)	; time constant
	out (CTC_CH2),a
	ret

; CH3 divides SIOCLK CLK by (16*CTC_CH3_TC) providing a clock signal at TO3.
; it also generates interrupt for 5 millisecond timer and clock at SYSTMR4-9
; TRG3 can be drivven from CPUCLK, 1.8432MHz oscillator or external source
CTC3_INIT: ld a,CTCV+6	; load CTC interrupt vector
	out (CTC_CH3),a		; set CTC T0 to that vector
	ld a,(CTC_CH3_CNF)	; interrupt off, timer mode, prescaler=16, don't care ext. TRG edge,
					; start timer on loading constant, time constant follows, software reset, command word
	out (CTC_CH3),a		; CH3 is halted
	ld A,(CTC_CH3_TC)	; time constant 56d
	out (CTC_CH3),a		; loaded into channel 1
	ret

; zero system timers
CTC_TC_INIT: ld hl,SYSTMR0
		ld b,10
		xor a
CTC_TC_INIT1:	ld (hl),a
		inc hl
		djnz CTC_TC_INIT1

		ld hl,CTC_DEFAULTS
		ld de,CTC_CH0_CNF
		ld bc,8
		ldir
		ret

; these are configured in CONSTANTS.asm
CTC_DEFAULTS:	db CTC_CH0_CNFV,CTC_CH1_CNFV,CTC_CH2_CNFV,CTC_CH3_CNFV
			db CTC_CH0_TV,CTC_CH1_TV,CTC_CH2_TV,CTC_CH3_TV

; T0 ISR - increment test byte at SYSTMR8+1

CTC_T0_ISR:	push af
	ld a,(SYSTMR8+1)	; 5 milliseconds
	inc a
	ld (SYSTMR8+1),a
	pop af
	ei
	reti

; T1 ISR - increment test byte at SYSTMR8+2

CTC_T1_ISR:	push af
	ld a,(SYSTMR8+2)	; 5 milliseconds
	inc a
	ld (SYSTMR8+2),a
	pop af
	ei
	reti

; T2 ISR - increment system timer by 1 on every interrupt
; 118 cycles when only lower counter incremented
; 151 cycles when overflow into upper counter = 22.65us @6.66MHz

CTC_T2_ISR:	push hl	; 11c
		push af		; 11c
		ld hl,(SYSTMR0)	; 16c
		inc hl		; 6c
		ld (SYSTMR0),hl	; 16c
		ld a,h		; 4c
		or l			; 4c
		jr nz,CTC_T2_X	; 12/7c
		ld hl,(SYSTMR2)	; 16c
		inc hl		; 6c
		ld (SYSTMR2),hl	; 16c
CTC_T2_X:	pop af		; 10c
		pop hl		; 10c
		ei			; 4c
		reti			; 14c

; T3 ISR - increment system timer by 1 on every interrupt
; same as T2 but interrupt timing my differ

CTC_T3_ISR:
up_isr:	push af
		ld a,(SYSTMR4)	; 5 milliseconds
		inc a
		cp 200
		jr nz,up_isr_1
		xor a
up_isr_1:	ld (SYSTMR4),a
		jr nz,up_isr_x

		ld a,(SYSTMR5)	; seconds
		inc a
		cp 60
		jr nz,up_isr_2
		xor a
up_isr_2:	ld (SYSTMR5),a
		jr nz,up_isr_x

		ld a,(SYSTMR6)	; minutes
		inc a
		cp 60
		jr nz,up_isr_3
		xor a
up_isr_3:	ld (SYSTMR6),a
		jr nz,up_isr_x

		ld a,(SYSTMR7)	; hours
		inc a
		cp 24
		jr nz,up_isr_4
		xor a
up_isr_4:	ld (SYSTMR7),a
		jr nz,up_isr_x

		push hl
		ld hl,(SYSTMR8)	; days
		inc hl
		ld (SYSTMR8),hl
		pop hl

up_isr_x:	pop af
		ei
		reti

