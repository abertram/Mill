program MillProc;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Hauptprogramm des Prozessrechners.
	Hier wird das Programm initialisiert, die Konfigurationsdatei eingelesen,
	alle Tasks ausser den Spielsteintasks kreiert und die Spielparameter werden
	an die Tasks verteilt.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

uses
	Crt, DOS,
	RTKernel, RTTextIO, RTIPX, Timer,
	Types, Logger, LoggerMB, Tools, Leader, Player, Token, THMsg, Semas, PIPX,
		PIPXSnd, PIPXRcv, PKey, SysStat, PlayMsg, PTypes, SysMB, Steal;

{$S-,F+}
procedure Int5Procedure; interrupt;
(*****************************************************************************
	Beschreibung:
		Interrup Service Routine, die beim Druck auf die Printscreen-Taste
		ausgeloest wird.

	In:
		-

	Out:
		-
*****************************************************************************)
begin
	{ Eregnis in Semaphore speichern}
	Signal(PrintScreenSemaphore);
end;

procedure Init(var Mode: integer; var PrintScreenVector: pointer);
(*****************************************************************************
	Beschreibung:
		Initialisiert das Programm.

	In:
		-

	Out:
		Mode: Bildschirmmodus vor dem Programmstart
		PrintScreenVector: Addresse des Printscreen-Interrupt-Handlers vor dem
			Programmstart
*****************************************************************************)
begin
	{ Adresse des alten Interrupt-Handlers merken }
	DOS.GetIntVec(5, PrintScreenVector);
	{ Eigenen Interrupt-Handler installieren }
	DOS.SetIntVec(5, Addr(Int5Procedure));
	Randomize;
	{ Preemptions einschalten, da wir Interrupts verarbeiten muessen }
	Preemptions(true);
	{ RTK-Timer-Intervall setzen }
	SetTimerInterval(cTimerInterval);
	{ Bildschirmmodus merken }
	Mode := LastMode;
	{ Neuen Bildschirmmodus setzen }
	TextMode(CO80 + Font8x8);
	{ RTK die Bildschirmgroesse mitteilen }
	SetScreenSize(80, 50);
	ClrScr;
	{ Blinkenden Cursor ausschalten }
	CursorOff;
end;

function CreateTasks(var LoggerTaskHandle, LeaderTaskHandle,
	UserTaskHandle, CPUTaskHandle, IPXSenderTaskHandle, IPXReceiverTaskHandle,
	KeyTaskHandle, SystemStatusTaskHandle,
	StealTaskHandle: TaskHandle): boolean;
(*****************************************************************************
	Beschreibung:
		Erzeugt die fuer den Start benoetigten Tasks und teilt ihnen
		Startparameter mit.

	In:
		-

	Out:
		Taskhandles der erzeugten Tasks.
		Rueckgabewert: True, wenn IPX gefunden wurde.
*****************************************************************************)
var
	LoggerMessage: TLoggerMessage;
	SystemStatusMessage: TSystemStatusMessage;
	PlayerMessage: TPlayerMessage;
