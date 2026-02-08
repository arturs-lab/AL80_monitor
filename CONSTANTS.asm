VERSMYR:    EQU     "1"
VERSMIN:    EQU     "3"

; clock divider
CLKDIV	EQU $a2		; upper nibble:PSGCLK, lower nibble:(SYSCLK MHz/2/(value+1)), 6.666MHz
SYSCLK	EQU "6.666"
MACHINE	EQU "AL80"
SIOCLK	EQU 1843200
CPUCLK	EQU 6666666
CPU		EQU "Z80"

; Constants, extracted to make the versioned file hardware agnostic

; we could use this to trigger including UART code
; but I want flexibility to include it but not use for console.
USE_UART:	EQU true

; do we want to enable interrupts?
EN_INT:	EQU true

; do we want to init memmap
if MACHINE="AL80"
INIT_MEMMAP:	EQU true
else
INIT_MEMMAP:	EQU false
endif

; ### MEM map
RAM_BOTTOM:	EQU 02000H       ; Bottom address of RAM
RAM_TOP:	EQU $ffff


	if def ROM_BOTTOM_c000

ROM_BOTTOM:	EQU $c000       ; Bottom address of ROM
ROM_TOP:	EQU ROM_BOTTOM + 01FFFh		; Top address of ROM

JUMPTAB:	EQU RAM_TOP - $2FF	; jump table for monitor routines
IRQTAB:	EQU RAM_TOP - $3FF	; interrupt vector table
SP_INIT:	EQU 0				; initial value of SP
CFSECT_BUF_V:	EQU $A000		; value for CFSECT_BUF variable. Defaults to $c000 in preparation for CPM loader
MONVARS:	EQU RAM_TOP - $1ff	; SP goes at the top of memory. Put monitor vars and buffers 511 bytes below it
epp_tmp:	EQU RAM_TOP - $ff	; this is where EEPROM programming code is copied before execution to avoid it
						; clashing with new data being programmed into its location in EEPROM
USERRREG:	equ RAM_TOP - $37F

	elseif def ROM_BOTTOM_a000

ROM_BOTTOM:	EQU $a000       ; Bottom address of ROM
ROM_TOP:	EQU ROM_BOTTOM + 01FFFh		; Top address of ROM

JUMPTAB:	EQU $c000 - $300	; jump table for monitor routines
IRQTAB:	EQU $c000 - $400	; interrupt vector table
SP_INIT:	EQU $c000			; initial value of SP
CFSECT_BUF_V:	EQU $C000		; value for CFSECT_BUF variable. Defaults to $c000 in preparation for CPM loader
MONVARS:	EQU $c000 - $200	; SP goes at the top of memory. Put monitor vars and buffers 511 bytes below it
epp_tmp:	EQU $c000 - $100	; this is where EEPROM programming code is copied before execution to avoid it
						; clashing with new data being programmed into its location in EEPROM
USERRREG:	equ $c000 - $380

	else

ROM_BOTTOM:	EQU 00000h       ; Bottom address of ROM
ROM_TOP:	EQU ROM_BOTTOM + 01FFFh		; Top address of ROM

JUMPTAB:	EQU RAM_BOTTOM + $0000	; jump table for monitor routines
IRQTAB:	EQU RAM_BOTTOM + $0100	; interrupt vector table
SP_INIT:	EQU RAM_BOTTOM + $0400	; initial value of SP
CFSECT_BUF_V:	EQU $C000			; value for CFSECT_BUF variable. Defaults to $c000 in preparation for CPM loader
MONVARS:	EQU RAM_BOTTOM + $0200	; SP goes at the top of memory. Put monitor vars and buffers 511 bytes below it
epp_tmp:	EQU RAM_BOTTOM + $0300	; this is where EEPROM programming code is copied before execution to
							; avoid it clashing with new data being programmed into its location in EEPROM
USERRREG:	equ RAM_BOTTOM + $0180

	endif


; these interrupt bases are added to Z80 interrupt vector register I to form final vector in IM2
SIOV:		EQU $0		; SIO interrupt vector base except bits 2-0 are set according to interrupt type, 16 interrupts
CTCV:		EQU $10		; CTC interrupt vector base, 4 interrupts
PIOV:		EQU $18		; PIO interrupt vector base, 2 interrupts

