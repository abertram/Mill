unit DIPXRcv;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Beinhaltet die IPX-Empfaenger-Task, die Nachrichten per IPX empfaengt und
	diese an die zustaendigen Tasks weiterleitet.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

procedure IPXReceiverTask;

implementation

uses
	RTKernel, RTIPX,
	Types, DIPX, Tools, DispMB, BoardMB, Board, DTypes, Semas;

{F+}
procedure IPXReceiverTask;
(*****************************************************************************
	Beschreibung:
		IPX-Empfaenger-Task

	In:
		-

	Out:
		-
*****************************************************************************)
var
	PMessage: PDisplayMessage;
	BoardMessage: TBoardMessage;
begin
	Debug('Wurde erzeugt');

	{ IPX-Kanal oeffnen }
	Debug('Oeffne Kanal');
	DIPX.OpenChannel(cIPXReceiveBuffers);
	Debug('Kanal geoeffnet');

	while true do
	begin
		{ Auf Nachrichten warten }
		Debug('Warte auf Nachrichten vom Prozessrechner');
		DIPX.Get(IPXMailbox, PMessage);
		Debug('Nachricht empfangen');

		{ Nachricht analysieren und wetierleiten }
		Debug('Analysiere Nachricht');
		case PMessage^.Kind of

			{ Initialisierungsnachricht }
			dmkInit:
			begin
				BoardMessage.Kind := bmkInit;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Spielerfarben }
			dmkPlayerColors:
			begin
				Debug('Spielerfarben empfangen');
				BoardMessage.Kind := bmkPlayerColors;
				BoardMessage.Colors := PMessage^.Colors;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Aktueller Spieler }
			dmkCurrentPlayer:
			begin
				Debug('Aktuellen Spieler empfangen');
				BoardMessage.Kind := bmkCurrentPlayer;
				BoardMessage.Player := PMessage^.Player;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Zugmoeglichkeiten }
			dmkMovePossibilities:
			begin
				Debug('Zugmoeglichkeiten empfangen');
				with BoardMessage do
				begin
					Kind := bmkTokenMovePossibilities;
					TokenMovePossibilities := PMessage^.Possibilities;
				end;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Spielfeld }
			dmkField:
			begin
				Debug('Spielfeld empfangen');
				with BoardMessage do
				begin
					Kind := bmkField;
					Field := PMessage^.Field;
				end;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Zugdaten }
			dmkTokenMove:
			begin
				Debug('Zugdaten empfangen');
				with BoardMessage do
				begin
					Kind := bmkTokenMove;
					TokenMoveData := PMessage^.TokenMoveData;
				end;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Spielerphase }
			dmkPlayerStage:
			begin
				Debug('Spielerphase empfangen');
				BoardMessage.Kind := bmkPlayerStage;
				BoardMessage.PlayerStage := PMessage^.Stage;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;

			{ Programmende }
			dmkExit:
			begin
				{$IFDEF DEBUG}
					LoggerMessage.Kind := lomkExit;
					LoggerMB.Put(Logger.Mailbox, LoggerMessage);
				{$ELSE}
					Signal(ExitSemaphore);
				{$ENDIF}
			end;

			{ Spielende }
			dmkGameOver:
			begin
				BoardMessage.Kind := bmkGameOver;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;
		end;
		Debug('Nachricht analysiert');

		{ IPX-Buffer freigeben }
		Debug('Gebe IPX-Buffer frei');
		DIPX.FreeBuffer(PMessage);
		Debug('IPX-Buffer freigegeben');

		{ Taskwechsel }
		RTKernel.Delay(0);
	end;

	Debug('Werde zerstoert');
end;

end.