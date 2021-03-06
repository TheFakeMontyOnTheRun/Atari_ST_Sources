***************************************************************************
*
* PROG: HACKING LANCE		version: 0.00E		date:	22/04/2013
*
*==========================================================================
* FUNCTION:
*	Allows Lance replay at 12.5 KHz / 25 KHz / 50 KHz for a MOD on STE.
* FILES:
*	- HACKL??E.PRG	this program
*	- xxxxxxxx.MOD	MOD file
*==========================================================================
* HISTORY:
*--------------------------------------------------------------------------
*	DATE		TIME	FORM	PCS	COMMENTS	
*--------------------------------------------------------------------------
*	05/03/2013	19:00	C00??	0.000	First version
*	05/03/2013	23:00	C00??	0.001	Go down to 25 KHz
*	06/03/2013	09:00	C00??	0.002	Add free time display
*	06/03/2013	09:00	C00??	0.003	Also for 50 KHz
*	06/03/2013	15:00	C00??	0.004	Add code cycles check
*	06/03/2013	09:00	C00??	0.005	Also for 50 KHz
*	06/03/2013	19:00	C00??	0.006	Add free time display SMA
*	06/03/2013	19:00	C00??	0.007	Also for 50 KHz
*	07/03/2013	09:00	C00??	0.008	One source for 25/50 KHz
*	07/03/2013	14:00	C00??	0.009	Add a 12.5 KHz option
*	08/03/2013	10:00	C00??	0.00A	no volume option
*	12/04/2013	10:00	C00??	0.00B	"Trash" mode option added
*	15/04/2013	11:00	C00??	0.00C	12.5 KHz option speed up
*	16/04/2013	10:00	C00??	0.00C	Correct base errors
*	16/04/2013	13:00	C00??	0.00C	No Volume Control detection
*	17/04/2013	13:00	C00??	0.00D	Short loops problem
*	19/04/2013	10:00	C00??	0.00E	General speed up
***************************************************************************
***************************************************************************
* PROGRAMSTART
***************************************************************************
programstart:

*////			The same start for all programs

	move.l	4(a7),a0		A0 -> program base page
	move.l	12(a0),d0		D0.l <- code size
	add.l	20(a0),d0		D0.l <- D0.l + data size
	add.l	28(a0),d0		D0.l <- D0.l + BSS size
	add.l	#zsbasepage+zsstacksize,d0	D0.l <- D0.l +extras
	addq.l	#1,d0			D0.l = required memory for program
	bclr	#0,d0			that has to be an EVEN value
	lea	0(a0,d0.l),a7		A7.l <- new value for Stack Pointer

*////			Now reserve this area only and free up the rest

	move.l	d0,-(sp)		memory size to reserve
	move.l	a0,-(sp)		start of the memory area to reserve
	clr	-(sp)
	move	#$4A,-(sp)		TOS Setblock
	trap	#1
	lea	12(sp),sp
	tst.l	d0			error ?
	bne.s	programend		no / yes => it's all over

*////			Go to SUPERVISOR mode now saving the TOS SSP

	clr.l	-(sp)
	move	#$20,-(sp)		TOS SUPERVISOR
	trap	#1
	addq	#6,sp
	lea	zsavedSSP(pc),a0
	move.l	d0,(a0)			save TOS SSP to restore it later

*////			Execute our main program

	bsr.s	mainprog		main program

*////			Go back to USER mode

	move.l	a7,usp			our Stack Pointer is now the USP
	move.l	zsavedSSP(pc),a7	restores the TOS SSP
	and	#$DFFF,sr		clears the SUPERVISOR bit in SR


***************************************************************************
* PROGRAMEND
***************************************************************************
programend:

*////			Go back to TOS

	clr	-(sp)
	move	#$4C,-(sp)		return to TOS desktop
	trap	#1

zsbasepage	equ	256
zsstacksize	equ	4096
zsavedSSP	ds.l	1


***************************************************************************
* MAINPROG
***************************************************************************
mainprog:	

*////			Init the system: memory, files ...
*////			and save context

	bsr	qinitsystem		init the system
	tst.b	d1			problems ?
	bne.s	lmainprog_0		no / yes => it's all over

*////			Load MOD

	bsr	lmod
	tst.b	d1			problems ?
	bne.s	lmainprog_0		no / yes => it's all over
	

*////			Play it

	bsr	play_it

*////			Restore TOS context and return the allocated memory

lmainprog_0
	bsr	qsetTOScontxt
	bsr	qreturnmem
	rts

zTOScontext	ds.w	67					C0002
bcontxtvideo	equ	0					C0002
bcontxtMFP	equ	50					C0002

zreplayfreq	dc.w	$0003	Values 3 (50KHz)/ 2 (25KHz)/ 1 (12.5KHz)
z_autovoldetect	dc.w	$0001	Values 0 (no) 1 (active)
z_volume_active	dc.w	$0001	Values 0 (no volume control) 1 (active)
z_trash_idx	dc.w	8	values 2 (normal) 3..32 (N trash buffers)
z_autobpmdetect	dc.w	$0001	Values 0 (no) 1 (active)
z_bpm_active	dc.w	$0001	Values 0 (not active) 1 (active)
zs_amiga_freq	dc.l	7093790	values 7093790 PAL	7159090 NTSC
zfilename	dc.b	'ILLUSION.MOD',0
zstr50		dc.b	' @ 50 KHz',0
zstr25		dc.b	' @ 25 KHz',0
zstr125		dc.b	' @ 12.5 KHz',0
zstrpal		dc.b	' (PAL)',0
zstrntsc	dc.b	' (NTSC)',0
zstrvolume	dc.b	'VOLUME CONTROL ACTIVE',0
zstrnovolume	dc.b	'NO VOLUME CONTROL ACTIVE',0
zstrautovol	dc.b	' (AUTODETECTED)',0
zstrnotrash	dc.b	'NO TRASH',0
zstrtrash	dc.b	'TRASH BUFFERS: ',0

	even

***************************************************************************
* PROC: QSAVECONTEXT
***************************************************************************
qsavecontext:
	move.l	a0,-(sp)
	lea	bcontxtvideo(a0),a0
	bsr	qsavidcontxt
	move.l	(sp)+,a0
	lea	bcontxtMFP(a0),a0
	bsr	qsavMFPcontxt
	rts


***************************************************************************
* PROC: INSTALL
***************************************************************************
install:
	bsr	wdrvmot
	move	#$2700,sr
	bsr	instvid
	bsr	psgoff
	bsr	inikey
	bsr	instmfp
	move	#$2300,sr
	rts


***************************************************************************
* PROC: QSETTOSCONTXT
***************************************************************************
qsetTOScontxt:
	move	#$2700,sr
	lea	zTOScontext(pc),a0
	lea	bcontxtvideo(a0),a0
	bsr	qsetvidcontxt
	bsr	psgoff
	bsr	restkey
	lea	zTOScontext(pc),a0
	lea	bcontxtMFP(a0),a0
	bsr	qsetMFPcontxt
	move	#$2300,sr
	rts


***************************************************************************
* PROC: QINITSYSTEM
***************************************************************************
qinitsystem:
	lea	zTOScontext(pc),a0
	bsr	qsavecontext
	bsr	qinitmemory		init memory
	tst.b	d1			problems ?
	bne.s	linitsystem_0		no / yes


	move.b	zaboveSTE(pc),d0
	cmp.b	#3,d0			Falcon or CT60 ?
	seq	d1
	beq.s	linitsystem_0
	move.b	zSTE(pc),d0		STE detected ?
	seq	d1
	beq.s	linitsystem_0		STF not possible

	bsr	inidsk			init disk access
	tst.b	d1			problems ?
	bne.s	linitsystem_0		no / yes
	bsr	inivid			init video part
	bsr	initrk
*	moveq	#0,d1			all ok / value will come from subrout
linitsystem_0
	rts


***************************************************************************
* PROC: INITRK
*	Inits STE DMA and checks the replay frequency
***************************************************************************
initrk:
	bsr	qinitSTEdma

	move	zreplayfreq(pc),d0
	cmp	#$0001,d0
	scs	d1
	cmp	#$0003,d0
	shi	d2
	or.b	d2,d1
	rts
	

***************************************************************************
* PROC: INIT_CODE
*	Prepares the code depending of the replay frequency
***************************************************************************
init_code:
	move	z_volume_active(pc),d0	Volume control active
	bne.s	l_inicod12		no / yes
	lea	lv_mt_mixcode1(pc),a0
	lea	lc_mt_mixcode1(pc),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move	(a0)+,(a1)+

l_inicod12
	move	zreplayfreq(pc),d0
	cmp	#$0001,d0		12.5 KHz ?
	bne.s	l_inicod25		yes / no
	lea	mt_frequency(pc),a0
	move	d0,(a0)
	lea	mt_replay_len(pc),a0
	move.l	#500,(a0)
	lea	ll_mt_makefreq1(pc),a0
	move.l	lc_mt_makefreq1(pc),(a0)+
	move	4+lc_mt_makefreq1(pc),(a0)
	lea	ll_mt_makefreq2(pc),a0
	move.l	lc_mt_makefreq2(pc),(a0)
	lea	ll_mt_makefreq3(pc),a0
	move.l	lc_mt_makefreq3(pc),(a0)
	lea	ll_mt_make_freq(pc),a0
	move	lc_mt_make_freq(pc),-2(a0)
	lea	ll_mt_makefreq4(pc),a0
	move.l	lc_mt_makefreq4(pc),(a0)
	lea	ll_mt_makefreq5(pc),a0
	move.l	lc_mt_makefreq5(pc),(a0)
	lea	ll_mt_mixcode1(pc),a0
	move.l	lc_mt_mixcode1(pc),(a0)+
	move	4+lc_mt_mixcode1(pc),(a0)
	lea	ll_mt_make_it1(pc),a0
	move	lc_mt_make_it1(pc),-2(a0)
	lea	ll_mt_mixcode2(pc),a0
	move.l	lc_mt_mixcode2(pc),(a0)
	bra	l_inicodok_e
l_inicod25
	cmp	#$0002,d0		25 KHz ?
	bne.s	l_inicod50		yes / no
	lea	mt_frequency(pc),a0
	move	d0,(a0)
	lea	mt_replay_len(pc),a0
	move.l	#1000,(a0)
	lea	ll_mt_makefreq1(pc),a0
	move.l	6+lc_mt_makefreq1(pc),(a0)+
	move	10+lc_mt_makefreq1(pc),(a0)
	lea	ll_mt_makefreq2(pc),a0
	move.l	4+lc_mt_makefreq2(pc),(a0)
	lea	ll_mt_makefreq3(pc),a0
	move.l	4+lc_mt_makefreq3(pc),(a0)
	lea	ll_mt_make_freq(pc),a0
	move	2+lc_mt_make_freq(pc),-2(a0)
	lea	ll_mt_makefreq4(pc),a0
	move.l	4+lc_mt_makefreq4(pc),(a0)
	lea	ll_mt_makefreq5(pc),a0
	move.l	4+lc_mt_makefreq5(pc),(a0)
	lea	ll_mt_mixcode1(pc),a0
	move.l	6+lc_mt_mixcode1(pc),(a0)+
	move	10+lc_mt_mixcode1(pc),(a0)
	lea	ll_mt_make_it1(pc),a0
	move	2+lc_mt_make_it1(pc),-2(a0)
	lea	ll_mt_mixcode2(pc),a0
	move.l	4+lc_mt_mixcode2(pc),(a0)
	bra.s	l_inicodok_e
l_inicod50
	lea	mt_frequency(pc),a0
	move	d0,(a0)
	lea	mt_replay_len(pc),a0
	move.l	#2000,(a0)
	lea	ll_mt_makefreq1(pc),a0
	move.l	12+lc_mt_makefreq1(pc),(a0)+
	move	16+lc_mt_makefreq1(pc),(a0)
	lea	ll_mt_makefreq2(pc),a0
	move.l	8+lc_mt_makefreq2(pc),(a0)
	lea	ll_mt_makefreq3(pc),a0
	move.l	8+lc_mt_makefreq3(pc),(a0)
	lea	ll_mt_make_freq(pc),a0
	move	4+lc_mt_make_freq(pc),-2(a0)
	lea	ll_mt_makefreq4(pc),a0
	move.l	8+lc_mt_makefreq4(pc),(a0)
	lea	ll_mt_makefreq5(pc),a0
	move.l	8+lc_mt_makefreq5(pc),(a0)
	lea	ll_mt_mixcode1(pc),a0
	move.l	12+lc_mt_mixcode1(pc),(a0)+
	move	16+lc_mt_mixcode1(pc),(a0)
	lea	ll_mt_make_it1(pc),a0
	move	4+lc_mt_make_it1(pc),-2(a0)
	lea	ll_mt_mixcode2(pc),a0
	move.l	8+lc_mt_mixcode2(pc),(a0)
l_inicodok_e
	rts

lc_mt_makefreq1
	move.l	#25*10*2,d0		10 words(10 updates) * 25 speeds
	move.l	#25*20*2,d0		20 words(20 updates) * 25 speeds
	move.l	#25*40*2,d0		40 words(40 updates) * 25 speeds
lc_mt_makefreq2
	divu	#10,d1				12.5 KHz => only 10 updates
	divu	#20,d1				25 KHz => only 20 updates
	divu	#40,d1				50 KHz
lc_mt_makefreq3
	cmp	#5,d1				12.5 KHz => only 10 updates
	cmp	#10,d1				25 KHz => only 20 updates
	cmp	#20,d1				50 KHz
lc_mt_make_freq
	moveq	#10-1,d7			12.5 KHz => only 10 updates
	moveq	#20-1,d7			25 KHz => only 20 updates
	moveq	#40-1,d7			50 KHz
lc_mt_makefreq4
	cmp	#10,d1				12.5 KHz => only 10 updates
	cmp	#20,d1				25 KHz => only 20 updates
	cmp	#40,d1				50 KHz
lc_mt_makefreq5
	sub	#10,d1				12.5 KHz => only 10 updates
	sub	#20,d1				25 KHz => only 20 updates
	sub	#40,d1				50 KHz
lc_mt_mixcode1
	move.l	#38819*2,d0		38819 words of generated code
	move.l	#55497*2,d0		55497 words of generated code
	move.l	#75557*2,d0		75557 words of generated code
lc_mt_make_it1
	moveq	#10-1,d5			12.5 KHz => only 10 updates
	moveq	#20-1,d5			25 KHz => only 20 updates
	moveq	#40-1,d5			50 KHz
lc_mt_mixcode2
	lea	20(a2),a2			12.5 KHz
	lea	40(a2),a2			25 KHz
	lea	80(a2),a2			50 KHz
lv_mt_mixcode1
	move.l	#27719*2,d0		27719 words of generated code
	move.l	#38147*2,d0		38147 words of generated code
	move.l	#56807*2,d0		56807 words of generated code

***************************************************************************
* PROC: LMOD
***************************************************************************
lmod:
	clr	-(sp)
	pea	zfilename(pc)
	bsr	bload			load file
	addq	#6,sp
	tst.b	d1			error ?
	bmi	lmodE			if yes then end of the job

	move.l	d0,d1			save mod length
	add.l	#484+31*2*664,d0	484 bytes + 31 samples * 2 * 664 bytes
	bsr	qmalloc
	tst.l	d0
	bmi	lmodE
	move.l	d1,d0			mod length

	bsr	mt_init

	bra.s	lmod4_01
lmodE:
	moveq	#-1,d1			error
lmod4_01:
	rts

***************************************************************************
* PROC: PLAY_IT
***************************************************************************
play_it:
	dc.w	$A00A

	lea	mt_trash_active(pc),a0
	sf	(a0)
	bsr	install				install special context
*	bsr	mfpset

	lea	timebest(pc),a0
	moveq	#0,d0
	move.l	#$1DBC,d1			95 % CPU free
	move	d0,(a0)+
	move	d1,(a0)+
	move	d0,(a0)+
	move.l	d0,(a0)+
	move	d1,d2
	mulu	z_trash_idx(pc),d1
	move.l	d1,(a0)+			current sum
	move.l	d1,(a0)+			worse sum
	move	d0,(a0)+			current index position
	moveq	#31,d0				32 counters
linitbest
	move	d2,(a0)+
	dbf	d0,linitbest

	bsr	wsync

	lea	mt_trash_active(pc),a0
	move	z_trash_idx(pc),d0
	cmp	#2,d0
	sne	(a0)
	beq.s	play_it00
	lea	mt_trash_oodata(pc),a0
	sf	(a0)
l_main_trash_lp
	move.b	mt_trash_oodata(pc),d0
	bne	force_it
	cmp.b	#$B9,$FFFFFC02.w		Space pressed ?
	beq	force_it			no / yes
	lea	mt_trash_status(pc),a0
	add	mt_trash_wt_idx(pc),a0
	moveq	#-1,d2
