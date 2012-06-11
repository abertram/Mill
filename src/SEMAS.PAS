unit Semas;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	In dieser Unit sind alles im Programm verwendeten Semaphoren enthalten.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel;

var
	StartSemaphore,
	ExitSemaphore,
	RandomWordSemaphore,
	PrintScreenSemaphore: Semaphore;

implementation

begin
	{ Semaphoren initialisieren }
	InitSemaphore(StartSemaphore, Binary, 0, 'Start semaphore');
	InitSemaphore(ExitSemaphore, Binary, 0, 'Exit semaphore');
	InitSemaphore(RandomWordSemaphore, Counting, 1, 'Random word semaphore');
	InitSemaphore(PrintScreenSemaphore, Binary, 0, 'Print screen semaphore');
end.