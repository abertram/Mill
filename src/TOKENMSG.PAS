unit TokenMsg;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer eine Spielsteinnachricht.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	PTypes;

type
	MsgType = TTokenMessage;

{$I RTMSG.INT}

implementation

{$I RTMSG.IMP}

end.
