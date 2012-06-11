unit Tools;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diesen Unit enthaelt universelle Hilfsroutinen.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTTextIO,
	Types, SysMB, SysStat, PTypes;

{ Wandelt eine Ganzzahl in einen String um. }
function IntToStr(I: integer; Width: word): string;

{ Entfernt alle Leerzeichen aus einem String. }
function Trim(S: string): string;

{ Gibt eine Meldung aus und speichert ein Ereignis in der Exitsemaphore ab. }
procedure Die(ErrorMessage: string);

{ Wandelt einen String in Grossbuchstaben um. }
function StrUpCase(S: string): string;

{ Wandelt einen String in einen Integer um. }
function StrToInt(S: string; var I: integer): boolean;

{ Wandelt einen String in ein Byte um. }
function StrToByte(S: string; var B: byte): boolean;

{ Wandelt einen String in einen Spieler um. }
function StrToPlayer(S: string; var P: TPlayer): boolean;

{ Wandelt einen Spieler in einen String um. }
function PlayerToStr(P: TPlayer): string;

{ Wandelt einen String in eine Bedenkzeit um. }
function StrToTimeLimit(S: string; var TL: TTimeLimit): boolean;

{ Wandelt eine Farbe in einen String um. }
function ColorToStr(Color: byte): string;

{ Sorgt fuer das Anzeigen einer Systemstatusmeldung. }
procedure ShowSystemStatus(S: string);

{ Liefert eine Zufallszahl im Bereich 0 <= X < Range. }
function GetRandomWord(Range: word): word;

{ Konvertiert einen Spieler in einen Besitzer. }
function PlayerToOwner(P: TPlayer): TOwner;

{ Berechnet ausgehend von einer Spielfeldposition die linke Nachbarposition. }
function GetLeftFieldPos(F: TField; var FP: TFieldPos): boolean;

{ Berechnet ausgehend von einer Spielfeldposition die rechte
	Nachbarposition. }
function GetRightFieldPos(F: TField; var FP: TFieldPos): boolean;

{ Berechnet ausgehend von einer Spielfeldposition die obere Nachbarposition. }
function GetUpperFieldPos(F: TField; var FP: TFieldPos): boolean;

{ Berechnet ausgehend von einer Spielfeldposition die untere
	Nachbarposition. }
function GetLowerFieldPos(F: TField; var FP: TFieldPos): boolean;

{ Berechnet die erste gueltige Position in einer Zeile. }
function GetFirstXPos(F: TField; var FP: TFieldPos): boolean;

{ Berechnet die erste gueltige Position in einer Spalte. }
function GetFirstYPos(F: TField; var FP: TFieldPos): boolean;

{ Berechnet die Spielerphase anhand der Anzahl der Spielsteine. }
function GetPlayerStage(PlacedTC, CapturedTC: TTokenCount): TPlayerStage;

{ Ausgabe der Position als String. }
function FieldPosToStr(FP: TFieldPos): string;

{ Sendet eine Debugmedldung an den Logger, wenn der Compilerschalter DEBUG
	definiert ist. }
procedure Debug(S: string);

{ Umwandlung von Besitzer zum Spieler. }
function OwnerToPlayer(O: TOwner): TPlayer;

{ Bereitet Zugdaten zum Schreiben in die Logdatei vor und sendet diese an
	den Logger. }
procedure LogMove(P: TPlayer; MD: TMoveData);

{ Liefert den anderen Spieler zurueck. }
function GetOtherPlayer(CurrentPlayer: TPlayer): TPlayer;

{ Sendet eine Logmeldung an den Logger. }
procedure Log(S: string);

implementation

uses
	RTKernel,
	Semas, Logger, LoggerMB;

function IntToStr(I: integer; Width: word): string;
(*****************************************************************************
	Beschreibung:
		Wandelt eine Ganzzahl in einen String um.

	In:
		I: integer: Zahl, die umgewandelt werden soll
		Width: word: Laenge des Resultatstrings. Ist Width groesser als
			Stellenanzahl von I, wird der String von links mit '0' aufgefuellt.

	Out:
		Zahl als String
*****************************************************************************)
var
	S: string;