l_main_trash_lp0
	move.b	(a0),d0				buffer is free ?
	dbeq	d2,l_main_trash_lp0		yes / no
	not 	d2				invert free time value
	move	d2,-(sp)

	move	#$357,$FFFF8240.w

	bsr	mt_music
	bsr	mt_mixer

	lea	mt_trash_status(pc),a1
	lea	mt_trash_wt_idx(pc),a0
	move	(a0),d0
	move.b	#1,0(a1,d0)			set to ready-for-read
	addq	#1,d0
	cmp	z_trash_idx(pc),d0
	bcs.s	l_main_trash_lp1
	sub	z_trash_idx(pc),d0
l_main_trash_lp1
	move	d0,(a0)

	move	#$777,$FFFF8240.w

	move	(sp)+,d0
	bsr	q_check_ftime
	bra.s	l_main_trash_lp

play_it00
	lea	mt_trash_rd_idx(pc),a0
	move	#1,(a0)			read index set to 1

	lea	locsync(pc),a0
	move.b	$469.w,d0
	subq.b	#1,d0
	move.b	d0,(a0)

play_it0:
	bsr	wsync
*****	bne	force_it			Stop if frequency is too high
	move	d2,-(sp)

	bsr	mt_Paula

	move	#$357,$FFFF8240.w

	bsr	mt_music
	bsr	mt_mixer

	lea	mt_trash_rd_idx(pc),a1
	not.l	(a1)
	and.l	#$00010001,(a1)			switch buffers

	move	#$777,$FFFF8240.w
	move	(sp)+,d0
	not	d0
	bsr	q_check_ftime

test_keyb
	cmp.b	#$B9,$FFFFFC02.w		Space pressed ?
	bne	play_it0			yes / no

force_it:
	lea	mt_trash_active(pc),a0
	sf	(a0)
*	bsr	mfprest				Stop timers
	bsr	mt_end

	bsr	clr_scr

	lea	zfilename(pc),a0
	bsr	write_str
	move	zreplayfreq(pc),d0
	cmp	#1,d0
	bne.s	l_wrtfreq25
	lea	zstr125(pc),a0
	bra.s	l_wrtfreqgo
l_wrtfreq25
	cmp	#2,d0
	bne.s	l_wrtfreq50
	lea	zstr25(pc),a0
	bra.s	l_wrtfreqgo
l_wrtfreq50
	lea	zstr50(pc),a0
l_wrtfreqgo
	bsr	write_str
	move.l	zs_amiga_freq(pc),d0
	cmp.l	#7093790,d0
	bne.s	l_wrtntsc
	lea	zstrpal(pc),a0
	bra.s	l_wrtpalgo
l_wrtntsc
	lea	zstrntsc(pc),a0
l_wrtpalgo
	bsr	write_str
	bsr	cr_lf

	move	z_volume_active(pc),d0
	beq.s	l_wrtnovol
	lea	zstrvolume(pc),a0
	bra.s	l_wrtvolgo
l_wrtnovol
	lea	zstrnovolume(pc),a0
l_wrtvolgo
	bsr	write_str
	move	z_autovoldetect(pc),d0
	beq.s	l_wrtnoauto
	lea	zstrautovol(pc),a0
	bsr	write_str
l_wrtnoauto
	bsr	cr_lf

	move	z_trash_idx(pc),d0
	cmp	#2,d0
	bne.s	l_wrt_trash
	lea	zstrnotrash(pc),a0
	bsr	write_str
	bra.s	l_wrt_trash_go
l_wrt_trash
	ext.l	d0
	divu	#10,d0
	move.l	d0,-(sp)
	lea	zstrtrash(pc),a0
	bsr	write_str
	move.l	(sp)+,d0
	move.l	d0,-(sp)
	add	#'0',d0
	bsr	car_out
	move.l	(sp)+,d0
	swap	d0
	add	#'0',d0
	bsr	car_out
l_wrt_trash_go
	bsr	cr_lf


	lea	timebest(pc),a0
	move.l	6(a0),d0
	divu	4(a0),d0
	move.l	a0,-(sp)
	move	d0,-(sp)
	bsr	right_curs
	move	(sp)+,d0
	bsr	write_int
	move.l	(sp)+,a0
	move	(a0),d0
	move.l	a0,-(sp)
	move	d0,-(sp)
	bsr	right_curs
	move	(sp)+,d0
	bsr	write_int
	move.l	(sp)+,a0

*	move	2(a0),d0
*	move.l	a0,-(sp)
*	move	d0,-(sp)
*	bsr	right_curs
*	move	(sp)+,d0
*	bsr	write_int
*	move.l	(sp)+,a0

	move.l	14(a0),d0
	move	z_trash_idx(pc),d1
	subq	#1,d1
	divu	d1,d0
	move.l	a0,-(sp)
	move	d0,-(sp)
	bsr	right_curs
	move	(sp)+,d0
	bsr	write_int
	move.l	(sp)+,a0

test_keyb2
	cmp.b	#$B9,$FFFFFC02.w		Still pressed ?
	beq.s	test_keyb2

test_keyb3
	cmp.b	#$B9,$FFFFFC02.w		new Space pressed ?
	bne.s	test_keyb3

	rts


q_check_ftime:
	tst	d0
	beq	q_check_ftime_e
	cmp	#$1F4C,d0
	bcc	q_check_ftime_e
	ext.l	d0

	lea	timebest(pc),a0

	move.l	10(a0),d2		timecurrsum
	move	mt_trash_rd_idx(pc),d3
	add	d3,d3
	lea	20(a0,d3),a1		points to array position
	moveq	#0,d1
	move	(a1),d1			old value
	move	d0,(a1)			new value
	sub.l	d1,d2			sub old value
	move.l	d2,d3
	add.l	d0,d3			add new value
	move.l	d3,10(a0)		store new timecurrsum
	cmp.l	14(a0),d2		compare to worst case
	bcc.s	test_wsma
	move.l	d2,14(a0)
test_wsma

	cmp	#$1DBC,d0		95% free is max allowed
	bcc.s	test_best
	cmp	(a0),d0
	bcs.s	test_best
	move	d0,(a0)
test_best
	cmp	2(a0),d0	
	bcc.s	test_worse
	move	d0,2(a0)
test_worse
	cmp	#$FFFF,4(a0)
	beq.s	test_avg
	addq	#1,4(a0)
	ext.l	d0
	add.l	d0,6(a0)
test_avg

q_check_ftime_e
	rts


timebest	dc.w	0		0
timeworse	dc.w	$1F4C		2
timeavgcntr	dc.w	0		4
timeavgcntrl	dc.l	0		6
timecurrsum	ds.l	1		10
timeworsesum	ds.l	1		14
timesmaindex	ds.w	1		18
timeavgsma	ds.w	32		20


write_str:
	move.b	(a0)+,d0
	beq.s	write_stre
	move.l	a0,-(sp)
	bsr	car_out
	move.l	(sp)+,a0
	bra.s	write_str
write_stre
	rts

write_int:
	move	d0,d1

	rol	#4,d1
	move	d1,d0
	and	#$000F,d0
	cmp	#$0009,d0
	ble.s	lwrite_int0
	addq	#7,d0
lwrite_int0
	add	#'0',d0
	move	d1,-(sp)
	bsr	car_out
	move	d1,(sp)+

	rol	#4,d1
	move	d1,d0
	and	#$000F,d0
	cmp	#$0009,d0
	ble.s	lwrite_int1
	addq	#7,d0
lwrite_int1
	add	#'0',d0
	move	d1,-(sp)
	bsr	car_out
	move	d1,(sp)+

	rol	#4,d1
	move	d1,d0
	and	#$000F,d0
	cmp	#$0009,d0
	ble.s	lwrite_int2
	addq	#7,d0
lwrite_int2
	add	#'0',d0
	move	d1,-(sp)
	bsr	car_out
	move	d1,(sp)+

	rol	#4,d1
	move	d1,d0
	and	#$000F,d0
	cmp	#$0009,d0
	ble.s	lwrite_int3
	addq	#7,d0
lwrite_int3
	add	#'0',d0
*	move	d1,-(sp)
	bsr	car_out
*	move	d1,(sp)+

	rts

right_curs:
	move	#$1B,d0
	bsr.s	car_out
	move	#'C',d0
	bsr.s	car_out
	rts

clr_scr:
	move	#$1B,d0
	bsr.s	car_out
	move	#'E',d0
	bsr.s	car_out
	rts

cr_lf:
	move	#$0A,d0
	bsr.s	car_out
	move	#$0D,d0
	bsr.s	car_out
	rts

car_out:
	move	d0,-(sp)
	move	#2,-(sp)
	trap	#1
	addq	#4,sp
	rts

qinitSTEdma:
	clr.b	$FFFF8901.w		Disable DMA
	move.b	zaboveSTE(pc),d0
	cmp.b	#3,d0			Falcon ?
	beq.s	no_LCM_Falcon		no / yes
	lea	$FFFF8922.w,a0		Microwire data register
	lea	$FFFF8924.w,a1		Microwire mask register
	move	#$07FF,d0		Normal mask
	move	d0,(a1)
	move	#%0000010011101000,(a0)	Master volume
	bsr	inidmaw
	move	d0,(a1)
	move	#%0000010101010100,(a0)	Left channel volume
	bsr	inidmaw
	move	d0,(a1)
	move	#%0000010100010100,(a0)	Right channel volume
	bsr	inidmaw
	move	d0,(a1)
	move	#%0000010010000110,(a0)	Treble
	bsr	inidmaw
	move	d0,(a1)
	move	#%0000010001000110,(a0)	Bass
	bsr	inidmaw
	move	d0,(a1)
	move	#%0000010000000001,(a0)	Mix
no_LCM_Falcon
	rts

inidmaw:
	cmp	(a1),d0
	bne.s	inidmaw
	rts

*	$FFFF8901.w = xxxxxxdd  00 off  01 play sample  11 play loop
*	$FFFF8903.w,$FFFF8905.w,$FFFF8907.w sample start address
*	$FFFF8909.w,$FFFF890B.w,$FFFF890D.w sample address counter
*	$FFFF890F.w,$FFFF8911.w,$FFFF8913.w sample end address (byte after)
*	$FFFF8921.w = mxxxxxdd  m=1 mono m=0 stereo
*	dd = 00 f=f0/8  dd = 01 f=f0/4  dd = 10  f=f0/2  11 f=f0 = 50xxx


***************************************************************************
* PROC: MFPSET
***************************************************************************
mfpset:
	move	#$2700,sr

	move.b	zvideores(pc),d0	High resolution ?
	bmi.s	mfpset4			no / yes
	move.b	zNTSC(pc),d0		60 Hz ?			0.832
	bne.s	mfpset4			no / yes		0.832
	lea	vblmono(pc),a0		comment these 2 lines and leave the
	move.l	a0,$70.w		next one in to have a VBL sync in colour
	bra.s	mfpset1			Comment to force a timer sync in colour
mfpset4:

	lea	vblmono(pc),a0
	move.l	a0,$70.w
	and.b	#$0F,$FFFFFA1D.w
	move.b	#246,$FFFFFA23.w
	or.b	#$70,$FFFFFA1D.w
	lea	refresh(pc),a0
	move.l	a0,$114.w
	bset	#5,$FFFFFA09.w
	bset	#5,$FFFFFA15.w
	bra.s	mfpset2
mfpset1:
	clr.b	$FFFFFA1B.w
	bset	#0,$FFFFFA07.w
	bset	#0,$FFFFFA13.w
mfpset2:
	move	#$2300,sr
	rts


***************************************************************************
* PROC: MFPREST
***************************************************************************
mfprest:
	move	#$2700,sr
	lea	vbl(pc),a0
	move.l	a0,$70.w
	clr.b	$FFFFFA19.w			STOP TIMER A
	bclr	#5,$FFFFFA07.w
	bclr	#5,$FFFFFA13.w
	clr.b	$FFFFFA1B.w			STOP TIMER B
	bclr	#0,$FFFFFA07.w
	bclr	#0,$FFFFFA13.w
	and.b	#$0F,$FFFFFA1D.w		STOP TIMER C
	bclr	#5,$FFFFFA09.w
	bclr	#5,$FFFFFA15.w
	move	#$2300,sr
	rts


***************************************************************************
* PROC: QINITMEMORY
*
* CHANGED:	01/03/2005	VERSION:	001
* FUNCTION:
*	Inits the memory allocation system by allocating all the available
*	memory except 4096 bytes that will be reserved for GEM.
* DESCRIPTION:
*	- Determines all available memory
*	- Substracts 4096 bytes
*	- Allocates the remaining amount
* RECEIVES:
*	NONE
* RETURNS:
*	- D1.b		$00 all ok	$FF error
*	- ZPFREEMEM	pointer to the current start of free memory
*	- ZFREEMEMSIZE	current number of available bytes
*	- ZPRETURNMEM	initial value of ZPFREEMEM
* CALLS:
*	TOS
* CHANGES(X)/USES(u):
* 	 D0   D1   D2   D3   D4   D5   D6   D7  A0 A1 A2 A3 A4 A5 A6 A7 US
*	XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX XX XX XX XX XX XX XX uu --
***************************************************************************
qinitmemory:
	move.l	#-1,-(sp)		get total amount of free memory
	move	#$48,-(sp)
	trap	#1
	addq	#6,sp
	tst.l	d0			any memory available ?
	smi	d1			set D1.b with $FF if problems
	bmi.s	linitmemory_0
	sub.l	#4096,d0		memory for GEM
	smi	d1			set D1.b with $FF if problems
	bmi.s	linitmemory_0
	lea	zfreememsize(pc),a0
	move.l	d0,(a0)
	move.l	d0,-(sp)		allocate total amount of memory
	move	#$48,-(sp)
	trap	#1
	addq	#6,sp
	tst.l	d0
	smi	d1			set D1.b with $FF if problems
	bmi.s	linitmemory_0
	lea	zpfreemem(pc),a0
	move.l	d0,(a0)
	lea	zpreturnmem(pc),a0
	move.l	d0,(a0)
	moveq	#0,d1
linitmemory_0
	rts


***************************************************************************
* PROC: QMALLOC
*
* CHANGED:	01/03/2005	VERSION:	001
* FUNCTION:
*	Tries to allocate a number of bytes specified in D0.l, returning a
*	pointer in A0.l and the remaining bytes in D0.l
* DESCRIPTION:
*	- turns the requested size an even number
*	- checks if the remaing bytes will be >= 0
*	- calculates the new values for ZFREEMEMSIZE and ZPFREEMEM
*	- returns as pointer the old value of ZPFREEMEM
* RECEIVES:
*	- D0.l		number of bytes of allocate
*	- ZPFREEMEM	pointer to the current start of free memory
*	- ZFREEMEMSIZE	current number of available bytes
* RETURNS:
*	- A0.l		pointer to allocated memory
*	- D0.l		remaining free bytes (must be >= 0)
*	- ZPFREEMEM	pointer to the current start of free memory
*	- ZFREEMEMSIZE	current number of available bytes
* CALLS:
*	NONE
* CHANGES(X)/USES(u):
* 	 D0   D1   D2   D3   D4   D5   D6   D7  A0 A1 A2 A3 A4 A5 A6 A7 US
*	XXXX uuuu ---- ---- ---- ---- ---- ---- XX uu -- -- -- -- -- uu --
***************************************************************************
qmalloc:
	movem.l	d1/a1,-(sp)		saves used registers
	addq.l	#1,d0
	bclr	#0,d0			request even number of bytes C0001
	lea	zfreememsize(pc),a1
	move.l	(a1),d1
	sub.l	d0,d1			remaining free bytes >= 0 ?
	bmi.s	lmalloc_0		yes / no
	move.l	d1,(a1)
	lea	zpfreemem(pc),a1
	move.l	(a1),a0			pointer to allocated area
	add.l	a0,d0
	move.l	d0,(a1)
lmalloc_0
	move.l	d1,d0			copies remaing bytes to D0.l
	movem.l	(sp)+,d1/a1		restores used registers
	rts	


***************************************************************************
* PROC: QMFREE
*
* CHANGED:	01/03/2005	VERSION:	001
* FUNCTION:
*	Sets a new start of free memory with the pointer received in A0.l.
*	Updates ZPFREEMEM with it and calculates ZFREEMEMSIZE using
*	the old value from ZPFREEMEM
* DESCRIPTION:
*	- turns the provided pointer an even number
*	- sets the new value for ZPFREEMEM
*	- calculates the new value for ZFREEMEMSIZE
* RECEIVES:
*	- A0.l		new start for free memory
*	- ZPFREEMEM	pointer to the current start of free memory
*	- ZFREEMEMSIZE	current number of available bytes
* RETURNS:
*	- ZPFREEMEM	pointer to the current start of free memory
*	- ZFREEMEMSIZE	current number of available bytes
* CALLS:
*	NONE
* CHANGES(X)/USES(u):
* 	 D0   D1   D2   D3   D4   D5   D6   D7  A0 A1 A2 A3 A4 A5 A6 A7 US
*	uuuu ---- ---- ---- ---- ---- ---- ---- XX uu -- -- -- -- -- uu --
***************************************************************************
qmfree:
	movem.l	d0/a1,-(sp)		saves used registers
	move.l	a0,d0
	addq.l	#1,d0
	bclr	#0,d0
	move.l	d0,a0			pointer is now an even number
	lea	zpfreemem(pc),a1
	move.l	(a1),d0			old free memory pointer
	sub.l	a0,d0			- new pointer = new free area
	bcs.s	lmfree_0		problems ? yes / no
	move.l	a0,(a1)			set new value for ZPFREEMEM
	lea	zfreememsize(pc),a1
	add.l	d0,(a1)			add it to ZFREEMEMSIZE
