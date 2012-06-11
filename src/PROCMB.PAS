unit ProcMB;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer eine IPX-Nachricht an den Prozessrechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	Types;

type
	MessageType = TProcessMessage;

{$I Mailbox.DEF}
{$I Mailbox.INT}

implementation

{$I Mailbox.IMP}

end.
