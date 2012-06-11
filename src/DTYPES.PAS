unit DTypes;
(*****************************************************************************
	Prozessprogrammierung SS08
	Aufgabe: Muehle

	Typen fuer den Darstellungsrechner.

	Autor: Alexander Bertram (B_TInf 2616)
*****************************************************************************)

interface

uses
	RTKernel, RTTextIO,
	Types;

const
	{ Konstanten fuer die Darstellung des Spielfeldes }

	{ Breite des inneren Quadrates }
	cBoardInnerSquareWidth = 5;
	{ Hoehe des inneren Quadrates }
	cBoardInnerSquareHeight = 5;
	{ Horizontaler Abstand zwischen den Quadraten }
	cBoardLineHorizontalMargin = 1;
	{ Vertikaler Abstand zwischen den Quadraten }
	cBoardLineVerticalMargin = 1;
	{ Spielfeldbreite ausgehend vom inneren Quadrat }
	cBoardWidth = cBoardInnerSquareWidth + (cFieldSquareCount - 1) *
		(cBoardLineHorizontalMargin + 1) * 2;
	{ Spielfeldhoehe ausgehend vom inneren Quadrat }
	cBoardHeight = cBoardInnerSquareHeight + (cFieldSquareCount - 1) *
		(cBoardLineVerticalMargin + 1) * 2;

	{ Startposition des Spielfeldes }
	cBoardStartX = 1;
	cBoardStartY = 1;

	{ Hintergrundfarben }

	{ Spielfeld }
	cBoardBGColor = BGBlack;
	{ Cursor }
	cCursorFieldPosBGColor = BGBrown;
	{ Markierte Position }
	cSelectedFieldPosBGColor = BGMagenta;

	{ Konstanten, die fuer das Kreieren der Spielbretttask noetig sind }
	cBoardPriority = MainPriority;
	cBoardStack = cDefaultStack * 5;
	cBoardTaskName = 'Spielbrett';
	{ Mailboxslots fuer die Spielbrettmailbox }
	cBoardMailboxSlots = 10;

	{ Position und Farben fuer die Fenster auf dem Darrstellungsrechner }

	{ Spielbrett }
	cBoardWindowFirstCol = 32;
	cBoardWindowFirstRow = 0;
	cBoardWindowLastCol = cBoardWindowFirstCol + cBoardWidth + 4;
	cBoardWindowLastRow = cBoardWindowFirstRow + cBoardHeight + 4;
	cBoardWindowColor = Normal + cBoardBGColor;

	{ Benutzerspielsteine }
	cUserTokenWindowFirstCol = 0;
	cUserTokenWindowFirstRow = 0;
	cUserTokenWindowLastCol = cUserTokenWindowFirstCol + 4;
	cUserTokenWindowLastRow = cBoardWindowLastRow;
	cUserTokenWindowColor = Normal + cBoardBGColor;

	{ CPU-Spielsteine }
	cCPUTokenWindowFirstCol = 75;
	cCPUTokenWindowFirstRow = 0;
	cCPUTokenWindowLastCol = cCPUTokenWindowFirstCol + 4;
	cCPUTokenWindowLastRow = cBoardWindowLastRow;
	cCPUTokenWindowColor = Normal + cBoardBGColor;

	{ Systemstatus }
	cSystemStatusWindowFirstCol = 0;
	cSystemStatusWindowFirstRow = 43;
	cSystemStatusWindowLastCol = cSystemStatusWindowFirstCol + 79;
	cSystemStatusWindowLastRow = cSystemStatusWindowFirstRow + 6;
	cSystemStatusWindowFrameColor = LightRed + cBoardBGColor;
	cSystemStatusWindowAttribute = Normal + cBoardBGColor;

	{ Spielverlauf }
	cGameFlowWindowFirstCol = 0;
	cGameFlowWindowFirstRow = cBoardWindowLastRow + 1;
	cGameFlowWindowLastCol = cGameFlowWindowFirstCol + 79;
	cGameFlowWindowLastRow = cGameFlowWindowFirstRow + 15;
	cGameFlowWindowColor = Normal + cBoardBGColor;
  cGameFlowWindowTitle = ' Spielablauf ';

	{ Tasten }
	cKeyWindowFirstCol = 0;
	cKeyWindowFirstRow = cGameFlowWindowLastRow + 1;
	cKeyWindowLastCol = cKeyWindowFirstCol + 79;
	cKeyWindowLastRow = cKeyWindowFirstRow + 8;
	cKeyWindowColor = Gray;

	{ ASCII-Zeichen fuer das Spielfeld }
	cBoardUpperLeftCornerChar = #$DA;
	cBoardHorizontalLineChar = #$C4;
	cBoardUpperCrossChar = #$C2;
	cBoardUpperRightCornerChar = #$BF;
	cBoardVerticalLineChar = #$B3;
	cBoardCrossChar = #$C5;
	cBoardLeftCrossChar = #$C3;
	cBoardRightCrossChar = #$B4;
	cBoardLowerLeftCornerChar = #$C0;
	cBoardLowerCrossChar = #$C1;
	cBoardLowerRightCornerChar = #$D9;

	{ ASCII-Zeichen fuer die Spielsteine }
	cUserTokenChar = 'o';
	cCPUTokenChar = 'o';

type
	{ Spielbrettbreite }
	TBoardWidth = 0..cBoardWidth - 1;
	{ Spielbretthoehe }
	TBoardHeight = 0..cBoardHeight - 1;

	{ Lookup-Tabelle fuer die Spielbrettdarstellung }
	TBoardCharLookupTable = array[TBoardWidth, TBoardHeight] of char;

	{ Nachrichttyp fuer die Kommunikation mit der Spielbretttask }
	TBoardMessageKind = (
		{ Initialisierung}
		bmkInit,
		{ Spielerfarben }
		bmkPlayerColors,
		{ Aktueller Spieler }
		bmkCurrentPlayer,
		{ Zugmoeglichkeiten }
		bmkTokenMovePossibilities,
		{ Cursorbewegung }
		bmkCursorMove,
		{ Spielfeld }
		bmkField,
		{ Positionsmarkierung }
		bmkFieldPositionSelection,
		{ Spielsteinzug }
		bmkTokenMove,
		{ Spielerstatus }
		bmkPlayerStage,
		{ Spielenden }
		bmkGameOver);
	TBoardMessage = record
		case Kind: TBoardMessageKind of
			bmkPlayerColors: (
				Colors: TPlayerColors;
			);
			bmkCurrentPlayer: (
				Player: TPlayer;
			);
			bmkTokenMovePossibilities: (
				TokenMovePossibilities: TMovePossibilities;
			);
			bmkCursorMove: (
				Direction: TDirection;
			);
			bmkField: (
				Field: TField;
			);
			bmkTokenMove: (
				TokenMoveData: TTokenMoveData;
			);
      bmkPlayerStage: (
      	PlayerStage: TPlayerStage;
      );
	end;

implementation

end.