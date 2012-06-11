unit THMsg;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Nachrichttypdeifinition fuer ein Taskhandle.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel;

type
	MsgType = TaskHandle;

{$I RTMSG.INT}

implementation

{$I RTMSG.IMP}

end.