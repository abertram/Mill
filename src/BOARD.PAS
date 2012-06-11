unit Board;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit enthaelt die Spielbretttask, die fuer das Zeichnen des
	Spielbrettes zustaendig ist, und die dafuer noetigen Hilfsroutinen.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	BoardMB;

var
	Mailbox: BoardMB.Mailbox;

procedure BoardTask;

implementation

uses
	RTKernel, RTTextIO, RTKeybrd,
	Types, Tools, DTypes, ProcMB, DIPXSnd, Semas;

procedure CreateWindows(var BoardIn, BoardOut, UserTokenIn,
	UserTokenOut, CPUTokenIn, CPUTokenOut, GameFlowIn,
	GameFlowOut: text);
(*****************************************************************************
	Beschreibung:
		Erstellt alle benoetigten Fenster.

	In:
		Textdateivariablen

	Out:
		-
*****************************************************************************)
begin
	{ Fenster fuer das Spielfeld }
	NewWindow(BoardIn, BoardOut, cBoardWindowFirstCol, cBoardWindowFirstRow,
		cBoardWindowLastCol, cBoardWindowLastRow, cBoardWindowColor,
		' ' + cBoardTaskName + ' ');

	{ Fenster fuer die Spielsteine des Benutzers, die noch nicht gesetzt sind }
	NewWindow(UserTokenIn, UserTokenOut,
		cUserTokenWindowFirstCol, cUserTokenWindowFirstRow,
		cUserTokenWindowLastCol, cUserTokenWindowLastRow,
		cUserTokenWindowColor, ' ' + Copy(cUserTaskName, 1, 1) + ' ');

	{ Fenster fuer die Spielsteine des CPU-Spielers, die noch nicht gesetzt
		sind }
	NewWindow(CPUTokenIn, CPUTokenOut,
		cCPUTokenWindowFirstCol, cCPUTokenWindowFirstRow,
		cCPUTokenWindowLastCol, cCPUTokenWindowLastRow,
		cCPUTokenWindowColor, ' ' + Copy(cCPUTaskName, 1, 1) + ' ');

	{ Fenster fuer den Spielablauf }
	NewWindow(GameFlowIn, GameFlowOut, cGameFlowWindowFirstCol,
		cGameFlowWindowFirstRow, cGameFlowWindowLastCol, cGameFlowWindowLastRow,
		cGameFlowWindowColor, cGameFlowWindowTitle);
end;

procedure CreateBoardCharLookupTable(var BoardCharLUT: TBoardCharLookupTable);
(*****************************************************************************
	Beschreibung:
		Erstellt eine Lookup-Tabelle  mit den ASCII-Zeichen fuer das Spielbrett.

	In:
		-

	Out:
		BoardCharLUT: TBoardCharLookupTable: Lookup-Tabelle mit den ASCII-Zeichen
*****************************************************************************)
var
	i: TFieldSquareCount;
	x,
	StartX,
	Width,
	EndX: TBoardWidth;
	y,
	StartY,
	Height,
	EndY: TBoardHeight;
	c: char;
