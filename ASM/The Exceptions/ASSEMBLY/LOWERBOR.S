E.L  A0,A1         Copy it to A1
	MOVE.L  A1,A2         and A2
	MOVE.L  #$1701c,D1    This is the adress we relocate the program
;                             to execute from (Change as above)
;If you use another adress remember to move your program to the new
;adress before executing it!
	ADD.L   D0,A1         Get adress of RELOCATION TABLE
	MOVE.L  (A1)+,D0      Get the Long Word
	ADD.L   D0,A2         Point to the first Absolute adress
	ADD.L   D1,(A2)       Relocate it
	CLR.L   D0            Clear D0
RELO:	MOVE.B  (A1)+,D0      Get next byte from table
	BEQ     RELEND        Is it the end (zero)
	CMP.B   #1,D0         1 is a 254 jump
	BEQ     JUMP          If it is then do it
	ADD.L   D0,A2         If not find next absolute adress
	ADD.L   D1,(A2)       and relocate it
	BRA     RELO          Continue until the zero is found
JUMP:	ADD.L   #254,A2       Jump 254 bytes
	BRA     RELO          and continue
RELEND:
	RTS
; Uninitialised data is not loader so we simply forget it

         ; opens lower and upper border
; for K-SEKA versions 1.5 and higher
; written by Gunter (6719)
; Color only!
 
x:
        clr.l   -(sp)
        move.w  #$20,-(sp)
        trap    #1
        move.l  d0,savereg
        move.l  #$70000,a7

        move.l  #moff,-(sp)
        clr.w   -(sp)
        move.w  #25,-(sp)
        trap    #14
        addq.l  #8,sp
        line_a $a               ;mouse off

        move.w  #4,-(sp)        
        trap    #14
        addq.l  #2,sp
        move.w  d0,oldrez
        move.l  $44e.w,oldscr
        move.l  #$70000,screen  ;new screen address

        movem.l $ffff8240.w,d0-d7
        movem.l d0-d7,oldpal
        move.b  #$02,$ffff820a.w

        bsr     prepare
        bsr     hblon

        move.w  #7,-(sp)
        trap    #1
        addq.l  #2,sp

        bsr     hbloff

        movem.l oldpal,d0-d7
        movem.l d0-d7,$ffff8240.w
        move.w  oldrez,-(sp)
        move.l  oldscr,-(sp)
        move.l  oldscr,-(sp)
        move.w  #5,-(sp)
        trap    #14
        add.l   #12,sp

        move.l  #mon,-(sp)
        clr.w   -(sp)
        move.w  #25,-(sp)
        trap    #14
        addq.l  #8,sp
        line_a  $9              ;mouse on
        move.l  savereg,-(sp)
        move.w  #$20,-(sp)
        trap    #1
        addq.l  #6,sp

;       illegal
        clr.l   -(sp)
        trap    #1

oldrez:  dc.w 0
oldscr:  dc.l 0
savereg: dc.l 0
screen:  dc.l 0
oldpal:  blk.w 16,0
mon:  dc.b $08
moff: dc.b $12

;-----------------------------
hblon:
        move.l  $120.w,oldtb    ;preserve vectors
        move.l  $70.w,old4
        move.l  $70.w,new4b+2
        move.b  $fffffa07.w,old07
        move.b  $fffffa09.w,old09
        move.b  $fffffa0f.w,old0f
        move.b  $fffffa11.w,old11
        move.b  $fffffa1b.w,old1b
        and.b   #$df,$fffa09    ;disable Timer C
        and.b   #$fe,$fffa07    ;disable Timer B
        move.l  #newtb,$120.w
        move.l  #new4,$70.w
        or.b    #1,$fffffa07.w  ;Timer B enable
        or.b    #1,$fffffa13.w
        rts

hbloff:
        move.w  sr,-(sp)
        move.w  #$2700,sr
        move.b  old07(pc),$fffffa07.w    ;restore all registers
        move.b  old09(pc),$fffffa09.w
        move.b  old0f(pc),$fffffa0f.w
        move.b  old11(pc),$fffffa11.w
        move.b  old1b(pc),$fffffa1b.w
        move.l  oldtb,$120.w             ;restore vectors
        move.l  old4,$70.w
        move.w  (sp)+,sr
        rts

old4:  dc.l 0
oldtb: dc.l 0
old07: dc.b 0
old09: dc.b 0
old0f: dc.b 0
old11: dc.b 0
old1b: dc.b 0
even

new4:
        clr.b   $fffffa1b.w
        move.b  #199,$fffffa21.w
        move.b  #8,$fffffa1b.w
new4b:
        jmp     $000000

newtb:
        clr.b   $fffffa1b.w     ;timer stop
        movem.l d0-d1/a0-a1,-(sp)
        move.w  #$fa21,a1
        move.b  #47,(a1)
        move.b  #8,$fffffa1b.w

        move.b  (a1),d0
wait:                           ;wait for the end of the last line
        cmp.b   (a1),d0
        beq     wait
        clr.b   $ffff820a.w     ;60 Hz

        moveq   #3,d0
