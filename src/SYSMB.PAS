unit SysMB;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer eine Systemstatusnachricht.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	Types;

type
	MessageType = TSystemStatusMessage;

{$I Mailbox.DEF}
{$I Mailbox.INT}

implementation

{$I Mailbox.IMP}

end.