 '
 ' Teste par Bcostat si l'imprimante est pr�te
 ' OMIKRON-BASIC      ONLINE.BAS
 '
 BIOS (Status%L,8,0)
 IF Status%L=-1
   THEN PRINT "L'imprimante est pr�te!"
   ELSE PRINT "L'imprimante n'est pas pr�te!"
 ENDIF
 END
