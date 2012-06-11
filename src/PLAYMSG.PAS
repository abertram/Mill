unit PlayMsg;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer eine Spielernachricht.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	PTypes;

type
	MsgType = TPlayerMessage;

{$I RTMSG.INT}

implementation

{$I RTMSG.IMP}

end.