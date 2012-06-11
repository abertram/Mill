unit Types;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Datentypen, die sowohl im Prozessrechner als auch im Anzeigerechner
	verwendet werden.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel, RTTextIO;

const
	{ Standartstackgroesse fuer die Taskerzeugung }
	cDefaultStack = 1024;

	{ Taskname fuer die Benutzertask }
	cUserTaskName = 'Benutzer';

	{ Taskname fuer die CPU-Task }
	cCPUTaskName = 'CPU';

	{ Parameter, die fuer die Taskerzeugung benoetigt werden }

	{ Loggertask }
	cLoggerPriority = MainPriority + 4;
	cLoggerStack = cDefaultStack * 6;
	cLoggerTaskName = 'Logger';
	cLoggerMailboxSlots = 10;

	{ IPX-Sender-Task }
	cIPXSenderPriority = MainPriority + 5;
	cIPXSenderStack = cDefaultStack * 2;
	cIPXSenderTaskName = 'IPX Sender';

	{ IPX-Empfaenger-Task }
	cIPXReceiverPriority = MainPriority + 5;
	cIPXReceiverStack = cDefaultStack * 3;
	cIPXReceiverTaskName = 'IPX Receiver';

	{ Tastentask }
	cKeyPriority = MainPriority + 3;
	cKeyStack = cDefaultStack * 2;
	cKeyTaskName = 'Menue';

	{ Systemstatustask }
	cSystemStatusPriority = MainPriority + 4;
	cSystemStatusStack = cDefaultStack * 3;
	cSystemStatusTaskName = 'Systemstatus';
	cSystemStatusMailboxSlots = 1;
	sSystemStatusDisplayDuration = 2;

	{ Parameter fuer die IPX-Kommunikation }
	cProcessComputerNodeName = 'P2616';
	cDisplayComputerNodeName = 'D2616';
	cPIPXChannel = 1;
	cDIPXChannel = 2;
	cMaxIPXInConnections = 1;
	cMaxIPXSendRetries = 10;
	cIPXSendTimeout = 10;
	cIPXSendBuffers = 0;
	cIPXConnectRetries = 10;
	cIPXConnectTimeOut = 10;
	cIPXMailboxSlots = 10;
	cIPXReceiveBuffers = 10;

	{ Anzahl der Spielsteine }
	cTokenCount = 9;

	{ Anzahl der Quadrate im Spielfeld }
	cFieldSquareCount = 3;

	{ Spielfeldbreite }
	cFieldWidth = cFieldSquareCount * 2 + 1;
	{ Spielfeldhoehe }
	cFieldHeight = cFieldSquareCount * 2 + 1;

	{ Farbe zum Ausgeben von Schlaginfos }
	cCapturePossibilityColor = LightRed;
