unit LoggerMB;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Nachrichttypdefinition fuer die Loggermailbox.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	Types;

type
	MessageType = TLoggerMessage;

{$I Mailbox.DEF}
{$I Mailbox.INT}

implementation

{$I Mailbox.IMP}

end.