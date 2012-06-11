unit Leader;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit beinhaltet die Spielleitertask. Der Spielleiter steuert den
	Spielablauf, nimmt die Zuege der Spieler entgegen und verwaltet das
	Spielfeld.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	LeadMB;

var
	Mailbox: LeadMB.Mailbox;

procedure LeaderTask;

implementation

uses
	DOS,
	RTKernel, RTTextIO, Timer,
	Types, Tools, THMsg, Semas, PlayMsg, PTypes, DispMB, PIPXSnd, TokenMsg,
		Player;

procedure InitField(var Field: TField);
(*****************************************************************************
	Beschreibung:
		Initialisiert das Spielfeld mit Defaultwerten.

	In:
		Field: TField: Spielfeld, das initialisiert werden soll

	Out:
		Field: TField: Initialisiertes Spielfeld
*****************************************************************************)
var
	x: TFieldWidth;
	y: TFieldHeight;
begin
	{ Spielfeld horizontal durchlaufen }
	for x := Low(TFieldWidth) to High(TFieldWidth) - 1 do
	begin
		{ Spielfeld vertikal durchlaufen }
		for y := Low(TFieldHeight) to High(TFieldHeight) - 1 do
		begin
			with Field.Pos[x, y] do
			begin
				{ Berechnen, ob Position gueltig ist }
				Valid := ((x <> cFieldSquareCount) or (y <> cFieldSquareCount)) and
					((x = y) or ((x + y) = (cFieldSquareCount * 2)) or
					(x = cFieldSquareCount) or (y = cFieldSquareCount));
				{ Kein Spieler }
				Owner := oNone;
				{ Kein Spielstein }
				TokenTH := NoTask;
			end;
		end;
	end;
end;

procedure SendFieldToPlayer(F: TField; TH: TaskHandle);
(*****************************************************************************
	Beschreibung:
		Sendet das Spielfeld per Message-Passing an einen Spieler.

	In:
		F: TField: Spielfeld
		TH: TaskHandle: Taskhandle des Spielers

	Out:
		-
*****************************************************************************)
var
	PlayerMessage: TPlayerMessage;
begin
	{ Nachrichtinhalt als Spielfeld markieren und absenden }
	PlayerMessage.Kind := plmkField;
	PlayerMessage.Field := F;
	Debug('Sende Spielfeld an ' + GetTaskName(TH));
	PlayMsg.Send(TH, PlayerMessage);
	Debug('Spielfeld an ' + GetTaskName(TH) + ' gesendet');
end;

procedure SendFieldToDisplayComputer(F: TField);
(*****************************************************************************
	Beschreibung:
		Sendet das Spielfeld an den Anzeigerechner, indem die Nachricht in der
		Mailbox der IPX-Sendetask abgelegt wird.

	In:
		F: TField: Spielfeld.

	Out:
		-
*****************************************************************************)
var
	DM: TDisplayMessage;
begin
	{ Nachrichtinhalt als Spielfeld markieren und in IPX-Mailbox ablegen }
	DM.Kind := dmkField;
	DM.Field := F;
	Debug('Sende Spielfeld an Displayrechner');
	DispMB.Put(PIPXSnd.Mailbox, DM);
	Debug('Spielfeld an Displayrechner gesendet');
end;

procedure PreparePlayerMove(TH: TaskHandle; PMK: TPlayerMessageKind);
(*****************************************************************************
	Beschreibung:
		Sendet per Message-Passing eine Nachricht an einen Spieler, sodass der
		Spieler einen Zug vorbereiten kann.

	In:
		TH: TaskHandle: Taskhandle des Spielers
		PMK: TPlayerMessageKind: Zugart (Ziehen / Schlagen)

	Out:
		-
*****************************************************************************)
var
	PM: TPlayerMessage;
