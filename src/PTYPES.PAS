unit PTypes;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Datentypen fuer den Prozessrechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel, RTTextIO,
	Types;

const
	{ Name der Konfigurationsdatei }
	cIniFilename = 'MILL.INI';

	{ Taskparameter }

	{ Spielleiter }
	cLeaderPriority = MainPriority;
	cLeaderStack = cDefaultStack * 6;
	cLeaderTaskName = 'Spielleiter';
	cLeaderMailboxSlots = 10;

	{ Spieler }
	cPlayerPriority = MainPriority + 1;
	cPlayerStack = cDefaultStack * 7;

	{ Spielstein }
	cTokenPriority = MainPriority + 2;
	cTokenStack = cDefaultStack * 4;
	cTokenTaskName = 'Spielstein';

	{ Klautask }
	cStealPriority = MainPriority + 3;
	cStealStack = cDefaultStack;
	cStealTaskName = 'Klautask';

	{ Fensterposition }

	{ Statistikfensterposition des Benutzers }
	cUserStatisticWindowFirstCol = 40;
	cUserStatisticWindowFirstRow = 0;
	cUserStatisticWindowLastCol = cUserStatisticWindowFirstCol + 39;
	cUserStatisticWindowLastRow = cUserStatisticWindowFirstRow + 5;

	{ Statusfensterposition des Benutzers }
	cUserStatusWindowFirstCol = cUserStatisticWindowFirstCol;
	cUserStatusWindowFirstRow = cUserStatisticWindowLastRow + 1;
	cUserStatusWindowLastCol = cUserStatusWindowFirstCol + 39;
	cUserStatusWindowLastRow = cUserStatusWindowFirstRow + 9;

	{ Statistikfensterposition des CPU-Spielers }
	cCPUStatisticWindowFirstCol = cUserStatisticWindowFirstCol;
	cCPUStatisticWindowFirstRow = cUserStatusWindowLastRow + 1;
	cCPUStatisticWindowLastCol = cCPUStatisticWindowFirstCol + 39;
	cCPUStatisticWindowLastRow = cCPUStatisticWindowFirstRow + 5;

	{ Statusfensterposition des CPU-Spielers }
	cCPUStatusWindowFirstCol = cUserStatisticWindowFirstCol;
	cCPUStatusWindowFirstRow = cCPUStatisticWindowLastRow + 1;
	cCPUStatusWindowLastCol = cCPUStatusWindowFirstCol + 39;
	cCPUStatusWindowLastRow = cCPUStatusWindowFirstRow + 10;

	{ Spielleiterfenster }
	cLeaderWindowFirstCol = 0;
	cLeaderWindowFirstRow = 0;
	cLeaderWindowLastCol = cLeaderWindowFirstCol + 39;
	cLeaderWindowLastRow = cCPUStatusWindowLastRow;
	cLeaderWindowColor = Gray;

	{ Systemstatusfenster }
	cSystemStatusWindowFirstCol = 0;
	cSystemStatusWindowFirstRow = 43;
	cSystemStatusWindowLastCol = cSystemStatusWindowFirstCol + 79;
	cSystemStatusWindowLastRow = cSystemStatusWindowFirstRow + 6;
	cSystemStatusWindowFrameColor = LightRed;
	cSystemStatusWindowAttribute = Gray;

	{ Tasten- / Menuefenster }
	cKeyWindowFirstCol = 0;
	cKeyWindowFirstRow = cLeaderWindowLastRow + 1;
	cKeyWindowLastCol = cKeyWindowFirstCol + 79;
	cKeyWindowLastRow = cKeyWindowFirstRow + 9;
	cKeyWindowColor = Gray;

	{ RTKernel-Timerticks }
	cTimerInterval = 1 / 1000;