;MPFMON:	EQU 0000h
UPLOADBUF:	EQU MONVARS + 0h     ; Buffer for hex-intel upload. Allows up to 128 bytes (80h) per line.
ULBUFSIZE:	EQU 80h                  ; a 20h byte hex-intel record use 75 bytes...
ULBEND:	EQU UPLOADBUF + ULBUFSIZE
MSGBUF:	EQU UPLOADBUF
RX_READ_P:	EQU MONVARS + $80     ; read pointer
RX_WRITE_P:	EQU MONVARS + $82     ; write pointer
ASCDMPBUF:	EQU MONVARS + $84      ;Buffer to construct ASCII part of memory dump
ASCDMPEND:	EQU MONVARS + $94     ;End of buffer, fill with EOS
DMPADDR:	EQU MONVARS + $95     ;Last dump address
MVADDR:	EQU MONVARS + $96     ; 6 bytes: start-address, end-address, dest-address or fill-value (23, 24, 25, 26, 27, 28)
ERRFLAG:	EQU MONVARS + $9c     ; Location to store 
MUTE:		EQU MONVARS + $9d     ; 0 - print received chars, 1 - do not print received chars
ULSIZE:	EQU MONVARS + $9e     ; actual size of current/last hex-intel message
IECHECKSUM:	EQU MONVARS + $9f        ; hex-intel record checksum
IECADDR:	EQU MONVARS + $a0        ; hex-intel record address (2 bytes)
IERECTYPE:	EQU MONVARS + $a2        ; hex-intel record type
DEBUG:	EQU MONVARS + $a3
MTPHFLAG:	EQU MONVARS + $a3     ; Phase counter: phase 1 doesn't check old value (being unknown)
CHKSUM_C:	EQU MONVARS + $a4     ; uses 3 bytes

CF_SECCNT:	EQU MONVARS + $a7 
CF_LBA0:	EQU MONVARS + $a8
CF_LBA1:	EQU MONVARS + $a9
CF_LBA2:	EQU MONVARS + $aa
CF_LBA3:	EQU MONVARS + $ab
CF_PART_CUR:	EQU MONVARS + $ac	; Current partition offset into MBR
CFSECT_BUF:	EQU MONVARS + $ae	; pointer to location of CF data buffer. Need $200 byte buffer

SYSTMR0:	EQU MONVARS + $b0		; system timers. SYSTMR0 overflowing into SYSTMR2 gets incremented on T2 interrupt every 1ms
SYSTMR2:	EQU MONVARS + $b2
SYSTMR4:	EQU MONVARS + $b4		; SYSTMR4 overflowing into SYSTMR6 gets incremented on T3 interrupt, 5ms
SYSTMR5:	EQU MONVARS + $b5		; seconds
SYSTMR6:	EQU MONVARS + $b6		; minutes
SYSTMR7:	EQU MONVARS + $b7		; hours
SYSTMR8:	EQU MONVARS + $b8		; days, 16 bit
SYSTMR9:	EQU MONVARS + $b9

;i8255
i8255CNF		EQU MONVARS + $e2
; SIO
SIOA_WR0:		EQU MONVARS + $e3
SIOA_WR1:		EQU MONVARS + $e4
SIOA_WR3:		EQU MONVARS + $e5
SIOA_WR4:		EQU MONVARS + $e6
SIOA_WR5:		EQU MONVARS + $e7
SIOA_WR6:		EQU MONVARS + $e8
SIOA_WR7:		EQU MONVARS + $e9
SIOB_WR2:		EQU MONVARS + $ea
SIOB_WR0:		EQU MONVARS + $eb
SIOB_WR1:		EQU MONVARS + $ec
SIOB_WR3:		EQU MONVARS + $ed
SIOB_WR4:		EQU MONVARS + $ee
SIOB_WR5:		EQU MONVARS + $ef
SIOB_WR6:		EQU MONVARS + $f0
SIOB_WR7:		EQU MONVARS + $f1
; PIO
PIOA_CNF:		EQU MONVARS + $f2
PIOA_INT_CTRL:	EQU MONVARS + $f3
PIOA_INT_EN:	EQU MONVARS + $f4
PIOB_CNF:		EQU MONVARS + $f5
PIOB_INT_CTRL:	EQU MONVARS + $f6
PIOB_INT_EN:	EQU MONVARS + $f7

