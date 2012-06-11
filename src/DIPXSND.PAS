unit DIPXSnd;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Die Unit enthaelt die IPX-Sender-Task, die Nachrichten per IPX an den
	Anzeigerechner sendet.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	ProcMB;

var
	Mailbox: ProcMB.Mailbox;

procedure IPXSenderTask;

implementation

uses
	RTKernel, RTIPX,
	Tools, Types, PIPX;

{$F+}
procedure IPXSenderTask;
(*****************************************************************************
	Beschreibung:
		IPX-Sender-Task

	In:
		-

	Out:
		-
*****************************************************************************)
var
	IPXConnection: PIPX.IPXConnection;
	Connected,
	Sent: boolean;
	Message: TProcessMessage;
begin
	Debug('Wurde erzeugt');

	{ Mailbox initialisieren }
	Debug('Initialisiere IPX Mailbox');
	ProcMB.InitMailbox(Mailbox, cIPXMailboxSlots, 'IPX mailbox');
	Debug('IPX Mailbox initialisiert');

	{ IPX-Kanal oeffnen }
	Debug('Oeffne Kanal zum Prozessrechner');
	PIPX.OpenChannel(cIPXSendBuffers);
	Debug('Kanal zum Prozessrechner geoeffnet');

	{ Variablen initialisieren }
	Connected := false;
	Sent := true;

	while true do
	begin
		{ Pruefen, ob Verbindung zum Anzeigerechner besteht }
		if not Connected then
		begin
			{ Verbindung zum Anzeigerechner herstellen }
			Debug('Stelle Verbindung zum Prozessrechner her');
			PIPX.Connect(IPXConnection, cProcessComputerNodeName,
				cIPXConnectRetries, cIPXConnectTimeout, Connected);
			{ Pruefen, ob Verbindung herstellen geklappt hat }
			if Connected then
      begin
				{ Fehlermeldung }
				Debug('Verbindung zum Prozessrechner hergestellt');
				ShowSystemStatus('Verbindung zum Prozessrechner hergestellt');
      end
			else
			begin
				{ Info ausgebene }
				Debug('Keine Verbindung zum Prozessrechner');
				ShowSystemStatus('Keine Verbindung zum Prozessrechner');
			end;
		end
		else
		begin
			{ Pruefen, ob letzte Nachricht gesendet werden konnte }
			if Sent then
			begin
				{ Auf Nachrichten warten }
				Debug('Warte auf Nachrichten fuer den Prozessrechner');
				ProcMB.Get(Mailbox, Message);
				Debug('Nachricht empfangen');
			end;
			{ Nachricht senden }
			Debug('Sende Nachricht an Prozessrechner');
			PIPX.IPXSend(IPXConnection, Addr(Message), Sent);
			{ Pruefen, ob Nachricht gesendet wurde }
			if Sent then
				{ Info ausgeben }
				Debug('Nachricht an Prozessrechner gesendet')
			else
			begin
				{ Fehlermedlung }
				Debug('Nachricht konnte nicht an den Prozessrechner gesendet werden');
				ShowSystemStatus('Nachricht konnte nicht an den Prozessrechner ' +
					'gesendet werden');
			end;
    end;

    { Taskwechsel }
    RTKernel.Delay(0);
	end;
end;

end.