lmfree_0
	movem.l	(sp)+,d0/a1		restores used registers
	rts	


***************************************************************************
* PROC: QRETURNMEM
*
* CHANGED:	01/03/2005	VERSION:	001
* FUNCTION:
*	Returns the allocated memory to TOS when quitting the program
* DESCRIPTION:
*	- Returns the allocated memory to TOS using ZPRETURNMEM
* RECEIVES:
*	- ZPRETURNMEM
* RETURNS:
*	NONE
* CALLS:
*	TOS
* CHANGES(X)/USES(u):
* 	 D0   D1   D2   D3   D4   D5   D6   D7  A0 A1 A2 A3 A4 A5 A6 A7 US
*	XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX XX XX XX XX XX XX XX uu --
***************************************************************************
qreturnmem:
	move.l	zpreturnmem(pc),-(sp)
	move	#$49,-(sp)
	trap	#1
	addq	#6,sp
	rts


***************************************************************************
* DATA
*
***************************************************************************

zpfreemem	ds.l	1
zfreememsize	ds.l	1
zpreturnmem	ds.l	1

*****			VIDEO PART			*****

***************************************************************************
* PROC: INIVID
***************************************************************************
inivid:
	move.b	$FFFF820A.w,d0					0.832
	not.b	d0						0.832
	and.b	#%00000010,d0					0.832
	lsr.b	#1,d0						0.832
	lea	zNTSC(pc),a0					0.832
	or.b	d0,(a0)						0.832
	move.b	$FFFF8260.w,d0		actual resolution
	and.b	#%00000011,d0		keeps only the relevant bits
	cmp.b	#$02,d0			high resolution ?
	seq	d1			yes => D1 <- $FF / no D1 <- $00
	and.b	#%11111100,d1		yes => D1 <- $FC / no D1 <- $00
	or.b	d1,d0			yes => D1 <- $FE / no D1 <- $00/01
	lea	zvideores(pc),a0
	move.b	d0,(a0)			keep this in ZVIDEORES
	rts


***************************************************************************
* PROC: VBL_TRASH
***************************************************************************
vbl_trash:
	addq.b	#1,$469.w
	move	d0,-(sp)
	move.b	mt_trash_active(pc),d0
	beq.s	vbl_trash_e
	bsr	mt_frame_play
vbl_trash_e
	move	(sp)+,d0
	rte


***************************************************************************
* PROC: VBL
***************************************************************************
vbl:
	addq.b	#1,$469.w		Increments sync counter
vblmono:
*	rte				set to have VBL sync ou timer in colour

	move.l	d0,-(sp)
	move.b	zvideores(pc),d0	High res ?
	bmi.s	vbl0			no / yes
	move.b	zNTSC(pc),d0		60 Hz ?			0.832
	bne.s	vbl0			no / yes		0.832

	clr.b	$FFFFFA1B.w		Stop timer B
	move.b	#200,$FFFFFA21.w	200 lines
	move.b	#8,$FFFFFA1B.w		Timer B event count
	pea	hbl_sync(pc)
	move.l	(sp)+,$120.w
vbl0:
	move.l	(sp)+,d0
	rte

hbl_sync:
	addq.b	#1,$469.w
	clr.b	$FFFFFA1B.w
	rte

***************************************************************************
* PROC: QSAVIDCONTXT
***************************************************************************
qsavidcontxt:

	move.l	a0,-(sp)

****				=> First detect if we have STE or above

	bsr	qwaitVBL		Wait vertical blanking
	moveq	#0,d4			default = STF
	lea	$FFFF8242.w,a0
	move	(a0),d5			save color
	move	#$0555,d0
	move	#$0AAA,d1
	move	d0,(a0)
	move	(a0),d2
	and	#$0FFF,d2
	move	d1,(a0)
	move	(a0),d3
	and	#$0FFF,d3
	cmp	d0,d2
	bne.s	lsavid0
	cmp	d1,d3
	bne.s	lsavid0
*	move.l	$05A0.w,d4		extra check with cookie
*	beq.s	lsavid0			if 0 then we consider an STF
	moveq	#1,d4			STE detected
lsavid0
	move	d5,(a0)			restore color
	lea	zSTE(pc),a0
	move.b	d4,(a0)

****				=> Now detect if we have a machine above STE

	moveq	#0,d1			no timer sync forced
	moveq	#0,d2			simple STF or STE
	move.b	zSTE(pc),d0		STE or above ?
	beq.s	lsavid3			yes / no (simple STF)
	move.l	$05A0.w,d0
	beq.s	lsavid3
	move.l	d0,a0
lsavid1
	moveq	#0,d2			simple STF or STE
	move.l	(a0)+,d0		get signature
	beq.s	lsavid3
	moveq	#3,d2			set Falcon
	cmp.l	#'CT60',d0		CT60 ?
	seq	d1
	beq.s	lsavid3
	cmp.l	#'_MCH',d0		STE / TT / Falcon ?
	beq.s	lsavid2
	addq	#4,a0			jump over value
	bra.s	lsavid1			loop to get next one (danger !)
lsavid2
	move	(a0)+,d2		get identifier
	cmp	#1,d2			STE ?
	sne	d1			set D1.b if NOT STE but above !
	and	d1,d2			set to 0 if STE
lsavid3
	and.b	#%00000001,d1		keep only bit 0
	lea	zaboveSTE(pc),a0				0.835
	move.b	d2,(a0)						0.835
	lea	zNTSC(pc),a0					0.832
	move.b	d1,(a0)						0.832

****				=> Now use the information to fetch the data

	move.l	(sp)+,a0

	move.b	zaboveSTE(pc),d1
	cmp.b	#3,d1			Falcon or CT60 ?
	bne.s	lsavid4			yes / no

	move.l	a0,-(sp)
	move	#-1,-(sp) 		VM_INQUIRE
	move	#88,-(sp)		VSETMODE (Falcon only)
	trap	#14 			XBIOS
	addq	#4,sp
	move.l	(sp)+,a0
	move	d0,(a0)+
	bra.s	lsavid5
lsavid4
	move.l	a0,-(sp)
	move	#4,-(sp)		Get resolution
	trap	#14			XBIOS
	addq	#2,sp
	move.l	(sp)+,a0
	move	d0,(a0)+
lsavid5
	move.l	a0,-(sp)
	move	#2,-(sp)		Get physbase
	trap	#14			XBIOS
	addq	#2,sp
	move.l	(sp)+,a0
	move.l	d0,(a0)+
	move.l	a0,-(sp)
	move	#3,-(sp)		Get logbase
	trap	#14			XBIOS
	addq	#2,sp
	move.l	(sp)+,a0
	move.l	d0,(a0)+

	lea	$FFFF8200.w,a1		video hardware address
	movep	$01(a1),d0
	move	d0,(a0)+
	move.b	$0A(a1),(a0)+		synchro register
	move.b	$60(a1),(a0)+		video resolution
	move.b	zSTE(pc),d0		STE or above ?
	beq.s	lsavid6			yes / no (simple STF)
	move.b	$0D(a1),(a0)+		video address byte low (STE)
	move.b	$65(a1),(a0)+		number of shift bits (STE)
	move	$0E(a1),(a0)+		offset to next line (STE)
	bra.s	lsavid7
lsavid6
	addq	#4,a0
lsavid7
	movem.l	$40(a1),d0-d7
	movem.l	d0-d7,(a0)		16 colours

	rts


***************************************************************************
* PROC: INSTVID
***************************************************************************
*					Remove the comments to force 50 Hz PAL !
instvid:
*	move.b	zvideores(pc),d0	High resolution ?
*	bmi.s	instvid1		no / yes
*	bsr	qwaitVBL		Wait vertical blanking
*	bset	#1,$FFFF820A.w		Sync mode = 50 Hz PAL
*	lea	zsNTSC(pc),a0
*	sf	(a0)			force 50 Hz behaviour
instvid1
	rts


***************************************************************************
* PROC: QSETVIDCONTXT
***************************************************************************
qsetvidcontxt:
	move.b	zaboveSTE(pc),d1
	beq.s	lsetvidcontxt2
	cmp.b	#3,d1			Falcon or CT60 ?
	bne.s	lsetvidcontxt0		yes / no
	move.l	a0,-(sp)
	move	(a0)+,-(sp) 		Falcon resolution
	move	#3,-(sp)		Use Falcon resolution
	move.l	(a0)+,-(sp) 		physbase
	move.l	(a0)+,-(sp) 		logbase
	move	#5,-(sp) 		Set screen
	trap	#14 			XBIOS
	lea	14(sp),sp
	move.l	(sp)+,a0
	bra.s	lsetvidcontxt1
lsetvidcontxt0
	move.l	a0,-(sp)
	move	(a0)+,-(sp)		TT resolution
	move.l	(a0)+,-(sp)		physbase
	move.l	(a0)+,-(sp)		logbase
	move	#5,-(sp)		Set screen
	trap	#14			XBIOS
	lea	12(sp),sp
	move.l	(sp)+,a0
lsetvidcontxt1
	lea	18(a0),a0
	bra.s	lsetvidcontxt4
lsetvidcontxt2
	lea	10(a0),a0
	move.l	a0,-(sp)
	bsr	qwaitVBL		Wait vertical blanking
	move.l	(sp)+,a0
	lea	$FFFF8200.w,a1
	move	(a0)+,d0
	movep	d0,1(a1)		video hardware address
	move.l	a0,-(sp)
	bsr	qwaitVBL		wait vertical blanking
	move.l	(sp)+,a0
	move.b	(a0)+,$0A(a1)		synchro register
	move.b	(a0)+,$60(a1)		video resolution
	move.b	zSTE(pc),d0		STE or above ?
	beq.s	lsetvidcontxt3		yes / no (simple STF)
	move.b	(a0)+,$0D(a1)		video address byte low (STE)
	move.b	(a0)+,$65(a1)		number of shift bits (STE)
	move	(a0)+,$0E(a1)		offset to next line (STE)
	bra.s	lsetvidcontxt4
lsetvidcontxt3
	addq	#4,a0
lsetvidcontxt4
	movem.l	(a0),d0-d7
	movem.l	d0-d7,$40(a1)		16 colours
	dc.w	$A009
	rts


***************************************************************************
* PROC: WSYNC
***************************************************************************
wsync:
	lea	$469.w,a0		Sync counter
	lea	locsync(pc),a1		Variavel to count nsyncs
	moveq	#-1,d2			**** free time ****
	move.b	(a0),d0
wsync1:
	cmp.b	(a0),d0
	dbne	d2,wsync1		Wait until it changes
	cmp	#-1,d2
	bne.s	wsync2
	moveq	#0,d2			maximum ftime value (not 0 = $FFFF)
wsync2:
	cmp.b	(a0),d0
	beq.s	wsync2			wait for the sync ...
	move.b	d0,d1			new locsync
	sub.b	(a1),d0			- old one
	move.b	d1,(a1)			store new
	subq.b	#1,d0			- 1 VBL
	rts

locsync		ds.b	1
	even


***************************************************************************
* PROC: QWAITVBL
***************************************************************************
qwaitVBL:
	lea	$FFFF8201.w,a0		current video memory start address
	movep	0(a0),d0
	lea	$FFFF8205.w,a0		current video memory address
lwaitVBL_0
	movep	0(a0),d1
	cmp	d0,d1			wait while both are equal
	beq.s	lwaitVBL_0		(top border ? )
lwaitVBL_1
	movep	0(a0),d1
	cmp	d0,d1			wait while they are different
	bne.s	lwaitVBL_1		(screen or lower border ?)
	rts

zpvideomem	ds.l	1
zpTOSvideomem	ds.l	1
zvideores	ds.b	1		$FE 640x400 $01 640x200 $00 320x200
zSTE		ds.b	1		0 STF 1 STE
zaboveSTE	ds.b	1		0 NO  2 TT 3 Falcon/CT60	0.835
zNTSC		ds.b	1						0.832

	even							C0002


*****			DISK ACCESS PART			*****

***************************************************************************
* PROC: INIDSK
***************************************************************************
inidsk:
	bsr	getdrv			Get current drive
	rts

drive		ds.b	1

	even

***************************************************************************
* PROC: GETDRV
***************************************************************************
getdrv:
	move	#$19,-(sp)		Get current drive
	trap	#1
	addq	#2,sp
	lea	drive(pc),a0
	add.b	#'A',d0
	move.b	d0,(a0)
	rts


***************************************************************************
* PROC: BLOAD
***************************************************************************
bload:
	link	a6,#0
	movem.l	d5-d7,-(sp)		Save registers D5 -> D7	
	bsr	setdta			Set disk transfer address
	move	12(a6),-(sp)
	move.l	8(a6),-(sp)
	bsr	searchf			Search file
	addq	#6,sp
	tst.b	d1
	bne.s	bloadend
	move	12(a6),-(sp)
	move.l	8(a6),-(sp)
	bsr	open			Open file
	addq	#6,sp	
	tst.b	d1
	bne.s	bloadend
	move	d0,d7			D7 <- file handle
	move.l	dtabuf+26(pc),d5	D5 <- file length
	cmp.l	zfreememsize(pc),d5
	sgt	d1
	bgt.s	bloadend
	move.l	zpfreemem(pc),d6	D6 <- pointer to buffer for file
	move.l	d6,-(sp)
	move.l	d5,-(sp)
	move	d7,-(sp)
	bsr	read			Read data from disk
	lea	10(sp),sp
	tst.b	d1
	bne.s	bloadend
	move	d7,-(sp)
	bsr	close			Close file
	addq	#2,sp
	tst.b	d1
	bne.s	bloadend
	move.l	d6,a0			A0 <- D6
	move.l	d5,d0			D0 <- D5
bloadend:
	movem.l	(sp)+,d5-d7		Restore registers D5 -> D7
	unlk	a6
	rts


***************************************************************************
* PROC: SETDTA
***************************************************************************
setdta:
	pea	dtabuf(pc)		Set disk transfer address
	move	#$1A,-(sp)
	trap	#1
	addq	#6,sp
	rts

dtabuf		ds.b	44


***************************************************************************
* PROC: OPEN
***************************************************************************
open:
	link	a6,#0			Open a file
	move	12(a6),-(sp)
	move.l	8(a6),-(sp)
	move	#$3D,-(sp)
	trap	#1
	addq	#8,sp	
	tst	d0
	smi	d1
	unlk	a6
	rts


***************************************************************************
* PROC: CLOSE
***************************************************************************
close:
	link	a6,#0			Close a file
	move	8(a6),-(sp)
	move	#$3E,-(sp)
	trap	#1
	addq	#4,sp	
	tst	d0
	smi	d1
	unlk	a6
	rts


***************************************************************************
* PROC: READ
***************************************************************************
read:
	link	a6,#0			Read data from disk
	move.l	14(a6),-(sp)
	move.l	10(a6),-(sp)
	move	8(a6),-(sp)
	move	#$3F,-(sp)
	trap	#1
	lea	12(sp),sp	
	cmp.l	10(a6),d0
	sne	d1
	unlk	a6
	rts


***************************************************************************
* PROC: SEARCHF
***************************************************************************
searchf:
	link	a6,#0			Search first file
	move	12(a6),-(sp)
	move.l	8(a6),-(sp)
	move	#$4E,-(sp)
	trap	#1
	addq	#8,sp
	tst	d0
	sne	d1
	unlk	a6
	rts


***************************************************************************
* PROC: WDRVMOT
***************************************************************************
wdrvmot:
	move.b	drive(pc),d0
	cmp.b	#'C',d0
	bpl.s	wdrvmot_e
	move	#$80,$FFFF8606.w	status register
wdrvmot1:
	moveq	#64,d0
wdrvmot2:
	dbf	d0,wdrvmot2		delay
	move	$FFFF8604.w,d0		status
	btst	#7,d0			motor running ?
	bne.s	wdrvmot1		yes
	move	sr,-(sp)
	move	#$2700,sr
	move.b	#14,$FFFF8800.w		register 14
	move.b	$FFFF8800.w,d0		actual value
	or.b	#%00000111,d0		unselect drives
	move.b	d0,$FFFF8802.w
	move	(sp)+,sr
wdrvmot_e:
	rts

	even

*****			SOUND PART			*****

***************************************************************************
* PROC: PSGOFF
***************************************************************************
psgoff:
	move	sr,-(sp)
	move	#$2700,sr
	lea	$FFFF8800.w,a0		PSG address
	moveq	#13,d0			14 registers
psgoff1:
	move.b	d0,(a0)
	cmp.b	#7,d0			register 7 ?
	bne.s	psgoff2			no
	move.b	(a0),d1
	or.b	#$3F,d1			only 6 bits are forced to 1
	move.b	d1,2(a0)
	bra.s	psgoff3
psgoff2:
	clr.b	2(a0)			clear it
psgoff3:
	dbf	d0,psgoff1
	move	(sp)+,sr
	rts