; CTC prescaler value locations
CTC_CH0_CNF:	EQU MONVARS + $f8
CTC_CH1_CNF:	EQU MONVARS + $f9
CTC_CH2_CNF:	EQU MONVARS + $fa
CTC_CH3_CNF:	EQU MONVARS + $fb
; location of time constant values for CTC channels
CTC_CH0_TC:	EQU MONVARS + $fc		; time constant for channel 0 system interrupt 200Hz
CTC_CH1_TC:	EQU MONVARS + $fd		; time constant for channel 1
CTC_CH2_TC:	EQU MONVARS + $fe		; time constant for channel 2 this feeds SIOB
CTC_CH3_TC:	EQU MONVARS + $ff		; time constant for channel 3 this feeds SIOA


; ### IO map
IOAY		EQU 000h		; AY on IO board
IOYMZ		EQU 002h		; YMZ on IO board
IOFRQSRC	EQU 004h		; IO board frequency source for sound chips
IOFRQDIV	EQU 005h		; IO board frequency divider for sound chips
UART_BASE:	EQU 008h		; Base port address, P8250A/USART uses 8 ports.

CTC_BASE:	EQU 040H         ; Base port address for Z80 CTC, only CTC2 is used. 64h
CTC_CH0:	EQU CTC_BASE		; system interrupt 200Hz
CTC_CH1:	EQU CTC_BASE+1
CTC_CH2:	EQU CTC_BASE+2		; this feeds SIOB
CTC_CH3:	EQU CTC_BASE+3		; this feeds SIOA

SIO_BASE:	EQU 44h			; SIO port
SIO_DA:	EQU SIO_BASE
SIO_CA:	EQU SIO_BASE+2
SIO_DB:	EQU SIO_BASE+1
SIO_CB:	EQU SIO_BASE+3

PIO_BASE:	EQU 48h         ; Base port address for Z80 PIO, not used. 68h
PIO_DA:	EQU PIO_BASE+0
PIO_CA:	EQU PIO_BASE+1
PIO_DB:	EQU PIO_BASE+2
PIO_CB:	EQU PIO_BASE+3

if MACHINE = "AL80"
i8255A:	EQU 4Ch
i8255B:	EQU 4Dh
i8255C:	EQU 4Eh
i8255D:	EQU 4Fh
endif

;CNFIGSW	EQU $a0	; config switch read only
ymbase:	EQU $b0	; 02 address reg 03 data reg, on mint board $70/$b0

CF_RESET	EQU 0B8h	; CF soft reset write only if configured by jumper
CFBASE:	EQU 080h
;The addresses that the CF Card resides in I/O space.
;Change to suit hardware.
CFDATA:	EQU CFBASE + 00h		; Data (R/W)
CFERR:	EQU CFBASE + 01h		; Error register (R)
CFFEAT:	EQU CFBASE + 01h		; Features (W)
CFSECCO:	EQU CFBASE + 02h		; Sector count (R/W)
CFLBA0:	EQU CFBASE + 03h		; LBA bits 0-7 (R/W, LBA mode)
CFLBA1:	EQU CFBASE + 04h		; LBA bits 8-15 (R/W, LBA mode)
CFLBA2:	EQU CFBASE + 05h		; LBA bits 16-23 (R/W, LBA mode)
CFLBA3:	EQU CFBASE + 06h		; LBA bits 24-27 (R/W, LBA mode)
CFSTAT:	EQU CFBASE + 07h		; Status (R)
CFCMD:	EQU CFBASE + 07h		; Command (W)
CFCTL:	EQU CFBASE + 08h + 06h	; write: Device control
CFALTSTAT:	EQU CFBASE + 08h + 06h	; read: Alternate status
CFADDR:	EQU CFBASE + 08h + 07h	; read: Drive address

turbo:	EQU $f0	; clock divider 0=4MHz, 1=2MHz, 2=1.33MHz, 3=1MHz
beepr:	EQU $f1	; speaker beeper
cpld:	equ 	$f2
cpld2:	equ 	$f3
sp_r:	equ 	$f4
ymcs:	equ 	$f6	; f6 address reg f7 data reg
memmap:	EQU $f8	; memory map $d8-$df

; ### other

;i8255 default config
i8255_CV			EQU 10011011b	; all inputs in mode 0

