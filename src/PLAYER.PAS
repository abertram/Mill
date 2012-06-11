unit Player;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit enthaelt die Spielertask sowohl fuer den Benutzer als auch fuer
	den CPU-Spieler.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	Types;

{ Spielertask. }
procedure PlayerTask;
{ Ueberprueft, ob ein Spieler eine Muehle in einer Spalte hat. }
function HasMillInCol(F: TField; FP: TFieldPos; O: TOwner): boolean;
{ Ueberprueft, ob ein Spieler eine Muehle in einer Zeile hat. }
function HasMillInRow(F: TField; FP: TFieldPos; O: TOwner): boolean;

implementation

uses
	RTKernel, RTTextIO, Timer,
	Tools, Token, PTypes, TokenMsg, LeadMB, Leader, PlayMsg, Semas,
		DispMB, PIPXSnd;

procedure ShowStatistic(var f: text; Color: byte; TokenCount: TTokenCount;
	TimeLimit, MaxTimeLimit: TTimeLimit);
(*****************************************************************************
	Beschreibung:
		Zeigt die Statistik des Spielers an.

	In:
		f: text: Textvariable des Ausgabefensters
		Color: byte: Spielerfarbe
		TokenCount: TTokenCount: Anzahl der Spielsteine
		TimeLimit: TTimeLimit: Aktuelle Bedenkzeit
		MaxTimeLimit: TTimeLimit: Maximale Bedenkzeit

	Out:
		-
*****************************************************************************)
begin
	Write(f, FormFeed);
	WriteLn(f, 'Farbe:           ', ColorToStr(Color));
	WriteLn(f, 'Spielsteine:     ', IntToStr(TokenCount, 0));
	WriteLn(f, 'Akt. Bedenkzeit: ', TimeLimit, ' Sekunde(n)');
	Write(f, 'Max. Bedenkzeit: ', MaxTimeLimit, ' Sekunde(n)');
end;

function GetFirstNotPlacedToken(PTD: TPlayerTokenData): TaskHandle;
(*****************************************************************************
	Beschreibung:
		Gibt das Taskhandle des ersten nicht gesetzten Spielsteins zurueck.

	In:
		PTD: TPlayerTokenData: Spielsteindaten

	Out:
		Taskhandle des ersten nicht gesetzten Spielsteins
*****************************************************************************)
var
	i: TTokenCount;
begin
	i := Low(TTokenCount);

	{ Spielsteine durchsuchen und Zustand auswerten }
	while (i < cTokenCount) and (PTD[i].State <> tsNotPlaced) do
		Inc(i);

	GetFirstNotPlacedToken := PTD[i].TokenTH;
end;

function GetTokenByTaskHandle(TTH: TaskHandle;
	PTD: TPlayerTokenData): TTokenCount;
(*****************************************************************************
	Beschreibung:
		Berechnet die Spielsteinnummer anhand des Taskhandles.

	In:
		TTH: TaskHandle: Spielstein-Taskhandle
		PTD: TPlayerTokenData: Spielsteindaten

	Out:
		Spielsteinnummer
*****************************************************************************)
var
	i: TTokenCount;
begin
	i := Low(TTokenCount);

	{ Spielsteine durchsuchen und Taskhandles vergleichen }
	while (i < cTokenCount) and (TTH <> PTD[i].TokenTH) do
		Inc(i);

	GetTokenByTaskHandle := i;
end;

function GetEqualTokenCountInCol(F: TField; FP: TFieldPos;
	O: TOwner): TTokenCount;
(*****************************************************************************
	Beschreibung:
		Berechnet die Anzahl der Spielsteine eines Spielers in einer Spalte.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Feldposition, mit der zu durchsuchenden Spalte
		O: TOwner: Spieler, dessen Spielsteine gezaehlt werden

	Out:
		Anzahl der Spielsteine
*****************************************************************************)
var
	ifsc: TFieldSquareCount;
	itc: TTokenCount;
begin
	itc := Low(TTokenCount);

	{ In die oberste Zeile }
	GetFirstYPos(F, FP);
	{ Schleife ueber die Anzahl der Quadrate }
	for ifsc := 0 to cFieldSquareCount - 1 do
	begin
		{ Spieler an der aktuellen Position mit dem uebergebenen vergleichen }
		if F.Pos[FP.X, FP.Y].Owner = O then
			Inc(itc);
		{ Eine Position tiefer }
		GetLowerFieldPos(F, FP);
	end;

	GetEqualTokenCountInCol := itc;
end;

function GetFirstPosInColByOwner(F: TField; var FP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet die erste Position in einer Spalte anhand eines Spielers.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Feldposition mit der zu durchsuchenden Spalte
		O: TOwner: Spieler, dessen Spielstein gesucht wird

	Out:
		True, wenn Spielstein gefunden
		FP: TFieldPos: Feldposition des gefundenen Spielsteines
*****************************************************************************)
var
	ifsc: TFieldSquareCount;
	Found: boolean;
	TmpFP: TFieldPos;
begin
	Found := false;

	{ Position merken }
	TmpFP := FP;
	ifsc := Low(TFieldSquareCount);
	{ Oberste Zeile }
	GetFirstYPos(F, FP);
	{ Suchen, bis Anzahl der Quadrate erreicht oder die Position gefunden
		wurde }
	while (ifsc < cFieldSquareCount) and not Found do
	begin
		{ Spieler vergleichen }
		Found := F.Pos[FP.X, FP.Y].Owner = O;
		if not Found then
			{ Eine Position tiefer }
			GetLowerFieldPos(F, FP);
		Inc(ifsc);
	end;
	{ Wenn nicht gefunden, Position nicht veraendern }
	if not Found then
		FP := TmpFP;

	GetFirstPosInColByOwner := Found;
end;

function GetFirstPosInRowByOwner(F: TField; var FP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet die erste Position in einer Zeile anhand eines Spielers.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Feldposition mit der zu durchsuchenden Zeile
		O: TOwner: Spieler, dessen Spielstein gesucht wird

	Out:
		True, wenn Spielstein gefunden
		FP: TFieldPos: Feldposition des gefundenen Spielsteines
*****************************************************************************)
var
	ifsc: TFieldSquareCount;
	Found: boolean;
	TmpFP: TFieldPos;
begin
	Found := false;

	{ Position merken }
	TmpFP := FP;
	ifsc := Low(TFieldSquareCount);
	{ In die erste Spalte }
	GetFirstXPos(F, FP);
	{ Suchen }
	while (ifsc < High(TFieldSquareCount)) and not Found do
	begin
		{ Spieler vergleichen }
		Found := F.Pos[FP.X, FP.Y].Owner = O;
		if not Found then
			{ Eine Position nach rechts }
			GetRightFieldPos(F, FP);
		Inc(ifsc);
	end;
	{ Wenn nicht gefunden, Position wiederherstellen }
	if not Found then
		FP := TmpFP;

	GetFirstPosInRowByOwner := Found;
end;

function GetNextPosInColByOwner(F: TField; var FP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht ausgehend von einer Position nach der naechsten Position in einer
		Spalte anhand des Spielers.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition
		O: TOwner: Spieler

	Out:
		True, wenn gefunden
		FP: TFieldPos: Gefundene Spielfeldposition
*****************************************************************************)
var
	Found: boolean;
	TmpFP: TFieldPos;
begin
	Found := false;

	{ Position merken }
	TmpFP := FP;
	{ Suchen }
	while not Found and GetLowerFieldPos(F, FP) do
		Found := F.Pos[FP.X, FP.Y].Owner = O;
	{ Wenn nicht gefunden, Position wiederherstellen }
	if not Found then
		FP := TmpFP;

	GetNextPosInColByOwner := Found;
end;

function GetNextPosInRowByOwner(F: TField; var FP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht ausgehend von einer Position nach der naechsten Position in einer
		Zeile anhand des Spielers.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Ausgangsposition
		O: TOwner: Spieler

	Out:
		True, wenn gefunden
		FP: TFieldPos: Gefundene Spielfeldposition
*****************************************************************************)
var
	Found: boolean;
	TmpFP: TFieldPos;
begin
	Found := false;

	{ Position merken }
	TmpFP := FP;
	{ Suchen }
	while not Found and GetRightFieldPos(F, FP) do
		Found := F.Pos[FP.X, FP.Y].Owner = O;
	{ Wenn nicht gefunden, Position wiederherstellen }
	if not Found then
		FP := TmpFP;

	GetNextPosInRowByOwner := Found;
end;