type
	{ Spielsteintaskhandles eines Spielers }
	TTokenTaskHandles = array[0..cTokenCount - 1] of TaskHandle;

	{ Spielertaskhandles }
	TPlayerTaskHandles = array[TPlayer] of TaskHandle;

	{ Bedenkzeit }
	TTimeLimit = 0..10;

	{ Bedenkzeiten beider Spieler }
	TPLayerTimeLimits = array[TPLayer] of TTimeLimit;

	{ Spielparameter }
	TGameParameters = record
		{ Erster Spieler }
		FirstPlayer: TPlayer;
		{ Spielerfarben }
		PlayerColors: TPlayerColors;
		{ Maximale Bedenkzeit des CPU-Spielers }
		CPUMaxTimeLimit: TTimeLimit;
	end;

	{ Spielleiternachricht }
	{ Nachrichtart }
	TLeaderMessageKind = (
		{ Spielertaskhandles }
		lemkPlayerTaskHandles,
		{ Erster Spieler }
		lemkFirstPlayer,
		{ Spielerfarben }
		lemkPlayerColors,
		{ Initialisierung }
		lemkInit,
		{ Zugvorbereitung }
		lemkPrepareMove,
		{ Zug }
		lemkMove,
		{ Zugbestaetigung }
		lemkPlayerMoved,
		{ Spielende }
		lemkEndGame,
		{ Zugwahl des Benutzers }
		lemkUserMoveSelected,
		{ Anfrage nach Zugmoeglcihkeiten }
		lemkGetTokenMovePossibilities,
		{ Schlagvorbereitung }
		lemkPrepareCapture,
		{ Schlag }
		lemkCapture,
		{ Schlagbestaetigung }
		lemkPlayerCaptured,
		{ Spielende }
		lemkGameOver,
		{ Cheatzug }
		lemkStealToken,
		{ Maximale Bedenkzeit }
		lemkTimeLimit);
	{ Nachricht }
	TLeaderMessage = record
		case Kind: TLeaderMessageKind of
			lemkPlayerTaskHandles: (
				PlayerTaskHandles: TPlayerTaskHandles;
			);
			lemkFirstPlayer: (
				FirstPlayer: TPlayer;
			);
			lemkPlayerColors: (
				PlayerColors: TPlayerColors;
			);
			lemkUserMoveSelected: (
				MoveData: TMoveData;
			);
			lemkPlayerMoved, lemkPlayerCaptured: (
				TokenMoveData: TTokenMoveData;
			);
			lemkGetTokenMovePossibilities: (
				TokenTaskHandle: TaskHandle;
			);
			lemkTimeLimit: (
				TimeLimit: TTimeLimit;
			);
	end;

	{ Spielernachricht }
	{ Nachrichtart }
	TPlayerMessageKind = (
		{ Spielerart }
		plmkPlayerKind,
		{ Fensterposition }
		plmkWindowPosition,
		{ Fensterfarbe }
		plmkWindowColor,
		{ Maximale Bedenkzeit }
		plmkMaxTimeLimit,
		{ Spielleitertaskhandle }
		plmkLeaderTaskhandle,
		{ Initialisierung }
		plmkInit,
		{ Zug }
		plmkMove,
		{ Spielsteindaten }
		plmkTokenData,
		{ Inkrementierung der maximalen Bedenkzeit }
		plmkIncrementMaxTimeLimit,
		{ Dekrementierung der maximalen Bedenkzeit }
		plmkDecrementMaxTimeLimit,
		{ Zugwahl des Benutzers }
		plmkUserMoveSelected,
		{ Zugbestaetigung des Spielsteins }
		plmkTokenMoved,
		{ Anfrage nach Zugmoeglichkeiten }
		plmkGetMovePossibilities,
		{ Spielfeld }
		plmkField,
		{ Zugvorbereitung }
		plmkPrepareMove,
		{ Schlagvorbereitung }
		plmkPrepareCapture,
		{ Schlag }
		plmkCapture,
		{ Cheatzug }
		plmkStealToken);
	{ Nachricht }
	TPlayerMessage = record
		case Kind: TPlayerMessageKind of
			plmkPlayerKind: (
				PlayerKind: TPlayer;
			);
			plmkWindowPosition: (
				WindowPosition: TWindowPosition;
			);
			plmkWindowColor: (
				WindowColor: TWindowColor;
			);
			plmkMaxTimeLimit: (
				MaxTimeLimit: TTimeLimit;
			);
			plmkLeaderTaskhandle: (
				LeaderTaskHandle: TaskHandle;
			);
			plmkTokenData: (
				TokenData: TTokenData;
			);
			plmkGetMovePossibilities: (
				TokenTaskHandle: TaskHandle;
			);
			plmkUserMoveSelected, plmkTokenMoved: (
				TokenMoveData: TTokenMoveData;
			);
			plmkField: (
				Field: TField;
			);
	end;

	{ Spielsteinnachricht }
	TTokenMessageKind = (
		{ Initialisierung }
		tmkInit,
		{ Spielertaskhandle }
		tmkPlayerTaskHandle,
		{ Anfrage nach Spielsteindaten }
		tmkGetTokenData,
		{ Zug }
		tmkMove,
		{ Zugbestaetigung }
		tmkTokenMoved,
		{ Spielfeld }
		tmkField,
		{ Spielerphase }
		tmkPlayerStage,
		{ Cheatzug }
		tmkSteal);
	{ Nachricht }
	TTokenMessage = record
		case Kind: TTokenMessageKind of
			tmkPlayerTaskHandle: (
				PlayerTaskHandle: TaskHandle;
			);
			tmkGetTokenData: (
				SenderTaskHandle: TaskHandle;
			);
			tmkMove: (
				MoveData: TMoveData;
			);
			tmkField: (
				Field: TField;
			);
			tmkPlayerStage: (
				PlayerStage: TPlayerStage;
			);
	end;

implementation

end.