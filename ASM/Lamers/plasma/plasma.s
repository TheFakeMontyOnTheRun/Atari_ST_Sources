PLASMA_MAP1_X_MOVE_SIZE	equ 300
PLASMA_MAP1_Y_MOVE_SIZE	equ 300	
PLASMA_MAP2_X_MOVE_SIZE	equ 300
PLASMA_MAP2_Y_MOVE_SIZE	equ 300		
	section text
plasmaInit:
	firstRunOrReturn
	bsr 	clearScreenBuffer
	move.l	ramBufferPtr,a1
		
	moveq.l	#0,d0	
	move.l	a1,plasmaBitMapStartPtr	
	lea		plasmaBitMap,a0
	move.l	#320*200-1,d7
_plasmaInitLoop	
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	dbf		d7,_plasmaInitLoop
	
	
	move.w	#0,plasmaBitMap1OffsetXnow
	move.w	#0,plasmaBitMap1OffsetYnow
	move.w	#100,plasmaBitMap2OffsetXnow
	move.w	#200,plasmaBitMap2OffsetYnow	
	
	; rgb init
	bsr		video_rgb_320x100x16
	
	rts
	
plasmaMain:
	bsr 	switchScreens
	;move
	move.l	plasmaBitMapStartPtr,a1
	lea		plasmaBitMap1OffsetsX,a4
	move.w	plasmaBitMap1OffsetXnow,d4
	add.l	(a4,d4.w*4),a1
	add.w	#1,plasmaBitMap1OffsetXnow
	cmp.w	#PLASMA_MAP1_X_MOVE_SIZE,plasmaBitMap1OffsetXnow
	blt.s	_plasmaBitMap1OffsetXok
	move.w	#0,plasmaBitMap1OffsetXnow
_plasmaBitMap1OffsetXok	

	lea		plasmaBitMap1OffsetsY,a4
	move.w	plasmaBitMap1OffsetYnow,d4
	add.l	(a4,d4.w*4),a1
	add.w	#1,plasmaBitMap1OffsetYnow
	cmp.w	#PLASMA_MAP1_Y_MOVE_SIZE,plasmaBitMap1OffsetYnow
	blt.s	_plasmaBitMap1OffsetYok
	move.w	#0,plasmaBitMap1OffsetYnow
_plasmaBitMap1OffsetYok	

	move.l	plasmaBitMapStartPtr,a2
	lea		plasmaBitMap2OffsetsX,a4
	move.w	plasmaBitMap2OffsetXnow,d4
	add.l	(a4,d4.w*4),a2
	add.w	#1,plasmaBitMap2OffsetXnow
	cmp.w	#PLASMA_MAP2_X_MOVE_SIZE,plasmaBitMap2OffsetXnow
	blt.s	_plasmaBitMap2OffsetXok
	move.w	#0,plasmaBitMap2OffsetXnow
_plasmaBitMap2OffsetXok	

	lea		plasmaBitMap2OffsetsY,a4
	move.w	plasmaBitMap2OffsetYnow,d4
	add.l	(a4,d4.w*4),a2
	add.w	#1,plasmaBitMap2OffsetYnow
	cmp.w	#PLASMA_MAP2_Y_MOVE_SIZE,plasmaBitMap2OffsetYnow
	blt.s	_plasmaBitMap2OffsetYok
	move.w	#0,plasmaBitMap2OffsetYnow
_plasmaBitMap2OffsetYok	
		
	; render
	move.l	scr1,a0
	lea		plasmaColor,a3
	
	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#0,d5
	move.l	d0,a4
	move.l	d0,a5

    move.l  #100-1,d7                     
rgbPlasmaLoopY:  
	move.l  #160/4/5-1,d6                     
rgbPlasmaLoopX:  
	rept	5
	movem.w	(a1)+,d0-d3
	movem.w	(a2)+,d4-d5/a4-a5
	add.w	d4,d0
	add.w	d5,d1
	add.w	a4,d2
	add.w	a5,d3
	move.l	(a3,d0.l*4),(a0)+
	move.l	(a3,d1.l*4),(a0)+
	move.l	(a3,d2.l*4),(a0)+
	move.l	(a3,d3.l*4),(a0)+
    endr
    dbra    d6,rgbPlasmaLoopX
    lea	160*2(a1),a1
    lea	160*2(a2),a2
    dbra    d7,rgbPlasmaLoopY                    

	rts
	
		
	section data
	cnop 0,4
