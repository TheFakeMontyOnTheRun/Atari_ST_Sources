	LEA	$A0000,A6
	LEA	$80000+34,A0
	MOVE	#8*24*160-1,D0
	BSR	TAKE
	LEA	$90000+34,A0
	MOVE	#7*24*160-1,D0
	BSR	TAKE

	LEA	$A0000,A0
	LEA	$B0000,A1
	ADD.L	#15*24*160,A1
	MOVE	#15*24*4-1,D0
REVERT:
	MOVEM.L	(A0)+,D2-D7/A2-A5
	MOVEM.L	D2-D7/A2-A5,-(A1)
	DBRA	D0,REVERT

	LEA	$B0000,A0
	LEA	$B0000,A1
	ADD.L	#15*24*160,A1

	ILLEGAL
TAKE:	MOVE.B	(A0)+,(A6)+
	DBRA	D0,TAKE
	RTS