begin
	{ Zahl umwandeln }
	Str(I, S);
	{ Mit '0' auffuellen }
	while Length(s) < Width do
		S := '0' + S;
	IntToStr := S;
end;

procedure Debug(S: string);
(*****************************************************************************
	Beschreibung:
		Sendet eine Debugmedldung an den Logger, wenn der Compilerschalter DEBUG
		definiert ist.

	In:
		S: string: Meldung

	Out:
		-
*****************************************************************************)
{$IFDEF DEBUG}
	var
		LoggerMessage: TLoggerMessage;
{$ENDIF}
begin
	{$IFDEF DEBUG}
		LoggerMessage.Kind := lomkLog;
		{ Taskhandle der aufrufenden Task mitsenden }
		LoggerMessage.Sender := CurrentTaskHandle;
		LoggerMessage.Message := Message;
		{ Nachricht in der Loggermailbox ablegen }
		LoggerMB.Put(Logger.Mailbox, LoggerMessage);
	{$ENDIF}
end;

function Trim(S: string): string;
(*****************************************************************************
	Beschreibung:
		Entfernt alle Leerzeichen aus einem String.

	In:
		S: string: String, aus dem die Leerzeichen entfernt werden sollen

	Out:
		-
*****************************************************************************)
var
	i: word;
begin
	i := 1;
	{ String zeichnenweise durchlaufen }
	while i <= Length(S) do
	begin
		{ Auf Leerzeichen pruefen }
		if S[i] = ' ' then
			{ Loeschen }
			Delete(S, i, 1)
		else
			{ Zaehler inkrementieren }
			Inc(i);
	end;
	Trim := S;
end;

function StrToInt(S: string; var I: integer): boolean;
(*****************************************************************************
	Beschreibung:
		Wandelt einen String in einen Integer um.

	In:
		S: string: String, der die Zahl darstellt
		I: integer: Integer, in dem das Ergebnis gespeichert wird

	Out:
		True, wenn die Umwandlung erfolgreich war
*****************************************************************************)
var
	C: integer;
begin
	{ Umwandeln }
	Val(S, I, C);
	{ Rueckgabewert berechnen }
	StrToInt := c = 0;
end;

function StrToByte(S: string; var B: byte): boolean;
(*****************************************************************************
	Beschreibung:
		Wandelt einen String in ein Byte um.

	In:
		S: string: String, der die Zahl enthaelt
		B: byte: Byte, in dem das Ergebnis gespeichert wird

	Out:
		True, wenn Umwandlung erfolgreich war
*****************************************************************************)
var
	I,
	C: integer;
begin
	StrToByte := false;

	{ Umwandeln }
	Val(s, i, c);
	{ Wertberich ueberpruefen }
	if (c = 0) and (i >= Low(byte)) and (i <= High(byte)) then
	begin
		B := I;
		{ Rueckgabewert setzen }
		StrToByte := true;
	end;
end;

procedure Die(ErrorMessage: string);
(*****************************************************************************
	Beschreibung:
		Gibt eine Meldung aus und speichert ein Ereignis in der Exitsemaphore ab.

	In:
		ErrorMessage: string: Meldung, die ausgegeben wird

	Out:
		-
*****************************************************************************)
begin
	WriteLn(ErrorMessage);
	Signal(ExitSemaphore);
end;

function StrUpCase(S: string): string;
(*****************************************************************************
	Beschreibung:
		Wandelt einen String in Grossbuchstaben um.

	In:
		S: string: String, der umgewandelt werden soll

	Out:
		String in Grossbuchstaben
*****************************************************************************)
var
	i: integer;
begin
	{ String zeichenweise durchlaufen }
	for i := 1 to Length(s) do
		{ Jede Stelle umwandeln }
		StrUpCase[i] := UpCase(S[i]);
	StrUpCase := S;
end;