; SIO config values
SIOA_WR0_CV:		EQU 00110000b	; write into WR0: error reset
SIOA_WR1_CV:		EQU 00000000b	; no interrupts
SIOA_WR3_CV:		EQU 11000001b	; write into WR3: RX enable;
if MACHINE = "AL80"
SIOA_WR4_CV:		EQU 00000100b	; write into WR4: presc. 1x, 1 stop bit, no parity
else
SIOA_WR4_CV:		EQU 01000100b	; write into WR4: presc. 16x, 1 stop bit, no parity
endif
SIOA_WR5_CV:		EQU 11101000b	; write into WR5: DTR on, TX 8 bits, BREAK off, TX on, RTS off
SIOA_WR6_CV:		EQU 0
SIOA_WR7_CV:		EQU 0

SIOB_WR0_CV:		EQU 0
;if EN_INT
;SIOB_WR1_CV:		EQU 00011100b	; RX int enable, parity does not affect vector, status affects vector
;else
SIOB_WR1_CV:		EQU 00000100b	; RX int disable, parity does not affect vector, status affects vector
;endif
SIOB_WR2_CV:		EQU SIOV		; set interrupt vector, but bits D3/D2/D1 of this vector
							; will be affected by the channel & condition that raised the interrupt
							; (see datasheet)
SIOB_WR3_CV:		EQU 11000001b	; write into WR3: RX enable;
if MACHINE = "AL80"
SIOB_WR4_CV:		EQU 00000100b	; write into WR4: presc. 1x, 1 stop bit, no parity
else
SIOB_WR4_CV:		EQU 01000100b	; write into WR4: presc. 16x, 1 stop bit, no parity
endif
SIOB_WR5_CV:		EQU 11101000b	; write into WR5: DTR on, TX 8 bits, BREAK off, TX on, RTS off
SIOB_WR6_CV:		EQU 0
SIOB_WR7_CV:		EQU 0

; PIO config values
PIOA_CNFV:		EQU 11001111b
PIOA_INT_CTRV:	EQU 00000111b	; interrupt control word
PIOA_INT_ENV:	EQU 00000011b	; interrupt disable
PIOB_CNFV:		EQU 11001111b
PIOB_INT_CTRV:	EQU 00000111b	; interrupt control word
PIOB_INT_ENV:	EQU 00000011b	; interrupt disable

; CTC config values
if MACHINE = "AL80"
CTC_CH0_CNFV:	EQU 01010111b	; no int, counter, no prescaler
CTC_CH1_CNFV:	EQU 01010111b	; no int, counter, no prescaler
if EN_INT
CTC_CH2_CNFV:	EQU 10100111b	; int, timer, /256 prescaler
CTC_CH3_CNFV:	EQU 10100111b	; int, timer, /256 prescaler
else
CTC_CH2_CNFV:	EQU 00100111b	; int, timer, /256 prescaler
CTC_CH3_CNFV:	EQU 00100111b	; int, timer, /256 prescaler
endif
else
CTC_CH0_CNFV:	EQU 10100111b
CTC_CH1_CNFV:	EQU 10100111b
CTC_CH2_CNFV:	EQU 01110111b
CTC_CH3_CNFV:	EQU 01110111b
endif

; CTC time constants values
if MACHINE = "AL80"
CTC_CH0_TV:	EQU (SIOCLK/19200)	; SIOA 19200 baud with no prescaler in CTC and no prescaler in SIO
CTC_CH1_TV:	EQU (SIOCLK/19200)	; SIOB 19200 baud with no prescaler in CTC and no prescaler in SIO
CTC_CH2_TV:	EQU (CPUCLK/(1000*256))	; @6.66MHz with 256 prescaler in CTC $1a -> 1000Hz, 1ms
CTC_CH3_TV:	EQU (CPUCLK/(200*256))	; @6.66MHz with 256 prescaler in CTC $82 -> 200Hz, 5ms
else
CTC_CH0_TV:	EQU $24	; $24 -> 1000Hz, 1ms, $12 -> 2000Hz, 500us
CTC_CH1_TV:	EQU $b4	; 180=$b4 system interrupt, $b4 -> 200Hz, 5ms
CTC_CH2_TV:	EQU $0f	; SIOB 9600 baud with 16x prescaler in SIO ; @4MHz CPU: 11=57600baud, 1a=38400baud, 34=19200baud, 45=14400baud, 68=9600baud, d0=4800baud
CTC_CH3_TV:	EQU $0f	; SIOA 9600 baud with 16x prescaler in SIO ; @4.608MHz CPU: 14=115200, 28=57600, 3c=38400, 78=19200, a0=14400, f0=9600baud
					; with 256x prescaler in SIO ; @4.608MHz CPU: 01=14400, 0f=9600, 1e=4800, 3c=2400
					; with 256x prescaler in SIO ; @9.216MHz CPU: 0f=19200, 14=14400, 1e=9600, 3c=4800, 78=2400
