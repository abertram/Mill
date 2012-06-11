program MillDisp;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Hauptprogramm des Anzeigerechners.
	Hier werden alle fuer den Anzeigerechner noetigen Tasks erstellt.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

uses
	Crt,
	RTKernel, RTTextIO, RTIPX,
	Types, Logger, Tools, DIPXSnd, DIPXRcv, SysStat, DKey, Semas, Board, DTypes;

procedure Init(var Mode: integer);
(*****************************************************************************
	Beschreibung:
		Initialisiert das Programm.

	In:
		-

	Out:
		Mode: integer: Bildschirmmodus vor dem Programmstart
*****************************************************************************)
begin
	{ Bildschrimmodus merken }
	Mode := LastMode;
	{ Bidschirmmodus setzen }
	TextMode(CO80 + Font8x8);
	{ Bildschirm leeren }
	RTTextIO.ClearScreen(cBoardBGColor);
	{ Cursor aus }
	CursorOff;
end;

function CreateTasks(var LoggerTaskHandle, IPXSenderTaskHandle,
	IPXReceiverTaskHandle, BoardTaskHandle, KeyTaskHandle,
	SystemStatusTaskHandle: TaskHandle): boolean;
(*****************************************************************************
	Beschreibung:
		Kreiert alle benoetigten Tasks.

	In:
		-

	Out:
		Taskhandles der kreierten Tasks
*****************************************************************************)
var
	SystemStatusMessage: TSystemStatusMessage;
	LoggerMessage: TLoggerMessage;
begin
	CreateTasks := true;

	{ Debugmodus }
	{$IFDEF DEBUG}
		{ Logger erzeugen }
		CreateTask(LoggerTask, cLoggerPriority, cLoggerStack, cLoggerTaskName,
			LoggerTaskHandle);
		LoggerMessage.Kind := lomkSetFilename;
		{ Praefix fuer den Logdateinamen }
		LoggerMessage.Filename := 'Disp';
		{ Nachricht zum Erzeugen einer neuen Logdatei in der Loggermailbox
			ablegen }
		LoggerMB.Put(Logger.Mailbox, LoggerMessage);
		LoggerMessage.Kind := lomkCreateNewFile;
		LoggerMB.Put(Logger.Mailbox, LoggerMessage);
		Debug('LoggerTask erzeugt');
	{$ENDIF}

	{ Pruefen, ob IPX-Treiber installiert und geladen }
	if RTIPX.IPXLoaded then
	begin
		{ IPX gefunden }
		Debug('IPX Treiber gefunden');

		{ Systemstatustask erzeugen }
		Debug('Erzeuge SystemStatusTask');
		CreateTask(SystemStatusTask, cSystemStatusPriority, cSystemStatusStack,
			cSystemStatusTaskName, SystemStatusTaskHandle);
		Debug('SystemStatusTask erzeugt');

		{ Fensterposition der Statustask mitteilen }
		SystemStatusMessage.Kind := ssmkWindowPosition;
		with SystemStatusMessage.WindowPosition do
		begin
			FirstCol := cSystemStatusWindowFirstCol;
			FirstRow := cSystemStatusWindowFirstRow;
			LastCol := cSystemStatusWindowLastCol;
			LastRow := cSystemStatusWindowLastRow;
		end;
		Debug('Sende Fensterposition an Systemstatustask');
		SysMB.Put(SysStat.Mailbox, SystemStatusMessage);
		Debug('Fensterposition an Systemstatustask gesendet');

		{ Fensterfarbe der Statustask mitteilen }
		SystemStatusMessage.Kind := ssmkWindowColor;
		with SystemStatusMessage.WindowColor do
		begin
			FrameColor := cSystemStatusWindowFrameColor;
			Attribute := cSystemStatusWindowAttribute
		end;
		Debug('Sende Fensterfarben an Systemstatustask');
		SysMB.Put(SysStat.Mailbox, SystemStatusMessage);
		Debug('Fensterfarben an Systemtask gesendet');

		{ IPX-Knoten initialisieren }
		Debug('Initialisiere IPX Knoten');
		RTIPX.InitNode(cDisplayComputerNodeName, cMaxIPXInConnections,
			cMaxIPXSendRetries, cIPXSendTimeOut, cIPXSenderPriority);
		Debug('IPX Knoten initalisiert');

		{ IPX-Sender erzeugen }
		Debug('Erzeuge IPXSenderTask');
		CreateTask(IPXSenderTask, cIPXSenderPriority, cIPXSenderStack,
			cIPXSenderTaskName, IPXSenderTaskHandle);
		Debug('IPXSenderTask erzeugt');

		{ IPX-Empfaenger erzeugen }
		Debug('Erzeuge IPXReceiverTask');
		CreateTask(IPXReceiverTask, cIPXReceiverPriority, cIPXReceiverStack,
			cIPXReceiverTaskName, IPXReceiverTaskHandle);
		Debug('IPXReceiverTask erzeugt');

		{ Spielbretttask erzeugen }
		Debug('Erzeuge BoardTask');
		CreateTask(BoardTask, cBoardPriority, cBoardStack, cBoardTaskName,
			BoardTaskHandle);
		Debug('BoardTask erzeugt');

		{ Tastentask erzeugen }
		Debug('Erzeuge KeyTask');
		CreateTask(KeyTask, cKeyPriority, cKeyStack, cKeyTaskName, KeyTaskHandle);
		Debug('KeyTask erzeugt');
	end
	else
	begin
		{ Kein IPX }
		{ Fehlermeldung }
		Debug('IPX Treiber nicht gefunden');
		WriteLn('IPX Treiber nicht gefunden. Weiter mit beliebiger Taste...');
		{ Auf Tastendruck warten }
		ReadKey;
	end;
end;

procedure Deinit(Mode: integer);
(*****************************************************************************
	Beschreibung:
		Stellt den Systemzustand vor dem Spiel wieder her.

	In:
		Mode: integer: Bildschirmmodus vor dem Spielstart

	Out:
		-
*****************************************************************************)
begin
	{ Bildschirmmodus setzen }
	TextMode(Mode);
	{ Bildschirm loeschen }
	ClrScr;
end;

procedure StartGame;
(*****************************************************************************
	Beschreibung:
		Startet das Spiel.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	LoggerTaskHandle,
	BoardTaskHandle,
	IPXSenderTaskHandle,
	IPXReceiverTaskHandle,
	KeyTaskHandle,
	SystemStatusTaskHandle: TaskHandle;
	Mode: integer;
begin
	{ Initialisierung }
	Init(Mode);
	{ Tasks erzeugen }
	if CreateTasks(LoggerTaskhandle, IPXSenderTaskHandle, IPXReceiverTaskHandle,
		BoardTaskHandle, KeyTaskHandle, SystemStatusTaskHandle) then
	begin
		{ An der Semaphore aufs Spielende warten }
		Wait(ExitSemaphore);
	end;
	{ Deinitialisierung }
	Deinit(Mode);
end;

begin
	{ Spiel starten }
	StartGame;
end.
