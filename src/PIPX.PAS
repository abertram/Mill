unit PIPX;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typdefinition fuer IPX-Nachrichten vom Anzeige- zum Prozessrechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel, RTIPX,
	Types;

const
	Channel = cPIPXChannel;

type
	IPXMessageType = TProcessMessage;
	IPXMessagePtr = PProcessMessage;

	{$I IPX.DEF }
	{$I IPX.INT }

implementation

	{$I IPX.IMP}

end.