function StrToPlayer(S: string; var P: TPlayer): boolean;
(*****************************************************************************
	Beschreibung:
		Wandelt einen String in einen Spieler um.

	In:
		S: string: String, der den Spieler enthaelt
		Player: TPlayer: Spieler

	Out:
		True, wenn Umwandlung geklappt hat
*****************************************************************************)
begin
	StrToPlayer := false;

	{ String in Grossbuchstaben umwandeln }
	S := StrUpCase(s);
	{ Pruefen, welchen Spieler der String enthaelt und Rueckgabewert setzen }
	if S = 'USER' then
	begin
		StrToPlayer := true;
		P := User;
	end
	else if s = 'CPU' then
	begin
		StrToPlayer := true;
		P := CPU;
	end;
end;

function PlayerToStr(P: TPlayer): string;
(*****************************************************************************
	Beschreibung:
		Wandelt einen Spieler in einen String um.

	In:
		Player: TPlayer: Spieler, der umgewandelt werden soll

	Out:
		Spieler als String
*****************************************************************************)
begin
	{ Spieler auswerten und Rueckgabewert setzen }
	if P = User then
		PlayerToStr := cUserTaskName
	else if P = CPU then
		PlayerToStr := cCPUTaskName
	else
		PlayerToStr := 'Unknown player';
end;

function StrToTimeLimit(S: string; var TL: TTimeLimit): boolean;
(*****************************************************************************
	Beschreibung:
		Wandelt einen String in eine Bedenkzeit um.

	In:
		S: string: String, der die Bedenkzeit enthaelt
		TimeLimit: TTimeLimit: Bendenkzeit

	Out:
		True, wenn erfolgreich
*****************************************************************************)
var
	I, C: integer;
begin
	StrToTimeLimit := false;

	{ Umwandeln }
	Val(S, I, C);
	{ Werteberich ueberpruefen und Rueckgabewert setzen }
	if (c = 0) and (i >= Low(TTimeLimit)) and (i <= High(TTimeLimit)) then
	begin
		TL := i;
		StrToTimeLimit := true;
	end;
end;

function ColorToStr(Color: byte): string;
(*****************************************************************************
	Beschreibung:
		Wandelt eine Farbe in einen String um.

	In:
		Color: byte: Farbe, die umgewandelt werden soll

	Out:
		Farbe als String
*****************************************************************************)
type
	{ Farben als Aufzaehlungstyp }
	TColor = (Black, Blue, Green, Cyan, Red, Magenta, Brown, Gray, DarkGray,
		LightBlue, LightGreen, LightCyan, LightRed, LightMagenta, Yellow, White);
	TColorStrings = array[TColor] of string;
const
	{ Farben als Strings }
	ColorStrings: TColorStrings = ('Black', 'Blue', 'Green', 'Cyan', 'Red',
		'Magenta', 'Brown', 'Gray', 'DarkGray', 'LightBlue', 'LightGreen',
		'LightCyan', 'LightRed', 'LightMagenta', 'Yellow', 'White');
begin
	ColorToStr := 'Unknown Color';
	{ Farbe auswerten und Rueckgabewert setzen }
	if (TColor(Color) >= Low(TColor)) and (TColor(Color) <= High(TColor)) then
		ColorToStr := ColorStrings[TColor(Color)];
end;

procedure ShowSystemStatus(S: string);
(*****************************************************************************
	Beschreibung:
		Sorgt fuer das Anzeigen einer Systemstatusmeldung.

	In:
		Meldung, die angezeigt werden soll

	Out:
		-
*****************************************************************************)
var
	SystemStatusMessage: TSystemStatusMessage;
begin
	{ Nachrichtart setzen und in der Mailbox der Systemstatustask ablegen }
	SystemStatusMessage.Kind := ssmkSystemStatus;
	SystemStatusMessage.Message := S;
	SysMB.Put(SysStat.Mailbox, SystemStatusMessage);
end;

function GetRandomWord(Range: word): word;
(*****************************************************************************
	Beschreibung:
		Liefert eine Zufallszahl im Bereich 0 <= X < Range.

	In:
		Range: word: Wertebereich fuer die Zufallszahl

	Out:
		Zufallszahl
*****************************************************************************)
begin
	Wait(RandomWordSemaphore);
	GetRandomWord := Random(Range);
	Signal(RandomWordSemaphore);
end;

