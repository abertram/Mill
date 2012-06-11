unit LeadMB;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Nchrichttypdefinition fuer die Spielleitermailbox.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	PTypes;

type
	MessageType = TLeaderMessage;

{$I Mailbox.DEF}
{$I Mailbox.INT}

implementation

{$I Mailbox.IMP}

end.