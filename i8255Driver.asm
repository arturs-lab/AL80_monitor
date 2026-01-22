i8255RST:	ld a,i8255_CV
	ld (i8255CNF),a

i8255INIT:	ld a, (i8255CNF)
	out (i8255A),a
	ret

