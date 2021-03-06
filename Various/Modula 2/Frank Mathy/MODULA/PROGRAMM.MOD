(*********************************************************************)
(* Hauptmodul des �bersetzungsprogrammes                             *)
(*-------------------------------------------------------------------*)
(*             Datum:      Autor:             Kommentar:             *)
(* Erstellung: 09.10.1991  Frank Mathy                               *)
(* �nderung:                                                         *)
(*********************************************************************)

MODULE Programm;


FROM Datenkapsel IMPORT LiesWoerterbuch,SchreibWoerterbuch,
                        LoeschWoerterbuch;
FROM Textdatei IMPORT UebersetzeText;

FROM TermWindow IMPORT InitTerminal,OpenTerminal,CloseTerminal,
                       DeleteTerminal,NewTitle;

PROCEDURE Uebersetze;
(* Hauptprozedur des �bersetzungsprogrammes *)
BEGIN
LiesWoerterbuch;
UebersetzeText;
SchreibWoerterbuch;
LoeschWoerterbuch;
END Uebersetze;


BEGIN
(* Hier Platz f�r eventuelle Initialisierungen.  *)
InitTerminal(TRUE);
OpenTerminal(-1,-1,-1,-1);

Uebersetze;

(* Hier Platz f�r Aktionen vor dem Programmende. *)
CloseTerminal;
DeleteTerminal;
END Programm.