begin
	{ ASCII-Zeichen fuer die Quadrate berechnen }
	for i := 0 to cFieldSquareCount - 1 do
	begin

		{ Startposition, Breite, Hoehe und Endposition berechnen }
		StartX := i * (cBoardLineHorizontalMargin + 1);
		StartY := i * (cBoardLineVerticalMargin + 1);
		Width := cBoardWidth - i * (cBoardLineHorizontalMargin + 1) * 2 - 1;
		Height := cBoardHeight - i * (cBoardLineVerticalMargin + 1) * 2 - 1;
		EndX := StartX + Width;
		EndY := StartY + Height;

		{ ASCII-Zeichen an jeder Position bestimmen }

		{ Spalten durchlaufen }
		for x := StartX to EndX do
		begin
			{ Zeilen durchlaufen }
			for y := StartY to EndY do
			begin
				{ Linke Kante }
				if x = StartX then
				begin
					{ Linke obere Ecke }
					if y = StartY then
						c := cBoardUpperLeftCornerChar
					{ Horizontale Linie }
					else if (y > StartY) and (y < EndY) then
						c := cBoardVerticalLineChar
					{ Linke untere Ecke }
					else if (y = EndY) then
						c := cBoardLowerLeftCornerChar
					else
						c := ' ';
				end
				{ Zwischen der linken und der rechten Kante }
				else if (x > StartX) and (x < EndX) then
				begin
					{ Obere oder untere Kante }
					if (y = StartY) or (y = EndY) then
						c := cBoardHorizontalLineChar
					else
						c := ' ';
				end
				{ Rechte Kante }
				else if x = EndX then
				begin
					{ Rechte obere Ecke }
					if y = StartY then
						c := cBoardUpperRightCornerChar
					{ Horizontale Linie }
					else if (y > StartY) and (y < EndY) then
						c := cBoardVerticalLineChar
					{ Rechte untere Ecke }
					else if (y = EndY) then
						c := cBoardLowerRightCornerChar
					else
						c := ' ';
				end
				else
					c := ' ';

				{ Zeichen in der Lookup-Tabelle speichern }
				BoardCharLUT[x, y] := c;
			end;
		end;
	end;

	{ Horizontale Linien vom aeusseren zum inneren Quadrat }
	StartX := Low(TBoardWidth);
	y := cBoardHeight div 2;
	Width := cBoardWidth div 2 - cBoardInnerSquareWidth div 2;
	EndX := StartX + Width;
	for x := StartX to EndX do
	begin
		if x = StartX then
			c := cBoardLeftCrossChar
		else if (x > StartX) and (x < EndX) and ((x - StartX) mod
			(cBoardLineHorizontalMargin + 1) = 0) then
			c := cBoardCrossChar
		else if x = EndX then
			c := cBoardRightCrossChar
		else
			c := cBoardHorizontalLineChar;
		BoardCharLUT[x, y] := c;
	end;
	StartX := cBoardWidth div 2 + cBoardInnerSquareWidth div 2;
	EndX := StartX + Width;
	for x := StartX to EndX do
	begin
		if x = StartX then
			c := cBoardLeftCrossChar
		else if (x > StartX) and (x < EndX) and ((x - StartX) mod
			(cBoardLineHorizontalMargin + 1) = 0) then
			c := cBoardCrossChar
		else if x = EndX then
			c := cBoardRightCrossChar
		else
			c := cBoardHorizontalLineChar;
		BoardCharLUT[x, y] := c;
	end;

	{ Vertikale Linien vom aeusseren zum inneren Quadrat }
	StartY := Low(TBoardHeight);
	x := cBoardWidth div 2;
	Height := cBoardHeight div 2 - cBoardInnerSquareHeight div 2;
	EndY := StartY + Height;
	for y := StartY to EndY do
	begin
		if y = StartY then
			c := cBoardUpperCrossChar
		else if (Y > StartY) and (Y < EndY) and ((Y - StartY) mod
			(cBoardLineVerticalMargin + 1) = 0) then
			c := cBoardCrossChar
		else if Y = EndY then
			c := cBoardLowerCrossChar
		else
			c := cBoardVerticalLineChar;
		BoardCharLUT[x, y] := c;
	end;
	StartY := cBoardHeight div 2 + cBoardInnerSquareHeight div 2;
	EndY := StartY + Height;
	for y := StartY to EndY do
	begin
		if y = StartY then
			c := cBoardUpperCrossChar
		else if (Y > StartY) and (Y < EndY) and ((Y - StartY) mod
			(cBoardLineVerticalMargin + 1) = 0) then
			c := cBoardCrossChar
		else if Y = EndY then
			c := cBoardLowerCrossChar
		else
			c := cBoardVerticalLineChar;
		BoardCharLUT[x, y] := c;
	end;
end;

procedure DrawBoard(var F: text; BoardCharLUT: TBoardCharLookupTable);
(*****************************************************************************
	Beschreibung:
		Zeichnet das Spielbrett.

	In:
		F: text: Textvariable des Fensters, in dem gezeichnet werden soll
		BoardCharLUT: TBoardCharLookupTable: Lookup-Tabelle

	Out:
		-
*****************************************************************************)
var
	x: TBoardWidth;
	y: TBoardHeight;
	ColChar,
	RowChar: char;
begin
	{ Startzeichen fuer die Spaltenbeschriftung }
	ColChar := 'a';
	{ Startzeichen fuer die Zeilenbeschriftung }
	RowChar := '1';

	{ Lookup-Tabelle spaltenweise durchlaufen }
	for x := Low(TBoardWidth) to High(TBoardWidth) do
	begin
		{ Lookup-Tabelle zeilenweise durchlaufen }
		for y := Low(TBoardHeight) to High(TBoardHeight) do
		begin
			{ Zeilenbeschriftung berechnen und ausgeben }
			if x = Low(TBoardWidth) then
			begin
				if (y mod (cBoardLineVerticalMargin + 1) = 0) then
				begin
					GoToXY(f, x + cBoardStartX - 1, y + cBoardStartY);
					Write(f, RowChar);
					RowChar := Succ(RowChar);
				end;
			end;

			{ Zeichen aus der Lookup-Tabelle ausgeben }
			GoToXY(f, x + cBoardStartX, y + cBoardStartY);
			Write(f, BoardCharLUT[x, y]);
		end;

		{ Spaltenbeschriftung berechnen und ausgeben }
		if (x mod (cBoardLineHorizontalMargin + 1) = 0) then
		begin
			GoToXY(f, x + cBoardStartX, y + cBoardStartY + 1);
			Write(f, ColChar);
			ColChar := Succ(ColChar);
		end;
	end;
