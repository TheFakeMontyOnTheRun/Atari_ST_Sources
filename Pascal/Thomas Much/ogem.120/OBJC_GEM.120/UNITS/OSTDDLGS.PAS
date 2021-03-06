{**************************************
 *  O b j e c t G E M   Version 1.20  *
 *  Copyright 1992-94 by Thomas Much  *
 **************************************
 *       Unit  O S T D D L G S        *
 **************************************
 *    Softdesign Computer Software    *
 *    Thomas Much, Gerwigstra�e 46,   *
 *  76131 Karlsruhe, (0721) 62 28 41  *
 *         Thomas Much @ KA2          *
 *  UK48@ibm3090.rz.uni-karlsruhe.de  *
 **************************************
 *    erstellt am:        03.03.1994  *
 *    letztes Update am:  03.03.1994  *
 **************************************}

{
  WICHTIGE ANMERKUNGEN ZUM QUELLTEXT:

  ObjectGEM wird mit dem _vollst�ndigen_ Quelltext ausgeliefert, d.h.
  jeder kann sich die Unit selbst compilieren, womit die extrem l�stigen
  Kompatibilit�tsprobleme mit den PP-Releases beseitigt sind.
  ObjectGEM ist und bleibt aber trotzdem SHAREWARE, d.h. wer die Biblio-
  thek regelm��ig benutzt, mu� sich REGISTRIEREN lassen. Daf�r gibt es
  die neueste Version und - gegen einen geringen Aufpreis - auch ein
  gedrucktes Handbuch.

  WICHTIG: Wer den Quelltext ver�ndert und dann Probleme beim Compilieren,
  Ausf�hren o.�. hat, kann nicht damit rechnen, da� ich den Fehler suche;
  tritt der Fehler allerdings auch mit dem Original-Quelltext auf, w�rde
  ich mich �ber eine genaue Fehlerbeschreibung freuen. Ver�nderte Quell-
  texte d�rfen _nicht_ weitergegeben werden, dies w�re ein Versto� gegen
  das Copyright!

  Wer beim Durchst�bern des Textes auf vermeintliche Fehler oder verbesse-
  rungsw�rdige Stellen trifft (von letzterem gibt es sicherlich noch viele),
  kann mir dies gerne mitteilen - ich habe auch ich nichts gegen kostenlos
  zur Verf�gung gestellte optimierte Routinen (sofern sich jemand die M�he
  macht). Wer in anderen Projekten, die nicht in direkter Konkurrenz zu
  ObjectGEM stehen, einzelne Routinen verwenden m�chte, wendet sich bitte
  an mich (ein solcher Austausch sollte kein Problem sein).

  Wer sich auf nicht dokumentierte "implementation"- oder "private"-Eigen-
  schaften verl��t, darf sich nicht �ber Inkompatibilit�ten zu sp�teren
  Versionen wundern; wer meint, eine Dokumentationsl�cke entdeckt zu haben,
  kann mir dies gerne mitteilen.

  Kleine Info zum Schlu�: Als "default tabsize" verwende ich 2. Wer drei
  Punkte ("...") im Quelltext entdeckt, hat eine Stelle gefunden, an der
  ich z.Z. arbeite ;-)

  "M�ge die OOP mit Euch sein!"
}


{$IFDEF DEBUG}
	{$B+,D+,G-,I-,L+,N-,P-,Q+,R+,S+,T-,V-,X+,Z-}
{$ELSE}
	{$B+,D-,G-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$ENDIF}

unit OStdDlgs;

interface

uses

	OWindows;

type

	TFileDialog = object(TDialog)
		public
		{ ... }
		function GetClassName: string; virtual;
	end;

	TColorDialog = object(TDialog)
		public
		{ ... }
		function GetClassName: string; virtual;
	end;

	TFontDialog = object(TDialog)
		public
		{ ... }
		function GetClassName: string; virtual;
	end;


implementation


{ *** Objekt TFILEDIALOG *** }

function TFileDialog.GetClassName: string;

	begin
		GetClassName:='FileDialog'
	end;

{ *** TFILEDIALOG *** }



{ *** Objekt TCOLORDIALOG *** }

function TColorDialog.GetClassName: string;

	begin
		GetClassName:='ColorDialog'
	end;

{ *** TCOLORDIALOG *** }



{ *** Objekt TFONTDIALOG *** }

function TFontDialog.GetClassName: string;

	begin
		GetClassName:='FontDialog'
	end;

{ *** TFONTDIALOG *** }

end.