begin
	CreateTasks := true;

	{ Loggertask erzeugen }
	CreateTask(LoggerTask, cLoggerPriority, cLoggerStack, cLoggerTaskName,
		LoggerTaskHandle);
	{ Anfang der Logdatei festlegen }
	LoggerMessage.Kind := lomkFilename;
	{$IFDEF DEBUG}
		LoggerMessage.Filename := 'Proc';
	{$ELSE}
		LoggerMessage.Filename := 'Mill';
	{$ENDIF}
	LoggerMB.Put(Logger.Mailbox, LoggerMessage);
	LoggerMessage.Kind := lomkCreateNewFile;
	LoggerMB.Put(Logger.Mailbox, LoggerMessage);
	Debug('Loggertask erzeugt');

	{ IPX-Treiber vorhanden und geladen? }
	if RTIPX.IPXLoaded then
	begin
		{ IPX-Treiber gefunden, es kann gespielt werden }
		Debug('IPX Treiber gefunden');

		{ Systemstatustask erzeugen }
		Debug('Erzeuge Systemstatustask');
		CreateTask(SystemStatusTask, cSystemStatusPriority, cSystemStatusStack,
			cSystemStatusTaskName, SystemStatusTaskHandle);
		Debug('Systemstatustask erzeugt');

		{ Fensterposition an die Systemstatustask senden }
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

		{ Fensterfarben an die Systemstatustask senden }
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
		RTIPX.InitNode(cProcessComputerNodeName, cMaxIPXInConnections,
			cMaxIPXSendRetries, cIPXSendTimeOut, cIPXSenderPriority);
		Debug('IPX Knoten initalisiert');

		{ IPX-Sendertask erzeugen }
		Debug('Erzeuge IPXSendertask');
		CreateTask(IPXSenderTask, cIPXSenderPriority, cIPXSenderStack,
			cIPXSenderTaskName, IPXSenderTaskHandle);
		Debug('IPXSendertask erzeugt');

		{ IPX-Receivertask erzeugen }
		Debug('Erzeuge IPXReceivertask');
		CreateTask(IPXReceiverTask, cIPXReceiverPriority, cIPXReceiverStack,
			cIPXReceiverTaskName, IPXReceiverTaskHandle);
		Debug('IPXReceivertask erzeugt');

		{ Tastentask erzeugen }
		Debug('Erzeuge Keytask');
		CreateTask(KeyTask, cKeyPriority, cKeyStack, cKeyTaskName, KeyTaskHandle);
		Debug('Keytask erzeugt');

		{ Spielleitertask erzeugen }
		Debug('Erzeuge Spielleitertask');
		CreateTask(LeaderTask, cLeaderPriority, cLeaderStack, cLeaderTaskName,
			LeaderTaskHandle);
		Debug('Spielleitertask erzeugt');

		{ Benutzertask erzeugen }
		Debug('Erzeuge Benutzertask');
		CreateTask(PlayerTask, cPlayerPriority, cPlayerStack, cUserTaskName,
			UserTaskHandle);
		Debug('Benutzertask erzeugt');

		{ Spielerart an die Benutzertask senden }
		PlayerMessage.Kind := plmkPlayerKind;
		PlayerMessage.PlayerKind := User;
		Debug('Sende Spielerart an Benutzer');
		PlayMsg.Send(UserTaskHandle, PlayerMessage);
		Debug('Spielerart an Benutzer gesendet');

		{ Fensterpositionen an die Benutzertask senden }
		PlayerMessage.Kind := plmkWindowPosition;
		with PlayerMessage.WindowPosition do
		begin
			FirstCol := cUserStatisticWindowFirstCol;
			FirstRow := cUserStatisticWindowFirstRow;
			LastCol := cUserStatisticWindowLastCol;
			LastRow := cUserStatisticWindowLastRow;
		end;
		Debug('Sende Statistikfensterposition an Benutzer');
		PlayMsg.Send(UserTaskHandle, PlayerMessage);
		Debug('Statistikfensterposition an Benutzer gesendet');
		with PlayerMessage.WindowPosition do
		begin
			FirstCol := cUserStatusWindowFirstCol;
			FirstRow := cUserStatusWindowFirstRow;
			LastCol := cUserStatusWindowLastCol;
			LastRow := cUserStatusWindowLastRow;
		end;
		Debug('Sende Statusfensterposition an Benutzer');
		PlayMsg.Send(UserTaskHandle, PlayerMessage);
		Debug('Statusfensterposition an Benutzer gesendet');

		{ CPU-Task erzeugen }
		Debug('Erzeuge CPU-Task');
		CreateTask(PlayerTask, cPlayerPriority, cPlayerStack,
			cCPUTaskName, CPUTaskHandle);
		Debug('CPU-Task erzeugt');
		{ Spielerart an die CPU-Task }
		PlayerMessage.Kind := plmkPlayerKind;
		PlayerMessage.PlayerKind := CPU;
		Debug('Sende Spielerart an CPU-Task');
		PlayMsg.Send(CPUTaskHandle, PlayerMessage);
		Debug('Spielerart an CPU-Spieler gesendet');

		{ Fensterpositionen an die CPU-Task senden }
		PlayerMessage.Kind := plmkWindowPosition;
		with PlayerMessage.WindowPosition do
		begin
			FirstCol := cCPUStatisticWindowFirstCol;
			FirstRow := cCPUStatisticWindowFirstRow;
			LastCol := cCPUStatisticWindowLastCol;
			LastRow := cCPUStatisticWindowLastRow;
		end;
		Debug('Sende Statistikfensterposition an CPU-Spieler');
		PlayMsg.Send(CPUTaskHandle, PlayerMessage);
		Debug('Statistikfensterposition an CPU-Player gesendet');
		with PlayerMessage.WindowPosition do
		begin
			FirstCol := cCPUStatusWindowFirstCol;
			FirstRow := cCPUStatusWindowFirstRow;
			LastCol := cCPUStatusWindowLastCol;
			LastRow := cCPUStatusWindowLastRow;
		end;
		Debug('Sende Statusfensterposition an CPU-Spieler');
		PlayMsg.Send(CPUTaskHandle, PlayerMessage);
		Debug('Statusfensterposition an CPU-Player gesendet');
		CreateTask(StealTask, cStealPriority, cStealStack, cStealTaskName,
			StealTaskHandle);
	end
	else
	begin
		{ IPX-Treiber nicht gefunden, es kann nicht gespielt werden }
		CreateTasks := false;
		Debug('IPX Treiber nicht geladen');
		WriteLn('IPX Treiber nicht geladen. Programm kann nicht gestartet ' +
			'werden');
		WriteLn('Weiter mit beliebiger Taste...');
		ReadKey;
	end;