*****			MFP/INTERRUPTS PART			*****

***************************************************************************
* PROC: REFRESH
***************************************************************************
refresh:
	eor.b	#%00000011,$FFFFFA23.w	to allow 245.5 divider
	addq.b	#1,$469.w
	rte


***************************************************************************
* PROC: INSTMFP
***************************************************************************
instmfp:
	clr.b	$FFFFFA07.w
	clr.b	$FFFFFA09.w
	bclr	#3,$FFFFFA17.w
	lea	vbl_trash(pc),a0
	move.l	a0,$70.w
	rts


***************************************************************************
* PROC: QSAVMFPCONTXT
***************************************************************************
qsavMFPcontxt:
	move	sr,-(sp)		save Status Register
	move.l	$68.w,(a0)+		save HBL handler pointer
	move.l	$70.w,(a0)+		save VBL handler pointer
	lea	$100.w,a1		MFP handlers pointers
	moveq	#15,d0			save 16 pointers
lsavMFPcontxt_0
	move.l	(a1)+,(a0)+
	dbf	d0,lsavMFPcontxt_0
	lea	$FFFFFA00.w,a1		MFP address
	movep	$07(a1),d0		interrupt enable registers
	move	d0,(a0)+
	movep	$13(a1),d0		interrupt masks registers
	move	d0,(a0)+
	movep.l	$17(a1),d0		vector and timer control registers
	move.l	d0,(a0)+
	move	#$2700,sr		disable interrupts
	lea	lsavMFPtimerA(pc),a2
	move.l	a2,$134.w		set new timer A handler
	lea	lsavMFPtimerB(pc),a2
	move.l	a2,$120.w		set new timer B handler
	lea	lsavMFPtimerC(pc),a2
	move.l	a2,$114.w		set new timer C handler
	lea	lsavMFPtimerD(pc),a2
	move.l	a2,$110.w		set new timer D handler
	move	#%0010000100110000,d0	allow timer interrupts
	move	-8(a0),d1
	or	d0,d1			enable timer interrupts
	movep	d1,$07(a1)
	movep	d0,$13(a1)		masks on only for timer interrupts
	bclr	#3,$17(a1)		no software end of interrupt
	moveq	#4,d1
	clr.b	$19(a1)			stop timer A
	move.b	#$07,$19(a1)		start timer A
	clr.b	$1B(a1)			stop timer B
	move.b	#$07,$1B(a1)		start timer B
	clr.b	$1D(a1)			stop timer C and D
	move.b	#$77,$1D(a1)		start timer C and D
	move	#$2500,sr		allow timer interrupts
lsavMFPcontxt_1
	tst	d1			4 interrupts occured ?
	bne.s	lsavMFPcontxt_1		yes / no
	move	#$2700,sr		disable interrupts
	move.l	-72+$10(a0),$110.w	restore timer handler pointers
	move.l	-72+$14(a0),$114.w
	move.l	-72+$20(a0),$120.w
	move.l	-72+$34(a0),$134.w
	move	-8(a0),d0
	movep	d0,$07(a1)		restore old enables
	move	-6(a0),d0
	movep	d0,$13(a1)		restore old masks
	move.l	-4(a0),d1
	movep.l	d1,$17(a1)		restore vector and timer control
	move	(sp)+,sr		restore Status Register
	rts

lsavMFPtimerA:
	move.b	$1F(a1),(a0)		copy timer A data
	clr.b	$19(a1)			stop timer A
	bra.s	lsavMFPcontxt_2
lsavMFPtimerB:
	move.b	$21(a1),1(a0)		copy timer B data
	clr.b	$1B(a1)			stop timer B
	bra.s	lsavMFPcontxt_2
lsavMFPtimerC:
	move.b	$23(a1),2(a0)		copy timer C data
	and.b	#$0F,$1D(a1)		stop timer C
	bra.s	lsavMFPcontxt_2
lsavMFPtimerD:
	move.b	$25(a1),3(a0)		copy timer D data
	and.b	#$F0,$1D(a1)		stop timer D
lsavMFPcontxt_2
	subq	#1,d1			1 more interrupt occured
	rte


***************************************************************************
* PROC: QSETMFPCONTXT
***************************************************************************
qsetMFPcontxt:
	move	sr,-(sp)		save Status Register
	move	#$2700,sr		disable interrupts
	move.l	(a0)+,$68.w		set HBL handler pointer
	move.l	(a0)+,$70.w		set VBL handler pointer
	lea	$100.w,a1		MFP handlers pointers
	moveq	#15,d0			set 16 pointers
lsetMFPcontxt_0
	move.l	(a0)+,(a1)+
	dbf	d0,lsetMFPcontxt_0
	lea	$FFFFFA00.w,a1		MFP address
	move	(a0)+,d0
	movep	d0,$07(a1)		interrupt enable registers
	move	(a0)+,d0
	movep	d0,$13(a1)		interrupt mask registers
	move.l	(a0)+,d0
	clr.b	$19(a1)			stop timers
	clr.b	$1B(a1)
	clr.b	$1D(a1)
	move.l	(a0)+,d1
	movep.l	d1,$1F(a1)		timer data registers
	movep.l	d0,$17(a1)		vector and timer control registers
	move	(sp)+,sr		restores Status Register
	rts


*****			ACIAS PART			*****

***************************************************************************
* PROC: RESETKEY
***************************************************************************
resetkey:
	lea	$FFFFFC00.w,a0
	bra.s	resetk2
resetk1:
	btst	#0,(a0)
	bne.s	resetk2
	subq	#1,d0
	beq.s	resetk3
	bra.s	resetk1
resetk2:
	move.b	2(a0),d0
	move	#300,d0
	bra.s	resetk1
resetk3:
	rts


***************************************************************************
* PROC: INIKEY
***************************************************************************
inikey:
	bsr	resetkey
	lea	zskeylist1(pc),a0
inikey2:
	move.b	(a0)+,d0
	bmi.s	inikey1
	bsr	qwrtkeybACIA
	bra.s	inikey2
inikey1:
	bsr	resetkey
	rts


***************************************************************************
* PROC: QWRTKEYBACIA
***************************************************************************
qwrtkeybACIA:
lwrtkeybACIA_0
	btst	#1,$FFFFFC00.w
	beq.s	lwrtkeybACIA_0
	move.b	d0,$FFFFFC02.w
	rts


***************************************************************************
* PROC: RESTKEY
***************************************************************************
restkey:
	bsr	resetkey
	lea	zskeylist2(pc),a0
restkey2:
	move.b	(a0)+,d0
	bmi.s	restkey1
	bsr	qwrtkeybACIA
	bra.s	restkey2
restkey1:
	bsr	resetkey
	rts

zskeylist1	dc.b	$12,$1A,$FF
zskeylist2	dc.b	$14,$8,$FF