end;

procedure DrawNotPlacedTokens(var UserTokenOut,
	CPUTokenOut: text; PlacedTokenCount: TPlayerTokenCount;
	TokenColors: TPlayerColors);
(*****************************************************************************
	Beschreibung:
		Zeichnet die nicht gesetzten Spielsteine.

	In:
		UserTokenOut: text: Textvariable des Fensers fuer die Benutzersteine
		CPUTokenOut: text: Textvariable des Fensers fuer die CPU-Spieler-Steine
		PlacedTokenCount: TPlayerTokenCount: Gesetzte Spielsteine
		TokenColors: TPlayerColors: Spielerfarben

	Out:
		-
*****************************************************************************)
var
	itc: TTokenCount;
begin
	{ Benutzerfenster leeren und steine zeichnen }
	Write(UserTokenOut, FormFeed);
	itc := Low(TTokenCount);
	while itc < (High(TTokenCount) - PlacedTokenCount[User]) do
	begin
		Write(UserTokenOut, cUserTokenChar);
		inc(itc);
	end;

	{ CPU-Spieler-Fenster leeren und Steine zeichnen }
	Write(CPUTokenOut, FormFeed);
	itc := Low(TTokenCount);
	while itc < High(TTokenCount) - PlacedTokenCount[CPU] do
	begin
		Write(CPUTokenOut, cCPUTokenChar);
		inc(itc);
	end;
end;

function FieldXToBoardX(FieldX: TFieldWidth): TBoardWidth;
(*****************************************************************************
	Beschreibung:
		Rechnet Spielfeld-X-Koordinate in Spielbrett-X-Koordinate um.

	In:
		FieldX: TFieldWidth: Spielfeld-X-Koordinate

	Out:
		Spielbrett-X-Koordinate
*****************************************************************************)
begin
	FieldXToBoardX := FieldX * (cBoardLineHorizontalMargin + 1);
end;

function FieldYToBoardY(FieldY: TFieldHeight): TBoardHeight;
(*****************************************************************************
	Beschreibung:
		Rechnet Spielfeld-Y-Koordinate in Spielbrett-Y-Koordinate um.

	In:
		FieldY: TFieldWidth: Spielfeld-X-Koordinate

	Out:
		Spielbrett-Y-Koordinate
*****************************************************************************)
begin
	FieldYToBoardY := FieldY * (cBoardLineVerticalMargin + 1);
end;

procedure DrawField(var F: text; Field: TField;
	PlayerColors: TPlayerColors; BoardCharLUT: TBoardCharLookupTable;
	CurrentPlayer: TPlayer; MovePossibilities: TMovePossibilities;
	DrawMovePossibilities: boolean; CursorFP, SelectedFP: TFieldPos;
	PlayerStage: TPLayerStage);
(*****************************************************************************
	Beschreibung:
		Zeichnet das Spielfeld.

	In:
		F: text: Textvariable des Spielbrettfensters
		Field: TField: Spielfeld
		PlayerColors: TPlayerColors: Spielerfarben
		BoardCharLUT: TBoardCharLookupTable: ASCII-Zeichen Lookup-Tabelle
		CurrentPlayer: TPlayer: Aktueller Spieler
		MovePossibilities: TMovePossibilities: Zugmoeglichkeiten
		DrawMovePossibilities: boolean: Wenn true, Zugmoeglichkeiten zeichnen
		CursorFP: TFieldPos: Position des Cursors
		SelectedFP: TFieldPos: Selektierte Position
		PlayerStage: TPLayerStage: Spielerphase des aktuellen Spielers

	Out:
		-
*****************************************************************************)
var
	x: TFieldWidth;
	y: TFieldHeight;
	BoardX: TBoardWidth;
	BoardY: TBoardHeight;
	Color: byte;
	c: char;
