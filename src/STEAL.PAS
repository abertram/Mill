unit Steal;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Diese Unit beinhaltet die Klautask, die fuer das Klauen eines Spielsteines
	des aktuellen Spielers notwendig ist.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

procedure StealTask;

implementation

uses
	RTKernel,
	Semas, PTypes, LeadMB, Leader;

{$F+}
procedure StealTask;
(*****************************************************************************
	Beschreibung:
		Klautask.

	In:
		-

	Out:
		-
*****************************************************************************)
var
	LeaderMessage: TLeaderMessage;
begin
	{ Nachrichtart als Klaunachricht markieren }
	LeaderMessage.Kind := lemkStealToken;
	while true do
	begin
		{ An der Printscrensemaphore (ISP) warten }
		Wait(PrintScreenSemaphore);
		{ Spielleiter benachrichtigen }
		LeadMB.PutFront(Leader.Mailbox, LeaderMessage);
	end;
end;

end.