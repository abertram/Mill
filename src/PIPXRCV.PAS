unit PIPXRcv;
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
	RTKernel, RTIPX, RTKeyBrd,
	Types, PTypes, PIPX, Tools, LeadMB, Leader, TokenMsg, LoggerMB, Logger;

{F+}
procedure IPXReceiverTask;
(*****************************************************************************
	Beschreibung:
		IPX-Empfaenger-Task.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	PMessage: PProcessMessage;
	LeaderMessage: TLeaderMessage;
	TokenMessage: TTokenMessage;
begin
	Debug('Wurde erzeugt');

	{ IPX-Kanal oeffnen }
	Debug('Oeffne Kanal');
	PIPX.OpenChannel(cIPXReceiveBuffers);
	Debug('Kanal geoffnet');

	while true do
	begin
		{ Auf Nachrichten warten }
		Debug('Warte auf Nachricht vom Displayrechner');
		PIPX.Get(IPXMailbox, PMessage);
		Debug('Nachricht empfangen');
		{ Nachricht analysieren }
		Debug('Analysiere Nachricht');
		case PMessage^.Kind of

			{ Benutzer hat auf dem Anzeigerechner einer Zug ausgewaehlt }
			prmkUserMoveSelected:
			begin
				{ Zugdaten an Spielleiter senden }
				Debug('Benutzerzugwahl empfangen');
				LeaderMessage.Kind := lemkUserMoveSelected;
				LeaderMessage.MoveData := PMessage^.MoveData;
				Debug('Leite Benutzerzugwahl an Spielleiter weiter');
				LeadMB.Put(Leader.Mailbox, LeaderMessage);
				Debug('Benutzerzugwahl an Spielleiter weitergeleitet');
			end;

			{ Zugbestaetigung vom Anzeigerechner }
			prmkTokenMoved:
			begin
				{ Zugbestaetigung an Spielstein senden }
				Debug('Zugbestaetigung empfangen');
				TokenMessage.Kind := tmkTokenMoved;
				TokenMessage.MoveData := PMessage^.TokenMoveData.MoveData;
				Debug('Leite Zugbestaetigung an Spielstein weiter');
				TokenMsg.Send(PMessage^.TokenMoveData.TokenTH, TokenMessage);
				Debug('Zugbestaetigung an Spielstein weitergeleitet');
			end;

			{ Anfrage nach Zugmoeglichkeiten }
			prmkGetTokenMovePossibilities:
			begin
				{ Anfrage an Spielleiter senden }
				Debug('Anfrage nach Zugmoeglichkeiten empfangen');
				LeaderMessage.Kind := lemkGetTokenMovePossibilities;
				LeaderMessage.TokenTaskHandle := PMessage^.TokenTH;
				Debug('Leite Anfrage nach Zugmoeglichkeiten an Spielleiter weiter');
				LeadMB.Put(Leader.Mailbox, LeaderMessage);
				Debug('Anfrage nach Zugmoeglichkeiten weitergeleitet');
			end;

			{ Spiel auf dem Darstellungsrechner gestartet }
			prmkStartGame:
			begin
				{ Tastendruck auf dem Prozessrechner simulieren }
				Debug('Spielstartkommando empfangen');
				PutChar('s', Chr($1F));
			end;

			{ Spiel auf dem Darstellungsrechner beendet }
			prmkEndGame:
			begin
				{ Tastendruck auf dem Prozessrechner simulieren }
				Debug('Spielendkommando empfangen');
				PutChar('b', Chr($30));
			end;

			{ Programm wurde auf dem Darstellungsrechner beendet }
			prmkExit:
			begin
				{ Logger ueber Programmende benachrichtigen }
				LoggerMessage.Kind := lomkExit;
				LoggerMB.Put(Logger.Mailbox, LoggerMessage);
			end;
		end;

		Debug('Nachricht analysiert');
		{ IPX-Buffer freigeben }
		Debug('Gebe IPX-Buffer frei');
		PIPX.FreeBuffer(PMessage);
	end;
end;

end.