plasmaBitMap		incbin 'plasma/plasma.dat'
	cnop 0,4
					incbin plasma/color.dat
plasmaColor	 		incbin plasma/color.dat

	cnop 0,4
plasmaBitMap1OffsetsX dc.l 160,162,166,170,172,176,180,182,186,188,192,196,198,202,206,208,212,214,218,222,224,228,230,234,236,238,242,244,248,250,254,256,258,260,264,266,268,270,274,276,278,280,282,284,286,288,290,292,294,296,298,300,300,302,304,306,306,308,308,310,312,312,314,314,314,316,316,316,318,318,318,318,318,318,318,320,318,318,318,318,318,318,318,316,316,316,314,314,314,312,312,310,308,308,306,306,304,302,300,300,298,296,294,292,290,288,286,284,282,280,278,276,274,270,268,266,264,260,258,256,254,250,248,244,242,238,236,234,230,228,224,222,218,214,212,208,206,202,198,196,192,188,186,182,180,176,172,170,166,162,160,158,154,150,148,144,140,138,134,132,128,124,122,118,114,112,108,106,102,98,96,92,90,86,84,80,78,76,72,70,66,64,62,60,56,54,52,50,46,44,42,40,38,36,34,32,30,28,26,24,22,20,20,18,16,14,14,12,12,10,8,8,6,6,6,4,4,4,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,4,4,4,6,6,6,8,8,10,12,12,14,14,16,18,20,20,22,24,26,28,30,32,34,36,38,40,42,44,46,50,52,54,56,60,62,64,66,70,72,76,78,80,84,86,90,92,96,98,102,106,108,112,114,118,122,124,128,132,134,138,140,144,148,150,154,158
	cnop 0,4
plasmaBitMap1OffsetsY dc.l 62720,62080,62080,62080,62080,62080,62080,62080,62080,62080,61440,61440,61440,61440,60800,60800,60800,60160,60160,60160,59520,59520,58880,58880,58880,58240,58240,57600,56960,56960,56320,56320,55680,55040,55040,54400,53760,53760,53120,52480,52480,51840,51200,50560,50560,49920,49280,48640,48000,47360,46720,46720,46080,45440,44800,44160,43520,42880,42240,41600,40960,40320,39680,39040,38400,37760,37120,37120,36480,35840,35200,34560,33920,33280,32640,32000,31360,30720,30080,29440,28800,28160,27520,26880,26880,26240,25600,24960,24320,23680,23040,22400,21760,21120,20480,19840,19200,18560,17920,17280,16640,16640,16000,15360,14720,14080,13440,13440,12800,12160,11520,11520,10880,10240,10240,9600,8960,8960,8320,7680,7680,7040,7040,6400,5760,5760,5120,5120,5120,4480,4480,3840,3840,3840,3200,3200,3200,2560,2560,2560,2560,1920,1920,1920,1920,1920,1920,1920,1920,1920,1280,1920,1920,1920,1920,1920,1920,1920,1920,1920,2560,2560,2560,2560,3200,3200,3200,3840,3840,3840,4480,4480,5120,5120,5120,5760,5760,6400,7040,7040,7680,7680,8320,8960,8960,9600,10240,10240,10880,11520,11520,12160,12800,13440,13440,14080,14720,15360,16000,16640,17280,17280,17920,18560,19200,19840,20480,21120,21760,22400,23040,23680,24320,24960,25600,26240,26880,26880,27520,28160,28800,29440,30080,30720,31360,32000,32640,33280,33920,34560,35200,35840,36480,37120,37120,37760,38400,39040,39680,40320,40960,41600,42240,42880,43520,44160,44800,45440,46080,46720,46720,47360,48000,48640,49280,49920,50560,50560,51200,51840,52480,52480,53120,53760,53760,54400,55040,55040,55680,56320,56320,56960,56960,57600,58240,58240,58880,58880,58880,59520,59520,60160,60160,60160,60800,60800,60800,61440,61440,61440,61440,62080,62080,62080,62080,62080,62080,62080,62080,62080
	cnop 0,4
