unit DispMB;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Mailboxdefinition fuer Nachrichten an den Anzeigerechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	Types;

type
	MessageType = TDisplayMessage;

{$I Mailbox.DEF}
{$I Mailbox.INT}

implementation

{$I Mailbox.IMP}

end.