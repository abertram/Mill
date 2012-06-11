unit DKey;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Beinhaltet die Tastentask fuer den Anzeigerechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

procedure KeyTask;

implementation

uses
	RTKernel, RTKeybrd, RTTextIO,
	Types, DTypes, Tools, Board, Logger, LoggerMB, ProcMB, DIPXSnd, Semas;

procedure ShowKeySettings(var f: text);
(*****************************************************************************
	Beschreibung:
		Zeigt die Tastenbelegung an.

	In:
		f: text: Textdateivariable fuer die Ausgabe

	Out:
		-
*****************************************************************************)
begin
	Write(f, FormFeed);
	WriteLn(f, '[S] Spiel starten');
	WriteLn(f, '[B] Spiel beenden');
	WriteLn(f, '[', #$1B#$1A#$18#$19'] Cursor bewegen');
	WriteLn(f, '[Enter] Spielstein setzen, markieren, ziehen, schlagen');
	WriteLn(f, '[Esc] Programm beenden', #$A#$D);
end;

{$F+}
procedure KeyTask;
(*****************************************************************************
	Beschreibung:
		Tastentask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	Key: char;
	BoardMessage: TBoardMessage;
	LoggerMessage: TLoggerMessage;
	KeyIn,
	KeyOut: text;
	ProcessMessage: TProcessMessage;
  Success: boolean;
begin
	Debug('Wurde erzeugt');

	{ Fenster erzeugen }
	Debug('Erzeuge Fenster');
	NewWindow(KeyIn, KeyOut, cKeyWindowFirstCol, cKeyWindowFirstRow,
		cKeyWindowLastCol, cKeyWindowLastRow, cKeyWindowColor,
		' ' + cKeyTaskName + ' ');
	Debug('Fenster erzeugt');

	{ Tastenbelegung anzeigen }
	ShowKeySettings(KeyOut);

	while true do
	begin
		{ Auf Tastendruck warten }
		Debug('Warte auf Tastendruck');
		Key := RTKeybrd.ReadKey;
		Debug('Taste gedrueckt');

		{ Taste analaysieren }
		Debug('Analysiere Taste');
		case UpCase(Key) of
			{ Enter }
			#13:
			begin
				Debug('Enter gedrueckt');
				{ Positionswahl an Spielfeld melden }
				BoardMessage.Kind := bmkFieldPositionSelection;
				BoardMB.Put(Board.Mailbox, BoardMessage);
			end;
			{ Escape }
			#27:
			begin
				Debug('Escape gedrueckt');
				{ Abfrage, ob Programm beendet werden soll }
				Write(KeyOut, 'Programm wirklich beenden? [J]/[N]');
				repeat
					{ Auf Tastendruck warten }
					Key := UpCase(RTKeybrd.ReadKey);
					if Key = 'J' then
					begin
						{ Programmende an Prozessrechner senden }
						ProcessMessage.Kind := prmkExit;
						ProcMB.Put(DIPXSnd.Mailbox, ProcessMessage);
						{$IFDEF DEBUG}
							{ Programmende dem Logger senden }
							LoggerMessage.Kind := lomkExit;
							LoggerMB.Put(Logger.Mailbox, LoggerMessage);
						{$ELSE}
							{ Ereignis in der Exitsemaphore speichern }
							Signal(ExitSemaphore);
						{$ENDIF}
					end;
				until (Key = 'J') or (Key = 'N');
				{ Tastenbelegung anzeigen }
				ShowKeySettings(KeyOut);
			end;
			{ Sondertaste }
			#0:
			begin
				Debug('Sondertaste gedrueckt');
				{ Sondertaste auswerten }
				Key := ReadKey;
				case Key of
					{ Links }
					#75:
					begin
						Debug('Pfeiltaste nach links gedrueckt');
						{ Cursorbewegung nach links ans Spielfeld senden }
						BoardMessage.Kind := bmkCursorMove;
						BoardMessage.Direction := dLeft;
						BoardMB.Put(Board.Mailbox, BoardMessage);
					end;
					{ Rechts }
					#77:
					begin
						Debug('Pfeiltaste nach rechts gedrueckt');
						{ Cursorbewegung nach rechts ans Spielfeld senden }
						BoardMessage.Kind := bmkCursorMove;
						BoardMessage.Direction := dRight;
						BoardMB.Put(Board.Mailbox, BoardMessage);
					end;
					{ Hoch }
					#72:
					begin
						Debug('Pfeiltaste nach oben gedrueckt');
						{ Cursorbewegung nach oben ans Spielfeld senden }
						BoardMessage.Kind := bmkCursorMove;
						BoardMessage.Direction := dUp;
						BoardMB.Put(Board.Mailbox, BoardMessage);
					end;
					{ Runter }
					#80:
					begin
						Debug('Pfeiltaste nach unten gedrueckt');
						{ Cursorbewegung nach unten ans Spielfeld senden }
						BoardMessage.Kind := bmkCursorMove;
						BoardMessage.Direction := dDown;
						BoardMB.Put(Board.Mailbox, BoardMessage);
					end;
				end;
			end;
			'S':
			begin
				Debug('S gedrueckt');
				{ Spielstart an den Prozessrechner senden }
				ProcessMessage.Kind := prmkStartGame;
				ProcMB.PutCond(DIPXSnd.Mailbox, ProcessMessage, Success);
			end;
			'B':
			begin
				Debug('B gedrueckt');
				{ Spielende an den Prozessrechner senden }
				ProcessMessage.Kind := prmkEndGame;
				ProcMB.PutCond(DIPXSnd.Mailbox, ProcessMessage, Success);
			end;
		end;

		{ Taskwechsel }
    RTKernel.Delay(0);
	end;
end;

end.