unit BoardMB;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer eine Spielbretttasknachricht.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	DTypes;

type
	MessageType = TBoardMessage;

{$I Mailbox.DEF}
{$I Mailbox.INT}

implementation

{$I Mailbox.IMP}

end.