end;

procedure ShareTaskHandles(LoggerTaskHandle, LeaderTaskHandle,
	UserTaskHandle, CPUTaskHandle, KeyTaskHandle: TaskHandle);
(*****************************************************************************
	Beschreibung:
		Tauscht die Taskhandles unter den Tasks aus, damit die Tasks Nachrichten
		per Message-Passing senden koennen.

	In:
		LoggerTaskHandle,
		LeaderTaskHandle,
		UserTaskHandle,
		CPUTaskHandle,
		KeyTaskHandle: Taskhandles der Tasks, die Message-Passing verwenden
			wollen

	Out:
		-
*****************************************************************************)
var
	LeaderMessage: TLeaderMessage;
	PlayerMessage: TPlayerMessage;
begin
	{ Spielertaskhandles an Spielleitertask senden }
	LeaderMessage.Kind := lemkPlayerTaskHandles;
	LeaderMessage.PlayerTaskHandles[User] := UserTaskHandle;
	LeaderMessage.PlayerTaskHandles[CPU] := CPUTaskHandle;
	Debug('Sende Spielertaskhandles an Spielleiter');
	LeadMB.Put(Leader.Mailbox, LeaderMessage);
	Debug('Sende Spielertaskhandles an Spielleiter');

	{ Spielleitertaskhandle an Spieler senden }
	PlayerMessage.Kind := plmkLeaderTaskHandle;
	PlayerMessage.LeaderTaskHandle := LeaderTaskHandle;
	Debug('Sende Spielleitertaskhandle an Benutzer');
	PlayMsg.Send(UserTaskHandle, PlayerMessage);
	Debug('Spielleitertaskhandle an Benutzer gesendet');
	Debug('Sende Spielleitertaskhandle and CPU-Spieler');
	PlayMsg.Send(CPUTaskHandle, PlayerMessage);
	Debug('Spielleitertaskhandle an CPU-Spieler gesendet');

	{ CPU-Taskhandle an Tastentask senden, um die Bedenkzeit aendern zu
		koennen }
	Debug('Sende CPU-Spielertaskhandle an Keytask');
	THMsg.Send(KeyTaskHandle, CPUTaskHandle);
	Debug('CPU-Spielertaskhandle an Keytask gesendet');
end;

procedure GetGameParameters(var GameParameters: TGameParameters);
(*****************************************************************************
	Beschreibung:
		Liest Spielparameter aus einer Datei.

	In:
		-

	Out:
		GameParameters: Spielparameter
*****************************************************************************)
var
	f: text;
	s,
	Key,
	Value: string;
	EqualsSignPos: word;
