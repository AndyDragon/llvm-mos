	.text
	.file	"print-int.ll"
	.globl	print_int                       ; -- Begin function print_int
	.type	print_int,@function
print_int:                              ; @print_int
; %bb.0:                                ; %entry
	cmp	#10
	bcc	.LBB0_2
; %bb.1:                                ; %if.end.preheader
	sta	__save_a
	lda	mos8(__rc4)
	pha
	lda	mos8(__rc5)
	pha
	lda	__save_a
	ldx	#10
	sta	mos8(__rc5)
	jsr	__udivqi3
	sta	mos8(__rc4)
	ldx	#10
	lda	mos8(__rc5)
	jsr	__umodqi3
	sta	mos8(__rc5)
	lda	mos8(__rc4)
	jsr	print_int
	lda	mos8(__rc5)
	sta	__save_a
	pla
	sta	mos8(__rc5)
	pla
	sta	mos8(__rc4)
	lda	__save_a
.LBB0_2:                                ; %if.then
	clc
	adc	#48
	;APP
	jsr	65490
	;NO_APP
	rts
.Lfunc_end0:
	.size	print_int, .Lfunc_end0-print_int
                                        ; -- End function
	.ident	"clang version 12.0.0 (git@github.com:mysterymath/clang6502.git 51e3618d42bc67892d46290a51ea57ea7e127aa6)"
	.section	".note.GNU-stack","",@progbits
