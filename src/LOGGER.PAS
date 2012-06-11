unit Logger;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit beinhaltet die Loggertask, die fuer das Loggen von beliebigen
	Nachrichten zustaendig ist.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	LoggerMB;

var
	Mailbox: LoggerMB.Mailbox;

procedure LoggerTask;

implementation

uses
	RTKernel, RTTextIO,
	Dos,
	Types, Tools, Semas;

procedure CreateNewFile(var F: text; Filename: string);
(*****************************************************************************
	Beschreibung:
		Erzeugt eine neue Textdatei mit einer fortlaufenden Zahl als Namenssuffix.

	In:
		Filename: string: Dateinamenpraefix

	Out:
		F: text: Dateivariable
*****************************************************************************)
var
	i: integer;
begin
	{ Zaehler initialisieren }
	i := 0;

	{ Dateisuffix berechnen }
	repeat
		{ Zaehler inkrementieren }
		inc(i);
		Assign(F, Filename + IntToStr(i, 8 - Length(Filename)) + '.log');

		{ Versuchen, Datei zu oeffnen und zu schliessen }
		{$I-}
		Reset(f);
		Close(f);
		{$I+}

	{ Tritt ein Fehler auf, existiert Datei nicht }
	until IOResult <> 0;

	{ Datei erzeugen }
	Rewrite(f);
end;

procedure Log(var F: text; S: string);
(*****************************************************************************
	Beschreibung:
		Schreibt eine Meldung in die Logdatei.

	In:
		F: text: Dateivariable
		S: string: Meldung

	Out:
		-
*****************************************************************************)
begin
	WriteLn(F, S);
	Flush(f);
end;

procedure Debug(var F: text; Message: TLoggerMessage);
(*****************************************************************************
	Beschreibung:
		Schreibt eine Debugmeldung in eine Textdatei.

	In:
		F: text: Dateivariable
		Message: TLoggerMessage: Nachricht, aus der die Debugmeldung ermittelt
			wird.

	Out:
		-
*****************************************************************************)
var
	TaskName: Name;
begin
	{ Bei leerer Meldung, Info ueber alle TAsks ausgeben }
	if Message.Message = '' then
		RTKernel.TaskInfo(F, [RTKernel.TaskName, State, WaitingAtObj])
	else
	begin
		{ Tasknamen ermitteln }
		TaskName := GetTaskName(Message.Sender);
		{ Tasknamen mit Leerzeichen auffuellen, um gleich breite Spalten zu
			erzeugen }
		while Length(TaskName) < (SizeOf(Name) - 1) do
			TaskName := TaskName + ' ';
		{ Tasknamen + Meldung in die Datei schreiben }
		Log(F, TaskName + ' | ' + Message.Message);
	end;
	{ Puffer gleich in die Datei schreiben }
	Flush(F);
end;

{$F+}
procedure LoggerTask;
(*****************************************************************************
	Beschreibung:
		Loggertask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	Message: TLoggerMessage;
	F: text;
	Filename: string;
	Y, M, D, DOW, H, Min, S, CS: word;
begin
	InitMailbox(Mailbox, cLoggerMailboxSlots, 'Logger mailbox');

	while true do
	begin
		{ Auf Nachrichten warten }
		Get(Mailbox, Message);
		{ Nachricht analysieren }
		case Message.Kind of
			{ Name der Logdatei }
			lomkFilename:
				Filename := Message.Filename;

			{ Neue Logdatei erzeugen }
			lomkCreateNewFile:
			begin
				{ Neue Datei erzeugen }
				CreateNewFile(F, Filename);
				{ Datum und Uhrzeit des Programmstarts ermitteln und in die Logdatei
					schreiben }
				GetDate(y, m, d, dow);
				GetTime(h, min, s, cs);
				Log(F, 'Programmstart am ' + IntToStr(d, 2) + '.' + IntToStr(m, 2) +
					'.' + IntToStr(y, 4) + ' um ' + IntToStr(h, 2) + ':' +
					IntToStr(min, 2) + ':' + IntToStr(s, 2));
			end;
			{ Debugmeldung }
			lomkDebug:
				Debug(F, Message);
			{ Logmeldung }
			lomkLog:
				Log(F, Message.Message);
			{ Programmende }
			lomkExit:
			begin
				{ Datum und Uhrzeit des Programmendes ermitteln und in die Logdatei
					schreiben }
				GetDate(y, m, d, dow);
				GetTime(h, min, s, cs);
				Log(F, 'Programmende am ' + IntToStr(d, 2) + '.' + IntToStr(m, 2) +
					'.' + IntToStr(y, 4) + ' um ' + IntToStr(h, 2) + ':' +
					IntToStr(min, 2) + ':' + IntToStr(s, 2));
				Close(F);
				{ Ereignis in der Exitsemaphore speichern }
				Signal(ExitSemaphore);
				{ Moeglichkeit fuer einen Taskwechsel }
				RTKernel.Delay(0);
			end;
		end;
	end;
end;

end.