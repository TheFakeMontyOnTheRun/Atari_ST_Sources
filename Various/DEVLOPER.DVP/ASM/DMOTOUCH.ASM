;
; D�mo permanente (Quitter: appui touche)
; Assembleur           DMOTOUCH.ASM
;

gemdos         = 1
bios           = 13

bconstat       = 1
bconin         = 2
bconout        = 3

               .TEXT 

               clr.w      d3

loop:          lea.l      affichage,a3  ;Affichage de la cha�ne

outloop:       tst.b      (a3)          ;Arriv� en fin de cha�ne?
               beq.s      outfin        ;alors aller � la boucle d'attente
               move.b     (a3)+,d3      ;Sinon afficher caract�re
               move.w     d3,-(sp)      ;Plac� sur pile comme un mot
               move.w     #2,-(sp)      ;La console est le "2" (�cran)
               move.w     #bconout,-(sp)
               trap       #bios
               addq.l     #6,sp

               bra.s      outloop       ;Caract�re suivant...

outfin:        moveq.l    #-1,d0        ;Boucle de ralentissement
wait:          dbra       d0,wait

               move.w     #2,-(sp)      ;Touche appuy�e pendant ce temps?
               move.w     #bconstat,-(sp)
               trap       #bios
               addq.l     #4,sp
               tst.w      d0
               beq.s      loop          ;Si non, continuer...

               move.w     #2,-(sp)      ;Si oui, lire le caract�re
               move.w     #bconin,-(sp) ;dans le tampon du clavier...
               trap       #bios
               addq.l     #4,sp

               clr.w      -(sp)         ;... et quitter le programme
               trap       #gemdos

               .DATA 
affichage:     .DC.b 'D�MONSTRATION. Touche = Fin...          ',0

               .END 

