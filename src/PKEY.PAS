unit PKey;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Beinhaltet die Keytask, die Tastatureingaben entgegen nimmt, und
	verarbeitet.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

procedure KeyTask;

implementation

uses
	RTKernel, RTKeybrd, RTTextIO,
	Types, PTypes, Tools, Semas, Leader, LeadMB, THMsg, PlayMsg, Logger,
		LoggerMB, DispMB, PIPXSnd;

procedure ShowKeySettings(var F: text);
(*****************************************************************************
	Beschreibung:
		Zeigt die Tastenbelegung an.

	In:
		F: text: Dateivariable des Menuefensters

	Out:
		-
*****************************************************************************)
begin
	Write(f, FormFeed);
	WriteLn(f, '[S] Spiel starten');
	WriteLn(f, '[B] Spiel beenden');
	WriteLn(f, '[+] Max. CPU-Bedenkzeit inkrementieren');
	WriteLn(f, '[-] Max. CPU-Bedenkzeit dekrementieren');
	WriteLn(f, '[PrtScr] Spielstein klauen');
	WriteLn(f, '[Esc] Programm beenden', #$A#$D);
end;

{$F+}
procedure KeyTask;
(*****************************************************************************
	Beschreibung:
		Keytask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	Key: char;
	GameStarted: boolean;
	KeyIn,
	KeyOut: text;
	LeaderMessage: TLeaderMessage;
	CPUTaskHandle: TaskHandle;
	PlayerMessage: TPlayerMessage;
	DisplayMessage: TDisplayMessage;
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

	{ Spielleitertaskhandle empfangen }
	Debug('Warte auf CPU-Spielertaskhandle');
	THMsg.Receive(CPUTaskHandle);
	Debug('CPU-Spielertaskhandle empfangen');

	{ Spiel als nicht gestartet markieren }
	GameStarted := false;

	while true do
	begin
		{ Auf Tastendruck warten }
		Key := UpCase(RTKeybrd.ReadKey);
		case Key of

			{ Spiel starten }
			'S':
			begin
				{ Ueberpruefen, ob Spiel bereits gestartet ist }
				if not GameStarted then
				begin
					{ Spiel als gestartet markieren }
					GameStarted := true;
					{ Ereignis in der Startsemaphore speichern }
					Signal(StartSemaphore);
				end;
			end;

			{ Spiel beenden }
			'B':
			begin
				{ Pruefen, ob Spiel gestartet ist }
				if GameStarted then
				begin
					{ Spiel als nicht gestoppt markieren }
					GameStarted := false;
					{ Spielleiter benachrichtigen }
					LeaderMessage.Kind := lemkEndGame;
					LeadMB.PutFront(Leader.Mailbox, LeaderMessage);
				end;
			end;

			{ Escape }
			{ Programmende }
			#27:
			begin
				{ Sicherheitsabfrage }
				Write(KeyOut, 'Programm wirklich beenden? [J]/[N]');
				repeat
					{ Auf J oder N warten }
					Key := UpCase(RTKeybrd.ReadKey);
					if Key = 'J'  then
					begin
						{ Darstellungsrechner und Logger benachrichtigen }
						DisplayMessage.Kind := dmkExit;
						DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);
						LoggerMessage.Kind := lomkExit;
						LoggerMB.Put(Logger.Mailbox, LoggerMessage);
					end;
				until (Key = 'J') or (Key = 'N');
				{ Tastenbelegung anzeigen }
				ShowKeySettings(KeyOut);
			end;

			{ CPU-Bedenkzeit inkrementieren }
			'+':
			begin
				{ Entsprechende Nachricht an den CPU-Spieler senden }
				PlayerMessage.Kind := plmkIncrementMaxTimeLimit;
				PlayMsg.Send(CPUTaskHandle, PlayerMessage);
			end;

			{ CPU-Bedenkzeit dekrementieren }
			'-':
			begin
				{ Entsprechende Nachricht an den CPU-Spieler senden }
				PlayerMessage.Kind := plmkDecrementMaxTimeLimit;
				PlayMsg.Send(CPUTaskHandle, PlayerMessage);
			end;

			{ Taskinformationen in die Logdatei schreiben }
			'T':
			begin
				Debug('');
			end;

			{ Sondertasten auslassen }
			#0:
				Key := UpCase(RTKeybrd.ReadKey);
		end;
	end;
end;

end.