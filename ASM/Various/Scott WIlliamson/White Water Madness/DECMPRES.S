;       DEGAS PICTURE DECOMRESSION ROUTINE
DECOMPRESS:
;                               ***** DECOMPRESS PICTUERS
;       A0 - SOURCE     A6 - DEST
  CLR.L d6              ; screen length in bytes
  move.l #40,d5         ; line length 1 bpl
  move.l #4,d4          ; bpl counter
  MOVE.L #2,D3          ; WORD
READCOMMAND:

  MOVE.B (A0)+,D0
  CMP.B #-128,D0
  BEQ READCOMMAND       ; IGNORE -128
  CMP.B #0,D0
  BGE COPYNEXTBYTES     ; D0 >=0 COPY NEXT D0+1 BYTES LITERALLY

COPYNEXTBYTE:           ;    OTHERWISE
  NEG.B D0              ; D0 <0 COPY NEXT BYTE -D0+1 TIMES
  EXT.W D0
  EXT.L D0              ; NEGATE D0 & MAKE IT A LONG WORD

PUTBYTE:
  MOVE.B (A0),(A6,D6.L) ; PUT BYTE IN SCREEN BUFFER
  ADDQ.L #1,D6          ; INC SCREEN ADR
  SUBQ.L #1,D5          ; LINE LENGTH
  SUBQ.L #1,D3          ; BYTES PER WORD
  BNE WORDOK
  ADDQ.L #6,D6          ; SKIP OTHER BPL'S
  MOVE.L #2,D3
WORDOK:
  DBRA D0,PUTBYTE
        ADDQ.L  #1,A0
  BRA PROCEND

COPYNEXTBYTES:
  EXT.W D0
  EXT.L D0              ; MAKE D0 A LONG WORD
PUTBYTE2:
  MOVE.B (A0)+,(A6,D6.L) ; PUT BYTE IN SCREEN BUFFER
  ADDQ.L #1,D6          ; INC SCREEN ADR
  SUBQ.L #1,D5          ; LINE LENGTH
  SUBQ.L #1,D3          ; BYTES PER WORD
  BNE WORDOK2
  ADDQ.L #6,D6          ; SKIP OTHER BPL'S
  MOVE.L #2,D3
WORDOK2:
  DBRA D0,PUTBYTE2

PROCEND:
  CMP.L #0,D5           ; END OF LINE?
  BNE READCOMMAND       ; NO KEEP READING
  MOVE.L #40,D5         ; EOL - RESET LINE BYTE COUNER
  SUBQ.L #1,D4          ; LAST BPL ?
  BEQ NEXTLINE          ; YES
  SUB.L #158,D6         ; NO - NEXT BPL CURRENT LINE
  BRA READCOMMAND
NEXTLINE:               ; NEW LINE
  SUBQ.L #6,D6          ; RESET TO BPL 0 NEXT LINE
  MOVE.L #4,D4          ; RESET BPL COUNTER
  CMP.L #32000,D6       ; END OF SCREEN ?
  BEQ DONECOMPRESSED
        BRA READCOMMAND
DONECOMPRESSED:
        RTS
        END
 