function PlayerToOwner(P: TPlayer): TOwner;
(*****************************************************************************
	Beschreibung:
		Konvertiert einen Spieler in einen Besitzer.

	In:
		P: TPlayer: Spieler

	Out:
		Entsprechender Besitzer
*****************************************************************************)
begin
	{ Spieler auswerten und den entsprechenden Besitzer ermitteln }
	case P of
		User:
			PlayerToOwner := oUser;
		CPU:
			PlayerToOwner := oCPU;
	end;
end;

function GetLeftFieldPos(F: TField; var FP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet ausgehend von einer Spielfeldposition die linke Nachbarposition.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition

	Out:
		True, wenn Nachbarposition gefunden
		FP: TFieldPos: Neue Spielfeldposition
*****************************************************************************)
var
	TmpFP: TFieldPos;
begin
	GetLeftFieldPos := false;

	{ Position zwischenspeichern }
	TmpFP := FP;
	{ Pruefen, ob sich die Ausgangsposition am linken Rand befindet }
	if (FP.X > Low(TFieldWidth)) and
		{ Mittlere Zeile gesondert behandeln, wenn die Ausgangsspalte auf der
			rechten Kante des inneren Qudrates liegt }
		not ((FP.Y = cFieldSquareCount) and (FP.X = cFieldSquareCount + 1)) then
	begin
		{ Eine Position nach links }
		Dec(FP.X);
		{ Naechstlinke gueltige Position suchen und Rueckgabewert setzen }
		while (FP.X > Low(TFieldWidth)) and not F.Pos[FP.X, FP.Y].Valid do
			Dec(FP.X);
		GetLeftFieldPos := F.Pos[FP.X, FP.Y].Valid;
	end;
	{ Wenn nicht erfolgreich, Ausgangsposition wiederherstellen }
	if not F.Pos[FP.X, FP.Y].Valid then
		FP := TmpFP;
end;

function GetRightFieldPos(F: TField; var FP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet ausgehend von einer Spielfeldposition die rechte
		Nachbarposition.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition

	Out:
		True, wenn Nachbarposition gefunden
		FP: TFieldPos: Neue Spielfeldposition
*****************************************************************************)
var
	TmpFP: TFieldPos;
begin
	GetRightFieldPos := false;

	{ Position zwischenspeichern }
	TmpFP := FP;
	{ Pruefen, ob sich die Ausgangsposition am rechten Rand befindet }
	if (FP.X < High(TFieldWidth) - 1) and
		{ Mittlere Zeile gesondert behandeln, wenn die Ausgangsspalte auf der
			linken Kante des inneren Qudrates liegt }
		not ((FP.Y = cFieldSquareCount) and (FP.X = cFieldSquareCount - 1)) then
	begin
		{ Eine Position nach rechts }
		Inc(FP.X);
		{ Naechsrechte gueltige Position suchen und Rueckgabewert setzen }
		while (FP.X < High(TFieldWidth) - 1) and not
			F.Pos[FP.X, FP.Y].Valid do
		begin
			Inc(FP.X);
		end;
		GetRightFieldPos := F.Pos[FP.X, FP.Y].Valid;
	end;
	{ Wenn nicht erfolgreich, Ausgangsposition wiederherstellen }
	if not F.Pos[FP.X, FP.Y].Valid then
		FP := TmpFP;
end;

function GetUpperFieldPos(F: TField; var FP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet ausgehend von einer Spielfeldposition die obere Nachbarposition.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition

	Out:
		True, wenn Nachbarposition gefunden
		FP: TFieldPos: Neue Spielfeldposition
*****************************************************************************)
var
	TmpFP: TFieldPos;
begin
	GetUpperFieldPos := false;

	{ Position zwischenspeichern }
	TmpFP := FP;
	{ Pruefen, ob sich die Ausgangsposition am oberen Rand befindet }
	if (FP.Y > Low(TFieldHeight)) and
		{ Mittlere Spalte gesondert behandeln, wenn die Ausgangszeile auf der
			unteren Kante des inneren Qudrates liegt }
		not ((FP.X = cFieldSquareCount) and (FP.Y = cFieldSquareCount + 1)) then
	begin
		{ Eine Position nach oben }
		Dec(FP.Y);
		{ Naechstobere gueltige Position suchen und Rueckgabewert setzen }
		while (FP.Y > Low(TFieldHeight)) and not F.Pos[FP.X, FP.Y].Valid do
		begin
			Dec(FP.Y);
		end;
		GetUpperFieldPos := F.Pos[FP.X, FP.Y].Valid;
	end;
	{ Wenn nicht erfolgreich, Ausgangsposition wiederherstellen }
	if not F.Pos[FP.X, FP.Y].Valid then
		FP := TmpFP;