begin
	{ Spielfeld horizontal durchlaufen }
	for x := Low(TFieldWidth) to High(TFieldWidth) - 1 do
	begin
		{ Spielfeld vertikal durchlaufen }
		for y := Low(TFieldHeight) to High(TFieldHeight) - 1 do
		begin

			{ Pruefen auf gueltige Position }
			if Field.Pos[x, y].Valid then
			begin
				{ Spielfeldkoordinaten in Spielbrettkoordinaten umrechnen }
				BoardX := FieldXToBoardX(x);
				BoardY := FieldYToBoardY(y);

				{ Je nach Spieler auf der aktuellen Position, Farbe und Zeichen
					berechnen }
				case Field.Pos[x, y].Owner of

					{ Kein Spieler }
					oNone:
					begin
						Color := cBoardWindowColor;
						c := BoardCharLUT[BoardX, BoardY];
					end;

					{ Benutzer }
					oUser:
					begin
						Color := PlayerColors[User];
						c := cUserTokenChar;
					end;

					{ CPU }
					oCPU:
					begin
						Color := PlayerColors[CPU];
						c := cCPUTokenChar;
					end;
				end;

				{ Hintergrundfarbe addieren }
				Inc(Color, cBoardBGColor);

				{ Pruefen, ob Benutzer an der Reihe }
				if CurrentPlayer = User then
				begin

					{ Pruefen, ob Zugmoeglichkeiten gezeichnet werden sollen und die
						aktuelle Position eine Zugmoeglichkeit ist }
					if DrawMovePossibilities and MovePossibilities[x, y] then
					begin
						{ Pruefen, ob Spieler schlagen darf und entsprechend die Farbe
							setzen}
						if PlayerStage = psCapture then
							Color := cCapturePossibilityColor
						{ Farbe einer Zugmoeglichkeit berechnen }
						else
							Color := PlayerColors[User] - Bright;
					end;

					{ Pruefen, ob Position selektiert ist }
					if (x = SelectedFP.X) and (y = SelectedFP.Y) then
						Color := Color - cBoardBGColor + cSelectedFieldPosBGColor

					{ Pruefen, ob der Cursor an der aktuellen Position steht }
					else if (x = CursorFP.X) and (y = CursorFP.Y) then

						{ Position blinkend darstellen }
						Color := Color - cBoardBGColor + cCursorFieldPosBGColor;
				end;

				{ Fensterattribite setzen }
				SetAttribute(f, Color);

				{ Zur Position gehen und Zeichen ausgeben }
				GoToXY(f, cBoardStartX + FieldXToBoardX(x), cBoardStartY +
					FieldYToBoardY(y));

				{ Zeichen ausgeben }
				Write(f, c);
			end;
		end;
	end;
end;

procedure MoveCursor(var F: text; var CursorFP: TFieldPos;
	Direction: TDirection; Field: TField);
(*****************************************************************************
	Beschreibung:
		Bewegt den Cursor auf dem Spielbrett.

	In:
		F: text: Textvariable des Spielbrettfensters
		CursorFP: TFieldPos: Cursorposition
		Direction: TDirection: Bewegungsrichtung
		Field: TField: Spielfeld

	Out:
		-
*****************************************************************************)
begin
	{ Cursorposition je nach Bewegungsrichtung aendern }
	case Direction of
		dLeft:
			GetLeftFieldPos(Field, CursorFP);
		dRight:
			GetRightFieldPos(Field, CursorFP);
		dUp:
			GetUpperFieldPos(Field, CursorFP);
		dDown:
			GetLowerFieldPos(Field, CursorFP);
	end;
end;

procedure GetTokenMovePossibilities(F: TField; CFP: TFieldPos);
(*****************************************************************************
	Beschreibung:
		Sendet eine Anfrage nach Zugmoeglichkeiten an den Prozesserechner.

	In:
		F: TField: Spielfeld
		CFP: TFieldPos: Cursorposition

	Out:
		-
*****************************************************************************)
var
	ProcessMessage: TProcessMessage;
begin
	{ Nachrichtinhalt als Anfrage nach Zugmoeglichkeiten markieren }
	ProcessMessage.Kind := prmkGetTokenMovePossibilities;

	{ Spielsteintaskhandle, dessen Zugmoeglichkeiten gebraucht werden }
	ProcessMessage.TokenTH := F.Pos[CFP.X, CFP.Y].TokenTH;
	Debug('Sende Anfrage nach Zugmoeglichkeiten an Prozessrechner');

	{ Nachricht in der Mailbox des IPX-Senders ablegen }
	ProcMB.Put(DIPXSnd.Mailbox, ProcessMessage);
	Debug('Anfrage nach Zugmoeglichkeiten an Prozessrechner gesendet');
end;