function CanCloseMillInCol(F: TField; var SFP, TFP: TFieldPos;
	O1, O2: TOwner; O2Stage: TPlayerStage): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet, ob ein Spieler beim naechsten Zug eine Muehle in einer Spalte
		schliessen und je nach Parameter, ob der andere Spieler diese Muehle
		verhindern kann.
		O1 = O2: Ueberpruefen, ob ein Spieler eine Muehle schliessen kann.
		O1 <> O2: Ueberpruefen, ob O1 eine Muehle schliessen und O2 diese
			verhindern kann.

	In:
		F: TField: Spielfeld
		O1: TOwner: Spieler, der die Muehle schliessen kann
		O2: TOwner: Spieler, der die Muehle schliessen / verhindern kann
		O2Stage: TPlayerStage: Spielphase des Spielers, der die Muehle
			schliessen / verhindern kann

	Out:
		True, wenn Muehle geschlossen werden kann.
		SFP: TFieldPos: Position des Spielsteines, der die Muehle schliessen kann
		TFP: TFieldPos: Position, auf der der Spielstein fehlt
*****************************************************************************)
var
	CanClose: boolean;
begin
	{ Muehle moeglich, wenn der erste Spieler alle Positionen bis auf eine
		besetzt hat und diese frei ist }
	CanClose := (GetEqualTokenCountInCol(F, TFP, O1) = cFieldSquareCount - 1)
		and (GetEqualTokenCountInCol(F, TFP, oNone) = 1);
	{ Wenn Muehle moeglich, ueberpruefen, ob sie auch geschlossen werden kann }
	if CanClose then
	begin
		{ Freie Position suchen }
		GetFirstPosInColByOwner(F, TFP, oNone);
		{ Quellposition auf Zielposition }
		SFP := TFP;
		{ Spielerphase des ersten Spielers auswerten }
		case GetPlayerStage(F.PlacedTC[OwnerToPlayer(O1)],
				F.CapturedTC[OwnerToPlayer(O1)]) of
			{ Spieler kann noch setzen und somit beim naechsten Zug eine Muehle
				schliessen }
			psPlace:
				{ Falls der zweite Spieler schlagen kann wird ein Stein des ersten
					Spielers aus der fast vollstaendigen Muehle geschlagen }
				GetFirstPosInColByOwner(F, SFP, O1);
			{ Spieler ist in der Ziehphase }
			psMove:
			begin
				SFP := TFP;
				{ Ueberpruefen, ob der erste Spieler links oder rechts von der
					Zielposition einen Stein hat }
				CanClose := GetLeftFieldPos(F, SFP) and
					(F.Pos[SFP.X, SFP.Y].Owner = O1);
				if not CanClose then
				begin
					SFP := TFP;
					CanClose := GetRightFieldPos(F, SFP) and
						(F.Pos[SFP.X, SFP.Y].Owner = O1);
				end;
			end;
		end;
		{ Ueberpruefen, ob der zweitgenannte Spieler die moegliche Muehele
			schliessen / verhindern kann }
		if CanClose then
		begin
			{ Spielerphase des zweiten Spielers auswerten }
			case O2Stage of
				{ Spieler zieht }
				psMove:
				begin
					{ Uberpruefen, ob links oder rechts ein Stein von Spieler zwei
						steht }
					SFP := TFP;
					CanClose := GetLeftFieldPos(F, SFP) and
						(F.Pos[SFP.X, SFP.Y].Owner = O2);
					if not CanClose then
					begin
						SFP := TFP;
						CanClose := GetRightFieldPos(F, SFP) and
							(F.Pos[SFP.X, SFP.Y].Owner = O2);
					end;
				end;
				{ Spieler kann springen }
				psFly:
				begin
					CanClose := false;

					{ Spalte suchen, in der der letzte Stein steht }
					SFP.X := Low(TFieldWidth);
					while (SFP.X < High(TFieldWidth)) and not CanClose do
					begin
						{ Die Zielspalte auslassen }
						if (SFP.X <> TFP.X) then
						begin
							SFP.Y := 0;
							CanClose := GetFirstPosInColByOwner(F, SFP, O2);
							if not CanClose and (SFP.X = cFieldSquareCount) then
							begin
								SFP.Y := cFieldSquareCount;
								CanClose := GetFirstPosInColByOwner(F, SFP, O2);
							end;
						end;
						{ Es sei denn, die Zielspalte ist die mittlere Spalte, die in
							zwei Spalten unterteilt ist und anders behandlet werden muss }
						if (TFP.X = cFieldSquareCount) and
							(SFP.X = cFieldSquareCount) then
						begin
							{ Zielposition ist in der unteren Haelfte }
							if TFP.Y > cFieldSquareCount then
							begin
								{ Stein in der oberen Haelfte suchen }
								SFP.Y := 0;
								CanClose := GetFirstPosInColByOwner(F, SFP, O2);
							end
							{ Zielposition ist in der oberen Haelfte }
							else if TFP.Y < cFieldSquareCount then
							begin
								{ Stein in der unteren Haelfte suchen }
								SFP.Y := cFieldSquareCount;
								CanClose := GetFirstPosInColByOwner(F, SFP, O2);
							end;
						end;
						{ Wenn nichts gefunden, eine Spalte weiter }
						if not CanClose then
							Inc(SFP.X);
					end;
				end;
				{ Spieler schlaegt }
				psCapture:
				begin
					SFP := TFP;
					GetFirstPosInColByOwner(F, SFP, O1);
				end;
			end;
		end;
	end;
	CanCloseMillInCol := CanClose;
end;

function GetEqualTokenCountInRow(F: TField; FP: TFieldPos;
	O: TOwner): TTokenCount;
(*****************************************************************************
	Beschreibung:
		Berechnet die Anzahl der gleichen Spielsteine in einer Zeile anhand des
		Spielers.

	In:
		F: TField: Spielfeld
		FP: TFieldPos: Position mit der Zeile
		O: TOwner: Spieler

	Out:
		Anzahl der Spielsteine
*****************************************************************************)
var
	ifsc: TFieldSquareCount;
	itc: TTokenCount;
begin
	itc := Low(TTokenCount);

	{ In die erste Spalte }
	GetFirstXPos(F, FP);
	{ Alle Kreuzungspunkte durchsuchen }
	for ifsc := 0 to cFieldSquareCount - 1 do
	begin
		{ Spielsteine vergleichen }
		if F.Pos[FP.X, FP.Y].Owner = O then
			Inc(itc);
		{ Eine Position nach rechts }
		GetRightFieldPos(F, FP);
	end;

	GetEqualTokenCountInRow := itc;
end;

function CanCloseMillInRow(F: TField; var SFP, TFP: TFieldPos;
	O1, O2: TOwner; O2Stage: TPlayerStage): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet, ob ein Spieler beim naechsten Zug eine Muehle in einer Zeile
		schliessen und je nach Parameter, ob der andere Spieler diese Muehle
		verhindern kann.
		O1 = O2: Ueberpruefen, ob ein Spieler eine Muehle schliessen kann.
		O1 <> O2: Ueberpruefen, ob O1 eine Muehle schliessen und O2 diese
			verhindern kann.

	In:
		F: TField: Spielfeld
		O1: TOwner: Spieler, der die Muehle schliessen kann
		O2: TOwner: Spieler, der die Muehle schliessen / verhindern kann
		O2Stage: TPlayerStage: Spielphase des Spielers, der die Muehle
			schliessen / verhindern kann

	Out:
		True, wenn Muehle geschlossen werden kann.
		SFP: TFieldPos: Position des Spielsteines, der die Muehle schliessen kann
		TFP: TFieldPos: Position, auf der der Spielstein fehlt
*****************************************************************************)
var
	CanClose: boolean;
