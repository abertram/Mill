unit Token;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit beinhaltet die Spielsteintask.
	Diese berechnet die Zugmoeglichkeiten eines Spielsteins, nimmt einen Zug
	entgegen, sendet diesen an den Displayrechner, empfaengt die
	Zugbestaetigung und sendet diese an den zustaendigen Spieler.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

procedure TokenTask;

implementation

uses
	RTKernel,
	Types, PTypes, Tools, TokenMsg, LeadMB, Leader, PlayMsg, DispMB, PIPXSnd;

procedure ProcessMoveData(MoveData: TMoveData; var FP: TFieldPos;
	var State: TTokenState);
(*****************************************************************************
	Beschreibung:
		Verarbeitet Zugdaten.

	In:
		MoveData: TMoveData: Zugdaten

	Out:
		FP: TFieldPos: Position des Steins
		State: TTokenState: Zustand des Steins
*****************************************************************************)
begin
	with MoveData do
	begin
		FP := TargetFP;
		case Kind of
			{ Stein gesetzt }
			mkPlace:
			begin
				Debug('Wurde gesetzt');
				State := tsPlaced;
			end;

			{ Stein gezogen }
			mkMove:
				Debug('Wurde von ' + FieldPosToStr(SourceFP) + ' auf ' +
					FieldPosToStr(TargetFP) + ' gezogen');

			{ Stein geschlagen }
			mkCapture:
			begin
				Debug('Wurde geschlagen');
				State := tsCaptured;
			end;

			{ Stein geklaut }
			mkSteal:
			begin
				Debug('Wurde geklaut');
				State := tsStolen;
			end;
		end;
	end;
end;

