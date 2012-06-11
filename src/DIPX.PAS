unit DIPX;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer IPX-Nachrichten vom Prozess- zum Anzeigerechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel,
	RTIPX,
	Types;

const
	Channel = cDIPXChannel;

type
	IPXMessageType = TDisplayMessage;
	IPXMessagePtr = PDisplayMessage;

	{$I IPX.DEF }
	{$I IPX.INT }

implementation

	{$I IPX.IMP}

end.