;----------------------------------------------------------
;
;
;
;
;
;
;                PROtracker replay routine
;                ���������� ������ �������
;                        converted
;                           by:
;
;                        � Lance �
;
;
;
;
;
;
;----------------------------------------------------------
;  ....PROtracker was invented by Freelancers (Amiga)....
;----------------------------------------------------------
; This version includes the version 3 of my Paula emulators
; It's totally rewritten and by combining several tricks
; I'm manage to do a 50kHz(!!!) replay routine that only
; takes around 30% and I'm not using any cheats like over-
; sample. This version is indeed four times faster than my
; first replay routine and I hope all you hackers out there
; will like my routine and would like to contact me :
;---------------------------------------------------------- 
;	M�rten R�nge
;	Oxelv�gen 6
;	524 32 HERRLJUNGA
;	SWEDEN
;----------------------------------------------------------
; Or call:
;----------------------------------------------------------
;	+46-(0)513-10137
;    (Ask for M�rten , Maarten in english)
;----------------------------------------------------------
; This program is a CardWare program. Which means if you
; like it and use it regulary you are encouraged to send
; me a card or a letter(I prefer them without bombs(joke!))
; and tell me how much like my routine and that you think
; that I'm the greatest coder in the world etc. etc.
; This will encourage me to go on with my work on a UCDM -
; player and a Octalizer routine(XIA contacted me after he
; saw my version 0 of my Paula emulators and it's much
; thanks to him and to all others that have contacted me
; that version is made. So as you can see,contacting the
; programmer is very important.).
;----------------------------------------------------------
; Some Greets:
; ������������
; OMEGA and Electra - (   The Best DemoCrews in Sweden    )
;    Delta Force    - (DiscMaggie has never looked better )
;     AGGRESSION    - ('BrainDamage' is really ultra-cool )
;-------------
;  NewCore - (What do you think about this replay , Blade?)
;  NoCrew  - (Should be named CoolCrew (they're very nice))
;   Chip   - (     Good friend (and also a Teadrinker)    )
;    XIA   - (It was nice to meet you at 'Motorola inside')
;    ICE   - (             Hi there,TECHWAVE              )
;-------------
; Special greet to AURA - I don't know you guys but it's
; thanks to you and your demo 'HiFi-dreams' that I realized
; that it's possible to make a 50kHz replay routine.
;-------------
; And to all members in IMPULSE (They paid me for this!)
;----------------------------------------------------------
; Some notes:
; Always call mt_Paula before mt_music ,this because
; mt_music sometimes takes more time and sometimes takes
; less. DON'T use Trap0 because I am using that to switch
; between Supervisor- and Usermode.
;----------------------------------------------------------
; P.S. This replay routine supports every PT2.2 command D.S
;----------------------------------------------------------
;      - Lance / M�rten R�nge      1993/08/22
;----------------------------------------------------------


***************************************************************************
***************************************************************************
*
*	mt_init		MOD preparation procedure
*			A0 should point to MOD and loop space should
*			have been added at the end (31 * 2 * 664 bytes)
*			+ 484 bytes to convert mod if necessary
*			D0 contains the mod length
*
***************************************************************************
***************************************************************************
mt_init:
*	lea	mt_data,a0
*	move.l	a0,mt_SongDataPtr
	lea	mt_SongDataPtr(pc),a1
	move.l	a0,(a1)

	lea	0(a0,d0.l),a1
	move.l	d0,d1
	add.l	#484+31*2*664,d1
	lea	0(a0,d1.l),a2
l_mt_init00
	move.b	-(a1),-(a2)		copy mod to top of available memory
	cmp.l	a0,a1
	bne.s	l_mt_init00

	lea	$438(a2),a1		tag position
	cmp.l	#'1CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'2CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'3CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'5CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'6CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'7CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'8CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'9CHN',(a1)
	beq	mt_not_supported
	cmp.l	#'10CH',(a1)
	beq	mt_not_supported
	cmp.l	#'11CH',(a1)
	beq	mt_not_supported
	cmp.l	#'12CH',(a1)
	beq	mt_not_supported
	cmp.l	#'13CH',(a1)
	beq	mt_not_supported
	cmp.l	#'14CH',(a1)
	beq	mt_not_supported
	cmp.l	#'15CH',(a1)
	beq	mt_not_supported
	cmp.l	#'16CH',(a1)
	beq	mt_not_supported
	cmp.l	#'CD42',(a1)
	beq	mt_not_supported
	cmp.l	#'CD43',(a1)
	beq	mt_not_supported
	cmp.l	#'CD6 ',(a1)
	beq	mt_not_supported
	cmp.l	#'CD61',(a1)
	beq	mt_not_supported
	cmp.l	#'CD62',(a1)
	beq	mt_not_supported
	cmp.l	#'CD63',(a1)
	beq	mt_not_supported
	cmp.l	#'CD8 ',(a1)
	beq	mt_not_supported
	cmp.l	#'CD81',(a1)
	beq	mt_not_supported
	cmp.l	#'CD82',(a1)
	beq	mt_not_supported
	cmp.l	#'CD83',(a1)
	beq	mt_not_supported
	cmp.l	#'OCTA',(a1)
	beq	mt_not_supported
	cmp.l	#'FA06',(a1)
	beq	mt_not_supported
	cmp.l	#'FA08',(a1)
	beq	mt_not_supported
	cmp.l	#'FTL8',(a1)
	beq	mt_not_supported
	cmp.l	#'M.K.',(a1)
	beq	mt_supported
	cmp.l	#'M!K!',(a1)
	beq	mt_supported
	cmp.l	#'4CHN',(a1)
	beq.s	mt_supported
	cmp.l	#'FTL4',(a1)
	beq.s	mt_supported
	cmp.l	#'RASP',(a1)
	beq.s	mt_supported
	cmp.l	#'FA04',(a1)
	beq.s	mt_supported
*					Assumed old 15 samples mod
	lea	(a0),a1
	moveq	#4,d7			copy 5 longs
l_mt_init01
	move.l	(a2)+,(a1)+		copy name
	dbf	d7,l_mt_init01
	moveq	#14,d7			copy sample data
l_mt_init02
	moveq	#10,d6			copy 11 words
l_mt_init03
	move	(a2)+,(a1)+		copy sample name
	dbf	d6,l_mt_init03
	move.l	(a2)+,(a1)+		lenght + finetune + volume
	move	(a2)+,d0
	lsr	#1,d0			repeat start / 2
	move	d0,(a1)+
	move	(a2)+,(a1)+		looplen
	dbf	d7,l_mt_init02
	move	#'  ',d0
	move.l	#$00000040,d1		lenght 0 / finetune 0 / vol $40
	move.l	#$00000001,d2		repeat start 0 / looplen 1
	moveq	#15,d7
l_mt_init04
	move	d0,(a1)+		sample name
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move	d0,(a1)+
	move.l	d1,(a1)+
	move.l	d2,(a1)+
	dbf	d7,l_mt_init04
	moveq	#64,d7			copy 65 words
l_mt_init05
	move	(a2)+,(a1)+		song lenght / restart / patt list
	dbf	d7,l_mt_init05
	move.l	#'M.K.',(a1)+
	bra.s	l_mt_init07
mt_supported
	lea	(a0),a1
	move	#270,d7			copy 271 longs
l_mt_init06
	move.l	(a2)+,(a1)+		copy all up to patterns
	dbf	d7,l_mt_init06
l_mt_init07
*				only patterns and samples still to copy
*				now check sample info
	lea	20+22(a0),a3		first sample info
	moveq	#31-1,d7
l_mt_init08
	move	(a3),d0			length in words = 0?
	bne.s	l_mt_init09		yes / no
	moveq	#0,d0
	move.l	d0,(a3)			clear all info
	move.l	d0,4(a3)
	bra.s	l_mt_init12
l_mt_init09
	move	6(a3),d1		looplen
	cmp	#1,d1			<= 1
	bhi.s	l_mt_init10		yes / no
	clr.l	4(a3)			clear repeat start and looplen
	bra.s	l_mt_init12
l_mt_init10
	cmp	d0,d1			looplen <= length
	bls.s	l_mt_init11		no / yes
	clr.l	4(a3)			clear repeat start and looplen
	bra.s	l_mt_init12
l_mt_init11
	sub	d1,d0			maximum repeat start
	move	4(a3),d2
	cmp	d0,d2			actual value is >
	bls.s	l_mt_init12		yes / no
	move	d0,4(a3)		set to maximum possible
l_mt_init12
	lea	30(a3),a3
	dbf	d7,l_mt_init08
*
*					now check for pattern usage
*					and get the bigger index

	cmp.b	#$78,$3B7(a0)		restart index check
	bcs.s	l_mt_init12a		if >= $78 => set 0
	sf	$3B7(a0)
l_mt_init12a
	lea	$3B8(a0),a3
	lea	z_pattern_used(pc),a4
	lea	(a4),a5
	moveq	#0,d0
	moveq	#63,d7
l_mt_init13
	move.l	d0,(a5)+
	dbf	d7,l_mt_init13
	moveq	#0,d0
	moveq	#0,d1
	moveq	#127,d7
l_mt_init14
	move.b	(a3)+,d0		pattern index
	st	0(a4,d0)		set as used
	cmp	d0,d1			> as maximum value
	bcc.s	l_mt_init15		yes / no
	move.b	d0,d1			get new maximum
l_mt_init15
	dbf	d7,l_mt_init14
	addq	#1,d1
	lea	z_total_patterns(pc),a5
	move	d1,(a5)
	lsl	#8,d1			x 256 longs per pattern
	subq	#1,d1
l_mt_init16
	move.l	(a2)+,(a1)+
	dbf	d1,l_mt_init16

	move	z_autovoldetect(pc),d0
	beq.s	lm_chkpatused6
	lea	$43C(a0),a3		points to patterns
	moveq	#0,d5			result = no volume control used
	move	#255,d7			max 256 patterns
lm_chkpatused0
	moveq	#0,d0
	move.b	(a4)+,d0
	beq.s	lm_chkpatused4
	sub	d7,d0			D0 gets $FF from flag
	add	d0,d0
	add	d0,d0
	lsl.l	#8,d0			x 1024
	lea	0(a3,d0.l),a5
	move	#255,d6			256 = 64 positions x 4 voices
lm_chkpatused1
	move.l	(a5)+,d0
	and	#$0FF0,d0
	lsr	#4,d0			$Ex command
	move	d0,d1
	lsr	#4,d1			$X commands
	cmp	#5,d1			Portamento + Volume Slide ?
	beq.s	lm_chkpatused2
	cmp	#6,d1			Vibrato + Volume Slide ?
	beq.s	lm_chkpatused2
	cmp	#7,d1			Tremolo ?
	beq.s	lm_chkpatused2
	cmp	#$A,d1			Volume Slide ?
	beq.s	lm_chkpatused2
	cmp	#$C,d1			Volume Set ?
	beq.s	lm_chkpatused2
	cmp	#$EA,d0			Fine volume Slide ?
	beq.s	lm_chkpatused2
	cmp	#$EB,d0			Fine volume Slide ?
	bne.s	lm_chkpatused3
lm_chkpatused2
	moveq	#1,d5			volume control is used
	bra.s	lm_chkpatused5
lm_chkpatused3
	dbf	d6,lm_chkpatused1
lm_chkpatused4
	dbf	d7,lm_chkpatused0
lm_chkpatused5
	lea	z_volume_active(pc),a3
	move	d5,(a3)
lm_chkpatused6
	movem.l	a0-a2,-(sp)
	bsr	init_code
	movem.l	(sp)+,a0-a2

	lea	mt_SampleStarts(pc),a4
	lea	20+22(a0),a3		first sample info
	moveq	#31-1,d7
l_mt_init_20
	move.l	a1,(a4)+		store sample start pointer
	move	(a3),d6			lenght = 0 ?
	bne.s	l_mt_init_23		yes / no
l_mt_init_21
	moveq	#0,d0
	move	#166-1,d6		664 bytes / 4 - 1 for dbf
l_mt_init_22
	move.l	d0,(a1)+
	dbf	d6,l_mt_init_22
	bra.s	l_mt_init_26
l_mt_init_23
	subq	#1,d6			lenght (in words) - 1
l_mt_init_24
	move	(a2)+,(a1)+		copy words
	dbf	d6,l_mt_init_24
	moveq	#0,d0
	move	6(a3),d0		looplen = 0 ?
	beq.s	l_mt_init_21		no / yes
	moveq	#0,d1
	move	4(a3),d1		repeat start
	add	d0,d1
	move.l	d0,d2
	add.l	d2,d2
	add.l	d1,d1			end of loop
	move.l	-4(a4),a1		sample pointer
	add.l	d1,a1			end of loop pointer
	move.l	a1,a5
	sub.l	d2,a5			start of loop pointer
	move.l	#664,d6			max read byte sper VBL
	move.l	d6,d5
	divu	d2,d5			/ loop size
	mulu	d2,d5			x loop size = extra area
	add	d5,d6			for small loops
	lsr	#1,d6
l_mt_init_25
	move	(a5)+,(a1)+		copy loop data
	dbf	d6,l_mt_init_25
	lsr	#1,d5			extra size in words
	add	d5,d0			new loop len
	move	d0,6(a3)
l_mt_init_26
	lea	30(a3),a3
	dbf	d7,l_mt_init_20

	lea	mt_module_end(pc),a2
	move.l	a1,(a2)

	lea	mt_PT_data(pc),a4
*	move.b	#6,mt_speed
	move.b	#6,bt_speed(a4)
*	move.b	#6,mt_counter
	move.b	#6,bt_counter(a4)
*	clr.b	mt_SongPos
	clr.b	bt_SongPos(a4)
*	clr	mt_PatternPos
	clr	bt_PatternPos(a4)

	move.l	mt_SampleStarts(pc),a0
	move.l	mt_module_end(pc),a1
l_mt_shift_down
	move.b	(a0),d0
	asr.b	#1,d0
	move.b	d0,(a0)+
	cmp.l	a0,a1
	bne.s	l_mt_shift_down

	bsr	qmfree			free memory starting from A0

	bsr	qgenpertab
	bsr	qgenvibtrem
	tst.b	d1
	bne.s	mt_init_e
	bsr	mt_init_Paula

	move	d1,-(sp)

	move	z_volume_active(pc),d0	volume control_active
	bne.s	lvolsamp_e		no / yes => nothing to do
	move.l	mt_SongDataPtr(pc),a0
	lea	20+22(a0),a0
	lea	mt_SampleStarts(pc),a1
	moveq	#31-1,d7		31 samples
lvolsamp
	move.l	(a1)+,a2		sample start pointer
	moveq	#0,d0
	move	(a0),d0			word length
	add.l	d0,d0			byte length
	add.l	#664,d0			+ loop area
	moveq	#0,d1
	move.b	3(a0),d1		volume
	cmp.b	#$40,d1			= maximum ?
	beq.s	lvolsamp2		no / yes => nothing to do
	lsl	#8,d1
	add.l	mt_volume_tab(pc),d1	volume table pointer
lvolsamp1
	move.b	(a2),d1
	move.l	d1,a3
	move.b	(a3),(a2)+		volume sample data
	subq.l	#1,d0
	bne.s	lvolsamp1
lvolsamp2
	lea	30(a0),a0
	dbf	d7,lvolsamp
lvolsamp_e

	move	(sp)+,d1
mt_init_e
	rts

mt_not_supported
	moveq	#-1,d1
	rts

z_pattern_used	ds.b	256
z_total_patterns	ds.w	1


***************************************************************************
***************************************************************************


***************************************************************************
***************************************************************************
*
*	mt_init_Paula	tables and routines generation required by Lance
*
***************************************************************************
***************************************************************************
mt_init_Paula
	bsr	mt_make_freq
	tst.b	d1
	bne	mt_ini_Paula_rts
	bsr	mt_make_tables
	tst.b	d1
	bne	mt_ini_Paula_rts
	bsr	mt_make_frame_f
	tst.b	d1
	bne	mt_ini_Paula_rts
	bsr	mt_make_voltab
	tst.b	d1
	bne	mt_ini_Paula_rts
	bsr	mt_make_divtab
	tst.b	d1
	bne	mt_ini_Paula_rts
	bsr	mt_make_mixcode
	tst.b	d1
	bne	mt_ini_Paula_rts

	move.l	mt_replay_len(pc),d0		request memory for digi buffers
	mulu	z_trash_idx(pc),d0
	bsr	qmalloc
	tst.l	d0
	smi	d1
	bmi	mt_ini_Paula_rts

	lea	mt_trash_str(pc),a1
	moveq	#0,d0
	move	z_trash_idx(pc),d1
	subq	#1,d1
l_mt_init_trash0
	move.l	a0,(a1)+		digi buffer pointer
	move.l	#$FF00FF00,(a1)+	LCM volume updates
	move.l	mt_replay_len(pc),d2
	lsr.l	#2,d2
	subq	#1,d2
l_mt_init_digibuf
	move.l	d0,(a0)+		init with middle value: 00
	dbf	d2,l_mt_init_digibuf
	dbf	d1,l_mt_init_trash0
	moveq	#-1,d1
	lea	mt_trash_status(pc),a0
	move.l	d1,(a0)+		all buffers ready-for-read FF
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	lea	mt_trash_rd_idx(pc),a0
	move	d0,(a0)			read index set to 0 (VBL -> 1)
	lea	mt_trash_wt_idx(pc),a0
	move	d0,(a0)			write index set to 0


	lea	mt_channel_p(pc),a1
	lea	mt_channel_0(pc),a0
	move.l	a0,(a1)+
	lea	mt_channel_1(pc),a0
	move.l	a0,(a1)+
	lea	mt_channel_2(pc),a0
	move.l	a0,(a1)+
	lea	mt_channel_3(pc),a0
	move.l	a0,(a1)+

	lea	mt_dummy_tab(pc),a1
	lea	mt_dummy_spl(pc),a0
	move.l	a0,(a1)+
	move.l	a0,(a1)+

l_mt_init_trap0
	lea	mt_save_trap0(pc),a0
	move.l	$80.w,(a0)
	lea	mt_return_Paula(pc),a0
	move.l	a0,$80.w
	moveq	#0,d1
mt_ini_Paula_rts
	rts
***************************************************************************

***************************************************************************
*
*	mt_make_freq	generates table with reads required per DMA buffer
*
***************************************************************************
mt_make_freq
ll_mt_makefreq1
**	move.l	#23*40*2,d0		40 words(40 updates) * 23 speeds
	move.l	#25*20*2,d0		20 words(20 updates) * 25 speeds
	bsr	qmalloc
	tst.l	d0
	smi	d1
	bmi.s	mt_make_freq_rts
	lea	mt_freq_list(pc),a1
	move.l	a0,(a1)

*	move.l	mt_freq_list(pc),a0

	moveq	#3,d0
l_mt_maker0
	move.l	d0,d1

	moveq	#0,d2				25 KHz => only 20 updates
ll_mt_makefreq4
	cmp	#20,d1				so result can be > 1
	bcs.s	freq_lab1
*	moveq	#1,d2				store integer part in D2.l
	addq	#1,d2
ll_mt_makefreq5
	sub	#20,d1
	bne.s	ll_mt_makefreq4
freq_lab1
	swap	d2

	swap	d1

ll_mt_makefreq2
**	divu	#40,d1
	divu	#20,d1				25 KHz => only 20 updates

	move	d1,d2
	swap	d1

ll_mt_makefreq3
**	cmp	#20,d1
	cmp	#10,d1				25 KHz => only 20 updates

	blt.s	l_mt_no_round0
	addq	#1,d2
l_mt_no_round0
	moveq	#0,d1
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5

**	moveq	#39,d7
	moveq	#20-1,d7			25 KHz => only 20 updates

ll_mt_make_freq
l_mt_make_freq
	add	d2,d1
	negx	d4
	neg	d4
	move	d4,d5
	move	d1,d6
	add	d6,d6
	negx	d5
	neg	d5
	cmp	d3,d5
	ble.s	l_mt_set_zero0
	move	d5,d3
	moveq	#1,d5

	swap	d2				25 KHz => add integer part
	add	d2,d5				of division result to D5
	swap	d2

	move	d5,(a0)+
	bra.s	l_mt_set_zero00
l_mt_set_zero0
	moveq	#0,d5

	swap	d2				25 KHz => add integer part
	add	d2,d5				of division result to D5
	swap	d2

	move	d5,(a0)+
l_mt_set_zero00
	dbf	d7,l_mt_make_freq
	addq	#1,d0
**	cmp	#26,d0
	cmp	#28,d0
	bne.s	l_mt_maker0
	moveq	#0,d1
mt_make_freq_rts
	rts
***************************************************************************

***************************************************************************
*
*	mt_make_tables	generates long read steps per Amiga divider
*
***************************************************************************
mt_make_tables
	move.l	#$400*4,d0		$400 Amiga dividers * 1 long
	bsr	qmalloc
	tst.l	d0
	smi	d1
	bmi.s	mt_make_tabl_rts
	lea	mt_freq_table(pc),a1
	move.l	a0,(a1)

*	move.l	mt_freq_table(pc),a0

**	moveq	#$72-1,d7
**	move.l	#$02260000,d0
l_mt_make_first
**	move.l	d0,(a0)+
**	dbf	d7,l_mt_make_first

**	moveq	#$72,d0
	moveq	#0,d0
l_mt_maker1
	move	d0,-(sp)

	move	#108,d2
	cmp	d2,d0
	bcc.s	l_mt_maker1a
	move	d2,d0
l_mt_maker1a
	move	#907,d2
	cmp	d2,d0
	bls.s	l_mt_maker1b
	move	d2,d0
l_mt_maker1b


**	move.l	mt_amiga_freq(pc),d1
	move.l	zs_amiga_freq(pc),d1
	move	d0,d2
	add	d2,d2
	divu	d2,d1
	moveq	#0,d2
	moveq	#0,d3
	move	d1,d2
	swap	d1
	cmp	d0,d1
	blt.s	l_mt_no_round1
	addq	#1,d2
l_mt_no_round1
	divu	#50,d2
	move	d2,d1
	clr	d2
	divu	#50,d2
	move.l	d2,d3
	swap	d3
	cmp	#50/2,d3
	blt.s	l_mt_no_round2
	addq	#1,d2
l_mt_no_round2
**	sub	#75,d1
	sub	#78,d1
	bpl.s	l_mt_no_zero
	moveq	#0,d1
	moveq	#0,d2
l_mt_no_zero
	move	d1,(a0)+
	move	d2,(a0)+

	move	(sp)+,d0

	addq	#1,d0
	cmp	#$400,d0
	bne.s	l_mt_maker1
	moveq	#0,d1
mt_make_tabl_rts
	rts
***************************************************************************

***************************************************************************
*
*	mt_make_frame_f	generates number of reads per VBL sub block
*
***************************************************************************
mt_make_frame_f
**	move.l	#551*25*2,d0		551 read speeds (from 75 to 625)
	move.l	#586*25*2,d0		586 read speeds (from 78 to 663)
	bsr	qmalloc			* 25 words (1 for each VBL block)
	tst.l	d0			with number of reads (3..27)
	smi	d1
	bmi.s	mt_make_fr_f_rts
	lea	mt_frame_freq_t(pc),a1
	move.l	a0,(a1)
**	move.l	#551*4,d0		551 pointers: 1 per case
	move.l	#586*4,d0		586 pointers: 1 per case
	bsr	qmalloc
	tst.l	d0
	smi	d1
	bmi.s	mt_make_fr_f_rts
	lea	mt_frame_freq_p(pc),a1
	move.l	a0,(a1)

	move.l	a0,a1
	move.l	mt_frame_freq_t(pc),a0
*	move.l	mt_frame_freq_p(pc),a1

**	moveq	#75,d0
	moveq	#78,d0
l_mt_maker2
	move.l	d0,d1
	divu	#25,d1
	moveq	#0,d3
	move	d1,d2
	subq	#3,d2
	clr	d1
	divu	#25,d1
	move	d1,d3
	addq	#1,d3
l_mt_no_round
	move.l	a0,(a1)+
	moveq	#0,d4
	moveq	#24,d7
	moveq	#0,d1
l_mt_make_it0
	moveq	#0,d1
	add	d3,d4
	addx	d2,d1
	move	d1,d5

**	mulu	#23<<7,d5
*	mulu	#25<<6,d5
*	add	d1,d1
**	add	d1,d1
	lsl	#8,d5
	add	d1,d1
	add	d1,d1

	or	d1,d5
	move	d5,(a0)+
	dbf	d7,l_mt_make_it0
	addq	#1,d0
**	cmp	#626,d0
	cmp	#664,d0
	bne.s	l_mt_maker2
	moveq	#0,d1
mt_make_fr_f_rts
	rts
***************************************************************************

***************************************************************************
*
*	mt_make_voltab	generates the volume table
*
***************************************************************************
mt_make_voltab
	move.l	#16894,d0		65 volumes * 256 bytes (7 bits)
	bsr	qmalloc			+ 254 bytes for 256 bytes boundary
	tst.l	d0
	smi	d1
	bmi.s	mt_make_vtab_rts
	move.l	a0,d0			get the A= pointer to D0
	add.l	#254,d0			add.l 254 to pointer value
	clr.b	d0			and clr the byte to have a 256 bytes
	move.l	d0,a0			boundary and send the pointer to A0
	lea	mt_volume_tab(pc),a1
	move.l	a0,(a1)

	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d3
l_mt_clop0
	move	d1,d2
	ext	d2
	muls	d0,d2
	asr	#6,d2
	move.b	d2,(a0)+
	addq	#1,d1
	cmp	#$40,d1
	bne.s	l_mt_clop0
	lea	$80(a0),a0
	move	#$c0,d1
l_mt_clop1
	move	d1,d2
	ext	d2
	muls	d0,d2
	asr	#6,d2
	move.b	d2,(a0)+
	addq	#1,d1
	cmp	#$100,d1
	bne.s	l_mt_clop1

	moveq	#0,d1
	addq	#1,d0
	cmp	#$41,d0
	bne.s	l_mt_clop0
	moveq	#0,d1
mt_make_vtab_rts
	rts
***************************************************************************

***************************************************************************
*
*	mt_make_divtab	generates the volume division table
*
***************************************************************************
mt_make_divtab
	move.l	#64*64*2,d0		64*64 possible volume combinations
	bsr	qmalloc			1 word for each case
	tst.l	d0
	smi	d1
	bmi.s	mt_make_dtab_rts
	lea	mt_div_table(pc),a1
	move.l	a0,(a1)

	moveq	#1,d0
	moveq	#1,d1
*	move.l	mt_div_table(pc),a0
l_mt_init_div
	move.l	d1,d2
	lsl	#6,d2
	move	d0,d3
	divu	d0,d2
	lsr	#1,d3
	negx	d3
	neg	d3
	move	d2,d4
	swap	d2
	cmp	d3,d2
	blt.s	l_mt_no_round3
	addq	#1,d4
l_mt_no_round3

	lsl	#8,d4

	move	d4,(a0)+
	addq	#1,d0
	cmp	#$41,d0
	bne.s	l_mt_init_div
	moveq	#1,d0
	addq	#1,d1
	cmp	#$41,d1
	bne.s	l_mt_init_div
	moveq	#0,d1
mt_make_dtab_rts
	rts
***************************************************************************

***************************************************************************
*
*	mt_make_mixcode	generates the mixer code
*
* CHANGES(X)/USES(u):
* 	 D0   D1   D2   D3   D4   D5   D6   D7  A0 A1 A2 A3 A4 A5 A6 A7 US
*	XXXX XXXX XXXX      XXXX XXXX XXXX XXXX XX XX XX XX XX    XX uu --
***************************************************************************
mt_make_mixcode
	lea	l_mt_ana_code(pc),a1
**	lea	l_mt_ana_code0(pc),a0
**	move.l	a0,(a1)+
**	lea	l_mt_ana_code1(pc),a0
**	move.l	a0,(a1)+
**	lea	l_mt_ana_code2(pc),a0
**	move.l	a0,(a1)+
**	lea	l_mt_ana_code3(pc),a0
**	move.l	a0,(a1)+
	lea	l_mt_ana_code0(pc),a0		0 0
	move.l	a0,(a1)+
	lea	l_mt_ana_code1(pc),a0		0 1
	move.l	a0,(a1)+
	lea	l_mt_ana_code1(pc),a0		0 2
	move.l	a0,(a1)+
	lea	l_mt_ana_code1(pc),a0		0 3
	move.l	a0,(a1)+
	lea	l_mt_ana_code2(pc),a0		1 0
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		1 1
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		1 2
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		1 3
	move.l	a0,(a1)+
	lea	l_mt_ana_code2(pc),a0		2 0
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		2 1
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		2 2
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		2 3
	move.l	a0,(a1)+
	lea	l_mt_ana_code2(pc),a0		3 0
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		3 1
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		3 2
	move.l	a0,(a1)+
	lea	l_mt_ana_code3(pc),a0		3 3
	move.l	a0,(a1)+

	lea	l_mt_ana_codej0(pc),a1
	lea	l_mt_ana_code000(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code001(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code002(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code003(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code010(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code011(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code012(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code013(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code020(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code021(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code022(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code023(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code030(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code031(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code032(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code033(pc),a0
	move.l	a0,(a1)+

	lea	l_mt_ana_codej1(pc),a1
	lea	l_mt_ana_code100(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code101(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code102(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code103(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code110(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code111(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code112(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code113(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code120(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code121(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code122(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code123(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code130(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code131(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code132(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code133(pc),a0
	move.l	a0,(a1)+

	lea	l_mt_ana_codej2(pc),a1
	lea	l_mt_ana_code200(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code201(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code202(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code203(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code210(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code211(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code212(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code213(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code220(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code221(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code222(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code223(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code230(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code231(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code232(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code233(pc),a0
	move.l	a0,(a1)+

	lea	l_mt_ana_codej3(pc),a1
	lea	l_mt_ana_code300(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code301(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code302(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code303(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code310(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code311(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code312(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code313(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code320(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code321(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code322(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code323(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code330(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code331(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code332(pc),a0
	move.l	a0,(a1)+
	lea	l_mt_ana_code333(pc),a0
	move.l	a0,(a1)+


**	move.l	#529*4,d0		529 pointers: 1 per case (23 * 23)
*	move.l	#625*4,d0		625 pointers: 1 per case (25 * 25)
	move.l	#24*256+25*4,d0		5518 bytes / 1546 pointers

	bsr	qmalloc
	tst.l	d0
	smi	d1
	bmi	mt_make_mcod_rts
	lea	mt_mixcode_p(pc),a1
	move.l	a0,(a1)
ll_mt_mixcode1
**	move.l	#61517*2,d0		61517 words of generated code
	move.l	#45539*2,d0		45539 words of generated code
	bsr	qmalloc
	tst.l	d0
	smi	d1
	bmi	mt_make_mcod_rts
	lea	mt_mixer_chunk(pc),a1
	move.l	a0,(a1)

	move.l	a0,a1
	move.l	mt_mixcode_p(pc),a0
*	move.l	mt_mixer_chunk(pc),a1

	move	z_volume_active(pc),d3		volume control active ?

	move.l	mt_freq_list(pc),a2
	lea	(a2),a4
**	moveq	#22,d7
**	moveq	#22,d6
	moveq	#24,d7
	moveq	#24,d6
l_mt_maker3
	move.l	a1,(a0)+
	lea	(a2),a3

**	moveq	#40-1,d5
	moveq	#20-1,d5			25 KHz => only 20 updates

ll_mt_make_it1
l_mt_make_it1
	move	l_mt_copy(pc),(a1)+
	move	(a3)+,d0
	move	(a4)+,d1

**	add	d1,d1
	add	d1,d1
	add	d1,d1				2 bits instead of 1 to handle 0, 1 and 2

	or	d1,d0
	dbne	d5,l_mt_make_it1
	tst	d5
	beq	l_mt_end_ops
	bpl	l_mt_no_exit
l_mt_make_end
	move	#$4ED6,(a1)+			JMP (A6)

	move	mt_frequency(pc),d0
	cmp	#1,d0
	bne.s	l_mt_no_lea_cor0

	cmp	#12,d6				insert space for LEA correction
	bcc.s	l_mt_make_end0			@ 12.5 KHz (speeds above 15)
	move	d6,d0				NOT to be executed @ 25 KHz or 50 KHz
	subq	#7,d0				addqs not inserted
	bpl.s	l_mt_make_end2
	moveq	#0,d0				speed 16/11:4 17/10:3 18/9:2 19/8:1 OTH:0
l_mt_make_end2
	add	d0,d0
	addq	#2,d0				+ LEA - last addq = extra space required
	add	d0,a1
l_mt_make_end0
	cmp	#12,d7
	bcc.s	l_mt_make_end1
	move	d7,d0
	subq	#7,d0				addqs not inserted
	bpl.s	l_mt_make_end3
	moveq	#0,d0				speed 16/11:4 17/10:3 18/9:2 19/8:1 OTH:0
l_mt_make_end3
	add	d0,d0
	addq	#2,d0				+ LEA - last addq = extra space required
	add	d0,a1
l_mt_make_end1

l_mt_no_lea_cor0

	dbf	d6,l_mt_maker3
**	moveq	#22,d6
	moveq	#24,d6
	lea	256-25*4(a0),a0

ll_mt_mixcode2
**	lea	80(a2),a2
	lea	40(a2),a2			new table size

	move.l	mt_freq_list(pc),a4
	dbf	d7,l_mt_maker3

	move	mt_frequency(pc),d0
	cmp	#1,d0
	bne.s	l_mt_no_lea_cor1

	bsr	mt_lea_correct			LEA correction @ 12.5 KHz

l_mt_no_lea_cor1

	moveq	#0,d1
mt_make_mcod_rts
	rts

l_mt_end_ops

**	cmp	#3,d0
**	beq.s	l_mt_ana_code03
**	cmp	#2,d0
**	beq.s	l_mt_ana_code02
*	cmp	#%1111,d0			3 3
*	beq	l_mt_ana_code033
*	cmp	#%1110,d0			3 2
*	beq	l_mt_ana_code032
*	cmp	#%1101,d0			3 1
*	beq	l_mt_ana_code031
*	cmp	#%1100,d0			3 0
*	beq	l_mt_ana_code030
*	cmp	#%1011,d0			2 3
*	beq	l_mt_ana_code023
*	cmp	#%1010,d0			2 2
*	beq	l_mt_ana_code022
*	cmp	#%1001,d0			2 1
*	beq	l_mt_ana_code021
*	cmp	#%1000,d0			2 0
*	beq	l_mt_ana_code020
*	cmp	#%0111,d0			1 3
*	beq	l_mt_ana_code013
*	cmp	#%0110,d0			1 2
*	beq	l_mt_ana_code012
*	cmp	#%0101,d0			1 1
*	beq	l_mt_ana_code011
*	cmp	#%0100,d0			1 0
*	beq.s	l_mt_ana_code010
*	cmp	#%0011,d0			0 3
*	beq.s	l_mt_ana_code003
*	cmp	#%0010,d0			0 2
*	beq.s	l_mt_ana_code002

	add	d0,d0
	add	d0,d0
	move.l	l_mt_ana_codej0(pc,d0),a6
	jmp	(a6)

l_mt_ana_codej0	ds.l	16

l_mt_ana_code000
	rts

l_mt_ana_code001
	lea	l_mt_copy(pc),a6		0 1	l_mt_ana_code01
	move	l_mt_copy2(pc),(a6)
	move	l_mt_ch0_fetch(pc),(a1)+
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end
*	move	#$4ed6,(a1)+
*	dbf	d6,l_mt_maker3
*	moveq	#22,d6
*	lea	80(a2),a2
*	move.l	mt_freq_list(pc),a4
*	dbf	d7,l_mt_maker3
*	moveq	#0,d1
*	rts

l_mt_ana_code002
	lea	l_mt_copy(pc),a6		0 2
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move	l_mt_ch0_fetch(pc),(a1)+
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code003
	lea	l_mt_copy(pc),a6		0 3
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move	l_mt_ch0_fetch(pc),(a1)+
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code010
	lea	l_mt_copy(pc),a6		1 0	l_mt_ana_code02
	move	l_mt_copy2(pc),(a6)
	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0100
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod0100
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end
*	move	#$4ed6,(a1)+
*	dbf	d6,l_mt_maker3
*	moveq	#22,d6
*	lea	80(a2),a2
*	move.l	mt_freq_list(pc),a4
*	dbf	d7,l_mt_maker3
*	moveq	#0,d1
*	rts

l_mt_ana_code020
	lea	l_mt_copy(pc),a6		2 0
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0200
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod0200
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code030
	lea	l_mt_copy(pc),a6		3 0
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0300
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod0300
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code011
	lea	l_mt_copy(pc),a6		1 1	l_mt_ana_code03
	move	l_mt_copy2(pc),(a6)
	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0110
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0110
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end
*	move	#$4ed6,(a1)+
*	dbf	d6,l_mt_maker3
*	moveq	#22,d6
*	lea	80(a2),a2
*	move.l	mt_freq_list(pc),a4
*	dbf	d7,l_mt_maker3
*	moveq	#0,d1
*	rts

l_mt_ana_code012
	lea	l_mt_copy(pc),a6		1 2
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0120
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0120
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code013
	lea	l_mt_copy(pc),a6		1 3
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0130
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0130
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code021
	lea	l_mt_copy(pc),a6		2 1
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0210
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0210
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code031
	lea	l_mt_copy(pc),a6		3 1
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0310
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0310
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end

l_mt_ana_code022
	lea	l_mt_copy(pc),a6		2 2
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0220
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0220
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end


l_mt_ana_code023
	lea	l_mt_copy(pc),a6		2 3
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0230
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0230
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end


l_mt_ana_code032
	lea	l_mt_copy(pc),a6		3 2
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0320
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0320
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end


l_mt_ana_code033
	lea	l_mt_copy(pc),a6		3 3
	move	l_mt_copy2(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod0330
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod0330
	move.l	l_mt_add012(pc),(a1)+
	dbf	d5,l_mt_make_it1
	bra	l_mt_make_end


l_mt_no_exit
	move.l	a3,-(sp)
	move.l	a4,-(sp)
	move	d5,d4
	subq	#1,d4

l_mt_analyse
	move	(a3)+,d1
	move	(a4)+,d2

**	add	d2,d2
	add	d2,d2
	add	d2,d2				2 bits instead of 1 to handle 0, 1 and 2

	or	d2,d1
	add	d1,d1
	add	d1,d1
	move.l	l_mt_ana_code(pc,d1),a6
	jsr	(a6)
	dbf	d4,l_mt_analyse
	move.l	(sp)+,a4
	move.l	(sp)+,a3
	tst	d1
	dbeq	d5,l_mt_make_it1
	bra	l_mt_end_ops
l_mt_ana_code
**	ds.l	4
	ds.l	16

l_mt_ana_code0
	rts

l_mt_ana_code1
**	cmp	#3,d0
**	beq.s	l_mt_ana_code13
**	cmp	#2,d0
**	beq.s	l_mt_ana_code12
*	cmp	#%1111,d0			3 3
*	beq	l_mt_ana_code133
*	cmp	#%1110,d0			3 2
*	beq	l_mt_ana_code132
*	cmp	#%1101,d0			3 1
*	beq	l_mt_ana_code131
*	cmp	#%1100,d0			3 0
*	beq	l_mt_ana_code130
*	cmp	#%1011,d0			2 3
*	beq	l_mt_ana_code123
*	cmp	#%1010,d0			2 2
*	beq	l_mt_ana_code122
*	cmp	#%1001,d0			2 1
*	beq	l_mt_ana_code121
*	cmp	#%1000,d0			2 0
*	beq	l_mt_ana_code120
*	cmp	#%0111,d0			1 3
*	beq	l_mt_ana_code113
*	cmp	#%0110,d0			1 2
*	beq	l_mt_ana_code112
*	cmp	#%0101,d0			1 1
*	beq	l_mt_ana_code111
*	cmp	#%0100,d0			1 0
*	beq.s	l_mt_ana_code110
*	cmp	#%0011,d0			0 3
*	beq.s	l_mt_ana_code103
*	cmp	#%0010,d0			0 2
*	beq.s	l_mt_ana_code102

	add	d0,d0
	add	d0,d0
	move.l	l_mt_ana_codej1(pc,d0),a6
	jmp	(a6)

l_mt_ana_codej1	ds.l	16

l_mt_ana_code100
	rts

l_mt_ana_code101
	moveq	#0,d4				0 1	l_mt_ana_code11
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)
	move	l_mt_ch0_fetch(pc),(a1)+
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code102
	moveq	#0,d4				0 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move	l_mt_ch0_fetch(pc),(a1)+
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code103
	moveq	#0,d4				0 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move	l_mt_ch0_fetch(pc),(a1)+
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code110
	moveq	#0,d4				1 0	l_mt_ana_code12
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)
	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1100
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod1100
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code120
	moveq	#0,d4				2 0
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1200
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod1200
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code130
	moveq	#0,d4				3 0
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1300
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod1300
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code111
	moveq	#0,d4				1 1	l_mt_ana_code13
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)
	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1110
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1110
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code112
	moveq	#0,d4				1 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1120
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1120
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code113
	moveq	#0,d4				1 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1130
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1130
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code121
	moveq	#0,d4				2 1
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1210
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1210
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code131
	moveq	#0,d4				3 1
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1310
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1310
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code122
	moveq	#0,d4				2 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1220
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1220
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code123
	moveq	#0,d4				2 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1230
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1230
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code132
	moveq	#0,d4				3 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1320
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1320
	move	l_mt_add10(pc),(a1)+
	rts

l_mt_ana_code133
	moveq	#0,d4				3 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod1330
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod1330
	move	l_mt_add10(pc),(a1)+
	rts


l_mt_ana_code2
**	cmp	#3,d0
**	beq.s	l_mt_ana_code23
**	cmp	#2,d0
**	beq.s	l_mt_ana_code22
*	cmp	#%1111,d0			3 3
*	beq	l_mt_ana_code233
*	cmp	#%1110,d0			3 2
*	beq	l_mt_ana_code232
*	cmp	#%1101,d0			3 1
*	beq	l_mt_ana_code231
*	cmp	#%1100,d0			3 0
*	beq	l_mt_ana_code230
*	cmp	#%1011,d0			2 3
*	beq	l_mt_ana_code223
*	cmp	#%1010,d0			2 2
*	beq	l_mt_ana_code222
*	cmp	#%1001,d0			2 1
*	beq	l_mt_ana_code221
*	cmp	#%1000,d0			2 0
*	beq	l_mt_ana_code220
*	cmp	#%0111,d0			1 3
*	beq	l_mt_ana_code213
*	cmp	#%0110,d0			1 2
*	beq	l_mt_ana_code212
*	cmp	#%0101,d0			1 1
*	beq	l_mt_ana_code211
*	cmp	#%0100,d0			1 0
*	beq.s	l_mt_ana_code210
*	cmp	#%0011,d0			0 3
*	beq.s	l_mt_ana_code203
*	cmp	#%0010,d0			0 2
*	beq.s	l_mt_ana_code202

	add	d0,d0
	add	d0,d0
	move.l	l_mt_ana_codej2(pc,d0),a6
	jmp	(a6)

l_mt_ana_codej2	ds.l	16

l_mt_ana_code200
	rts

l_mt_ana_code201
	moveq	#0,d4				0 1	l_mt_ana_code21
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)
	move	l_mt_ch0_fetch(pc),(a1)+
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code202
	moveq	#0,d4				0 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move	l_mt_ch0_fetch(pc),(a1)+
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code203
	moveq	#0,d4				0 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move	l_mt_ch0_fetch(pc),(a1)+
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code210
	moveq	#0,d4				1 0	l_mt_ana_code22
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)
	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2100
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod2100
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code220
	moveq	#0,d4				2 0
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2200
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod2200
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code230
	moveq	#0,d4				3 0
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	move	l_mt_ch1_fetch(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2300
	move.l	l_mt_ch1_fetch+2(pc),(a1)+
l_mt_ana_cod2300
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code211
	moveq	#0,d4				1 1	l_mt_ana_code23
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)
	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2110
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2110
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code212
	moveq	#0,d4				1 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2120
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2120
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code213
	moveq	#0,d4				1 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2130
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2130
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code221
	moveq	#0,d4				2 1
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2210
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2210
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code231
	moveq	#0,d4				3 1
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2310
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2310
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code222
	moveq	#0,d4				2 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2220
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2220
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code223
	moveq	#0,d4				2 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2230
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2230
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code232
	moveq	#0,d4				3 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2320
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2320
	move	l_mt_add01(pc),(a1)+
	rts

l_mt_ana_code233
	moveq	#0,d4				3 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	move.l	l_mt_ch01fetadd1(pc),(a1)+
	tst.b	d3
	beq.s	l_mt_ana_cod2330
	move.l	l_mt_ch01fetadd1+4(pc),(a1)+
l_mt_ana_cod2330
	move	l_mt_add01(pc),(a1)+
	rts


l_mt_ana_code3
**	cmp	#3,d0
**	beq.s	l_mt_ana_code33
**	cmp	#2,d0
**	beq.s	l_mt_ana_code32
*	cmp	#%1111,d0			3 3
*	beq	l_mt_ana_code333
*	cmp	#%1110,d0			3 2
*	beq	l_mt_ana_code332
*	cmp	#%1101,d0			3 1
*	beq	l_mt_ana_code331
*	cmp	#%1100,d0			3 0
*	beq	l_mt_ana_code330
*	cmp	#%1011,d0			2 3
*	beq	l_mt_ana_code323
*	cmp	#%1010,d0			2 2
*	beq	l_mt_ana_code322
*	cmp	#%1001,d0			2 1
*	beq	l_mt_ana_code321
*	cmp	#%1000,d0			2 0
*	beq	l_mt_ana_code320
*	cmp	#%0111,d0			1 3
*	beq	l_mt_ana_code313
*	cmp	#%0110,d0			1 2
*	beq	l_mt_ana_code312
*	cmp	#%0101,d0			1 1
*	beq	l_mt_ana_code311
*	cmp	#%0100,d0			1 0
*	beq.s	l_mt_ana_code310
*	cmp	#%0011,d0			0 3
*	beq.s	l_mt_ana_code303
*	cmp	#%0010,d0			0 2
*	beq.s	l_mt_ana_code302

	add	d0,d0
	add	d0,d0
	move.l	l_mt_ana_codej3(pc,d0),a6
	jmp	(a6)

l_mt_ana_codej3	ds.l	16

l_mt_ana_code300
	rts

l_mt_ana_code301
	moveq	#0,d4				0 1	l_mt_ana_code31
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)
	move	l_mt_ch0_fet_add(pc),(a1)+
	rts

l_mt_ana_code302
	moveq	#0,d4				0 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	move	l_mt_ch0_fet_add(pc),(a1)+
	rts

l_mt_ana_code303
	moveq	#0,d4				0 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy1(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	move	l_mt_ch0_fet_add(pc),(a1)+
	rts

l_mt_ana_code310
	moveq	#0,d4				1 0	l_mt_ana_code32
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)
	tst.b	d3
	beq.s	l_mt_ana_cod3100
	move	l_mt_ch1_fet_add(pc),(a1)+
	move.l	l_mt_ch1_fet_add+2(pc),(a1)+
	bra.s	l_mt_ana_cod3101
l_mt_ana_cod3100
	move	l_mt_ch1_fet_ad2(pc),(a1)+
l_mt_ana_cod3101
	rts

l_mt_ana_code320
	moveq	#0,d4				2 0
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3200
	move	l_mt_ch1_fet_add(pc),(a1)+
	move.l	l_mt_ch1_fet_add+2(pc),(a1)+
	bra.s	l_mt_ana_cod3201
l_mt_ana_cod3200
	move	l_mt_ch1_fet_ad2(pc),(a1)+
l_mt_ana_cod3201
	rts

l_mt_ana_code330
	moveq	#0,d4				3 0
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3300
	move	l_mt_ch1_fet_add(pc),(a1)+
	move.l	l_mt_ch1_fet_add+2(pc),(a1)+
	bra.s	l_mt_ana_cod3301
l_mt_ana_cod3300
	move	l_mt_ch1_fet_ad2(pc),(a1)+
l_mt_ana_cod3301
	rts

l_mt_ana_code311
	moveq	#0,d4				1 1	l_mt_ana_code33
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)
	tst.b	d3
	beq.s	l_mt_ana_cod3110
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3111
l_mt_ana_cod3110
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3111
	rts

l_mt_ana_code312
	moveq	#0,d4				1 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3120
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3121
l_mt_ana_cod3120
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3121
	rts

l_mt_ana_code313
	moveq	#0,d4				1 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3130
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3131
l_mt_ana_cod3130
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3131
	rts

l_mt_ana_code321
	moveq	#0,d4				2 1
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq1(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3210
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3211
l_mt_ana_cod3210
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3211
	rts

l_mt_ana_code331
	moveq	#0,d4				3 1
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq21(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3310
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3311
l_mt_ana_cod3310
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3311
	rts

l_mt_ana_code322
	moveq	#0,d4				2 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3220
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3221
l_mt_ana_cod3220
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3221
	rts

l_mt_ana_code323
	moveq	#0,d4				2 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq1(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3230
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3231
l_mt_ana_cod3230
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3231
	rts

l_mt_ana_code332
	moveq	#0,d4				3 2
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq0(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3320
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3321
l_mt_ana_cod3320
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3321
	rts

l_mt_ana_code333
	moveq	#0,d4				3 3
	moveq	#1,d1
	lea	l_mt_copy(pc),a6
	move	l_mt_copy0(pc),(a6)

	move	l_mt_addq20(pc),(a1)+
	move	l_mt_addq21(pc),(a1)+

	tst.b	d3
	beq.s	l_mt_ana_cod3330
	move.l	l_mt_ch01fetadd0(pc),(a1)+
	move.l	l_mt_ch01fetadd0+4(pc),(a1)+
	bra.s	l_mt_ana_cod3331
l_mt_ana_cod3330
	move.l	l_mt_ch01fetadd2(pc),(a1)+
l_mt_ana_cod3331
	rts


mt_lea_correct
	move.l	mt_mixcode_p(pc),a1	LEA correction @ 12.5 KHz only
	moveq	#24,d7
l_mt_lea_corr0
	moveq	#24,d6
l_mt_lea_corr1
	move.l	(a1)+,a0
	cmp	#12,d7
	scs	d5			set if below 12 (speeds 16-27)
	cmp	#12,d6
	scs	d4			set if below 12 (speeds 16-27)
	move.b	d4,d0
	or.b	d5,d0			any speed in 16..25 range ?
	beq	l_mt_lea_corr9		yes / no => do nothing
	lea	l_mt_code_buf(pc),a2
	lea	(a0),a3
	moveq	#90,d0
l_mt_lea_corr2
	move	(a3)+,(a2)+		copy code to local buffer
	dbf	d0,l_mt_lea_corr2
	moveq	#0,d3			LEA offset 0
	moveq	#0,d2			LEA offset 1
	lea	l_mt_code_buf(pc),a2

	moveq	#0,d1			no updates
l_mt_lea_corr3
	cmp.b	#$4E,(a2)		JMP ?
	beq	l_mt_lea_corr5		no / yes => job ended
	cmp.b	#$48,1(a2)		ADDQ #xx,A0
	beq.s	l_mt_lea_addq0
	cmp.b	#$49,1(a2)		ADDQ #xx,A1
	beq.s	l_mt_lea_addq1
	cmp	#$1018,(a2)		MOVE.B (A0)+,D0
	beq.s	l_mt_lea_mova0
	cmp	#$1219,(a2)		MOVE.B (A1)+,D1
	beq.s	l_mt_lea_mova1
	cmp	#$D218,(a2)		ADD.B (A0)+,D1
	beq.s	l_mt_lea_adda0
	cmp	#$D019,(a2)		ADD.B (A1)+,D0
	beq	l_mt_lea_adda1
	cmp.b	#$1E,(a2)		update ?
	bne.s	l_mt_lea_corr4		yes / no
	addq	#1,d1
l_mt_lea_corr4
	move	(a2)+,d0
l_mt_lea_copy
	move	d0,(a0)+		copy as it is
	bra.s	l_mt_lea_corr3

l_mt_lea_addq0
	moveq	#0,d0
	move.b	(a2),d0
	sub.b	#$50,d0
	lsr	#1,d0
	add	d0,d3			correct offset
	move	(a2)+,d0
	tst.b	d5			correct this one ?
	bne.s	l_mt_lea_corr3		no / yes
	bra.s	l_mt_lea_copy
l_mt_lea_addq1
	moveq	#0,d0
	move.b	(a2),d0
	sub.b	#$50,d0
	lsr	#1,d0
	add	d0,d2			correct offset
	move	(a2)+,d0
	tst.b	d4			correct this one ?
	bne.s	l_mt_lea_corr3		no / yes
	bra.s	l_mt_lea_copy
l_mt_lea_mova0
	move	(a2)+,d0
	tst.b	d5
	beq.s	l_mt_lea_copy
	cmp	#10,d1			last update ?
	beq.s	l_mt_insleacp0
	move	#$1028,(a0)+		MOVE.B $xxxx(A0),D0
	move	d3,(a0)+		$xxxx
	addq	#1,d3			old ( )+ update
	bra.s	l_mt_lea_corr3
l_mt_insleacp0
	move	#$41E8,(a0)+		LEA $xxxx(A0),A0
	move	d3,(a0)+		$xxxx
	bra.s	l_mt_lea_copy
l_mt_lea_mova1
	move	(a2)+,d0
	tst.b	d4
	beq.s	l_mt_lea_copy
	cmp	#10,d1			last update ?
	beq.s	l_mt_insleacp1
	move	#$1229,(a0)+		MOVE.B $xxxx(A1),D1
	move	d2,(a0)+		$xxxx
	addq	#1,d2			old ( )+ update
	bra	l_mt_lea_corr3
l_mt_insleacp1
	move	#$43E9,(a0)+		LEA $xxxx(A1),A1
	move	d2,(a0)+		$xxxx
	bra.s	l_mt_lea_copy
l_mt_lea_adda0
	move	(a2)+,d0
	tst.b	d5
	beq.s	l_mt_lea_copy
	cmp	#10,d1			last update ?
	beq.s	l_mt_insleacp0
	move	#$D228,(a0)+		ADD.B $xxxx(A0),D1
	move	d3,(a0)+		$xxxx
	addq	#1,d3			old ( )+ update
	bra	l_mt_lea_corr3
l_mt_lea_adda1
	move	(a2)+,d0
	tst.b	d4
	beq	l_mt_lea_copy
	cmp	#10,d1			last update ?
	beq.s	l_mt_insleacp1
	move	#$D029,(a0)+		ADD.B $xxxx(A1),D0
	move	d2,(a0)+		$xxxx
	addq	#1,d2			old ( )+ update
	bra	l_mt_lea_corr3

l_mt_lea_corr5
	move	(a2)+,(a0)+		copy JMP

l_mt_lea_corr9
	dbf	d6,l_mt_lea_corr1
	lea	256-25*4(a1),a1
	dbf	d7,l_mt_lea_corr0
	rts

l_mt_code_buf	ds	91	Max = JMP(1W) + 10x(1UPD + 2ADDQ + 1RDA0 + 3RDA1 + 2MOVADD)


l_mt_copy
	move.b	d2,(sp)+
l_mt_copy0
	move.b	d0,(sp)+
l_mt_copy1
	move.b	d1,(sp)+
l_mt_copy2
	move.b	d2,(sp)+

l_mt_ch0_fetch
	move.b	(a0)+,d0
l_mt_ch0_fet_add
	add.b	(a0)+,d1
l_mt_ch1_fetch
	move.b	(a1)+,d1
	move.l	d1,a2
	move.b	(a2),d1
l_mt_ch1_fet_add
	move.b	(a1)+,d1
	move.l	d1,a2
	add.b	(a2),d0
l_mt_ch1_fet_ad2
	add.b	(a1)+,d0
l_mt_ch01fetadd0
	move.b	(a0)+,d0
	move.b	(a1)+,d1
	move.l	d1,a2
	add.b	(a2),d0
l_mt_ch01fetadd2
	move.b	(a0)+,d0
	add.b	(a1)+,d0
l_mt_ch01fetadd1
	move.b	(a0)+,d0
	move.b	(a1)+,d1
	move.l	d1,a2
	move.b	(a2),d1
l_mt_add01
	add.b	d0,d1
l_mt_add10
	add.b	d1,d0
l_mt_add012
	move.b	d0,d2
	add.b	d1,d2
l_mt_addq0
	addq	#1,a0				new 25 KHz
l_mt_addq1
	addq	#1,a1				new 25 KHz
l_mt_addq20
	addq	#2,a0				new 12.5 KHz
l_mt_addq21
	addq	#2,a1				new 12.5 KHz

***************************************************************************
***************************************************************************

***************************************************************************
***************************************************************************
*
*	mt_end	to quit
*
***************************************************************************
***************************************************************************
mt_end
	bsr	mt_stop_Paula
	rts

mt_stop_Paula
	move.l	mt_save_trap0(pc),$80.w

	move	mt_LCM_mask(pc),d0
	move	mt_LCM_left(pc),d1
	or	#$14,d1
	bsr	l_mt_set_LCM
	move	mt_LCM_right(pc),d1
	or	#$14,d1
	bsr	l_mt_set_LCM
	rts

l_mt_set_LCM
	lea	$FFFF8900.w,a6
	move	d0,$24(a6)
	move	d1,$22(a6)

*	rept	16
*	nop
*	endr
	or.l	d0,d0				8 cycles each
	or.l	d0,d0
	or.l	d0,d0
	or.l	d0,d0
	or.l	d0,d0
	or.l	d0,d0
	or.l	d0,d0
	or.l	d0,d0

l_mt_LCM_loop
	cmp	$24(a6),d0
	bne.s	l_mt_LCM_loop
	rts

***************************************************************************
***************************************************************************


***************************************************************************
***************************************************************************
*
*	mt_Paula		The BIG GIRL
*
***************************************************************************
***************************************************************************
mt_frame_play
	movem.l	d0-d1/a0-a1,-(sp)
	lea	mt_trash_status(pc),a1
	lea	mt_trash_rd_idx(pc),a0
	move	(a0),d0
	move.b	#0,0(a1,d0)			set to ready-for-write
	addq	#1,d0
	cmp	z_trash_idx(pc),d0
	bcs.s	l_mt_frame_next
	sub	z_trash_idx(pc),d0
l_mt_frame_next
	move	d0,(a0)				update next index
	move.b	0(a1,d0),d0			available for read ?
	bne.s	l_mt_frame_go			no => out of data !!! / yes
	lea	mt_trash_oodata(pc),a0
	st	(a0)
	bra.s	l_mt_frame_end
l_mt_frame_go
	bsr.s	mt_Paula
l_mt_frame_end
	movem.l	(sp)+,d0-d1/a0-a1
	rts

mt_Paula:
	lea	$FFFF8900.w,a1
	lea	mt_trash_str(pc),a0
	move	mt_trash_rd_idx(pc),d0
	lsl	#3,d0
	add	d0,a0
	move.l	(a0)+,d1		digi buffer pointer
	move	(a0)+,d0		left volume
	bmi.s	l_mt_set_pointer	if < 0 => no change
	move	mt_LCM_mask(pc),$24(a1)
	add	d0,d0
	move	lmt_LCM_vol_tab0(pc,d0),d0
	or	mt_LCM_left(pc),d0
	move	d0,$22(a1)
l_mt_set_pointer
	movep.l	d1,$1(a1)
	add.l	mt_replay_len(pc),d1
	movep.l	d1,$d(a1)
	move	mt_frequency(pc),$20(a1)
	move	mt_start(pc),(a1)
	move	(a0)+,d0		right volume
	bmi.s	l_mt_no_right		if < 0 => no change
	move	mt_LCM_mask(pc),d1
	add	d0,d0
	move	lmt_LCM_vol_tab0(pc,d0),d0
	or	mt_LCM_right(pc),d0
l_mt_wait_LCM
	cmp	$24(a1),d1
	bne.s	l_mt_wait_LCM
	move	d0,$22(a1)
l_mt_no_right
	rts

lmt_LCM_vol_tab0
	dc.w	0
	dc.w	2,5,7,8,9,10,10,11,11,12,12,13,13,13,14,14
	dc.w	14,14,15,15,15,15,16,16,16,16,16,16,17,17,17,17
	dc.w	17,17,17,18,18,18,18,18,18,18,18,18,18,19,19,19
	dc.w	19,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20


***************************************************************************
*
*	mt_mixer	main mixer part
*
***************************************************************************
mt_mixer:
	lea	mt_save_SSP(pc),a0
	move.l	sp,(a0)			Save Supervisor Stack Pointer
	pea	mt_emulate(pc)		mt_emulate for return address
	move	sr,d0
	andi	#$0FFF,d0		Status Register with User mode set
	move	d0,-(sp)		new Status Register for next code
	rte				Load new SR and mt_emulate as PC
*					So from here we go to mt_emulate
*					in User mode to allow interrupts


mt_emulate
	lea	mt_save_USP(pc),a0
	move.l	sp,(a0)

**	move.l	mt_logic_buf(pc),sp
	lea	mt_trash_str(pc),a5
	move	mt_trash_wt_idx(pc),d0
	lsl	#3,d0
	add	d0,a5
	move.l	(a5),sp

	lea	mt_channel_p(pc),a0
	move.l	(a0),a3				voice 0 data
	move.l	12(a0),a4			voice 3 data

*					mt_channel03	mt_channel
*					mt_channel	macro

	move.l	(a3),d0				sample pointer voice 0
	bne.s	l_mt_v0_active			= 0 ? yes / no
	lea	mt_dummy_tab(pc),a3
l_mt_v0_active
	move.l	(a4),d0				sample pointer voice 3
	bne.s	l_mt_v3_active			= 0 ? yes / no
	lea	mt_dummy_tab(pc),a4
l_mt_v3_active
	move	z_volume_active(pc),d0		volume control active ?
	seq	4(a5)				set if not active
	beq.s	l_mt_st_mix03
	move	mt_volume(a3),d0		volume voice 0
	cmp	mt_volume(a4),d0		< volume voice 3
	bge.s	l_mt_no_swap03			no / yes
	exg	a3,a4				switch data pointers
l_mt_no_swap03
	move	mt_volume(a3),d0		bigger volume
	lea	mt_left_volume(pc),a1
	move	d0,(a1)				store it
	move	d0,4(a5)			store it in trash data
	lea	mt_left_volold(pc),a1		compare to old value
	cmp	(a1),d0
	seq	4(a5)				disable LCM update if equal
	move	d0,(a1)				store as old value
	
	moveq	#0,d1				volume table offset = 0
	tst	d0				bigger volume = 0 ?
	beq.s	l_mt_set_zero10			no / yes
	move	mt_volume(a4),d1		smaller volume = 0 ?
	beq.s	l_mt_set_zero10			no / yes
	subq	#1,d0				bigger volume - 1: 0..63
	subq	#1,d1				smaller volume - 1: 0..63
	and	#$003F,d0			security AND
	and	#$003F,d1			security AND
	lsl	#6,d1				x 64
	or	d0,d1				merge volume values: 0..4095
	add	d1,d1				x 2 for .word access
	move.l	mt_div_table(pc),a1		relative volume table
	move	0(a1,d1),d1			get relative volume x 256
l_mt_set_zero10
	add.l	mt_volume_tab(pc),d1		pointer to set of volume tables
l_mt_st_mix03

*	move.l	mt_sample_point(a3),a0		Sample 0 pointer
*	move.l	mt_sample_point(a4),a1		Sample 1 pointer
	move.l	(a3),a0
	move.l	(a4),a1
	lea	mt_left_temp(pc),a6
	lea	mt_temp_old_sam(a6),a2
	move.b	(a2)+,d0			Digi data 0
	move.b	(a2)+,d1			Digi data 1
	move.b	(a2)+,d2			Digi data for update

	move	mt_period(a3),d3		Period 0
	move.l	mt_freq_table(pc),a2
	add	d3,d3
	add	d3,d3
	move.l	0(a2,d3),d3			long VBL step
	move	d3,d4				coma part
	swap	d3				integer part
	add	mt_add_iw(a3),d4		add previous coma rest
	negx	d3				addx to d3
	neg	d3				= bytes to read this time
	move	d4,mt_add_iw(a3)		store coma part left

	move	mt_period(a4),d4		Period 1
	add	d4,d4
	add	d4,d4
	move.l	0(a2,d4),d4			long VBL step
	move	d4,d5				coma part
	swap	d4				integer part
	add	mt_add_iw(a4),d5		add previous coma rest
	negx	d4				addx to d4
	neg	d4				= bytes to read this time
	move	d5,mt_add_iw(a4)		store coma part left

	move.l	mt_frame_freq_p(pc),a2		read speed sequence table
	add	d3,d3
	add	d3,d3
	move.l	0(a2,d3),d3			read speed sequence 0 
	add	d4,d4
	add	d4,d4
	move.l	0(a2,d4),d4			read speed sequence 1

	move.l	a3,d5				save data pointer 0
	move.l	a4,d6				save data pointer 1
	move.l	a6,d7				Left_temp pointer save
	move.l	d3,a3
	move.l	d4,a4
	move.l	mt_mixcode_p(pc),a5

****************************************************************
*			A0	Sample 0 pointer
*			A1	Sample 1 pointer
*			A2	Jump to pointer / all pupose
*			A3	Variable speed 0 pointer
*			A4	Variable speed 1 pointer
*			A5	Variable speeds mix pointer
*			A6	Return jump pointer
*			A7	STE Digi buffer pointer
*			D0.b	Digi data
*			D1	Volume pointer + Digi data
*			D2.b	Digi data
*			D0.hw/D2.hw/D3/D4/		Free
*			D5	Data pointer 0 save
*			D6	Data pointer 1 save
*			D7	Left/Right_temp pointer save
****************************************************************

	lea	l_mt_return03(pc),a6			frame 00
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)
l_mt_return03
*	rept	24
*	lea	$10(a6),a6
*	move	(a3)+,d3
*	move	(a4)+,d4
*	move.b	d4,d3
*	move.l	0(a5,d3),a2
*	jmp	(a2)
*	endr

	lea	$10(a6),a6				frame 01
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 02
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 03
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 04
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 05
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 06
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 07
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 08
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 09
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 10
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 11
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 12
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 13
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 14
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 15
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 16
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 17
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 18
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 19
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 20
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 21
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 22
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 23
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 24
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	move.l	d7,a6
	move.l	d6,a4
	move.l	d5,a3
	lea	mt_temp_old_sam(a6),a2
	move.b	d0,(a2)+
	move.b	d1,(a2)+
	move.b	d2,(a2)+

	cmp.l	mt_sample_end(a3),a0
	blt.s	l_mt_updatev03_0
	move.l	mt_loop_size(a3),d0
	bne.s	l_mt_loop_v03_0
	move	mt_check_dummy(a3),d0
	bne.s	l_mt_end_v03_0
	moveq	#0,d0
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	bra.s	l_mt_end_v03_0
l_mt_loop_v03_0
	sub.l	d0,a0
l_mt_updatev03_0
	move.l	a0,(a3)
*	move.l	a0,mt_sample_point(a3)
l_mt_end_v03_0

	cmp.l	mt_sample_end(a4),a1
	blt.s	l_mt_updatev03_1
	move.l	mt_loop_size(a4),d0
	bne.s	l_mt_loop_v03_1
	move	mt_check_dummy(a4),d0
	bne.s	l_mt_end_v03_1
	moveq	#0,d0
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	bra.s	l_mt_end_v03_1
l_mt_loop_v03_1
	sub.l	d0,a1
l_mt_updatev03_1
	move.l	a1,(a4)
*	move.l	a1,mt_sample_point(a4)
l_mt_end_v03_1

	lea	mt_dummy_tab(pc),a3
	move.l	4(a3),(a3)
*						endm


**	move.l	mt_logic_buf(pc),sp
	lea	mt_trash_str(pc),a5
	move	mt_trash_wt_idx(pc),d0
	lsl	#3,d0
	add	d0,a5
	move.l	(a5),sp
	addq	#1,sp

	lea	mt_channel_p(pc),a0
	move.l	4(a0),a3			voice 1 data
	move.l	8(a0),a4			voice 2 data

*					mt_channel12	mt_channel
*					mt_channel	macro

	move.l	(a3),d0				sample pointer voice 1
	bne.s	l_mt_v1_active			= 0 ? yes / no
	lea	mt_dummy_tab(pc),a3
l_mt_v1_active
	move.l	(a4),d0				sample pointer voice 2
	bne.s	l_mt_v2_active			= 0 ? yes / no
	lea	mt_dummy_tab(pc),a4
l_mt_v2_active
	move	z_volume_active(pc),d0		volume control active ?
	seq	6(a5)				set if not active
	beq.s	l_mt_st_mix12
	move	mt_volume(a3),d0		volume voice 1
	cmp	mt_volume(a4),d0		< volume voice 2
	bge.s	l_mt_no_swap12			no / yes
	exg	a3,a4				switch data pointers
l_mt_no_swap12
	move	mt_volume(a3),d0		bigger volume
	lea	mt_right_volume(pc),a1
	move	d0,(a1)				store it
	move	d0,6(a5)			store it in trash data
	lea	mt_right_volold(pc),a1		compare to old value
	cmp	(a1),d0
	seq	6(a5)				disable LCM update if equal
	move	d0,(a1)				store as old value
	
	moveq	#0,d1				volume table offset = 0
	tst	d0				bigger volume = 0 ?
	beq.s	l_mt_set_zero11			no / yes
	move	mt_volume(a4),d1		smaller volume = 0 ?
	beq.s	l_mt_set_zero11			no / yes
	subq	#1,d0				bigger volume - 1: 0..63
	subq	#1,d1				smaller volume - 1: 0..63
	and	#$003F,d0			security AND
	and	#$003F,d1			security AND
	lsl	#6,d1				x 64
	or	d0,d1				merge volume values: 0..4095
	add	d1,d1				x 2 for .word access
	move.l	mt_div_table(pc),a1		relative volume table
	move	0(a1,d1),d1			get relative volume x 256
l_mt_set_zero11
	add.l	mt_volume_tab(pc),d1		pointer to set of volume tables
l_mt_st_mix12

*	move.l	mt_sample_point(a3),a0		Sample 0 pointer
*	move.l	mt_sample_point(a4),a1		Sample 1 pointer
	move.l	(a3),a0
	move.l	(a4),a1
	lea	mt_right_temp(pc),a6
	lea	mt_temp_old_sam(a6),a2
	move.b	(a2)+,d0			Digi data 0
	move.b	(a2)+,d1			Digi data 1
	move.b	(a2)+,d2			Digi data for update

	move	mt_period(a3),d3		Period 0
	move.l	mt_freq_table(pc),a2
	add	d3,d3
	add	d3,d3
	move.l	0(a2,d3),d3			long VBL step
	move	d3,d4				coma part
	swap	d3				integer part
	add	mt_add_iw(a3),d4		add previous coma rest
	negx	d3				addx to d3
	neg	d3				= bytes to read this time
	move	d4,mt_add_iw(a3)		store coma part left

	move	mt_period(a4),d4		Period 1
	add	d4,d4
	add	d4,d4
	move.l	0(a2,d4),d4			long VBL step
	move	d4,d5				coma part
	swap	d4				integer part
	add	mt_add_iw(a4),d5		add previous coma rest
	negx	d4				addx to d4
	neg	d4				= bytes to read this time
	move	d5,mt_add_iw(a4)		store coma part left

	move.l	mt_frame_freq_p(pc),a2		read speed sequence table
	add	d3,d3
	add	d3,d3
	move.l	0(a2,d3),d3			read speed sequence 0 
	add	d4,d4
	add	d4,d4
	move.l	0(a2,d4),d4			read speed sequence 1

	move.l	a3,d5				save data pointer 0
	move.l	a4,d6				save data pointer 1
	move.l	a6,d7				Right_temp pointer save
	move.l	d3,a3
	move.l	d4,a4
	move.l	mt_mixcode_p(pc),a5

****************************************************************
*			A0	Sample 0 pointer
*			A1	Sample 1 pointer
*			A2	Jump to pointer / all pupose
*			A3	Variable speed 0 pointer
*			A4	Variable speed 1 pointer
*			A5	Variable speeds mix pointer
*			A6	Return jump pointer
*			A7	STE Digi buffer pointer
*			D0.b	Digi data
*			D1	Volume pointer + Digi data
*			D2.b	Digi data
*			D0.hw/D2.hw/D3/D4/		Free
*			D5	Data pointer 0 save
*			D6	Data pointer 1 save
*			D7	Left/Right_temp pointer save
****************************************************************

	lea	l_mt_return12(pc),a6			frame 00
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)
l_mt_return12
*	rept	24
*	lea	$10(a6),a6
*	move	(a3)+,d3
*	move	(a4)+,d4
*	move.b	d4,d3
*	move.l	0(a5,d3),a2
*	jmp	(a2)
*	endr

	lea	$10(a6),a6				frame 01
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 02
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 03
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 04
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 05
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 06
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 07
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 08
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 09
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 10
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 11
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 12
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 13
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 14
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 15
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 16
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 17
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 18
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 19
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 20
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 21
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 22
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 23
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	lea	$10(a6),a6				frame 24
	move	(a3)+,d3
	move	(a4)+,d4
	move.b	d4,d3
	move.l	0(a5,d3),a2
	jmp	(a2)

	move.l	d7,a6
	move.l	d6,a4
	move.l	d5,a3
	lea	mt_temp_old_sam(a6),a2
	move.b	d0,(a2)+
	move.b	d1,(a2)+
	move.b	d2,(a2)+

	cmp.l	mt_sample_end(a3),a0
	blt.s	l_mt_updatev12_0
	move.l	mt_loop_size(a3),d0
	bne.s	l_mt_loop_v12_0
	move	mt_check_dummy(a3),d0
	bne.s	l_mt_end_v12_0
	moveq	#0,d0
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	bra.s	l_mt_end_v12_0
l_mt_loop_v12_0
	sub.l	d0,a0
l_mt_updatev12_0
	move.l	a0,(a3)
*	move.l	a0,mt_sample_point(a3)
l_mt_end_v12_0

	cmp.l	mt_sample_end(a4),a1
	blt.s	l_mt_updatev12_1
	move.l	mt_loop_size(a4),d0
	bne.s	l_mt_loop_v12_1
	move	mt_check_dummy(a4),d0
	bne.s	l_mt_end_v12_1
	moveq	#0,d0
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	move.l	d0,(a4)+
	bra.s	l_mt_end_v12_1
l_mt_loop_v12_1
	sub.l	d0,a1
l_mt_updatev12_1
	move.l	a1,(a4)
*	move.l	a1,mt_sample_point(a4)
l_mt_end_v12_1

	lea	mt_dummy_tab(pc),a3
	move.l	4(a3),(a3)
*						endm


	move.l	mt_save_USP(pc),sp
	trap	#0


***************************************************************************
*
*	mt_return_Paula		This is the trap #0 handler
*
***************************************************************************
mt_return_Paula
**	lea	mt_physic_buf(pc),a0	switch buffers
**	lea	mt_logic_buf(pc),a1
**	move.l	(a0),d0
**	move.l	(a1),(a0)
**	move.l	d0,(a1)
	move.l	mt_save_SSP(pc),sp	set Supervisor SP
	rts				go back in Supervisor (no rte done)

***************************************************************************

mt_bpm_counter	ds.l	1
mt_read_pbm	ds.w	1
mt_vbl_frames	dc.w	25
mt_frames_left	ds.w	1
mt_frames_to_do	ds.w	1

**mt_amiga_freq	dc.l	7090000
mt_freq_list	ds.l	1
mt_freq_table	ds.l	1
mt_volume_tab	ds.l	1
mt_div_table	ds.l	1
mt_frame_freq_t	ds.l	1
mt_frame_freq_p	ds.l	1
mt_mixcode_p	ds.l	1
mt_mixer_chunk	ds.l	1
mt_channel_p	ds.l	4
**mt_physic_buf	ds.l	1
**mt_logic_buf	ds.l	1
**mt_replay_len	dc.l	2000
mt_trash_str	ds.l	64
mt_trash_status	ds.b	32
mt_trash_rd_idx	ds.w	1
mt_trash_wt_idx	ds.w	1
mt_trash_active	ds.b	1
mt_trash_oodata	ds.b	1
mt_replay_len	dc.l	1000
mt_save_SSP	dc.l	0
mt_save_USP	dc.l	0
mt_save_trap0	dc.l	0
mt_start	dc.w	$0001
**mt_frequency	dc.w	$0003
mt_frequency	dc.w	$0002
mt_left_volume	dc.w	0
mt_right_volume	dc.w	0
mt_left_volold	dc.w	$0040
mt_right_volold	dc.w	$0040
mt_LCM_mask	dc.w	$07FF
mt_LCM_left	dc.w	$540
mt_LCM_right	dc.w	$500

mt_left_temp	dc.l	0,0,0
mt_right_temp	dc.l	0,0,0
	rsreset
mt_temp_regs	rs.l	2
mt_temp_old_sam	rs.w	2

**mt_dummy_spl	ds.w	320
mt_dummy_spl	ds.w	332



***************************************************************************
*
*	Interface_structs	mt_channel_x
*
***************************************************************************
mt_channel_0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.w	$3ff
	dc.w	0
	dc.w	0
mt_channel_1
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.w	$3ff
	dc.w	0
	dc.w	0
mt_channel_2
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.w	$3ff
	dc.w	0
	dc.w	0
mt_channel_3
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.w	$3ff
	dc.w	0
	dc.w	0
mt_dummy_tab
	ds.l	1
	ds.l	1
	dc.l	0
	dc.w	0
	dc.w	$3ff
	dc.w	0
	dc.w	-1
	rsreset
mt_sample_point	rs.l	1
mt_sample_end	rs.l	1
mt_loop_size	rs.l	1
mt_volume	rs.w	1
mt_period	rs.w	1
mt_add_iw	rs.w	1
mt_check_dummy	rs.w	1

***************************************************************************