begin
	{ Muehle moeglich, wenn der erste Spieler alle Positionen bis auf eine
		besetzt hat und diese frei ist }
	CanClose := (GetEqualTokenCountInRow(F, TFP, O1) = cFieldSquareCount - 1)
		and (GetEqualTokenCountInRow(F, TFP, oNone) = 1);
	{ Wenn moeglich, ueberpruefen, ob der erstgenannte Spieler sie auch schliessen
		kann }
	if CanClose then
	begin
		{ Zielposition auf die freie Stelle }
		GetFirstPosInRowByOwner(F, TFP, oNone);
		SFP := TFP;
		{ Spielerphase der erstgenannten Spielers ueberpruefen }
		case GetPlayerStage(F.PlacedTC[OwnerToPlayer(O1)],
				F.CapturedTC[OwnerToPlayer(O1)]) of
			{ Spieler kann setzen }
			psPlace:
				{ Sollte der zweitgenannte Spieler schlagen koennen, wird die in der
					naechsten Anweisung Quellposition genommen }
				GetFirstPosInRowByOwner(F, SFP, O1);
			{ Spieler zieht }
			psMove:
			begin
				SFP := TFP;
				{ Ueberpruefen, ob oben oder unten ein Spielstein des erstgenannten
					Spielers steht. Wenn ja, kann der Spieler eine Muehle bauen }
				CanClose := GetUpperFieldPos(F, SFP) and
					(F.Pos[SFP.X, SFP.Y].Owner = O1);
				if not CanClose then
				begin
					SFP := TFP;
					CanClose := GetLowerFieldPos(F, SFP) and
						(F.Pos[SFP.X, SFP.Y].Owner = O1);
				end;
			end;
		end;
		{ Ueberpruefen, ob der zweitgenannte Spieler die moegliche Muehele
			schliessen / verhindern kann }
		if CanClose then
		begin
			{ Spielerphase des zweitgenannten Spielers ueberpruefen }
			case O2Stage of
				{ Ziehen }
				psMove:
				begin
					SFP := TFP;
					{ Ueberpruefen, ob oben oder unten ein Spielstein des zweitgenannten
						Spielers steht. Wenn ja kann die Muehle geschlossen werden }
					CanClose := GetUpperFieldPos(F, SFP) and
						(F.Pos[SFP.X, SFP.Y].Owner = O2);
					if not CanClose then
					begin
						SFP := TFP;
						CanClose := GetLowerFieldPos(F, SFP) and
							(F.Pos[SFP.X, SFP.Y].Owner = O2);
					end;
				end;
				{ Spieler kann springen }
				psFly:
				begin
					CanClose := false;
					{ Zeile suchen, in der der letzte Spielstein steht }
					SFP.Y := 0;
					while (SFP.Y < cFieldHeight) and not CanClose do
					begin
						{ Zielzeile auslassen }
						if (SFP.Y <> TFP.Y) then
						begin
							SFP.X := 0;
							CanClose := GetFirstPosInRowByOwner(F, SFP, O2);
							if not CanClose and (SFP.Y = cFieldSquareCount) then
							begin
								SFP.X := cFieldSquareCount;
								CanClose := GetFirstPosInRowByOwner(F, SFP, O2);
							end;
						end;
						{ Es sein denn, es ist die mittlere Zeile. Diese ist in zwei
							Zeilen unterteilt und muss gesondert behandelt werden }
						if (TFP.Y = cFieldSquareCount) and
							(SFP.Y = cFieldSquareCount) then
						begin
							{ Zielspalte ist in der rechten Haelfte }
							if TFP.X > cFieldSquareCount then
							begin
								{ Position in der linken Haelfte suchen }
								SFP.X := 0;
								CanClose := GetFirstPosInRowByOwner(F, SFP, O2);
							end
							else if TFP.X < cFieldSquareCount then
							begin
								{ Position in der rechten Haelfte suchen }
								SFP.X := cFieldSquareCount;
								CanClose := GetFirstPosInRowByOwner(F, SFP, O2);
							end;
						end;
						{ Wenn nichts gefunden, eine Zeile weiter }
						if not CanClose then
							Inc(SFP.Y);
					end;
				end;
				{ Spieler kann schlagen }
				psCapture:
				begin
					SFP := TFP;
					GetFirstPosInRowByOwner(F, SFP, O1);
				end;
			end;
		end;
	end;

	CanCloseMillInRow := CanClose;
end;

function CanCloseMillInCols(F: TField; var SFP, TFP: TFieldPos;
	O1, O2: TOwner; O2Stage: TPlayerStage): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob in den Spalten eine Muehle geschlossen und / oder
		verhindert werden kann.

	In:
		F: TField: Spielfeld
		O1: TOwner: Spieler, der die Muehle schlissen kann
		O2: TOwner: Spieler, der die Muehle schliessen / verhindern kann
		O2Stage: TPlayerStage: Spielerphase des zweitgenannten Spielers

	Out:
		True, wenn eine Muehle in einer Spalte geschlossen werden kann.
		SFP: TFieldPos: Quellposition zum Schliessen / Verhindern der Muehle
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanClose: boolean;
begin
	CanClose := false;

	{ Spalten durchsuchen }
	while (TFP.X < High(TFieldWidth)) and not CanClose do
	begin
		{ In der obersten Zeile beginnen }
		TFP.Y := Low(TFieldHeight);
		GetFirstYPos(F, TFP);
		{ Aktuelle Spalte ueberpruefen }
		CanClose := CanCloseMillInCol(F, SFP, TFP, O1, O2, O2Stage);
		{ Mittlere Spalte muss zwei Mal durchsucht werden }
		if (TFP.X = cFieldSquareCount) and not CanClose then
		begin
			TFP.Y := cFieldSquareCount;
			GetFirstYPos(F, TFP);
			CanClose := CanCloseMillInCol(F, SFP, TFP, O1, O2, O2Stage);
		end;
		{ Wenn nichts gefudnen, eine Spalte weiter }
		if not CanClose then
			Inc(TFP.X);
	end;

	CanCloseMillInCols := CanClose;
end;

function CanCloseMillInRows(F: TField; var SFP, TFP: TFieldPos;
	O1, O2: TOwner; O2Stage: TPlayerStage): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob eine Muehle in den Zeilen geschlossen werden kann.

	In:
		F: TField: Spielfeld
		O1: TOwner: Spieler, der die Muehle schliessen kann
		O2: TOwner: Spieler, der die Muehle schliessen / verhindern kann
		O2Stage: TPlayerStage: Spielerphase des zweitgenannten Spielers

	Out:
		True, wenn Muehle geschlossen werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanClose: boolean;
begin
	CanClose := false;

	{ Zeilen durchsuchen }
	while (TFP.Y < High(TFieldHeight)) and not CanClose do
	begin
		{ In der ersten Spallte anfangen }
		TFP.X := Low(TFieldWidth);
		GetFirstXPos(F, TFP);
		{ Zeile ueberpruefen }
		CanClose := CanCloseMillInRow(F, SFP, TFP, O1, O2, o2Stage);
		{ Mittlere Zeile gesondert behandeln }
		if (TFP.Y = cFieldSquareCount) and not CanClose then
		begin
			TFP.X := cFieldSquareCount;
			GetFirstXPos(F, TFP);
			CanClose := CanCloseMillInRow(F, SFP, TFP, O1, O2, O2Stage);
		end;
		if not CanClose then
			Inc(TFP.Y);
	end;

	CanCloseMillInRows := CanClose;
end;

function CanCloseMill(F: TField; var SFP, TFP: TFieldPos;
	O1, O2: TOwner; O2Stage: TPlayerStage): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob eine Muehle geschlossen werden kann.

	In:
		F: TField: Spielfeld
		O1: TOwner: Spieler, der die Muehle schliessen kann
		O2: TOwner: Spieler, der die Muehle schliessen / verhindern kann
		O2Stage: TPlayerStage: Spielerphase des zweitgenannten Spielers

	Out:
		True, wenn Muehle geschlossen werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanClose: boolean;
begin
	CanClose := false;

	{ Spalten durchsuchen }
	TFP.X := Low(TFieldWidth);
	CanClose := CanCloseMillInCols(F, SFP, TFP, O1, O2, O2Stage);
	if not CanClose then
		TFP.Y := Low(TFieldHeight);

	{ Wenn nichts gefunden, Zeilen durchsuchen }
	CanCloseMill := CanClose or CanCloseMillInRows(F, SFP, TFP, O1, O2,
		O2Stage);
end;