type
	{ Spielerarten }
	TPlayer = (User, CPU);

	{ Spielsteinanzahl }
	TTokenCount = 0..cTokenCount;

	{ Spielsteinanzahl beider Spieler }
	TPlayerTokenCount = array[TPlayer] of TTokenCount;

	{ Anzahl der Quadrate im Spielfeld }
	TFieldSquareCount = 0..cFieldSquareCount;
	{ Spielfeldbreite }
	TFieldWidth = 0..cFieldWidth;
	{ Spielfeldhoehe }
	TFieldHeight = 0..cFieldHeight;

	{ Spielfeldposition }
	TFieldPos = record
		X: TFieldWidth;
		Y: TFieldHeight;
	end;

	{ Besitzer einer Spielfeldposition }
	TOwner = (oNone, oUser, oCPU);

	{ Eigenschaften einer Spielfeldposition }
	TFieldPosProperties = record
		{ Position ist gueltig }
		Valid: boolean;
		{ Besitzer }
		Owner: TOwner;
		{ Spielsteintaskhandle }
		TokenTH: TaskHandle;
	end;

	{ Spielfeld }
	TField = record
		{ Anzahl gesetzter Spielsteine }
		PlacedTC,
		{ Anzahl geschlagener Spielsteine }
		CapturedTC: TPlayerTokenCount;
		{ Positionen }
		Pos: array[Low(TFieldWidth)..High(TFieldWidth) - 1,
			Low(TFieldHeight)..High(TFieldHeight) - 1] of TFieldPosProperties;
	end;

	{ Spielsteinzustand }
	TTokenState = (
		{ Nicht gesetzt }
		tsNotPlaced,
		{ Gesetzt }
		tsPlaced,
		{ Geschlagen }
		tsCaptured,
		{ Geklaut durch Cheaten }
		tsStolen);

	{ Ziehrichtung }
	TDirection = (dLeft, dRight, dUp, dDown);
	{ Anzahl der Richtungen }
	TDirectionCount = 0..Ord(High(TDirection)) + 1;
	{ Ziehrichtungsmenge }
	TDirectionSet = set of TDirection;

	{ Zugmoeglichkeiten }
	TMovePossibilities = array[TFieldWidth, TFieldHeight] of boolean;

	{ Spielsteindaten }
	TTokenData = record
		{ Spielsteintaskhandle }
		TokenTH: TaskHandle;
		{ Spielfeldposition }
		FieldPos: TFieldPos;
		{ Zustand }
		State: TTokenState;
		{ Moegliche Ziehrichtungen }
		MoveDirections: TDirectionSet;
		{ Zugmoeglichkeiten }
		MovePossibilities: TMovePossibilities;
	end;

	{ Spielsteindaten beider Spieler }
	TPlayerTokenData = array[0..cTokenCount - 1] of TTokenData;

	{ Spielerfarben }
	TPlayerColors = array[TPlayer] of byte;

	{ Spielerphase }
	TPlayerStage = (
		{ Setzen }
		psPlace,
		{ Normal ziehen }
		psMove,
		{ Keine Zugmoeglichkeit }
		psCantMove,
		{ Springen }
		psFly,
		{ Schlagen }
		psCapture,
		{ Keine Schlagmoeglichkeit }
		psCantCapture);
	{ Spielerphasen beider Spieler }
	TPlayerStages = array[TPlayer] of TPlayerStage;

	{ Nachrichttyp fuer die Loggertask }
	{ Nachrichtenart }
	TLoggerMessageKind = (
		{ Dateinamenpraefix }
		lomkFilename,
		{ Neue Datei }
		lomkCreateNewFile,
		{ Debugmeldung }
		lomkDebug,
		{ Logmeldung }
		lomkLog,
		{ Programmende }
		lomkExit);
	{ Nachricht }
	TLoggerMessage = record
		case Kind: TLoggerMessageKind of
			lomkFilename: (
				Filename: string;
			);
			lomkDebug, lomkLog: (
				Sender: TaskHandle;
				Message: string;
			);
	end;

	{ Zugart }
	TMoveKind = (
		{ Kein Zug }
		mkNoMove,
		{ Setzen }
		mkPlace,
		{ Ziehen }
		mkMove,
		{ Schlagen }
		mkCapture,
		{ Klauen durch Cheaten }
		mkSteal);

	{ Zugdaten }
	TMoveData = record
		{ Zugart }
		Kind: TMoveKind;
		{ Spielertaskhandle des ziehenden Spielers }
		PlayerTH: TaskHandle;
		{ Quellposition }
		SourceFP,
		{ Zielposition }
		TargetFP: TFieldPos;
	end;

	{ Zugdaten eines bestimmten Spielsteins }
	TTokenMoveData = record
		{ Spielsteintaskhandle }
		TokenTH: TaskHandle;
		{ Zugdaten }
		MoveData: TMoveData;
	end;

	{ Nachichttyp fuer den Prozessrechner }
	{ Nachrichtenart }
	TProcessMessageKind = (
		{ Zugwahl des Benutzers }
		prmkUserMoveSelected,
		{ Zugbestaetigung }
		prmkTokenMoved,
		{ Anfrage nach Zugmoeglichkeiten }
		prmkGetTokenMovePossibilities,
		{ Spielstart }
		prmkStartGame,
		{ Spielende }
		prmkEndGame,
		{ Programmende }
		prmkExit);
	{ Zeiger auf Nachricht fuer die IPX-Kommunikation }
	PProcessMessage = ^TProcessMessage;
	{ Nachricht }
	TProcessMessage = record
		case Kind: TProcessMessageKind of
			prmkUserMoveSelected: (
				MoveData: TMoveData;
			);
			prmkGetTokenMovePossibilities: (
				TokenTH: TaskHandle;
			);
			prmkTokenMoved: (
				TokenMoveData: TTokenMoveData;
			);
	end;

	{ Nachrichttyp fuer den Darstellungsrechner }
	{ Nachrichtart }
	TDisplayMessageKind = (
		{ Initialisierung }
		dmkInit,
		{ Spielerfarben }
		dmkPlayerColors,
		{ Aktueller Spieler }
		dmkCurrentPlayer,
		{ Zugmoeglichkeiten }
		dmkMovePossibilities,
		{ Spielfeld }
		dmkField,
		{ Zugdaten }
		dmkTokenMove,
		{ Spielerphase }
		dmkPlayerStage,
		{ Programmende }
		dmkExit,
		{ Spielende }
		dmkGameOver);
	{ Zeiger auf Nachricht fuer die IPX-Kommunikation }
	PDisplayMessage = ^TDisplayMessage;
	{ Nachricht }
	TDisplayMessage = record
		case Kind: TDisplayMessageKind of
			dmkPlayerColors: (
				Colors: TPlayerColors;
			);
			dmkCurrentPlayer: (
				Player: TPlayer;
			);
			dmkMovePossibilities: (
				Possibilities: TMovePossibilities;
			);
			dmkField: (
				Field: TField;
			);
			dmkTokenMove: (
				TokenMoveData: TTokenMoveData;
			);
			dmkPlayerStage: (
				Stage: TPlayerStage;
			);
	end;

	{ Fensterposition }
	TWindowPosition = record
		FirstCol,
		LastCol: ColRange;
		FirstRow,
		LastRow: RowRange;
	end;

	{ Fensterfarbe }
	TWindowColor = record
		FrameColor,
		Attribute: byte;
	end;

	{ Nachrichttyp fuer die Systemstatustask }
	{ Nachrichtart }
	TSystemStatusMessageKind = (
		{ Fensterposition }
		ssmkWindowPosition,
		{ Fensterfarbe }
		ssmkWindowColor,
		{ Systemstatus }
		ssmkSystemStatus);
	{ Nachricht }
	TSystemStatusMessage = record
		case Kind: TSystemStatusMessageKind of
			ssmkWindowPosition: (
				WindowPosition: TWindowPosition;
			);
			ssmkWindowColor: (
				WindowColor: TWindowColor;
			);
			ssmkSystemStatus: (
				Message: string;
			);
	end;

implementation

end.