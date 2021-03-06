PROGRAM Demo3E; (* Arbeit mit typisierten Bin�rdateien *)

TYPE TPerson =
	RECORD
	Name:STRING;
	Gehalt:REAL;
	END;

CONST Dateiname = 'GEHALT.DAT';

PROCEDURE ErzeugeDaten(Name:STRING);
VAR PersDatei:FILE OF TPerson;
	Person:TPerson;
BEGIN
ASSIGN(PersDatei,Name);
REWRITE(PersDatei);
IF IOResult<>0 THEN
	BEGIN
	WRITELN('Kann Datei nicht erzeugen.');
	HALT;
	END;
WITH Person DO
	BEGIN
	Name:='Manni Mantamanta';
	Gehalt:=1234.56;
	WRITE(PersDatei,Person);
	Name:='Erna M�ller-L�denscheidt';
	Gehalt:=4711;
	WRITE(PersDatei,Person);
	Name:='Batman';
	Gehalt:=94562.79;
	WRITE(PersDatei,Person);
	Name:='Catwoman';
	Gehalt:=113289.57;
	WRITE(PersDatei,Person);
	END;
CLOSE(PersDatei);
END;

PROCEDURE AnzeigeDaten(Name:STRING);
VAR PersDatei:FILE OF TPerson;
	Person:TPerson;
BEGIN
ASSIGN(PersDatei,Name);
RESET(PersDatei);
IF IOResult<>0 THEN
	BEGIN
	WRITELN('Kann Datei nicht �ffnen.');
	HALT;
	END;
WRITELN('Dateigr��e: ':31,FILESIZE(PersDatei),' Eintr�ge');
WRITELN;
WHILE NOT EOF(PersDatei) DO
	BEGIN
	READ(PersDatei,Person);
	WITH Person DO
		WRITELN(Name:30,Gehalt:20:2);
	END;
CLOSE(PersDatei);
WRITELN;
END;

PROCEDURE RueckwAnzeigeDaten(Name:STRING);
VAR PersDatei:FILE OF TPerson;
	Person:TPerson;
	FilePos:LONGINT;
BEGIN
WRITELN('Anzeige in umgekehrter Reihenfolge (per SEEK):');
ASSIGN(PersDatei,Name);
RESET(PersDatei);
IF IOResult<>0 THEN
	BEGIN
	WRITELN('Kann Datei nicht �ffnen.');
	HALT;
	END;
FOR FilePos:=FILESIZE(PersDatei)-1 DOWNTO 0 DO
	BEGIN
	SEEK(PersDatei,FilePos);
	READ(PersDatei,Person);
	WITH Person DO
		WRITELN(Name:30,Gehalt:20:2);
	END;
CLOSE(PersDatei);
WRITELN;
END;

PROCEDURE LoeschLetztenSatz(Name:STRING);
VAR Datei:FILE OF TPerson;
BEGIN
WRITELN('L�sche letzten Datensatz.');
ASSIGN(Datei,Name);
RESET(Datei);
IF IOResult<>0 THEN
	BEGIN
	WRITELN('Kann Datei nicht �ffnen.');
	HALT;
	END;
SEEK(Datei,FILESIZE(Datei)-1);
TRUNCATE(Datei);
CLOSE(Datei);
END;

PROCEDURE LoeschDatei(Name:STRING);
VAR Datei:FILE OF TPerson;
BEGIN
WRITELN('L�sche Datei.');
ASSIGN(Datei,Name);
ERASE(Datei);
IF IOResult<>0 THEN
	BEGIN
	WRITELN('Kann Datei nicht l�schen.');
	HALT;
	END;
END;

BEGIN
ErzeugeDaten(Dateiname);
AnzeigeDaten(Dateiname);
RueckwAnzeigeDaten(Dateiname);
LoeschLetztenSatz(Dateiname);
AnzeigeDaten(Dateiname);
LoeschDatei(Dateiname);
END.