{$F+}
procedure BoardTask;
(*****************************************************************************
	Beschreibung:
		Spielfeldtask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	BoardIn, BoardOut,
	UserTokenIn, UserTokenOut,
	CPUTokenIn, CPUTokenOut,
	GameFlowIn, GameFlowOut: text;
	PlayerColors: TPlayerColors;
	Message: TBoardMessage;
	BoardCharLUT: TBoardCharLookupTable;
	CurrentPlayer: TPlayer;
	CursorFP,
	SelectedFP: TFieldPos;
	Field: TField;
	MovePossibilities: TMovePossibilities;
	ProcessMessage: TProcessMessage;
	PlayerStage: TPlayerStage;
	GameOver: boolean;
begin
	Debug('Wurde erzeugt');

	{ Mailbox initialisieren }
	Debug('Initalisiere Mailbox');
	BoardMB.InitMailbox(Mailbox, cBoardMailboxSlots, 'Board mailbox');
	Debug('Mailbox initalisiert');

	{ Fenster erzeugen }
	Debug('Erzeuge Fenster');
	CreateWindows(BoardIn, BoardOut, UserTokenIn, UserTokenOut,
		CPUTokenIn, CPUTokenOut, GameFlowIn, GameFlowOut);
	Debug('Fenster erzeugt');

	{ ASCII-Lookup-Tabelle erzeugen }
	CreateBoardCharLookupTable(BoardCharLUT);

	{ Spielbrett zeichnen }
	Debug('Zeichne Spielbrett');
	DrawBoard(BoardOut, BoardCharLUT);

	{ Nachricht zum Initialisieren in der Mailbox ablegen }
	Message.Kind := bmkInit;
	BoardMB.Put(Mailbox, Message);

	while true do
	begin
		{ Auf Nachrichten warten }
		Debug('Warte auf Nachrichten');
		BoardMB.Get(Mailbox, Message);
		Debug('Nachricht empfangen');

		{ Nachricht analysieren }
		Debug('Analysiere Nachricht');
		case Message.Kind of

			{ Initialisierungsnachricht }
			bmkInit:
			begin
				{ Variablen initialisieren }
				Debug('Initialisiere Cursorposition');
				CursorFP.X := Low(TFieldWidth);
				CursorFP.Y := Low(TFieldHeight);
				Debug('Initialisiere markierte Position');
				SelectedFP.X := High(TFieldWidth);
				SelectedFP.Y := High(TfieldHeight);
				FillChar(MovePossibilities, SizeOf(MovePossibilities), false);
				PlayerStage := Low(TPlayerStage);
				GameOver := false;

				{ Fenster leeren }
				Write(GameFlowOut, FormFeed);
				Write(UserTokenOut, FormFeed);
				Write(CPUTokenOut, FormFeed);

				{ Info ausgeben }
				SetAttribute(GameFlowOut, cGameFlowWindowColor);
				WriteLn(GameFlowOut, 'Spiel mit [S] starten (Verbindung zum ' +
					'Prozessrechner noetig!)');
			end;

			{ Spielerfarben }
			bmkPlayerColors:
			begin
				Debug('Spielerfarben empfangen');
				PlayerColors := Message.Colors;

				{ Fensterattribute setzen }
				SetAttribute(UserTokenOut, PlayerColors[User] + cBoardBGColor);
				SetAttribute(CPUTokenOut, PlayerColors[CPU] +
					cBoardBGColor);
			end;

			{ Aktueller Spieler }
			bmkCurrentPlayer:
			begin
				Debug('Aktuellen Spieler empfangen: ' + PlayerToStr(Message.Player));
				CurrentPlayer := Message.Player;

				{ Schriftfarbe setzen }
				SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);

				{ Info ausgeben }
				WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
					' ist an der Reihe');
			end;

			{ Zugmoeglichkeiten }
			bmkTokenMovePossibilities:
			begin
				Debug('Zugmoeglichkeiten empfangen');
				MovePossibilities := Message.TokenMovePossibilities;
				DrawField(BoardOut, Field, PlayerColors, BoardCharLUT, CurrentPlayer,
					MovePossibilities, true, CursorFP, SelectedFP, PlayerStage);
			end;

			{ Cursorbewegung }
			bmkCursorMove:
			begin
				Debug('Cursorbewegung empfangen');

				{ Pruefen, ob Benutzer an der Reihe }
				if CurrentPlayer = User then
				begin
					{ Cursor bewegen }
					MoveCursor(BoardOut, CursorFP, Message.Direction, Field);

					{ Pruefen, ob Zugmoeglichkeiten noetig sind }
					if (PlayerStage in [psPlace, psCapture]) or
						(PlayerStage in [psMove, psFly]) and
						(Field.Pos[CursorFP.X, CursorFP.Y].Owner = oUser) and
						(SelectedFP.X = High(TFieldWidth)) and
						(SelectedFP.Y = High(TFieldHeight)) and not GameOver then
					begin
						{ Zugmoeglichkeiten holen }
						GetTokenMovePossibilities(Field, CursorFP);
					end
					{ Pruefen, ob eine Position selektiert ist }
					else if (SelectedFP.X = High(TFieldWidth)) and
						(SelectedFP.Y = High(TFieldHeight)) then
					begin
						{ Zugmoeglichkeiten loeschen }
						FillChar(MovePossibilities, SizeOf(MovePossibilities), false);
					end;

					{ Spielfeld zeichnen }
					DrawField(BoardOut, Field, PlayerColors, BoardCharLUT,
						CurrentPlayer, MovePossibilities, true, CursorFP,
						SelectedFP, PlayerStage);
				end;
			end;

			{ Spielfeld }
			bmkField:
			begin
				Debug('Spielfeld empfangen');
				Field := Message.Field;

				{ Nicht gesetzte Steine zeichnen }
				DrawNotPlacedTokens(UserTokenOut, CPUTokenOut,
					Field.PlacedTC, PlayerColors);

				{ Spielfeld zeichnen }
				DrawField(BoardOut, Field, PlayerColors, BoardCharLUT, CurrentPlayer,
					MovePossibilities, false, CursorFP, SelectedFP, PlayerStage);
			end;

			{ Positionsauswahl }
			bmkFieldPositionSelection:
			begin
				Debug('Positionsauswahl empfangen');

				{ Pruefen, ob Benutzer am Zug und das Spiel noch nicht zu Ende ist }
				if (CurrentPlayer = User) and not GameOver then
				begin

					{ Pruefen, ob Benutzer setzt }
					if (PlayerStage = psPlace) and
						MovePossibilities[CursorFP.X, CursorFP.Y] then
					begin
						{ Zugdaten berechnen }
						with ProcessMessage do
						begin
							Kind := prmkUserMoveSelected;
							with MoveData do
							begin
								Kind := mkPlace;
								TargetFP := CursorFP;
							end;
						end;
						{ Zugdaten an Prozessrechner senden }
						Debug('Sende Zugart und Position(en) an Prozessrechner');
						ProcMB.Put(DIPXSnd.Mailbox, ProcessMessage);
						Debug('Zugart und Position an Prozessrechner gesendet');
					end

					{ Pruefen, ob Benutzer zieht }
					else if PlayerStage in [psMove, psFly] then
					begin
						{ Pruefen, ob ein Spielstein des Benutzers auf der selektierten
							Position steht }
						if Field.Pos[CursorFP.X, CursorFP.Y].Owner = oUser then
						begin
							{ Pruefen, ob der Cursor auf der aktuellen Position steht }
							if (SelectedFP.X = CursorFP.X) and
								(SelectedFP.Y = CursorFP.Y) then
							begin
								{ Position demarkieren }
								SelectedFP.X := High(TFieldWidth);
								SelectedFP.Y := High(TFieldHeight);
							end
							{ Pruefen, ob noch keine Position markiert ist }
							else if (SelectedFP.X = cFieldWidth) and
								(SelectedFP.Y = cFieldHeight) then
							begin
								{ Selektierte Position aktualisieren }
								SelectedFP := CursorFP;
								{ Zugmoeglichkeiten holen }
								GetTokenMovePossibilities(Field, CursorFP);
							end;

							{ Spielfeld zeichnen }
							DrawField(BoardOut, Field, PlayerColors, BoardCharLUT,
								CurrentPlayer, MovePossibilities, true, CursorFP,
								SelectedFP, PlayerStage)
						end

						{ Pruefen, ob die Position frei ist }
						else if (Field.Pos[CursorFP.X, CursorFP.Y].Owner = oNone) then
						begin
							{ Preuefen, ob noch keine Position markiert ist }
							if (SelectedFP.X < cFieldWidth) and
								(SelectedFP.Y < cFieldHeight) then
							begin
								{ Pruefen, ob die gewaehlte Position unter den
									Zugmoeglichkeiten ist }
								if MovePossibilities[CursorFP.X, CursorFP.Y] then
								begin
									{ Zugdaten setzen }
									with ProcessMessage do
									begin
										Kind := prmkUserMoveSelected;
										with MoveData do
										begin
											Kind := mkMove;
											SourceFP := SelectedFP;
											TargetFP := CursorFP;
										end;
									end;

									{ Zugdaten an Prozessrechner senden }
									Debug('Sende Zugart und Position(en) an Prozessrechner');
									ProcMB.Put(DIPXSnd.Mailbox, ProcessMessage);
									Debug('Zugart und Position an Prozessrechner gesendet');
								end
								else

								{ Fehlermeldung ausgeben }
								begin
									SetAttribute(GameFlowOut, LightRed);
									WriteLn(GameFlowOut, 'Ungueltige Eingabe: Markierten ' +
										'Spielstein auf eine leere Nachbarposition bewegen!');
									SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
								end;
							end
							else

							{ Fehlermeldung }
							begin
								SetAttribute(GameFlowOut, LightRed);
								WriteLn(GameFlowOut, 'Ungueltige Eingabe: Erst eigenen ' +
									'Spielstein markieren!');
								SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
							end;
						end
						else
						begin
							{ Pruefen, ob keine Position ausgewaehlt ist }
							if (SelectedFP.X >= High(TFieldWidth)) and
								(SelectedFP.Y >= High(TFieldHeight)) then
							begin
								{ Fehlermeldung }
								SetAttribute(GameFlowOut, LightRed);
								WriteLn(GameFlowOut, 'Ungueltige Eingabe: Erst eigenen ' +
									'Spielstein markieren!');
								SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
							end
							else
							begin
								{ Fehlermeldung }
								SetAttribute(GameFlowOut, LightRed);
								WriteLn(GameFlowOut, 'Ungueltige Eingabe: Markierten ' +
									'Spielstein auf eine leere Nachbarposition bewegen!');
								SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
							end;
						end;
					end

					{ Pruefen, ob Benutzer schlaegt und sich die markierte Position
						unter den Zugmoeglcihkeiten befindet }
					else if (PlayerStage = psCapture) and
						MovePossibilities[CursorFP.X, CursorFP.Y] then
					begin
						{ Zugdaten setzen }
						with ProcessMessage do
						begin
							Kind := prmkUserMoveSelected;
							with MoveData do
							begin
								Kind := mkCapture;
								SourceFP := CursorFP;
							end;
						end;

						{ Zugdaten an Prozessrechner senden }
						Debug('Sende Zugart und Position(en) an Prozessrechner');
						ProcMB.Put(DIPXSnd.Mailbox, ProcessMessage);
						Debug('Zugart und Position an Prozessrechner gesendet');
					end
					else

					{ Fehlermeldung }
					begin
						SetAttribute(GameFlowOut, LightRed);
						WriteLn(GameFlowOut, 'Ungueltige Eingabe: Position bereits ' +
							'belegt');
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
					end;
				end;
			end;

			{ Zugdaten }
			bmkTokenMove:
			begin
				Debug('Zugdaten empfangen');
				Debug('Analysiere Zugdaten');

				{ Schriftfarbe setzen }
				SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);

				{ Zugdaten analysieren }
				with Message.TokenMoveData.MoveData do
				begin
					case Kind of

						{ Spieler setzt }
						mkPlace:
						begin
							Debug('Zugart: Setzen');
							{ Info ausgeben }
							WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
								' setzt auf ' + FieldPosToStr(TargetFP));
							{ Anzahl gesetzter Steine inkrementieren }
							Inc(Field.PlacedTC[CurrentPlayer]);
							{ Spieler auf die Zielposition setzen }
							Field.Pos[TargetFP.X, TargetFP.Y].Owner :=
								PlayerToOwner(CurrentPlayer);
							{ Nicht gesetzte Steine zeichnen }
							DrawNotPlacedTokens(UserTokenOut, CPUTokenOut,
								Field.PlacedTC, PlayerColors);
						end;

						{ Spieler zieht }
						mkMove:
						begin
							Debug('Zugart: Ziehen');
							{ Info ausgeben }
							Write(GameFlowOut, PlayerToStr(CurrentPlayer) + ' ');
							if PlayerStage = psMove then
								Write(GameFlowOut, 'zieht ')
							else if PlayerStage = psFly then
								Write(GameFlowOut, 'springt ');
							WriteLn(GameFlowOut, 'von ' + FieldPosToStr(SourceFP) +
								' auf ' + FieldPosToStr(TargetFP));
							{ Spieler auf der Quellposition setzen }
							Field.Pos[SourceFP.X, SourceFP.Y].Owner := oNone;
							{ Selektierte Position loeschen }
							SelectedFP.X := High(TFieldWidth);
							SelectedFP.Y := High(TFieldHeight);
							{ Spieler auf die Zielposition setzen }
							Field.Pos[TargetFP.X, TargetFP.Y].Owner :=
								PlayerToOwner(CurrentPlayer);
						end;

						{ Spieler schlaegt }
						mkCapture:
						begin
							{ Info ausgeben }
							SetAttribute(GameFlowOut, cCapturePossibilityColor);
							WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
								' schlaegt ' + FieldPosToStr(SourceFP));
							SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
							{ Spieler auf der Quellposition setzen }
							Field.Pos[SourceFP.X, SourceFP.Y].Owner := oNone;
							{ Selektierte Position loeschen }
							SelectedFP.X := High(TFieldWidth);
							SelectedFP.Y := High(TFieldHeight);
						end;

						{ Stein wird geklaut }
						mkSteal:
						begin
							{ Info ausgeben }
							SetAttribute(GameFlowOut, cCapturePossibilityColor);
							WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
								' verliert ' + FieldPosToStr(SourceFP));
							SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
							{ Spieler auf der Quellposition setzen }
							Field.Pos[SourceFP.X, SourceFP.Y].Owner := oNone;
							{ Selektierte Position loeschen }
							SelectedFP.X := High(TFieldWidth);
							SelectedFP.Y := High(TFieldHeight);
						end;
					end;
				end;
				Debug('Zugdaten analysiert');
				Debug('Zeichne Spielfeld');

				{ Spielfeld zeichnen }
				DrawField(BoardOut, Field, PlayerColors, BoardCharLUT,
					CurrentPlayer, MovePossibilities, false, CursorFP,
					SelectedFP, PlayerStage);
				Debug('Spielfeld gezeichnet');

				{ Zugbestaetigung an Prozessrechner senden }
				with ProcessMessage do
				begin
					Kind := prmkTokenMoved;
					TokenMoveData := Message.TokenMoveData;
				end;
				Debug('Sende Zugbestaetigung an Prozessrechner');
				ProcMB.Put(DIPXSnd.Mailbox, ProcessMessage);
				Debug('Zugbestaetigung an Prozessrechner gesendet');
			end;

			{ Spielerphase }
			bmkPlayerStage:
			begin
				Debug('Spielerphase empfangen');
				PlayerStage := Message.PlayerStage;

				{ Pruefen, ob Benutzer an der Reihe ist }
				if (CurrentPlayer = User) then
				begin
					{ Pruefen, ob Zugmoeglichkeiten noetig sind }
					if (PlayerStage = psPlace) or ((PlayerStage in [psMove, psFly]) and
						(Field.Pos[CursorFP.X, CursorFP.Y].Owner = oUser)) then
					begin
						{ Zugmoeglichkeiten holen }
						GetTokenMovePossibilities(Field, CursorFP);
					end;
				end;

				{ Spielerphase auswerten und entsprechende Info ausgeben }
				case PlayerStage of
					{ Setzphase }
					psPlace:
					begin
						Write(GameFlowOut, PlayerToStr(CurrentPlayer) + ' darf setzen');
						SetAttribute(GameFlowOut, DefaultAttribute);
						if CurrentPlayer = User then
							WriteLn(GameFlowOut, ' (Position mit [Enter] auswaehlen)')
						else
							WriteLn(GameFlowOut);
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
					end;
					{ Ziehphase }
					psMove:
					begin
						Write(GameFlowOut, PlayerToStr(CurrentPlayer) + ' darf ziehen');
						SetAttribute(GameFlowOut, DefaultAttribute);
						if CurrentPlayer = User then
							WriteLn(GameFlowOut, ' (Quell- und Zielposition mit [Enter] ' +
								'auswaehlen)')
						else
							WriteLn(GameFlowOut);
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
					end;
					{ Spieler kann nicht ziehen }
					psCantMove:
						WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
							' kann nicht ziehen');
					{ Springphase }
					psFly:
					begin
						Write(GameFlowOut, PlayerToStr(CurrentPlayer) +
							' darf springen');
						SetAttribute(GameFlowOut, DefaultAttribute);
						if CurrentPlayer = User then
							WriteLn(GameFlowOut, ' (Quell- und Zielposition mit [Enter] ' +
								'auswaehlen)')
						else
							WriteLn(GameFlowOut);
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
					end;
					{ Schlagphase }
					psCapture:
					begin
						SetAttribute(GameFlowOut, cCapturePossibilityColor);
						WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
							' hat eine Muehle');
						Write(GameFlowOut, PlayerToStr(CurrentPlayer) +
							' darf schlagen');
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
						SetAttribute(GameFlowOut, DefaultAttribute);
						if CurrentPlayer = User then
							WriteLn(GameFlowOut, ' (Position mit [Enter] auswaehlen)')
						else
							WriteLn(GameFlowOut);
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
					end;
					{ Spieler kann nicht schlagen }
					psCantCapture:
					begin
						SetAttribute(GameFlowOut, cCapturePossibilityColor);
						WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) +
							' kann nicht schlagen');
						SetAttribute(GameFlowOut, PlayerColors[CurrentPlayer]);
					end;
				end;

				{ Spielerphase und Spieler auswerten und entsprechende Info ausgeben }
				if PlayerStage in [psPlace, psMove, psFly, psCapture] then
				begin
					if CurrentPlayer = User then
						WriteLn(GameFlowOut, 'Eingabe erwartet')
					else
						WriteLn(GameFlowOut, 'CPU denkt');
				end;
			end;

			{ Spiel zu Ende }
			bmkGameOver:
			begin
				GameOver := true;
				{ Info ausgeben }
				WriteLn(GameFlowOut, PlayerToStr(CurrentPlayer) + ' hat verloren');
				SetAttribute(GameFlowOut, cGameFlowWindowColor);
				WriteLn(GameFlowOut, 'Spiel mit [B] beenden');
			end;
		end;
		Debug('Nachricht analysiert');
		{ Taskwechsel }
		RTKernel.Delay(0);
	end;

	Debug('Werde zerstoert');
end;

end.