endif

; Error codes intel Hex record
E_NONE:	EQU 00h
E_NOHEX:	EQU 01h			; input char not 0-9, A-F
E_PARAM:	EQU 02h			; inconsistent range; start > end
E_BUFSIZE:	EQU 03h			; size larger than buffer
E_HITYP:	EQU 04h			; unsupported hex-intel record type
E_HICKSM:	EQU 05h			; hex-intel record checksum error
E_HIEND:	EQU 06h			; hex-intel end record type found

HI_DATA:	EQU 00h
HI_END:	EQU 01h

ESC:		EQU 01Bh		; 
EOS:		EQU 000h		; End of string
MUTEON:	EQU 001h
LF:		EQU 00Ah
CR:		EQU 00Dh


epp_src:	EQU $4000	; source of code to be programmed into EEPROM
epp_tgt:	EQU $0000	; target starting address
epp_len:	EQU $2000	; byte count of data to be programmed
epp_del:	EQU $1b	; delay between EEPROM readbacks, about 10ms max per datasheet 
epp_bank:	EQU $01	; eeprom bank to select. by default program RAM bank to allow testing and reset if programming fails

; for hex dump routine: number of lines to print
HEXLINES:	EQU 17 ; FIXIT: There is a off-by-one-error here


;$0000-$1fff ROM	d8 00->rom0, 02->rom2
;$2000-$3fff RAM	d9 00->rom1, 02->rom3
;$4000-$5fff RAM	da 00->rom0, 02->rom2
;$6000-$7fff RAM	db 00->rom1, 02->rom3
;$8000-$9fff RAM	dc 00->rom0, 02->rom2
;$a000-$bfff RAM	dd 00->rom1, 02->rom3
;$c000-$dfff RAM	de 00->rom0, 02->rom2
;$e000-$ffff RAM	df 00->rom1, 02->rom3

; rom0-rom3 refer to 8K chunks of 28C256 32K EEPROM

; AL80
; f8: 00->rom0, 01->ram0, 02->rom0, 03->ram8, 04->rom0, 05->ram10, 06->rom0, 07->ram18, 08->rom0, 09->ram20, 0B->ram28, 0D->ram30, 0F->ram38
; f9: 00->rom0, 01->ram1, 02->rom0, 03->ram9, 04->rom0, 05->ram11, 06->rom0, 07->ram19, 08->rom0, 09->ram21, 0B->ram29, 0D->ram31, 0F->ram39
; fa: 00->rom0, 01->ram2, 02->rom0, 03->rama, 04->rom0, 05->ram12, 06->rom0, 07->ram1A, 08->rom0, 09->ram22, 0B->ram2A, 0D->ram32, 0F->ram3A
; fb: 00->rom0, 01->ram3, 02->rom0, 03->ramb, 04->rom0, 05->ram13, 06->rom0, 07->ram1B, 08->rom0, 09->ram23, 0B->ram2B, 0D->ram33, 0F->ram3B
; fc: 00->rom0, 01->ram4, 02->rom0, 03->ramc, 04->rom0, 05->ram14, 06->rom0, 07->ram1C, 08->rom0, 09->ram24, 0B->ram2C, 0D->ram34, 0F->ram3C
; fd: 00->rom0, 01->ram5, 02->rom0, 03->ramd, 04->rom0, 05->ram15, 06->rom0, 07->ram1D, 08->rom0, 09->ram25, 0B->ram2D, 0D->ram35, 0F->ram3D
; fe: 00->rom0, 01->ram6, 02->rom0, 03->rame, 04->rom0, 05->ram16, 06->rom0, 07->ram1E, 08->rom0, 09->ram26, 0B->ram2E, 0D->ram36, 0F->ram3E
; ff: 00->rom0, 01->ram7, 02->rom0, 03->ramf, 04->rom0, 05->ram17, 06->rom0, 07->ram1F, 08->rom0, 09->ram27, 0B->ram2F, 0D->ram37, 0F->ram3F
