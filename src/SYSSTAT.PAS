unit SysStat;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	In dieser Unit ist die Systemstatustask enthalten. Diese gibt die CPU-Last,
	Uhrzeit, RTKernel-Ticks und die letzte Systemstatusnachricht z.B. eine
	Fehlermeldung aus.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	SysMB;

var
	Mailbox: SysMB.Mailbox;

procedure SystemStatusTask;

implementation

uses
	DOS,
	RTTextIO, Timer, CPUMoni,
	Types, Tools;

{$F+}
procedure SystemStatusTask;
(*****************************************************************************
	Beschreibung:
		Systemstatustask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	Message: TSystemStatusMessage;
	SystemStatusIn,
	SystemStatusOut: text;
	WindowPosition: TWindowPosition;
	WindowColor: TWindowColor;
	Success: boolean;
	H,
	M,
	S,
	CS: word;
begin
	Debug('Wurde erzeugt');

	{ Mailbox initialisieren }
	Debug('Initailisiere Mailbox');
	InitMailbox(Mailbox, cSystemStatusMailboxSlots, 'Systemstatus mailbox');
	Debug('Mailbox initialisiert');

	{ Fensterposition }
	Debug('Warte auf Fensterposition');
	SysMB.Get(Mailbox, Message);
	if Message.Kind <> ssmkWindowPosition then
		Die('Unexpected command in system status');
	WindowPosition := Message.WindowPosition;
	Debug('Fensterposition empfangen');

	{ Fensterfarben }
	Debug('Warte auf Fensterfarben');
	SysMB.Get(Mailbox, Message);
	if Message.Kind <> ssmkWindowColor then
		Die('Unexpected command in system status');
	WindowColor := Message.WindowColor;
	Debug('Fensterfarben empfangen');

	{ Fenster erzeugen }
	Debug('Erzeuge Fenster');
	NewWindow(SystemStatusIn, SystemStatusOut, WindowPosition.FirstCol,
		WindowPosition.FirstRow, WindowPosition.LastCol, WindowPosition.LastRow,
		WindowColor.FrameColor, ' ' + cSystemStatusTaskName + ' ');
	SetAttribute(SystemStatusOut, WindowColor.Attribute);
	Debug('Fenster erzeugt');

	{ Eine leere Meldung erzeugen }
	Message.Kind := ssmkSystemStatus;
	Message.Message := '';
	Success := true;

	while true do
	begin
		{ Fenster leeren }
		Write(SystemStatusOut, FormFeed);

		{ CPU-Last anzeigen }
		WriteLn(SystemStatusOut, 'CPU Auslastung:    ',
			CPUMoni.PercentCPUNeeded:5:2, '%');

		{ Uhrzeit anzeigen }
		DOS.GetTime(H, M, S, CS);
		Write(SystemStatusOut, 'Uhrzeit (DOS):    ', IntToStr(H, 2), ':', IntToStr(M, 2), ':', IntToStr(S, 2), #$A#$D);

		{ RTKernel-Ticks anzeigen }
		WriteLn(SystemStatusOut, 'Ticks (RTKernel): ', RTKernel.GetTime);
		WriteLn(SystemStatusOut);

		{ Sustemstatusmeldung empfangen und anzeigen }
		if Success then
			Debug('Warte auf Systemstatus');
		GetCond(Mailbox, Message, Success);
		if Message.Kind <> ssmkSystemStatus then
			Die('Unexpected command in system status');
		Debug('Systemstatus empfangen');
		Debug('Gebe Systemstatus aus');
		Write(SystemStatusOut, 'Letzte Meldung: ', Message.Message);
		Debug('Systemstatus ausgegeben');

		{ Eine Sekunde warten }
		RTKernel.Delay(Timer.Ticks(1));
	end;
end;

end.