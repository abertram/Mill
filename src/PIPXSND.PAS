unit PIPXSnd;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit beinhaltet den IPX-Sender, der IPX-Nachrichten an den
	Darstellungsrechner sendet.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	DispMB;

var
	Mailbox: DispMB.Mailbox;

procedure IPXSenderTask;

implementation

uses
	RTKernel, RTIPX,
	Tools, Types, DIPX;

{$F+}
procedure IPXSenderTask;
(*****************************************************************************
	Beschreibung:
		IPX-Sender-Task.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	IPXConnection: DIPX.IPXConnection;
	Connected,
	Sent: boolean;
	Message: TDisplayMessage;
begin
	Debug('Wurde erzeugt');

	{ IPX-Mailbox initialisieren }
	Debug('Initialisiere IPX Mailbox');
	DispMB.InitMailbox(Mailbox, cIPXMailboxSlots, 'IPX mailbox');
	Debug('IPX Mailbox initialisiert');

	{ Kanal oeffnen }
	Debug('Oeffne Kanal zum Displayrechner');
	DIPX.OpenChannel(cIPXSendBuffers);
	Debug('Kanal zum Displayrechner geoeffnet');

	{ Variablen initialisieren }
	Connected := false;
	Sent := true;

	while true do
	begin

		{ Keine Verbindung zum Anzeigerechner }
		if not Connected then
		begin
			{ Versuchen zu verbinden }
			Debug('Stelle Verbindung zum Displayrechner her');
			DIPX.Connect(IPXConnection, cDisplayComputerNodeName,
				cIPXConnectRetries, cIPXConnectTimeout, Connected);
			{ Verbindung pruefen und Status ausgeben }
			if Connected then
			begin
				Debug('Verbindung zum Displayrechner hergestellt');
				ShowSystemStatus('Verbindung zum Displayrechner hergestellt');
			end
			else
			begin
				Debug('Keine Verbindung zum Displayrechner');
				ShowSystemStatus('Keine Verbindung zum Displayrechner');
			end;
		end
		else

		{ Verbindung OK }
		begin
			{ Nachricht wurde gesendet }
			if Sent then
			begin
				{ Auf Nachrichten warten }
				Debug('Warte auf Nachrichten fuer den Displayrechner');
				DispMB.Get(Mailbox, Message);
				Debug('Nachricht empfangen');
			end;

			{ Nachricht senden }
			Debug('Sende Nachricht an Displayrechner');
			DIPX.IPXSend(IPXConnection, Addr(Message), Sent);

			{ Nachricht wurde gesendet }
			if Sent then
				Debug('Daten an Displayrechner gesendet')
			else
			{ Nachricht wurde nicht gesendet => im Statusfenster anzeigen }
			begin
				Debug('Daten konnten nicht an den Displayrechner gesendet werden');
				ShowSystemStatus('Daten konnten nicht an den Displayrechner ' +
					'gesendet werden');
			end;
		end;
	end;
end;

end.