end;

function GetLowerFieldPos(F: TField; var FP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet ausgehend von einer Spielfeldposition die untere
		Nachbarposition.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition

	Out:
		True, wenn Nachbarposition gefunden
		FP: TFieldPos: Neue Spielfeldposition
*****************************************************************************)
var
	TmpFP: TFieldPos;
begin
	GetLowerFieldPos := false;

	{ Position zwischenspeichern }
	TmpFP := FP;
	{ Pruefen, ob sich die Ausgangsposition am unteren Rand befindet }
	if (FP.Y < High(TFieldHeight) - 1) and
		{ Mittlere Spalte gesondert behandeln, wenn die Ausgangszeile auf der
			oberen Kante des inneren Qudrates liegt }
		not ((FP.X = cFieldSquareCount) and (FP.Y = cFieldSquareCount - 1)) then
	begin
		{ Eine Position nach unten }
		Inc(FP.Y);
		{ Naechstuntere gueltige Position suchen und Rueckgabewert setzen }
		while (FP.Y < High(TFieldHeight) - 1) and not
			F.Pos[FP.X, FP.Y].Valid do
		begin
			Inc(FP.Y);
		end;
		GetLowerFieldPos := F.Pos[FP.X, FP.Y].Valid;
	end;
	{ Wenn nicht erfolgreich, Ausgangsposition wiederherstellen }
	if not F.Pos[FP.X, FP.Y].Valid then
		FP := TmpFP;
end;

function GetFirstXPos(F: TField; var FP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet die erste gueltige Position in einer Zeile.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition

	Out:
		True, wenn Position gefunden
*****************************************************************************)
begin
	{ Pruefen, ob die Ausgangsposition auf der mittleren Zeile in der rechten
		Haelfte liegt }
	if (FP.Y = cFieldSquareCount) and (FP.X >= cFieldSquareCount) then
		{ Position auf die rechte Kante des inneren Quadrates setzen }
		FP.X := cFieldSquareCount
	else
		{ Position auf linke Kante setzen }
		FP.X := Low(TFieldWidth);
	{ Pruefen ob Position gueltig und Rueckgabewert setzen }
	if F.Pos[FP.X, FP.Y].Valid then
		GetFirstXPos := true
	else
		{ Naechstrechte Position suchen }
		GetFirstXPos := GetRightFieldPos(F, FP);
end;

function GetFirstYPos(F: TField; var FP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet die erste gueltige Position in einer Spalte.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition

	Out:
		True, wenn Position gefunden
*****************************************************************************)
begin
	{ Pruefen, ob die Ausgangsposition auf der mittleren Spalte in der unteren
		Haelfte liegt }
	if (FP.X = cFieldSquareCount) and (FP.Y >= High(TFieldSquareCount)) then
		{ Position auf die untere Kante des inneren Quadrates setzen }
		FP.Y := High(TFieldSquareCount)
	else
		{ Position auf obere Kante setzen }
		FP.Y := Low(TFieldHeight);
	{ Pruefen ob Position gueltig und Rueckgabewert setzen }
	if F.Pos[FP.X, FP.Y].Valid then
		GetFirstYPos := true
	else
		{ Naechstuntere Position suchen }
		GetFirstYPos := GetLowerFieldPos(F, FP);
end;