{$F+}
procedure TokenTask;
(*****************************************************************************
	Beschreibung:
		Spielsteintask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	PlayerTaskHandle: TaskHandle;
	Message: TTokenMessage;
	Field: TField;
	PlayerMessage: TPlayerMessage;
	State: TTokenState;
	MovePossibilities: TMovePossibilities;
	x: TFieldWidth;
	y: TFieldHeight;
	DisplayMessage: TDisplayMessage;
	PlayerStage: TPlayerStage;
	FieldPos,
	TmpFieldPos: TFieldPos;
	MoveDirections: TDirectionSet;
begin
	Debug('Wurde erzeugt');

	{ Spielertaskhandle empfangen }
	Debug('Warte auf Spielertaskhandle');
	TokenMsg.Receive(Message);
	if Message.Kind <> tmkPlayerTaskHandle then
		Die('Unexpected command in token');
	Debug('Spielertaskhandle empfangen');
	PlayerTaskHandle := Message.PlayerTaskHandle;

	while true do
	begin
		{ Auf Nachrichten warten }
		Debug('Warte auf Nachrichten');
		TokenMsg.Receive(Message);
		Debug('Nachricht empfangen');
		Debug('Analysiere Nachricht');

		{ Nachricht analysieren }
		case Message.Kind of

			{ Initialisierungsnachricht }
			tmkInit:
			begin
				Debug('Initialisierungskommando empfangen');
				{ Position initialisieren }
				FieldPos.X := Low(TFieldWidth);
				FieldPos.Y := Low(TFieldHeight);
				{ Zustand initialisieren }
				State := tsNotPlaced;
				{ Zugrichtungen initialisieren }
				MoveDirections := [];
			end;

			{ Anfrage nach Spielsteindaten }
			tmkGetTokenData:
			begin
				Debug('Anfrage nach Spielsteindaten von ' +
					GetTaskName(Message.SenderTaskHandle) + ' empfangen');
				Debug('Initialisiere Zugmoeglichkeiten');
				{ Zugmoeglichkeiten initialisieren }
				FillChar(MovePossibilities, SizeOf(MovePossibilities), false);
				{ Zugrichtungen initialisieren }
				MoveDirections := [];
				Debug('Zugmoeglichkeiten initialisiert');

				{ Stein ist noch nicht gesetzt oder gesetzt, also noch im Spiel }
				if State in [tsNotPlaced, tsPlaced] then
				begin
					Debug('Berechne Zugmoeglichkeiten');
					{ Spielerphase auswerten }
					case PlayerStage of

						{ Spieler zieht oder springt }
						psPlace, psFly:
						begin

							{ Stein kann auf jede freie Position }
							for x := Low(TFieldWidth) to High(TFieldWidth) - 1 do
								for y := Low(TFieldHeight) to High(TFieldHeight) - 1 do
									MovePossibilities[x, y] :=
										Field.Pos[x, y].Valid and
										(Field.Pos[x, y].Owner = oNone);
						end;

						{ Spieler zieht }
						psMove:
						begin
							{ Alle vier Zugrichtungen ausprobieren. Wenn die Position in
								der Richtung frei ist, Zugrichtung in die Zugrichtungsmenge
								aufnehmen }
							TmpFieldPos := FieldPos;
							{ Links }
							if GetLeftFieldPos(Field, TmpFieldPos) then
							begin
								if Field.Pos[TmpFieldPos.X, TmpFieldPos.Y].Owner = oNone then
								begin
									MovePossibilities[TmpFieldPos.X, TmpFieldPos.Y] := true;
									Include(MoveDirections, dLeft);
								end;
							end;
							TmpFieldPos := FieldPos;
							{ Rechts }
							if GetRightFieldPos(Field, TmpFieldPos) then
							begin
								if Field.Pos[TmpFieldPos.X, TmpFieldPos.Y].Owner = oNone then
								begin
									MovePossibilities[TmpFieldPos.X, TmpFieldPos.Y] := true;
									Include(MoveDirections, dRight);
								end;
							end;
							TmpFieldPos := FieldPos;
							{ Oben }
							if GetUpperFieldPos(Field, TmpFieldPos) then
							begin
								if Field.Pos[TmpFieldPos.X, TmpFieldPos.Y].Owner = oNone then
								begin
									MovePossibilities[TmpFieldPos.X, TmpFieldPos.Y] := true;
									Include(MoveDirections, dUp);
								end;
							end;
							TmpFieldPos := FieldPos;
							{ Unten }
							if GetLowerFieldPos(Field, TmpFieldPos) then
							begin
								if Field.Pos[TmpFieldPos.X, TmpFieldPos.Y].Owner = oNone then
								begin
									MovePossibilities[TmpFieldPos.X, TmpFieldPos.Y] := true;
									Include(MoveDirections, dDown);
								end;
							end;
						end;
					end;

					Debug('Zugmoeglichkeiten berechnet');
				end;

				{ Spielsteindaten zusammenfassen }
				with PlayerMessage do
				begin
					Kind := plmkTokenData;
					TokenData.TokenTH := CurrentTaskHandle;
					TokenData.FieldPos := FieldPos;
					TokenData.State := State;
					TokenData.MoveDirections := MoveDirections;
					TokenData.MovePossibilities := MovePossibilities;
				end;

				{ Spielsteindaten an den Spieler schicken }
				Debug('Sende Spielsteindaten an ' +
					GetTaskName(Message.SenderTaskHandle));
				PlayMsg.Send(PlayerTaskHandle, PlayerMessage);
				Debug('Spielsteindaten an ' + GetTaskName(Message.SenderTaskHandle) +
					' gesendet');
			end;

			{ Zugnachricht }
			tmkMove:
			begin
				Debug('Zugdaten empfangen');

				{ Zugdaten an den Anzeigerechner senden }
				with DisplayMessage do
				begin
					Kind := dmkTokenMove;
					with TokenMoveData do
					begin
						TokenTH := CurrentTaskHandle;
						MoveData := Message.MoveData;
					end;
				end;
				Debug('Sende Zugdaten an Displayrechner');
				DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);
				Debug('Zugdaten an Displayrechner gesendet');
				Debug('Warte auf Zugbestaetigung');
			end;

			{ Zugbestaetigung vom Anzeigerechner }
			tmkTokenMoved:
			begin
				Debug('Zugbestaetigung empfangen');
				Debug('Verarbeite Zugdaten');

				{ Zug verarbeiten }
				ProcessMoveData(Message.MoveData, FieldPos, State);
				Debug('Zugdaten verarbeitet');

				{ Zugbestaetigung an Spieler senden }
				with PlayerMessage do
				begin
					Kind := plmkTokenMoved;
					TokenMoveData.TokenTH := CurrentTaskHandle;
					TokenMoveData.MoveData := Message.MoveData;
				end;
				Debug('Sende Zugbestaetigung an Spieler');

				{ Wenn geschlagen wird, an Gegnerspieler senden }
				if Message.MoveData.Kind = mkCapture then
					PlayMsg.Send(Message.MoveData.PlayerTH, PlayerMessage)
				else
					PlayMsg.Send(PlayerTaskHandle, PlayerMessage);
				Debug('Zugbestaetigung an Spieler gesendet');
			end;

			{ Spielfeld }
			tmkField:
			begin
				Debug('Spielfeld empfangen');
				Field := Message.Field;
			end;

			{ Spielerphase }
			tmkPlayerStage:
			begin
				Debug('Spielerphase empfangen');
				PlayerStage := Message.PlayerStage;
			end;
		end;

		Debug('Nachricht analysiert');
	end;

	Debug('Werde zerstoert');
end;

end.