function CanPrepareMillInCol(F: TField; var SFP, TFP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob ein Spieler eine Muehle in einer Spalte vorbereiten kann.

	In:
		F: TField: Spielfeld
		O: TOwner: Spieler

	Out:
		True, wenn Muehle vorbereitet werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanPrepare: boolean;
begin
	{ Muehle kann vorbereitet werden, wenn der Spieler in der Spalte mehr als
		einen Stein hat und die anderen Positionen frei sind }
	CanPrepare := (GetEqualTokenCountInCol(F, TFP, O) > Low(TFieldSquareCount))
		and (GetEqualTokenCountInCol(F, TFP, oNone) =
		(High(TFieldSquareCount) - 1));
	{ Erste frei Position suchen }
	CanPrepare := CanPrepare and GetFirstPosInColByOwner(F, TFP, oNone);
	{ Wenn Muehle vorbereitet werden kann }
	if CanPrepare then
	begin
		{ Sielerphase ueberpruefen }
		case GetPlayerStage(F.PlacedTC[OwnerToPlayer(O)],
				F.CapturedTC[OwnerToPlayer(O)]) of
			{ Ziehen }
			psMove:
			begin
				{ Spaltenpositionen von oben nach unten durchsuchen und ueberpruefen,
					ob links oder rechts davon eigene Spielsteine stehen }
				repeat
					SFP := TFP;
					CanPrepare := GetLeftFieldPos(F, SFP) and
						(F.Pos[SFP.X, SFP.Y].Owner = O);
					if not CanPrepare then
					begin
						SFP := TFP;
						CanPrepare := GetRightFieldPos(F, SFP) and
							(F.Pos[SFP.X, SFP.Y].Owner = O);
					end;
				until not CanPrepare or not GetNextPosInColByOwner(F, TFP, oNone);
			end;
			{ Springen }
			psFly:
			begin
				CanPrepare := false;
				{ Andere Steine suchen }
				SFP.X := Low(TFieldWidth);
				while (SFP.X < High(TFieldWidth)) and not CanPrepare do
				begin
					{ Zielspalte auslassen }
					if (SFP.X <> TFP.X) then
					begin
						SFP.Y := 0;
						CanPrepare := GetFirstPosInColByOwner(F, SFP, O);
						if not CanPrepare and (SFP.X = cFieldSquareCount) then
						begin
							SFP.Y := cFieldSquareCount;
							CanPrepare := GetFirstPosInColByOwner(F, SFP, O);
						end;
					end;
					{ Mittlere Spalte gesondert behandeln }
					if (TFP.X = cFieldSquareCount) and
						(SFP.X = cFieldSquareCount) then
					begin
						{ Zielzeile in der unteren Haelfte }
						if TFP.Y > cFieldSquareCount then
						begin
							{ Quellposition in der oberen Haelfte suchen }
							SFP.Y := 0;
							CanPrepare := GetFirstPosInColByOwner(F, SFP, O);
						end
						{ Zielzeile in der unteren Haelfte }
						else if TFP.Y < cFieldSquareCount then
						begin
							{ Quellposition in der unteren HAelfte suchen }
							SFP.Y := cFieldSquareCount;
							CanPrepare := GetFirstPosInColByOwner(F, SFP, O);
						end;
					end;
					{ Wenn nichts gefunden, eine Spalte weiter }
					if not CanPrepare then
						Inc(SFP.X);
				end;
			end;
		end;
	end;

	CanPrepareMillInCol := CanPrepare;
end;

function CanPrepareMillInCols(F: TField; var SFP, TFP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob ein Spieler eine Muehle in den Spalten vorbereitet kann.

	In:
		F: TField: Spielfeld
		O: TOwner: Spieler

	Out:
		True, wenn Muehle vorbereitet werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanPrepare: boolean;
begin
	CanPrepare := false;

	{ Spalten durchsuchen }
	while (TFP.X < High(TFieldWidth)) and not CanPrepare do
	begin
		{ In der ersten Zeile beginnen }
		TFP.Y := Low(TFieldHeight);
		GetFirstYPos(F, TFP);
		{ Spalte ueberpruefen }
		CanPrepare := CanPrepareMillInCol(F, SFP, TFP, O);
		{ Mittlere Spalte gesondert behandeln }
		if (TFP.X = cFieldSquareCount) and not CanPrepare then
		begin
			TFP.Y := cFieldSquareCount;
			GetFirstYPos(F, TFP);
			CanPrepare := CanPrepareMillInCol(F, SFP, TFP, O);
		end;
		if not CanPrepare then
			{ Eine Spalte weiter }
			Inc(TFP.X);
	end;

	CanPrepareMillInCols := CanPrepare;
end;

function CanPrepareMillInRow(F: TField; var SFP, TFP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob ein Spieler eine Muehle in den Zeilen vorbereiten kann.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn Muehle vorbereitet werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanPrepare: boolean;
begin
	{ Muehle kann vorbereitet werden, wenn der Spieler in der Spalte mehr als
		einen Stein hat und die anderen Positionen frei sind }
	CanPrepare := (GetEqualTokenCountInRow(F, TFP, O) > Low(TFieldSquareCount))
		and (GetEqualTokenCountInRow(F, TFP, oNone) =
		(High(TFieldSquareCount) - 1));
	{ Erste frei Position suchen }
	CanPrepare := CanPrepare and GetFirstPosInRowByOwner(F, TFP, oNone);
	{ Wenn Muehle vorbereitet werden kann }
	if CanPrepare then
	begin
		{ Sielerphase ueberpruefen }
		case GetPlayerStage(F.PlacedTC[OwnerToPlayer(O)],
				F.CapturedTC[OwnerToPlayer(O)]) of
			{ Ziehen }
			psMove:
			begin
				{ Freie Zeilenpositionen von links nach rechts durchsuchen und
					pruefen, ob oben oder unten eigene Spielstein stehen }
				repeat
					SFP := TFP;
					CanPrepare := GetUpperFieldPos(F, SFP) and
						(F.Pos[SFP.X, SFP.Y].Owner = O);
					if not CanPrepare then
					begin
						SFP := TFP;
						CanPrepare := GetLowerFieldPos(F, SFP) and
							(F.Pos[SFP.X, SFP.Y].Owner = O);
					end;
				until not CanPrepare or not GetNextPosInRowByOwner(F, TFP, oNone);
			end;
			{ Springen }
			psFly:
			begin
				CanPrepare := false;
				{ Andere Spielsteine zeilenweise suchen }
				SFP.Y := 0;
				while (SFP.Y < cFieldHeight) and not CanPrepare do
				begin
					{ Zielzeile auslassen }
					if (SFP.Y <> TFP.Y) then
					begin
						SFP.X := 0;
						CanPrepare := GetFirstPosInRowByOwner(F, SFP, O);
						if not CanPrepare and (SFP.Y = cFieldSquareCount) then
						begin
							SFP.X := cFieldSquareCount;
							CanPrepare := GetFirstPosInRowByOwner(F, SFP, O);
						end;
					end;
					{ Mittlere Zeile gesondert behandeln }
					if (TFP.Y = cFieldSquareCount) and
						(SFP.Y = cFieldSquareCount) then
					begin
						{ Zielspalte in der rechten Haelfte }
						if TFP.X > cFieldSquareCount then
						begin
							{ Linke Haelfte durchsuchen }
							SFP.X := 0;
							CanPrepare := GetFirstPosInRowByOwner(F, SFP, O);
						end
						{ Zielzeile in der linken Haelfte }
						else if TFP.X < cFieldSquareCount then
						begin
							{ Rechte Haelfte durchsuchen }
							SFP.X := cFieldSquareCount;
							CanPrepare := GetFirstPosInRowByOwner(F, SFP, O);
						end;
					end;
					if not CanPrepare then
						{ Eine Zeile weiter }
						Inc(SFP.Y);
				end;
			end;
		end;
	end;

	CanPrepareMillInRow := CanPrepare;
end;

function CanPrepareMillInRows(F: TField; var SFP, TFP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob ein Spieler eine Muehle in den Zeilen vorbereiten kann.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn Muehle vorbereitet werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanPrepare: boolean;
begin
	CanPrepare := false;

	{ Zeilen durchsuchen }
	while (TFP.Y < High(TFieldHeight)) and not CanPrepare do
	begin
		{ In der ersten Spalte anfangen }
		TFP.X := Low(TFieldWidth);
		GetFirstXPos(F, TFP);
		{ Zeile ueberpruefen }
		CanPrepare := CanPrepareMillInRow(F, SFP, TFP, O);
		{ Mittlere Zeile gesondert behandeln }
		if (TFP.Y = cFieldSquareCount) and not CanPrepare then
		begin
			TFP.X := cFieldSquareCount;
			GetFirstXPos(F, TFP);
			CanPrepare := CanPrepareMillInRow(F, SFP, TFP, O);
		end;
		if not CanPrepare then
			{ Eine Zeile weiter }
			Inc(TFP.Y);
	end;

	CanPrepareMillInRows := CanPrepare;
end;

function CanPrepareMill(F: TField; var SFP, TFP: TFieldPos;
	O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueftm, ob ein Spieler eine Muehle vorbereiten kann.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn eine Muehle vorbereitet werden kann
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	CanPrepare: boolean;
	itc: TTokenData;
begin
	CanPrepare := false;

	{ Spalten durchsuchen }
	TFP.X := Low(TFieldWidth);
	CanPrepare := CanPrepareMillInCols(F, SFP, TFP, O);
	if not CanPrepare then
		TFP.Y := Low(TFieldHeight);

	{ Wenn nichts gefunden, Zeilen durchsuchen }
	CanPrepareMill := CanPrepare or CanPrepareMillInRows(F, SFP, TFP, O);
end;

function GetFirstColByOwner(F: TField; var FP: TFieldPos; O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht die erste voll besetzte Spalte anhand eines Spielers.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn gefunden
		FP: TFieldPos: Zielposition
*****************************************************************************)
var
	Found: boolean;
begin
	Found := false;

	{ Spalten ab der ersten Spalte durchsuchen }
	FP.X := Low(TFieldWidth);
	while (FP.X < High(TFieldWidth)) and not Found do
	begin
		{ In der ersten Zeile beginnen }
		FP.Y := Low(TFieldHeight);
		GetFirstYPos(F, FP);
		{ Spalte ueberpruefen }
		Found := GetEqualTokenCountInCol(F, FP, O) = cFieldSquareCount;
		{ Mittlere Spalte gesondert behandeln }
		if (FP.X = cFieldSquareCount) and not Found then
		begin
			FP.Y := cFieldSquareCount;
			GetFirstYPos(F, FP);
			Found := GetEqualTokenCountInCol(F, FP, O) = cFieldSquareCount;
		end;
		if not Found then
			{ Eine Spalte weiter }
			Inc(FP.X);
	end;

	GetFirstColByOwner := Found and GetFirstPosInColByOwner(F, FP, oNone);
end;

function GetFirstRowByOwner(F: TField; var FP: TFieldPos; O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht die erste voll besetzte Zeile anhand eines Spielers.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn gefunden
		FP: TFieldPos: Zielposition
*****************************************************************************)
var
	Found: boolean;
begin
	Found := false;

	{ Zeilen ab der ersten Zeile durchsuchen }
	FP.Y := Low(TFieldHeight);
	while (FP.Y < High(TFieldHeight)) and not Found do
	begin
		{ Mit der ersten Spalte beginnen }
		FP.X := Low(TFieldWidth);
		GetFirstXPos(F, FP);
		{ Zeile ueberpruefen }
		Found := GetEqualTokenCountInRow(F, FP, O) = cFieldSquareCount;
		{ Mittlere Zeile gesondert behandeln }
		if (FP.Y = cFieldSquareCount) and not Found then
		begin
			FP.X := cFieldSquareCount;
			GetFirstXPos(F, FP);
			Found := GetEqualTokenCountInRow(F, FP, O) = cFieldSquareCount;
		end;
		if not Found then
			{ Eine Zeile weiter }
			Inc(FP.Y);
	end;

	GetFirstRowByOwner := Found and GetFirstPosInRowByOwner(F, FP, oNone);
end;

function GetFirstPosByOwner(F: TField; var FP: TFieldPos; O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht die erste Position anhand eines Spielers.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn gefunden
		FP: TFieldPos: Zielposition
*****************************************************************************)
var
	Found: boolean;
begin
	Found := false;

	{ Feld ab der ersten Spalte spaltenweise durchsuchen }
	FP.X := Low(TFieldWidth);
	while (FP.X < High(TFieldWidth)) and not Found do
	begin
		{ In der ersten Zeile beginnen }
		FP.Y := Low(TFieldHeight);
		GetFirstYPos(F, FP);
		{ Position in der Spalte suchen }
		Found := GetFirstPosInColByOwner(F, FP, O);
		{ Mittlere Spalte gesondert behandeln }
		if (FP.X = cFieldSquareCount) and not Found then
		begin
			FP.Y := cFieldSquareCount;
			GetFirstYPos(F, FP);
			Found := GetFirstPosInColByOwner(F, FP, O);
		end;
		if not Found then
			{ Eine Spalte weiter }
			Inc(FP.X);
	end;

	GetFirstPosByOwner := Found;
end;

function GetNextPosByOwner(F: TField; var FP: TFieldPos; O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht ausgehen von einer Position die naechste Position anhand eines
		Spielers.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		True, wenn gefunden
		FP: TFieldPos: Zielposition
*****************************************************************************)
var
	Found: boolean;
begin
	Found := false;

	{ Spalten durchsuchen }
	while (FP.X < High(TFieldWidth)) and not Found do
	begin
		{ NAechste Position in der Spalte suchen }
		Found := GetNextPosInColByOwner(F, FP, O);
		{ Mittlere Spalte gesondert behandeln }
		if not Found and (FP.X = cFieldSquareCount) and
			(FP.Y < cFieldSquareCount) then
		begin
			FP.Y := cFieldSquareCount;
			GetFirstYPos(F, FP);
			Found := GetNextPosInColByOwner(F, FP, O);
		end;
		if not Found then
		begin
			{ Eine Spalte weiter und nach der ersten Position suchen }
			Inc(FP.X);
			FP.Y := 0;
			GetFirstYPos(F, FP);
			Found := GetFirstPosInColByOwner(F, FP, O);
		end;
	end;

	GetNextPosByOwner := Found;
end;

function GetDirectionSetElementCount(DS: TDirectionSet): TDirectionCount;
(*****************************************************************************
	Beschreibung:
		Zaehlt die Zierichtungen einer Richtungsmenge.

	In:
		DS: TDirectionSet: Riechtungsmenge

	Out:
		Anzahl der Richtungen
*****************************************************************************)
var
	i,
	DirectionCount: TDirectionCount;
begin
	DirectionCount := Low(TDirectionCount);

	{ Alle Richtungen durchgehen und pruefen, ob sie in der Menge sind }
	for i := Low(TDirectionCount) to High(TDirectionCount) - 1 do
	begin
		if TDirection(i) in DS then
			Inc(DirectionCount);
	end;

	GetDirectionSetElementCount := DirectionCount;
end;

function GetFirstMoveableToken(PTD: TPlayerTokenData;
	var TC: TTokenCount): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht den ersten Spielstein, der ziehen kann.

	In:
		PTD: TPlayerTokenData: Spielsteindaten

	Out:
		True, wenn gefunden
		TC: TTokenCount: Spielsteinnummer
*****************************************************************************)
var
	Found: boolean;
begin
	Found := false;

	{ Spielsteindaten durchgehen }
	TC := Low(TTokenCount);
	while (TC < High(TTokenCount)) and not Found do
	begin
		{ Anzahl der Richtungen ueberpruefen, in die der Stein ziehen kann }
		Found := GetDirectionSetElementCount(PTD[TC].MoveDirections) > 0;
		if not Found then
			Inc(TC);
	end;

	GetFirstMoveableToken := Found;
end;

function GetFirstDirection(DS: TDirectionSet; var D: TDirection): boolean;
(*****************************************************************************
	Beschreibung:
		Gibt die erste Richtung einer Richtungsmenge zurueck.

	In:
		DS: TDirectionSet: Richtungsmenge

	Out:
		True, wenn gefunden
		D: TDirection: Richtung
*****************************************************************************)
var
	i: TDirectionCount;
	Found: boolean;
begin
	Found := false;

	{ Alle Richtungen durchehen }
	i := Low(TDirectionCount);
	while (i < High(TDirectionCount)) and not Found do
	begin
		{ Pruefen, ob die Richtung in der Menge ist }
		D := TDirection(i);
		Found := D in DS;
		if not Found then
			Inc(i);
	end;

	GetFirstDirection := Found;
end;

function GetFirstPossibleMove(F: TField; PTD: TPlayerTokenData; var SFP,
	TFP: TFieldPos): boolean;
(*****************************************************************************
	Beschreibung:
		Sucht den ersten moeglichen Zug.

	In:
		F: TField: Feld
		PTD: TPlayerTokenData: Spielsteindaten

	Out:
		True, wenn gefunden
		SFP: TFieldPos: Quellposition
		TFP: TFieldPos: Zielposition
*****************************************************************************)
var
	Found: boolean;
	D: TDirection;
	TC: TTokenCount;
begin
	{ Ersten Stein suchen, der ziehen kann und die erste Richtung, in die er
		ziehen kann }
	Found := GetFirstMoveableToken(PTD, TC) and
		GetFirstDirection(PTD[TC].MoveDirections, D);
	if Found then
	begin
		{ Richtung auswerten und Zielposition berechnen }
		SFP := PTD[TC].FieldPos;
		TFP := SFP;
		case D of
			dLeft:
				GetLeftFieldPos(F, TFP);
			dRight:
				GetRightFieldPos(F, TFP);
			dUp:
				GetUpperFieldPos(F, TFP);
			dDown:
				GetLowerFieldPos(F, TFP);
		end;
	end;

	GetFirstPossibleMove := Found;
end;

function HasMillInCol(F: TField; FP: TFieldPos; O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob ein Spieler eine Muehle in einer Spalte hat.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		FP: TFieldPos: Position mit der Spalte
*****************************************************************************)
begin
	HasMillInCol := GetEqualTokenCountInCol(F, FP, O) = cFieldSquareCount;
end;

function HasMillInRow(F: TField; FP: TFieldPos; O: TOwner): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob ein Spieler eine Muehle in einer Zeile hat.

	In:
		F: TField: Feld
		O: TOwner: Spieler

	Out:
		FP: TFieldPos: Position mit der Zeile
*****************************************************************************)
begin
	HasMillInRow := GetEqualTokenCountInRow(F, FP, O) = cFieldSquareCount;
end;

procedure SendStageToDisplayComputer(S: TPlayerStage);
(*****************************************************************************
	Beschreibung:
		Sendet die Spielerphase an den Anzeigerechner.

	In:
		S: TPlayerStage: Spielerphase

	Out:
		-
*****************************************************************************)
var
	DM: TDisplayMessage;
begin
	{ Naschrichtart als Spielerphase kennzeichnen }
	DM.Kind := dmkPlayerStage;
	DM.Stage := S;
	{ Nachricht in der Mailbox des IPX-Senders ablegen }
	Debug('Sende Spielerphase an Displayrechner');
	DispMB.Put(PIPXSnd.Mailbox, DM);
	Debug('Spielerphase an Displayrechner gesendet');
end;

function GetCapturePossibilities(F: TField; O: TOwner;
	var MP: TMovePossibilities): boolean;
(*****************************************************************************
	Beschreibung:
		Berechnet Schlagmoeglichkeiten eines Spielers.

	In:
		F: TField: Feld
		O: TOwner: Spieler, dessen Steine geschlagen werden sollen

	Out:
		True, wenn Schlagmoeglichkeiten vorhanden
		MP: TMovePossibilities: Schlagmoeglichkeiten
*****************************************************************************)
var
	FP: TFieldPos;
	ifsc: TFieldSquareCount;
begin
	GetCapturePossibilities := false;

	{ Schlagmoeglichkeiten initialisieren }
	FillChar(MP, SizeOf(MP), false);
	{ Spielfeld spaltenweise durchsuchen }
	FP.X := Low(TFieldWidth);
	while (FP.X < High(TFieldWidth)) do
	begin
		{ Geschlossene Muehlen auslassen }
		if not HasMillInCol(F, FP, O) then
		begin
			{ In der ersten Zeile beginnen }
			FP.Y := 0;
			GetFirstYPos(F, FP);
			{ Kreuzungspunkte durchsuchen }
			for ifsc := Low(TFieldSquareCount) to High(TFieldSquareCount) - 1 do
			begin
				{ Schlagmoeglichkeit berechnen }
				MP[FP.X, FP.Y] := not HasMillInRow(F, FP, O) and
					(F.Pos[FP.X, FP.Y].Owner = O);
				if MP[FP.X, FP.Y] then
					GetCapturePossibilities := true;
				{ Eine Position tiefer }
				GetLowerFieldPos(F, FP);
			end;
		end;
		{ Mittlere Spalte gesondert behandeln }
		if (FP.X = cFieldSquareCount) then
		begin
			{ In der Mitte beginnen }
			FP.Y := cFieldSquareCount;
			GetFirstYPos(F, FP);
			{ Muehlen auslassen }
			if not HasMillInCol(F, FP, O) then
			begin
				for ifsc := Low(TFieldSquareCount) to High(TFieldSquareCount) - 1 do
				begin
					{ Schlagmoeglichkeit berechnen }
					MP[FP.X, FP.Y] := not HasMillInRow(F, FP, O) and
						(F.Pos[FP.X, FP.Y].Owner = O);
					if MP[FP.X, FP.Y] then
						GetCapturePossibilities := true;
					{ Eine Position tiefer }
					GetLowerFieldPos(F, FP);
				end;
			end;
		end;
		{ Eine Zeile weiter }
		Inc(FP.X);
	end;
end;

procedure SendMovePossibilitiesToDisplayComputer(MP: TMovePossibilities);
(*****************************************************************************
	Beschreibung:
		Zugmoeglichkeiten an den Anzeigerechner senden.

	In:
		MP: TMovePossibilities: Zugmoeglichkeiten

	Out:
		-
*****************************************************************************)
var
	DM: TDisplayMessage;
begin
	{ Nachrichtart als Zugmoeglichkeiten markieren }
	DM.Kind := dmkMovePossibilities;
	DM.Possibilities := MP;
	{ Nachricht in die Mailbox des IPX-Senders legen }
	Debug('Sende Zugmoeglichkeiten an Displayrechner');
	DispMB.Put(PIPXSnd.Mailbox, DM);
	Debug('Zugmoeglichkeiten an Displayrechner gesendet');
end;

function CanMove(PTD: TPlayerTokenData): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft, ob der Spieler ziehen kann.

	In:
		PTD: TPlayerTokenData: Spielsteindaten

	Out:
		True, wenn gezogen werden kann
*****************************************************************************)
var
	i: TTokenCount;
	Can: boolean;
begin
	Can := false;

	{ Spielsteindaten durchgehen }
	i := Low(TTokenCount);
	while (i < High(TTokenCount)) and not Can do
	begin
		{ Anzahl der Ziehrichtungen > 0 => Stein kann ziehen }
		Can := GetDirectionSetElementCount(PTD[i].MoveDirections) > 0;
		Inc(i);
	end;

	CanMove := Can;
end;

function CanCapture(MP: TMovePossibilities): boolean;
(*****************************************************************************
	Beschreibung:
		Ueberprueft ob der Spieler schlagen kann.

	In:
		MP: TMovePossibilities: Schlagmoeglichkeiten

	Out:
		True, wenn geschlagen werden kann
*****************************************************************************)
var
	x: TFieldWidth;
	y: TFieldHeight;
	Can: boolean;
begin
	Can := false;

	{ Schlagmoeglichkeiten durchgehen }
	x := 0;
	while (x < cFieldWidth) and not Can do
	begin
		y := 0;
		while (y < cFieldHeight) and not Can do
		begin
			{ Pruefen, ob geschlagen werden kann }
			Can := MP[x, y];
			Inc(y);
		end;
		Inc(x);
	end;

	CanCapture := Can;
end;

{$F+}
procedure PlayerTask;
(*****************************************************************************
	Beschreibung:
		Spielertask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	LeaderTaskHandle: TaskHandle;
	itc: TTokenCount;
	StatisticIn,
	StatisticOut,
	StatusIn,
	StatusOut: text;
	StatisticWindowPosition,
	StatusWindowPosition: TWindowPosition;
	WindowColor: TWindowColor;
	TokenMessage: TTokenMessage;
	LeaderMessage: TLeaderMessage;
	Message: TPlayerMessage;
	TokenData: TPlayerTokenData;
	TimeLimit,
	MaxTimeLimit: TTimeLimit;
	TokenTaskName: string;
	PlayerKind: TPlayer;
	TokenPlaced: boolean;
	DisplayMessage: TDisplayMessage;
	Owner: TOwner;
	Field: TField;
	Stage: TPlayerStage;
	MoveData: TMoveData;
	MovePossibilities: TMovePossibilities;
	TokenTaskHandle: TaskHandle;
	ComputeTimeLimitTime: FineTime;
begin
	Debug('Wurde erzeugt');

	{ Zeiten initialisieren }
	TimeLimit := 0;

	{ Spielerart }
	Debug('Warte auf Spielerart');
	PlayMsg.Receive(Message);
	if Message.Kind <> plmkPlayerKind then
		Die('Unexpected command in player');
	PlayerKind := Message.PlayerKind;
	Debug('Spielerart empfangen');

	{ Fensterpositionen }
	Debug('Warte auf Statistikfensterposition');
	PlayMsg.Receive(Message);
	if Message.Kind <> plmkWindowPosition then
		Die('Unexpected command in player');
	StatisticWindowPosition := Message.WindowPosition;
	Debug('Statistikfensterposition empfangen');

	Debug('Warte auf Statusfensterposition');
	PlayMsg.Receive(Message);
	if Message.Kind <> plmkWindowPosition then
		Die('Unexpected command in player');
	StatusWindowPosition := Message.WindowPosition;
	Debug('Statusfensterposition empfangen');

	{ Spielleitertaskhandle }
	Debug('Warte auf Spielleitertasktandle');
	PlayMsg.Receive(Message);
	if Message.Kind <> plmkLeaderTaskHandle then
		Die('Unexpected command in player');
	LeaderTaskHandle := Message.LeaderTaskHandle;
	Debug('Spielleitertaskhandle empfangen');

	{ Spielerfarbe }
	Debug('Warte auf Spielerfarbe');
	PlayMsg.Receive(Message);
	if Message.Kind <> plmkWindowColor then
		Die('Unexpected command in player (pcSetWindowColor expected)');
	WindowColor := Message.WindowColor;
	Debug('Spielerfarbe empfangen');

	{ Maximale Bedenkzeit }
	Debug('Warte auf maximale Bedenkzeit');
	PlayMsg.Receive(Message);
	if Message.Kind <> plmkMaxTimeLimit then
		Die('Unexpected command in player (pcSetMaxTimeLimit expected)');
	MaxTimeLimit := Message.MaxTimeLimit;
	Debug('Maximale Bedenkzeit empfangen');

	{ Fenster erzeugen }
	Debug('Erzeuge Statistikfenster');
	NewWindow(StatisticIn, StatisticOut, StatisticWindowPosition.FirstCol,
		StatisticWindowPosition.FirstRow, StatisticWindowPosition.LastCol,
		StatisticWindowPosition.LastRow, WindowColor.FrameColor, ' ' +
		GetTaskName(CurrentTaskHandle) + ' (Statistik) ');
	Debug('Statistikfenster erzeugt');
	SetAttribute(StatisticOut, WindowColor.Attribute);

	Debug('Erzeuge Statusfenster');
	NewWindow(StatusIn, StatusOut, StatusWindowPosition.FirstCol,
		StatusWindowPosition.FirstRow, StatusWindowPosition.LastCol,
		StatusWindowPosition.LastRow, WindowColor.FrameColor, ' ' +
		GetTaskName(CurrentTaskHandle) + ' (Status) ');
	Debug('Statusfenster erzeugt');
	SetAttribute(StatusOut, WindowColor.Attribute);

	{ Spielsteintasks erzeugen }
	Debug('Erzeuge Spielsteine');
	for itc := Low(TTokenCount) to High(TTokenCount) - 1 do
	begin
		TokenTaskName := cTokenTaskName + ' ' + IntToStr(itc, 0);
		Debug('Erzeuge ' + TokenTaskName);
		CreateTask(TokenTask, cTokenPriority, cTokenStack, TokenTaskName,
			TokenData[itc].TokenTH);
		Debug(TokenTaskName + ' erzeugt');

		{ Spielertaskhandle an Spielsteintask senden }
		TokenMessage.Kind := tmkPlayerTaskHandle;
		TokenMessage.PlayerTaskHandle := CurrentTaskHandle;
		Debug('Sende Spielertaskhandle an ' + TokenTaskName);
		TokenMsg.Send(TokenData[itc].TokenTH, TokenMessage);
		Debug('Spielertaskhandle an ' + TokenTaskName + ' gesendet');
	end;
	Debug('Spielsteine erzeugt');

	{ Statistik anzeigen }
	ShowStatistic(StatisticOut, WindowColor.FrameColor, High(TTokenCount),
		TimeLimit, MaxTimeLimit);

	while true do
	begin
		{ Auf Nachrichten warten }
		Debug('Warte auf Nachrichten');
		PlayMsg.Receive(Message);
		Debug('Nachricht empfangen');
		Debug('Analysiere Nachricht');

		{ Nachricht analysieren }
		case Message.Kind of
			{ Init }
			plmkInit:
			begin
				{ Aktuelle Bedenkzeit initialisieren }
				Debug('Initialisierungskommando empfangen');
				TimeLimit := 0;

				{ Initialisierungsnachricht an die Spielsteine senden }
				TokenMessage.Kind := tmkInit;
				Debug('Sende Initalisierungsbefehl an Spielsteine');
				for itc := Low(TTokenCount) to High(TTokenCount) - 1 do
					TokenMsg.Send(TokenData[itc].TokenTH, TokenMessage);
				Debug('Initialisierungsbefehl an Spielsteine gesendet');

				{ Fenster leeren }
				Write(StatisticOut, FormFeed);
				Write(StatusOut, FormFeed);

				{ Statistik anzeigen }
				ShowStatistic(StatisticOut, WindowColor.FrameColor,
					High(TTokenCount) - Field.CapturedTC[PlayerKind],
					TimeLimit, MaxTimeLimit);

				{ Zeit markieren }
				MarkTime(ComputeTimeLimitTime);
			end;

			{ Zugvorbereitungsnachricht (ziehen / schlagen) }
			plmkPrepareMove, plmkPrepareCapture:
			begin
				if Message.Kind = plmkPrepareMove then
					Debug('Zugvorbereitungskommando empfangen')
				else if Message.Kind = plmkPrepareCapture then
					Debug('Schlagvorbereitungskommando empfangen');

				{ Info ausgeben }
				WriteLn(StatusOut, 'Bin an der Reihe');
				WriteLn(StatusOut, 'Denke');

				{ Es soll gezogen werden }
				if Message.Kind = plmkPrepareMove then
					{ Phase berechnen }
					Stage := GetPlayerStage(Field.PlacedTC[PlayerKind],
						Field.CapturedTC[PlayerKind])
				{ Es soll geschlagen werden }
				else if Message.Kind = plmkPrepareCapture then
					Stage := psCapture;

				{ Es soll gezogen werden }
				if Message.Kind = plmkPrepareMove then
				begin
					Debug('Sende Anfrage nach Spielsteindaten an Spielsteine');

					{ Spielsteindaten nach aktuellen Daten fragen}
					for itc := 0 to cTokenCount - 1 do
					begin
						TokenTaskName := GetTaskName(TokenData[itc].TokenTH);

						{ Spielfeld an Stein senden }
						TokenMessage.Kind := tmkField;
						TokenMessage.Field := Field;
						Debug('Sende Spielfeld an ' + TokenTaskName);
						TokenMsg.Send(TokenData[itc].TokenTH, TokenMessage);
						Debug('Spielfeld an ' + TokenTaskName + ' gesendet');

						{ Spielerphase an Spielstein senden }
						TokenMessage.Kind := tmkPlayerStage;
						TokenMessage.PlayerStage := Stage;
						Debug('Sende Spielerphase an ' + TokenTaskName);
						TokenMsg.Send(TokenData[itc].TokenTH, TokenMessage);
						Debug('Spielerzustand an ' + TokenTaskName + ' gesendet');

						{ Anfrage nach Spielsteindaten senden }
						TokenMessage.Kind := tmkGetTokenData;
						TokenMessage.SenderTaskHandle := CurrentTaskHandle;
						Debug('Sende Anfrage nach Spielsteindaten an ' +
							TokenTaskName);
						TokenMsg.Send(TokenData[itc].TokenTH, TokenMessage);
						Debug('Anfrage nach Spielsteindaten an ' + TokenTaskName +
							' gesendet');
					end;
					Debug('Anfrage nach Spielsteindaten an Spielsteine gesendet');
				end;

				{ Spielerphase an den Anzeigerechner senden }
				SendStageToDisplayComputer(Stage);

				{ Wenn geschlagen werden soll und geschlagen werden kann }
				if (Message.Kind = plmkPrepareCapture) and
					GetCapturePossibilities(Field,
						PlayerToOwner(GetOtherPlayer(PlayerKind)),
						MovePossibilities) then
				begin
					{ Zugmoeglichkeiten an den Anzeigerechner senden }
					SendMovePossibilitiesToDisplayComputer(MovePossibilities);
				end;

				{ Neue Bedenkzeit erst dann berechnen, wenn die alte vorbei ist }
				if ElapsedTime(ComputeTimeLimitTime) >= TimeLimit then
				begin
					{ Zeit markieren }
					MarkTime(ComputeTimeLimitTime);
					{ Neue Bedenkzeit berechnen }
					if MaxTimeLimit > 0 then
						TimeLimit := GetRandomWord(MaxTimeLimit) + 1
					else
						TimeLimit := 0;
					{ Bedenkzeit an den Spieleiter senden }
					LeaderMessage.Kind := lemkTimeLimit;
					LeaderMessage.TimeLimit := TimeLimit;
					LeadMB.Put(Leader.Mailbox, LeaderMessage);
				end;

				{ Statistikanzeige aktualisieren }
				ShowStatistic(StatisticOut, WindowColor.FrameColor,
					cTokenCount - Field.CapturedTC[PlayerKind],
					TimeLimit, MaxTimeLimit);
			end;

			{ Ziehen oder schlagen }
			plmkMove, plmkCapture:
			begin
				Debug('Zugkommando empfangen');

				{ Pruefen, ob Spieler verloren hat }
				if
					{ Zu wenig Steine }
					((cTokenCount - Field.CapturedTC[PlayerKind]) =
					cFieldSquareCount - 1) or
					{ Keine Zugmoeglichkeiten }
					((Stage = psMove) and not CanMove(TokenData)) then
				begin
					{ Spielleiter ueber das Spielende benachrichtigen }
					SendStageToDisplayComputer(psCantMove);
					LeaderMessage.Kind := lemkGameOver;
					LeadMB.Put(Leader.Mailbox, LeaderMessage);
				end

				{ Pruefen, ob geschlagen werden kann }
				else if (Message.Kind = plmkCapture) and
					not CanCapture(MovePossibilities) then
				begin
					{ Anzeigerechner und Spielleiter mitteilen, dass nicht geschlagen
						werden kann }
					SendStageToDisplayComputer(psCantCapture);
					LeaderMessage.Kind := lemkPlayerMoved;
					LeaderMessage.TokenMoveData.MoveData.Kind := mkNoMove;
					LeadMB.Put(Leader.Mailbox, LeaderMessage);
				end
				else
				begin
					case PlayerKind of
						{ KI fuer die CPU

							Strategie ist grundsaetzlich:
								1. Muehle schliessen
								2. Muehle verhindern
								3. Muehle vorbereiten
								4. Ersten gefundenen Zug nehmen }
						CPU:
						begin
							with MoveData do
							begin

								{ CPU schlaegt }
								if Stage = psCapture then
								begin
									{ Pruefen, ob Gegener beim naechsten Zug eine Muehle
										schliessen kann }
									if not CanCloseMill(Field, SourceFP, TargetFP, oUser, oCPU,
										Stage) or HasMillInCol(Field, SourceFP, oUser) or
										HasMillInRow(Field, SourceFP, oUser) then
									begin
										{ Ersten gefundenen Stein schlagen... }
										GetFirstPosByOwner(Field, SourceFP, oUser);
										{ ...aber moeglichst nicht aus einer Muehle }
										while (HasMillInCol(Field, SourceFP, oUser) or
											HasMillInRow(Field, SourceFP, oUser)) and
											GetNextPosByOwner(Field, SourceFP, oUser) do
									end;
								end;

								{ CPU zieht }
								if Stage in [psPlace, psMove, psFly] then
								begin
									if
										{ Pruefen, ob Muehle geschlossen werden kann }
										not (CanCloseMill(Field, SourceFP, TargetFP, oCPU, oCPU,
											Stage) or
										{ Pruefen, ob Muehle verhindert werden kann }
										CanCloseMill(Field, SourceFP, TargetFP, oUser,
											oCPU, Stage) or
										{ Pruefen, ob Muehle vorbereitet werden kann }
										CanPrepareMill(Field, SourceFP, TargetFP,
											oCPU)) then
									begin
										{ CPU setzt oder springt }
										if Stage in [psPlace, psFly] then
										begin
											if
												{ Freie Spalte suchen }
												not (GetFirstColByOwner(Field, TargetFP, oNone) or
												{ Freie Zeile suchen }
												GetFirstRowByOwner(Field, TargetFP, oNone)) then
											begin
												{ Erste freie Stelle suchen }
												GetFirstPosByOwner(Field, TargetFP, oNone);
											end;
											{ Ersten CPU-Stein suchen }
											GetFirstPosByOwner(Field, SourceFP, oCPU);
										end;
										{ CPU zieht }
										if Stage = psMove then
											{ Ersten moeglichen Zug suchen }
											GetFirstPossibleMove(Field, TokenData, SourceFP,
												TargetFP);
									end;
								end;

								{ CPU setzt }
								if Stage = psPlace then
								begin
									{ Ersten nicht gesetzten Stein suchen }
									TokenTaskHandle := GetFirstNotPlacedToken(TokenData);
									Kind := mkPlace;
								end
								else
								begin
									{ Stein von der Quellposition nehmen }
									TokenTaskHandle :=
										Field.Pos[SourceFP.X, SourceFP.Y].TokenTH;
									{ Zwischen schlagen und ziehen unterscheiden }
									if Stage = psCapture then
									begin
										Kind := mkCapture;
										PlayerTH := CurrentTaskHandle;
									end
									else
										Kind := mkMove;
								end;

								{ Ziehkommando an Spielstein senden }
								TokenMessage.Kind:= tmkMove;
								TokenMessage.MoveData := MoveData;
								Debug('Sende Zugdaten an Spielstein');
								TokenMsg.Send(TokenTaskHandle, TokenMessage);
								Debug('Zugdaten an Spielstein gesendet');
							end;
						end;
					end;
				end;
			end;
			{ Bedenkzeit inkrementieren }
			plmkIncrementMaxTimeLimit:
			begin
				Debug('Kommando zum Inkrementieren der maximalen Denkzeit ' +
					'empfangen');
				if (PlayerKind = CPU) and (MaxTimeLimit < High(TTimeLimit)) then
				begin
					Inc(MaxTimeLimit);
					ShowStatistic(StatisticOut, WindowColor.FrameColor,
						cTokenCount - Field.CapturedTC[PlayerKind], TimeLimit,
						MaxTimeLimit);
					{ Bedenkzeit an den Spieleiter senden }
					LeaderMessage.Kind := lemkTimeLimit;
					LeaderMessage.TimeLimit := TimeLimit;
					LeadMB.Put(Leader.Mailbox, LeaderMessage);
				end;
			end;
			{ Bedenkzeit dekrementieren }
			plmkDecrementMaxTimeLimit:
			begin
				Debug('Kommando zum Dekrementieren der maximalen Denkzeit ' +
					'empfangen');
				if (PlayerKind = CPU) and (MaxTimeLimit > Low(TTimeLimit)) then
				begin
					Dec(MaxTimeLimit);
					ShowStatistic(StatisticOut, WindowColor.FrameColor,
						cTokenCount - Field.CapturedTC[PlayerKind], TimeLimit,
						MaxTimeLimit);
					{ Bedenkzeit an den Spieleiter senden }
					LeaderMessage.Kind := lemkTimeLimit;
					LeaderMessage.TimeLimit := TimeLimit;
					LeadMB.Put(Leader.Mailbox, LeaderMessage);
				end;
			end;
			{ Benutzer hat einen Zug ausgewaehlt }
			plmkUserMoveSelected:
			begin
				Debug('Benutzer hat Zug ausgewaehlt');
				{ Zugdaten verarbeiten }
				with Message.TokenMoveData do
				begin
					TokenMessage.Kind := tmkMove;
					TokenMessage.MoveData := MoveData;
					TokenMessage.MoveData.PlayerTH := CurrentTaskHandle;
					{ Spielstein ermitteln }
					if MoveData.Kind = mkPlace then
						TokenTaskHandle := GetFirstNotPlacedToken(TokenData)
					else
					begin
						with MoveData do
							TokenTaskHandle :=
								Field.Pos[SourceFP.X, SourceFP.Y].TokenTH;
					end;
					{ Zugdaten an Spielstein senden }
					Debug('Sende Zugdaten an ' + GetTaskName(TokenTaskHandle));
					TokenMsg.Send(TokenTaskHandle, TokenMessage);
					Debug('Zugdaten an ' + GetTaskName(TokenData[itc].TokenTH) +
						' gesendet');
				end;
			end;
			{ Zugbestaetigung vom Spielstein }
			plmkTokenMoved:
			begin
				Debug('Zugbestaetigung empfangen');

				{ Je nach Zug Info ausgeben }
				with Message.TokenMoveData do
				begin
					case MoveData.Kind of
						mkPlace:
						begin
							WriteLn(StatusOut, 'Setze auf ' +
								FieldPosToStr(Message.TokenMoveData.MoveData.TargetFP));
							LeaderMessage.Kind := lemkPlayerMoved;
						end;
						mkMove:
						begin
							WriteLn(StatusOut, 'Ziehe von ' +
								FieldPosToStr(Message.TokenMoveData.MoveData.SourceFP) +
								' auf ' +
								FieldPosToStr(Message.TokenMoveData.MoveData.TargetFP));
							LeaderMessage.Kind := lemkPlayerMoved;
						end;
						mkCapture:
						begin
							SetAttribute(StatusOut, cCapturePossibilityColor);
							WriteLn(StatusOut, 'Schlage ' +
								FieldPosToStr(Message.TokenMoveData.MoveData.SourceFP));
							SetAttribute(StatusOut, DefaultAttribute);
							LeaderMessage.Kind := lemkPlayerCaptured;
						end;
						mkSteal:
						begin
							SetAttribute(StatusOut, cCapturePossibilityColor);
							WriteLn(StatusOut, 'Verliere ' +
								FieldPosToStr(Message.TokenMoveData.MoveData.SourceFP));
							SetAttribute(StatusOut, DefaultAttribute);
							LeaderMessage.Kind := lemkPlayerCaptured;
						end;
					end;
				end;

				{ Zugdaten an den Spielleiter senden }
				LeaderMessage.TokenMoveData := Message.TokenMoveData;
				Debug('Sende Zug an Spielleiter');
				LeadMB.Put(Leader.Mailbox, LeaderMessage);
				Debug('Zug an Spielleiter gesendet');
			end;

			{ Anfrage nach Zugmoeglichkeiten }
			plmkGetMovePossibilities:
			begin
				Debug('Anfrage nach Zugmoeglichkeiten von Displayrechner ' +
					'erhalten');

				{ Spieler schlaegt }
				if Stage = psCapture then
					{ Schlagmoeglichkeiten berechnen }
					GetCapturePossibilities(Field, oCPU, MovePossibilities)
				else
				begin
					{ In Setzphase den ersten nicht gesetzten Stein nehmen }
					if Stage = psPlace then
						TokenTaskHandle := GetFirstNotPlacedToken(TokenData)
					{ Sonst den Spielstein aus der NAchricht ermitteln }
					else
						TokenTaskHandle := Message.TokenTaskHandle;
					{ Spielsteinnummer und Zugmoeglichkeiten ermitteln }
					itc := GetTokenByTaskHandle(TokenTaskHandle, TokenData);
					MovePossibilities := TokenData[itc].MovePossibilities;
				end;
				{ Zugmoeglichkeiten an den Anzeigerechner senden }
				SendMovePossibilitiesToDisplayComputer(MovePossibilities);
			end;

			{ Spielfeld empfangen }
			plmkField:
			begin
				Debug('Spielfeld empfangen');
				Field := Message.Field;
			end;

			{ Spielsteindaten empfangen }
			plmkTokenData:
			begin
				Debug('Spielsteindaten empfangen');
				{ Spielsteinnummer ermitteln und Spielsteindaten setzen }
				itc := GetTokenByTaskHandle(Message.TokenData.TokenTH,
					TokenData);
				TokenData[itc] := Message.TokenData;
			end;

			{ Klaunachricht }
			plmkStealToken:
			begin

				{ Ersten Spielstein ermitteln }
				if not GetFirstPosByOwner(Field, MoveData.SourceFP,
					PlayerToOwner(PlayerKind)) then
				begin
					SetAttribute(StatusOut, cCapturePossibilityColor);
					WriteLn(StatusOut, 'Keine Steine auf dem Spielfeld');
					SetAttribute(StatusOut, DefaultAttribute);
				end
				else
				begin
					{ Daten an Spielstein senden }
					MoveData.Kind := mkSteal;
					TokenMessage.Kind:= tmkMove;
					TokenMessage.MoveData := MoveData;
					TokenTaskHandle := Field.Pos[MoveData.SourceFP.X,
						MoveData.SourceFP.Y].TokenTH;
					TokenMsg.Send(TokenTaskHandle, TokenMessage);
				end;
			end;
		end;

		Debug('Nachricht analysiert');
	end;

	Debug('Werde zerstoert');
end;

end.