function GetPlayerStage(PlacedTC, CapturedTC: TTokenCount): TPlayerStage;
(*****************************************************************************
	Beschreibung:
		Berechnet die Spielerphase anhand der Anzahl der Spielsteine.

	In:
		PlacedTC: TTokenCount: Gesetzte Spielsteine
		CapturedTC: TTokenCount: Geschlagene Spielsteine

	Out:
		Spielerphase
*****************************************************************************)
begin
	{ Noch nicht alle Spielsteine gesetzt }
	if PlacedTC < cTokenCount then
		{ Setzphase }
		GetPlayerStage := psPlace
	{ Genug Steine zum Springen verloren }
	else if cTokenCount - CapturedTC = cFieldSquareCount then
		{ Sprungphase }
		GetPlayerStage := psFly
	else
		{ Ziehphase }
		GetPlayerStage := psMove;
end;

function FieldPosToStr(FP: TFieldPos): string;
(*****************************************************************************
	Beschreibung:
		Ausgabe der Position als String.

	In:
		FP: TFieldPos: Position

	Out:
		Position als String
*****************************************************************************)
begin
	FieldPosToStr := Chr(Ord('a') + FP.X) + Chr(Ord('1') + FP.Y);
end;

function OwnerToPlayer(O: TOwner): TPlayer;
(*****************************************************************************
	Beschreibung:
		Umwandlung von Besitzer zum Spieler.

	In:
		O: TOwner: Besitzer

	Out:
		Enstprechneder Spieler
*****************************************************************************)
begin
	{ Besitzer auswerten und entsprecheneden Spieler als Rueckgabewert }
	if O = oUser then
		OwnerToPlayer := User
	else if O = oCPU then
		OwnerToPlayer := CPU;
end;

procedure LogMove(P: TPlayer; MD: TMoveData);
(*****************************************************************************
	Beschreibung:
		Bereitet Zugdaten zum Schreiben in die Logdatei vor und sendet diese an
		den Logger.

	In:
		P: TPlayer: Spieler, der gezogen hat
		MD: TMoveData: Zugdaten

	Out:
		-
*****************************************************************************)
var
	LM: TLoggerMessage;
begin
	{ Nachrichtenart als Logmeldung markieren }
	LM.Kind := lomkLog;
	{ Erstes Zeichen des Spielernamens stellt den ziehenden Spieler in der
		Logdatei dar }
	LM.Message := Copy(PlayerToStr(P), 1, 1) + ' ';
	case MD.Kind of
		{ Spieler konnte nicht ziehen oder schlagen }
		mkNoMove:
			LM.Message := LM.Message + '.';
		{ Spieler hat gesetzt }
		mkPlace:
			LM.Message := LM.Message + '* ' + FieldPosToStr(MD.TargetFP);
		{ Spieler hat gezogen }
		mkMove:
			LM.Message := LM.Message + '  ' + FieldPosToStr(MD.SourceFP) + ' ' +
				FieldPosToStr(MD.TargetFP);
		{ Spieler hat geschlagen }
		mkCapture:
			LM.Message := LM.Message + 'x ' + FieldPosToStr(MD.SourceFP);
		{ Dem Spieler wurde ein Stein geklaut }
		mkSteal:
			LM.Message := LM.Message + '- ' + FieldPosToStr(MD.SourceFP);
	end;
	{ Zug als String in die Logmailbox ablegen }
	LoggerMB.Put(Logger.Mailbox, LM);
end;

function GetOtherPlayer(CurrentPlayer: TPlayer): TPlayer;
(*****************************************************************************
	Beschreibung:
		Liefert den anderen Spieler zurueck.

	In:
		CurrentPlayer: TPlayer: Aktueller Spieler

	Out:
		Anderer Spieler
*****************************************************************************)
begin
	{ Aktuellen Spieler auswerten und den anderen zurueck liefern }
	if CurrentPlayer = High(TPlayer) then
		GetOtherPlayer := Low(TPlayer)
	else
		GetOtherPlayer := Succ(CurrentPlayer);
end;


procedure Log(S: string);
(*****************************************************************************
	Beschreibung:
		Sendet eine Logmeldung an den Logger.

	In:
		S: string: Meldung

	Out:
		-
*****************************************************************************)
var
	LM: TLoggerMessage;
begin
	{ Nachricht als Logmeldung markieren }
	LM.Kind := lomkLog;
	LM.Message := S;
	{ Nachricht in der Loggermailbox ablegen }
	LoggerMB.Put(Logger.Mailbox, LM);
end;

end.