begin
	PM.Kind := PMK;
	Debug('Sende Zugvorbereitungskommando an ' + GetTaskName(TH));
	PlayMsg.Send(TH, PM);
	Debug('Zugvorbereitungskommando an ' + GetTaskName(TH) + ' gesendet');
end;

{$F+}
procedure LeaderTask;
(*****************************************************************************
	Beschreibung:
		Spielleitertask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	PlayerTaskHandles: TPlayerTaskHandles;
	LeaderIn,
	LeaderOut: text;
	FirstPlayer,
	CurrentPlayer: TPlayer;
	Field: TField;
	DisplayMessage: TDisplayMessage;
	GameStarted: boolean;
	PlayerColors: TPlayerColors;
	Message: TLeaderMessage;
	PlayerMessage: TPlayerMessage;
	ip: TPlayer;
	TaskName: Name;
	PlayerTimeLimits: TPlayerTimeLimits;
	MoveTime: FineTime;
	GameOver: boolean;
	Y, M, D, DOW, H, Min, S, CS: word;
begin
	Debug('Wurde erzeugt');

	{ Mailbox initialisieren }
	Debug('Initalisiere Mailbox');
	LeadMB.InitMailbox(Mailbox, cLeaderMailboxSlots, 'Leader mailbox');
	Debug('Mailbox initalisiert');

	{ Fenster erzeugen }
	Debug('Erzeuge Fenster');
	NewWindow(LeaderIn, LeaderOut, cLeaderWindowFirstCol, cLeaderWindowFirstRow,
		cLeaderWindowLastCol, cLeaderWindowLastRow, cLeaderWindowColor,
		' ' + cLeaderTaskName + ' ');
	Debug('Fenster erzeugt');

	{ Spielertaskhandles }
	Debug('Warte auf Spielertaskhandles');
	LeadMB.Get(Mailbox, Message);
	if Message.Kind <> lemkPlayerTaskHandles then
		Die('Unexpected command in leader');
	PlayerTaskHandles := Message.PlayerTaskHandles;
	Debug('Spielertaskhandles empfangen');

	{ Erster Spieler }
	Debug('Warte auf ersten Spieler');
	LeadMB.Get(Mailbox, Message);
	if Message.Kind <> lemkFirstPlayer then
		Die('Unexpected command in leader');
	FirstPlayer := Message.FirstPlayer;
	Debug('Ersten Spieler empfangen (' + PlayerToStr(FirstPlayer) + ')');

	{ Spielerfarben }
	Debug('Warte auf Spielerfarben');
	LeadMB.Get(Mailbox, Message);
	if Message.Kind <> lemkPlayerColors then
		Die('Unexpected command in leader');
	PlayerColors := Message.PlayerColors;
	Debug('Spielerfarben empfangen');

	GameOver := false;

	while true do
	begin
		{ Auf Nacrichten warten }
		Debug('Warte auf Nachrichten');
		LeadMB.Get(Mailbox, Message);
		Debug('Nachricht empfangen');

		{ Wenn Spiel zu Ende ist, nur bestimmte Nachrichtenarten verarbeiten }
		if not GameOver or (Message.Kind in [lemkInit, lemkEndGame]) then
		begin

			{ Nachricht analysieren }
			Debug('Analysiere Nachricht');
			case Message.Kind of
				{ Init }
				lemkInit:
				begin
					Debug('Initialisierungskommando empfangen');

					{ Ersten Spieler setzen }
					CurrentPlayer := FirstPlayer;

					{ Fensterfarbe setzen }
					SetAttribute(LeaderOut, DefaultAttribute);

					{ Spielfeld und Anzahl der Spielsteine initialisieren }
					Debug('Initialisiere Spielfeld');
					InitField(Field);
					Debug('Spielfeld initialisiert');
					Debug('Initalisiere Anzahl nicht gesetzter Spielsteine');
					Field.PlacedTC[User] := Low(TTokenCount);
					Field.PlacedTC[CPU] := Low(TTokenCount);
					Debug('Anzahl nicht gesetzter Spielsteine initalisiert');
					Debug('Initalisiere Anzahl geschlagener Spielsteine');
					Field.CapturedTC[User] := Low(TTokenCount);
					Field.CapturedTC[CPU] := Low(TTokenCount);
					Debug('Anzahl geschlagener Spielsteine initalisiert');

					{ Anzeigerechner initialisieren }
					DisplayMessage.Kind := dmkInit;
					DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);

					{ Spieler initialisieren }
					Debug('Initialisiere Spieler');
					for ip := Low(TPlayer) to High(TPlayer) do
					begin
						TaskName := GetTaskName(PlayerTaskHandles[ip]);
						SendFieldToPlayer(Field, PlayerTaskHandles[ip]);
						PlayerMessage.Kind := plmkInit;
						Debug('Sende Initialisierungkommando an ' + TaskName);
						PlayMsg.Send(PlayerTaskHandles[ip], PlayerMessage);
						Debug('Initialisierungskommando an ' + TaskName + ' gesendet');
					end;
					Debug('Spieler initialisiert');

					{ Fenster leeren und Info zum Spielstart ausgeben }
					Write(LeaderOut, FormFeed);
					WriteLn(LeaderOut, 'Spiel mit [S] starten');

					{ Auf Spielstart warten }
					Wait(StartSemaphore);

					{ Spielstart in die Logdatei schreiben }
					GetDate(Y, M, D, DOW);
					DOS.GetTime(H, Min, S, CS);
					Log('Spielstart am ' + IntToStr(d, 2) + '.' + IntToStr(m, 2) +
						'.' + IntToStr(y, 4) + ' um ' + IntToStr(h, 2) + ':' +
						IntToStr(min, 2) + ':' + IntToStr(s, 2));

					WriteLn(LeaderOut, 'Spiel gestartet');

					{ Mailbox leeren }
					LeadMB.ClearMB(Mailbox);

					{ Nachricht in der Mailbox ablegen, damit als naechstes der erste
						Spieler eine Nachricht zum Zug vorbereiten erhaelt }
					Message.Kind := lemkPrepareMove;
					LeadMB.Put(Mailbox, Message);

					GameOver := false;
				end;
				{ Zugvorbereitungsnachricht an den aktuellen Spieler schicken }
				lemkPrepareMove, lemkPrepareCapture:
				begin
					{ Je nach Zugart eine Debugmeldung ausgeben }
					if Message.Kind = lemkPrepareMove then
						Debug('Befehl zum Senden eines Zugkommandos empfangen')
					else if Message.Kind = lemkPrepareCapture then
						Debug('Befehl zum Senden eines Schlagkommandos empfangen');

					TaskName := GetTaskName(PlayerTaskHandles[CurrentPlayer]);
					SendFieldToPlayer(Field, PlayerTaskHandles[CurrentPlayer]);

					{ Beim normaler Zug den aktuellen Spieler an den Anzeigerechner
						senden }
					if Message.Kind = lemkPrepareMove then
					begin
						DisplayMessage.Kind := dmkCurrentPlayer;
						DisplayMessage.Player := CurrentPlayer;
						Debug('Sende aktuellen Spieler an Displayrechner');
						DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);
						Debug('Aktuellen Spieler an Displayrechner gesendet');
					end;
					SendFieldToDisplayComputer(Field);

					{ Textfarbe anpassen }
					SetAttribute(LeaderOut, PlayerColors[CurrentPlayer]);

					{ Entsprechende Nachricht an den Spieler schicken }
					if Message.Kind = lemkPrepareMove then
						PreparePlayerMove(PlayerTaskHandles[CurrentPlayer],
							plmkPrepareMove)
					else if Message.Kind = lemkPrepareCapture then
						PreparePlayerMove(PlayerTaskHandles[CurrentPlayer],
							plmkPrepareCapture);

					WriteLn(LeaderOut, TaskName + ' ist an der Reihe');

					{ Nachricht in der eigenen Mailbox ablegen, damit der Spieler als
						naechstes eine Nachricht zum Ziehen erhaelt, aber nur wenn
						der letzte Zug kein Klauzug war }
					if Message.TokenMoveData.MoveData.Kind <> mkSteal then
					begin

						if Message.Kind = lemkPrepareMove then
							Message.Kind := lemkMove
						else if Message.Kind = lemkPrepareCapture then
							Message.Kind := lemkCapture;

						{ Zeit merken, wenn der letzte kein Klauzug war }
						MarkTime(MoveTime);

						LeadMB.Put(Mailbox, Message);
					end;
					WriteLn(LeaderOut, 'Warte auf Zug von ' + TaskName);
				end;
				{ Zugnachricht an den aktuellen Spieler senden }
				lemkMove, lemkCapture:
				begin
					{ Ueberpruefen, ob der aktuelle Spieler noch "denkt" }
					if ElapsedTime(MoveTime) < PlayerTimeLimits[CurrentPlayer] then
						{ Nachricht wieder in der Mailbox ablegen }
						LeadMB.Put(Mailbox, Message)
					else
					begin
						{ Entsprechende Nachricht an den Spieler senden }
						if Message.Kind = lemkMove then
							PlayerMessage.Kind := plmkMove
						else if Message.Kind = lemkCapture then
							PlayerMessage.Kind := plmkCapture;
						Debug('Sende Zugkommando an ' + TaskName);
						PlayMsg.Send(PlayerTaskHandles[CurrentPlayer], PlayerMessage);
						Debug('Zugkommando an ' + TaskName + ' gesendet');
					end;
				end;
				{ Der aktuelle Spieler hat gezogen }
				lemkPlayerMoved, lemkPlayerCaptured:
				begin
					{ Schriftfarbe anpassen }
					SetAttribute(LeaderOut, PlayerColors[CurrentPlayer]);
					WriteLn(LeaderOut, 'Zug von ' + PlayerToStr(CurrentPlayer) +
						' empfangen');

					{ Zug auswerten }
					WriteLn(LeaderOut, 'Werte Zug aus');
					with Message.TokenMoveData do
					begin
						case MoveData.Kind of
							{ Spieler hat gesetzt }
							mkPlace:
							begin
								with MoveData do
								begin
									{ Anzahl gesetzter Spielsteine erhoehen }
									Inc(Field.PlacedTC[CurrentPlayer]);

									{ Zielposition als besetzt markeieren }
									Field.Pos[TargetFP.X, TargetFP.Y].Owner :=
										PlayerToOwner(CurrentPlayer);
									Field.Pos[TargetFP.X, TargetFP.Y].TokenTH := TokenTH;

									{ Info ausgeben }
									WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) +
										' setzt auf ' + FieldPosToStr(TargetFP));
								end;
							end;
							{ Spieler hat gezogen }
							mkMove:
							begin
								with MoveData do
								begin
									{ Quellposition als frei markieren }
									Field.Pos[SourceFP.X, SourceFP.Y].Owner := oNone;
									Field.Pos[SourceFP.X, SourceFP.Y].TokenTH := NoTask;

									{ Zielposition als besetzt markieren }
									Field.Pos[TargetFP.X, TargetFP.Y].Owner :=
										PlayerToOwner(CurrentPlayer);
									Field.Pos[TargetFP.X, TargetFP.Y].TokenTH := TokenTH;

									{ Info ausgeben }
									WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) +
										' zieht von ' + FieldPosToStr(MoveData.SourceFP) + ' auf ' +
										FieldPosToStr(MoveData.TargetFP));
								end;
							end;
							{ Spieler hat geschlagen }
							mkCapture:
							begin
								with MoveData do
								begin
									{ Anzahl geschlagener Steine erhoehen }
									Inc(Field.CapturedTC[GetOtherPlayer(CurrentPlayer)]);

									{ Quelle als frei markieren }
									Field.Pos[SourceFP.X, SourceFP.Y].Owner := oNone;
									Field.Pos[SourceFP.X, SourceFP.Y].TokenTH := NoTask;

									{ Info in besonderer Farbe ausgeben }
									SetAttribute(LeaderOut, cCapturePossibilityColor);
									WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) +
										' schlaegt ' + FieldPosToStr(MoveData.SourceFP));
									SetAttribute(LeaderOut, DefaultAttribute);
								end;
							end;
							{ Spieler konnte nicht schlagen, weil alle Spielsteine des
								Gegners in Muehlen sind }
							mkNoMove:
							begin
								{ Info ausgeben }
								SetAttribute(LeaderOut, cCapturePossibilityColor);
								WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) +
									' kann nicht schlagen');
								SetAttribute(LeaderOut, DefaultAttribute);
							end;
							{ Spieler hat einen Spielstein durch Cheaten verloren }
							mkSteal:
							begin
								with MoveData do
								begin
									{ Anzahl geschlagener Spielsteine erhoehen }
									Inc(Field.CapturedTC[CurrentPlayer]);

									{ Quellposition als frei markieren }
									Field.Pos[SourceFP.X, SourceFP.Y].Owner := oNone;
									Field.Pos[SourceFP.X, SourceFP.Y].TokenTH := NoTask;

									{ Info in besonderer Farbe ausgeben }
									SetAttribute(LeaderOut, cCapturePossibilityColor);
									WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) +
										' verliert ' + FieldPosToStr(MoveData.SourceFP));
									SetAttribute(LeaderOut, DefaultAttribute);
								end;
							end;
						end;
						{ Zug in die Logdatei schreiben }
						LogMove(CurrentPlayer, MoveData);

						{ Anzahl der Spielsteine des aktuellen Spielers ueberpruefen }
						if ((cTokenCount - Field.CapturedTC[CurrentPlayer]) =
							cFieldSquareCount - 1) then
						begin
							{ Zu wenig Steine => Spiel vorbei }
							Message.Kind := lemkGameOver;
							LeadMB.PutFront(Mailbox, Message);
						end

						{ Wenn Spieler gezogen hat, ueberpruefen, ob mit dem Zug eine
							Muehle geschlossen wurde }
						else if (Message.Kind = lemkPlayerMoved) and
							(MoveData.Kind in [mkPlace, mkMove]) and
							(HasMillInCol(Field, MoveData.TargetFP,
							PlayerToOwner(CurrentPlayer)) or (HasMillInRow(Field,
							MoveData.TargetFP, PlayerToOwner(CurrentPlayer)))) then
						begin
							{ Info in besonderer Farbe ausgeben }
							SetAttribute(LeaderOut, cCapturePossibilityColor);
							WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) +
								' hat eine Muehle');
							WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) + ' darf schlagen');
							SetAttribute(LeaderOut, DefaultAttribute);

							{ Nachricht in der eigenen Mailbox ablegen, damit als naechstes
								eine Schlagvorbereitungsnachricht an den aktuellen Spieler
								gesendet wird }
							Message.Kind := lemkPrepareCapture;
							LeadMB.Put(Mailbox, Message);
							Debug('Zug ausgewertet');
						end
						else
						{ Zug wurde ausgwertet }
						begin
							Debug('Zug ausgewertet');
							{ Wenn der Zug kein Klauzug ist, naechsten Spieler bestimmen }
							if MoveData.Kind <> mkSteal then
							begin
								Debug('Bestimme naechsten Spieler');
								CurrentPlayer := GetOtherPlayer(CurrentPlayer);
								Debug('Naechsten Spieler bestimmt');
							end;
							{ Nachricht in der eigenen Mailbox ablegen, damit der naechste
								Spieler ein Zugvorbereitungsnachricht erhaelt }
							Message.Kind := lemkPrepareMove;
							LeadMB.PutFront(Mailbox, Message);
						end;
					end;
				end;
				{ Spielende }
				lemkEndGame:
				begin
					{ Info ausgeben }
					Debug('Kommando zum Beenden des Spiels empfangen');
					SetAttribute(LeaderOut, DefaultAttribute);
					WriteLn(LeaderOut, 'Beende Spiel');

					{ Programmende in die Logdatei schreiben }
					GetDate(Y, M, D, DOW);
					DOS.GetTime(H, Min, S, CS);
					Log('Spielende am ' + IntToStr(D, 2) + '.' + IntToStr(M, 2) +
						'.' + IntToStr(Y, 4) + ' um ' + IntToStr(H, 2) + ':' +
						IntToStr(Min, 2) + ':' + IntToStr(S, 2));

					{ Anzeigerechner benachrichtigen }
					DisplayMessage.Kind := dmkInit;
					DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);

					{ Spielfeld initialisieren und an den Anzeigerechner senden }
					InitField(Field);
					SendFieldToDisplayComputer(Field);

					{ Initialisierungsnachricht in der Mailbox ablegen }
					Message.Kind := lemkInit;
					LeadMB.PutFront(Mailbox, Message);
				end;
				{ Benutzer hat einen Zug ausgewaehlt }
				lemkUserMoveSelected:
				begin
					Debug('Benutzer hat Zug ausgewaehlt');

					{ Spielleiter benachrichtigen }
					PlayerMessage.Kind := plmkUserMoveSelected;
					PlayerMessage.TokenMoveData.MoveData := Message.MoveData;
					Debug('Leite Nachricht an Benutzer weiter');
					PlayMsg.Send(PlayerTaskHandles[User], PlayerMessage);

					Debug('Nachricht an Benutzer weitergeleitet');
				end;
				{ Anzeigerechner fragt nach Zugmoeglichkeiten }
				lemkGetTokenMovePossibilities:
				begin
					Debug('Anfrage nach Zugmoeglichkeiten empfangen');

					{ Anfrage an aktuellen Spieler weiter leiten }
					PlayerMessage.Kind := plmkGetMovePossibilities;
					PlayerMessage.TokenTaskHandle := Message.TokenTaskHandle;
					Debug('Leite Anfrage nach Zugmoeglichkeiten an ' +
						PlayerToStr(CurrentPlayer) + ' weiter');
					PlayMsg.Send(PlayerTaskHandles[CurrentPlayer], PlayerMessage);

					Debug('Anfrage nach Zugmoeglichkeiten an ' +
						PlayerToStr(CurrentPlayer) + ' weitergeleitet');
				end;
				{ Aktueller Spieler kann nicht ziehen => Game over }
				lemkGameOver:
				begin
					{ Info ausgeben usgeben und in die Logdate schreiben }
					WriteLn(LeaderOut, PlayerToStr(CurrentPlayer) + ' hat verloren');
					Log(PlayerToStr(CurrentPlayer) + ' hat verloren');

					SetAttribute(LeaderOut, DefaultAttribute);
					WriteLn(LeaderOut, 'Spiel mit [B] beenden');

					{ Anzeigerechner benachrichtigen }
					DisplayMessage.Kind := dmkGameOver;
					DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);
					GameOver := true;
				end;
				{ Spielstein soll geklaut werden }
				lemkStealToken:
				begin
					{ Nachricht an Spieler weiterleiten }
					PlayerMessage.Kind := plmkStealToken;
					PlayMsg.Send(PlayerTaskHandles[CurrentPlayer], PlayerMessage);
				end;
				{ Bedenkzeit empfangen }
				lemkTimeLimit:
				begin
					PlayerTimeLimits[CurrentPlayer] := Message.TimeLimit;
				end;
			end;
			Debug('Nachricht analysiert');
		end;
	end;

	Debug('Werde zerstoert');
end;

end.