begin
  { Spielparameter initialisieren }
	Debug('Initalisiere Spielparameter');
	with GameParameters do
	begin
		FirstPlayer := Low(TPlayer);
		PlayerColors[User] := 3;
		PlayerColors[CPU] := 2;
		CPUMaxTimeLimit := High(TTimeLimit) div 2;
	end;
	Debug('Spielparameter initalisiert');

  { Versuchen, Datei oeffnen }
	Debug('Oeffne Ini-Datei');
	Assign(f, cIniFilename);
	{$I-}
	Reset(f);
	{$I+}

  { Ergebnis ueberpruefen }
	if IOResult <> 0 then
    { Datei konnte nicht geoffnet werden }
		Debug('Ini-Datein konnte nicht geoeffnet werden')
	else
	begin
  	{ Datei geoffnet }
		Debug('Ini-Datei geoeffnet');

    { Datei zeilenweise bis zum Ende lesen }
		Debug('Lese Ini-Datei');
		while not Eof(f) do
		begin
      { Zeile lesen }
			Debug('Lese Zeile');
			Readln(f, s);
			Debug('Zeile gelesen (''' + s + ''')');

      { Alle Leerzeichen entfernen }
			s := Trim(s);

      { Kommentar? }
			if s[1] = '#' then
				Debug('Gelesene zeile ist ein Kommentar')
			else
			begin
        { Zeile in Schluessel und Wert splitten }
				Debug('Extrahiere Schluessel und Wert');
				EqualsSignPos := Pos('=', s);
				Key := StrUpCase(Copy(s, 1, EqualsSignPos - 1));
				Value := Copy(s, EqualsSignPos + 1, Length(s));
				Debug('Schluessel und Wert extrahiert (K: ' + Key + ', V: ' + Value +
					')');

        { Schluessel und Wert auswerten }
				with GameParameters do
				begin
					if Key = 'FIRSTPLAYER' then
						StrToPlayer(Value, FirstPlayer)
					else if Key = 'USERCOLOR' then
						StrToByte(Value, PlayerColors[User])
					else if Key = 'CPUCOLOR' then
						StrToByte(Value, PlayerColors[CPU])
					else if Key = 'CPUMAXTIMELIMIT' then
						StrToTimeLimit(Value, CPUMaxTimeLimit);
				end;
			end;
		end;
	end;
  { Wertebereiche ueberpruefen }
	with GameParameters do
	begin
    if (PlayerColors[User] < Black) or (PlayerColors[User] > Gray) then
      PlayerColors[User] := 3;
    if (PlayerColors[CPU] < Black) or (PlayerColors[CPU] > Gray) then
      PlayerColors[CPU] := 2;
    Inc(PlayerColors[User], Bright);
    Inc(PlayerColors[CPU], Bright);
  end;
end;

procedure ShareGameParameters(LeaderTaskHandle, UserTaskHandle,
	CPUTaskHandle: TaskHandle; GameParameters: TGameParameters);
(*****************************************************************************
	Beschreibung:
		Verteilt die Spielparameter an die Tasks.

	In:
		LeaderTaskHandle,
		UserTaskHandle,
		CPUTaskHandle: Taskhandles der Tasks, die Spielparameter brauchen.
		GameParameters: Spielparameter

	Out:
		-
*****************************************************************************)
var
	LeaderMessage: TLeaderMessage;
	DisplayMessage: TDisplayMessage;
	PlayerMessage: TPlayerMessage;
begin
	with GameParameters do
	begin
    { Ersten Spieler an Spielleiter senden }
		LeaderMessage.Kind := lemkFirstPlayer;
		LeaderMessage.FirstPlayer := FirstPlayer;
		Debug('Sende ersten Spieler an Spielleiter');
		LeadMB.Put(Leader.Mailbox, LeaderMessage);
		Debug('Ersten Spieler an Spielleiter gesendet');

    { Spielerfarben an Spielleiter senden }
		LeaderMessage.Kind := lemkPlayerColors;
		LeaderMessage.PlayerColors[User] := PlayerColors[User];
		LeaderMessage.PlayerColors[CPU] := PlayerColors[CPU];
		Debug('Sende Spielerfarben an Spielleiter');
		LeadMB.Put(Leader.Mailbox, LeaderMessage);
		Debug('Spielerfarben an Spielleiter gesendet');

    { Spielerfarben an den Anzeigerechner senden }
		DisplayMessage.Kind := dmkPlayerColors;
		DisplayMessage.Colors[User] := PlayerColors[User];
		DisplayMessage.Colors[CPU] := PlayerColors[CPU];
		Debug('Sende Spielerfarben an Displayrechner');
		DispMB.Put(PIPXSnd.Mailbox, DisplayMessage);
		Debug('Spielerfarben an Displayrechner gesendet');

    { Spielerfarben an Spieler senden }
		PlayerMessage.Kind := plmkWindowColor;
		PlayerMessage.WindowColor.FrameColor := PlayerColors[User];
		PlayerMessage.WindowColor.Attribute := DefaultAttribute;
		Debug('Sende Benutzerfarbe an Benutzer');
		PlayMsg.Send(UserTaskHandle, PlayerMessage);
		Debug('Benutzerfarbe an Benutzer gesendet');
		PlayerMessage.WindowColor.FrameColor := PlayerColors[CPU];
		Debug('Sende CPU-Spielerfarbe an CPU-Spieler');
		PlayMsg.Send(CPUTaskHandle, PlayerMessage);
		Debug('CPU-Spielerfarbe an CPU-Spieler gesendet');

    { Maximale Bedenkzeit an Spieler senden }
		PlayerMessage.Kind := plmkMaxTimeLimit;
		PlayerMessage.MaxTimeLimit := 0;
		Debug('Sende maximale Denkzeit an Benutzer');
		PlayMsg.Send(UserTaskHandle, PlayerMessage);
		Debug('Maximale Denkzeit an Benutzer gesendet');
		PlayerMessage.MaxTimeLimit := CPUMaxTimeLimit;
		Debug('Sende maximale Denkzeit an CPU-Spieler');
		PlayMsg.Send(CPUTaskHandle, PlayerMessage);
		Debug('Maximale Denkzeit an CPU-Spieler gesendet');
	end;
end;

procedure Deinit(Mode: integer; PrintScreenVector: pointer);
(*****************************************************************************
	Beschreibung:
		Stellt den Systemzustand wieder her.

	In:
		Mode: Bildschrimmodus vor dem Programmstart
		PrintScreenVector: Printscreen-Interrupt-Handler vor dem Programmstart

	Out:
		-
*****************************************************************************)
begin
	DOS.SetIntVec(5, PrintScreenVector);
	TextMode(Mode);
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
	LoggerTaskhandle,
	LeaderTaskHandle,
	UserTaskHandle,
	CPUTaskHandle,
	IPXSenderTaskHandle,
	IPXReceiverTaskHandle,
	KeyTaskHandle,
	SystemStatusTaskHandle,
	StealTaskHandle: TaskHandle;
	GameParameters: TGameParameters;
	LeaderMessage: TLeaderMessage;
	Mode: integer;
	PrintScreenVector: pointer;
begin
	{ Programm initialisieren }
	Init(Mode, PrintScreenVector);

  { Versuchen, Tasks zu erzeugen }
	if CreateTasks(LoggerTaskHandle, LeaderTaskHandle, UserTaskHandle,
		CPUTaskHandle, IPXSenderTaskHandle, IPXReceiverTaskHandle,
		KeyTaskHandle, SystemStatusTaskHandle, StealTaskHandle) then
	begin
    { Taskhandles verteilen }
		ShareTaskHandles(LoggerTaskHandle, LeaderTaskHandle,
			UserTaskHandle, CPUTaskHandle, KeyTaskHandle);
    { Spielparameter auslesen }
		GetGameParameters(GameParameters);
    { Spielparameter verteilen }
		ShareGameParameters(LeaderTaskHandle, UserTaskHandle,
			CPUTaskHandle, GameParameters);
		{ Spielleitertask initialisieren }
		LeaderMessage.Kind := lemkInit;
		LeadMB.Put(Leader.Mailbox, LeaderMessage);
    { Auf Programmende warten }
		Wait(ExitSemaphore);
	end;

  { Systemzustand wiederherstellen }
	Deinit(Mode, PrintScreenVector);
end;

begin
	{ Spiel starten }
	StartGame;
end.