plasmaBitMap2OffsetsX dc.l 160,162,166,170,172,176,180,182,186,188,192,196,198,202,206,208,212,214,218,222,224,228,230,234,236,238,242,244,248,250,254,256,258,260,264,266,268,270,274,276,278,280,282,284,286,288,290,292,294,296,298,300,300,302,304,306,306,308,308,310,312,312,314,314,314,316,316,316,318,318,318,318,318,318,318,320,318,318,318,318,318,318,318,316,316,316,314,314,314,312,312,310,308,308,306,306,304,302,300,300,298,296,294,292,290,288,286,284,282,280,278,276,274,270,268,266,264,260,258,256,254,250,248,244,242,238,236,234,230,228,224,222,218,214,212,208,206,202,198,196,192,188,186,182,180,176,172,170,166,162,160,158,154,150,148,144,140,138,134,132,128,124,122,118,114,112,108,106,102,98,96,92,90,86,84,80,78,76,72,70,66,64,62,60,56,54,52,50,46,44,42,40,38,36,34,32,30,28,26,24,22,20,20,18,16,14,14,12,12,10,8,8,6,6,6,4,4,4,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,4,4,4,6,6,6,8,8,10,12,12,14,14,16,18,20,20,22,24,26,28,30,32,34,36,38,40,42,44,46,50,52,54,56,60,62,64,66,70,72,76,78,80,84,86,90,92,96,98,102,106,108,112,114,118,122,124,128,132,134,138,140,144,148,150,154,158
	cnop 0,4
plasmaBitMap2OffsetsY dc.l 62720,62080,62080,62080,62080,62080,62080,62080,62080,62080,61440,61440,61440,61440,60800,60800,60800,60160,60160,60160,59520,59520,58880,58880,58880,58240,58240,57600,56960,56960,56320,56320,55680,55040,55040,54400,53760,53760,53120,52480,52480,51840,51200,50560,50560,49920,49280,48640,48000,47360,46720,46720,46080,45440,44800,44160,43520,42880,42240,41600,40960,40320,39680,39040,38400,37760,37120,37120,36480,35840,35200,34560,33920,33280,32640,32000,31360,30720,30080,29440,28800,28160,27520,26880,26880,26240,25600,24960,24320,23680,23040,22400,21760,21120,20480,19840,19200,18560,17920,17280,16640,16640,16000,15360,14720,14080,13440,13440,12800,12160,11520,11520,10880,10240,10240,9600,8960,8960,8320,7680,7680,7040,7040,6400,5760,5760,5120,5120,5120,4480,4480,3840,3840,3840,3200,3200,3200,2560,2560,2560,2560,1920,1920,1920,1920,1920,1920,1920,1920,1920,1280,1920,1920,1920,1920,1920,1920,1920,1920,1920,2560,2560,2560,2560,3200,3200,3200,3840,3840,3840,4480,4480,5120,5120,5120,5760,5760,6400,7040,7040,7680,7680,8320,8960,8960,9600,10240,10240,10880,11520,11520,12160,12800,13440,13440,14080,14720,15360,16000,16640,17280,17280,17920,18560,19200,19840,20480,21120,21760,22400,23040,23680,24320,24960,25600,26240,26880,26880,27520,28160,28800,29440,30080,30720,31360,32000,32640,33280,33920,34560,35200,35840,36480,37120,37120,37760,38400,39040,39680,40320,40960,41600,42240,42880,43520,44160,44800,45440,46080,46720,46720,47360,48000,48640,49280,49920,50560,50560,51200,51840,52480,52480,53120,53760,53760,54400,55040,55040,55680,56320,56320,56960,56960,57600,58240,58240,58880,58880,58880,59520,59520,60160,60160,60160,60800,60800,60800,61440,61440,61440,61440,62080,62080,62080,62080,62080,62080,62080,62080,62080

	section bss
	cnop 0,4
plasmaBitMapStartPtr	dc.l	0	
plasmaBitMap1OffsetXnow	dc.w	0
plasmaBitMap1OffsetYnow	dc.w	0
plasmaBitMap2OffsetXnow	dc.w	0
plasmaBitMap2OffsetYnow	dc.w	0

	section text
