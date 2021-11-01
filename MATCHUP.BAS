 '************************
'*    QBASIC Matchup    *
'*  2020 Aron Hoekstra  *
'*************************

RANDOMIZE TIMER
ON TIMER(1) GOSUB TimeUpdate
DIM cTIME AS INTEGER
DIM cWIDTH  AS INTEGER
cWIDTH = -1
DIM cHEIGHT AS INTEGER
cHEIGHT = -1
DIM bSOUND AS STRING
bSOUND = ""
SCREEN 13
CLS
DIM chars(24) AS INTEGER
DIM cards(cWIDTH * cHEIGHT) AS INTEGER
DIM mask(cWIDTH * cHEIGHT) AS INTEGER
DIM status AS INTEGER
DIM guess1 AS INTEGER
DIM guess2 AS INTEGER
CONST mHIDE = 0
CONST mGUESS = 1
CONST mFOUND = 2
CONST sGUESS1 = 0
CONST sGUESS2 = 1
chars(1) = 1
chars(2) = 2
chars(3) = 3
chars(4) = 4
chars(5) = 5
chars(6) = 6
chars(7) = 14
chars(8) = 15
chars(9) = 18
chars(10) = 21
chars(11) = 33
chars(12) = 127
chars(13) = 232
chars(14) = 155
chars(15) = 157
chars(16) = 168
chars(17) = 225
chars(18) = 227
chars(19) = 234
chars(20) = 236
chars(21) = 240
chars(22) = 247
chars(23) = 251
chars(24) = 254
DIM selected AS INTEGER
DIM guesses AS INTEGER
DIM x, y
DIM level AS STRING
CLS

'initialize the cards
GOSUB Initialize
GOSUB DrawGrid
GOSUB DrawCards
GameLoop:
    GOSUB ProcessInput
    GOSUB DrawCards
    IF status = sGUESS1 THEN
        status = sGUESS2
    ELSEIF status = sGUESS2 THEN
        guesses = guesses + 1
        COLOR 15
        LOCATE 4, 23
        PRINT "GUESSES: ";
        PRINT guesses;
        IF cards(guess1) = cards(guess2) THEN
            IF bSOUND = "Y" THEN
                SOUND 800, 1
                SOUND 900, 1
                SOUND 1000, 1
            END IF
           
            mask(guess1) = mFOUND
            mask(guess2) = mFOUND
            GOSUB DrawCards
        ELSE
            mask(guess1) = mHIDE
            mask(guess2) = mHIDE
        END IF
        status = sGUESS1
       
        DIM found
        found = 1
        FOR i = 1 TO (cWIDTH * cHEIGHT)
            IF mask(i) <> mFOUND THEN
                found = 0
                EXIT FOR
            END IF
        NEXT i
        IF found = 1 THEN
            TIMER OFF
            LOCATE 23, 1
            COLOR 15
            PRINT "YOU WON !!!"
            FOR i = 1 TO 8
                IF bSOUND = "Y" THEN
                    SOUND 1100, 1
                    SOUND 1200, 1
                    SOUND 1300, 1
                END IF
            NEXT i
            SCREEN 12
            PRINT "thanks for playing"
            PRINT "you completed level ";
            PRINT level;
            PRINT " in ";
            PRINT guesses;
            PRINT " guesses and ";
            PRINT cTIME;
            PRINT " seconds."
            END
        END IF
    END IF

    GOTO GameLoop

ProcessInput:
    TIMER STOP
    LOCATE 22, 23
    PRINT "                "
    LOCATE 22, 1
    COLOR 15
    PRINT "Make a selection"
    coord$ = INKEY$
    TIMER ON
    IF coord$ = CHR$(0) + CHR$(72) THEN 'up
        IF bSOUND = "Y" THEN SOUND 500, 1
        IF selected > 1 THEN selected = selected - 1
        GOSUB DrawCards
        GOTO ProcessInput
    ELSEIF coord$ = CHR$(0) + CHR$(75) THEN 'left
        IF bSOUND = "Y" THEN SOUND 425, 1
        IF (selected - cHEIGHT) / cHEIGHT > 0 THEN selected = selected - cHEIGHT
        GOSUB DrawCards
        GOTO ProcessInput
    ELSEIF coord$ = CHR$(0) + CHR$(77) THEN 'right
        IF bSOUND = "Y" THEN SOUND 475, 1
        IF (selected + cHEIGHT) <= cHEIGHT * cWIDTH THEN
            selected = selected + cHEIGHT
        END IF
        GOSUB DrawCards
        GOTO ProcessInput
    ELSEIF coord$ = CHR$(0) + CHR$(80) THEN 'down
        IF bSOUND = "Y" THEN SOUND 400, 1
        IF selected + 1 <= cHEIGHT * cWIDTH THEN selected = selected + 1
        GOSUB DrawCards
        GOTO ProcessInput
    ELSEIF coord$ = CHR$(13) OR coord$ = " " THEN 'enter or space
        IF bSOUND = "Y" THEN SOUND 600, 1
        IF mask(selected) = mHIDE THEN
            mask(selected) = mGUESS
            IF status = sGUESS1 THEN
                guess1 = selected
            ELSE
                guess2 = selected
            END IF
        ELSE
			IF bSOUND = "Y" THEN SOUND 300, 2
            LOCATE 23, 20
            PRINT "Already Picked"
            GOTO ProcessInput
        END IF
    ELSEIF UCASE$(coord$) = "X" THEN 'enter
        END
    ELSE
        GOTO ProcessInput
    END IF
    RETURN

Initialize:
    LOCATE 1, 1
    PRINT "Use Sound? [Y/N] ";
   
    DO UNTIL bSOUND = "Y" OR bSOUND = "N"
        bSOUND = UCASE$(INKEY$)
    LOOP
    PRINT bSOUND
   
    PRINT "Choose Level: [1,2,3,4] ";
    DO UNTIL level = "1" OR level = "2" OR level = "3" OR level = "4"
        level = INKEY$
    LOOP
    IF level = "1" THEN
        cWIDTH = 3
        cHEIGHT = 2
    ELSEIF level = "2" THEN
        cWIDTH = 4
        cHEIGHT = 4
    ELSEIF level = "3" THEN
        cWIDTH = 6
        cHEIGHT = 5
    ELSEIF level = "4" THEN
        cWIDTH = 8
        cHEIGHT = 6
    END IF
    REDIM cards(cWIDTH * cHEIGHT) AS INTEGER
    REDIM mask(cWIDTH * cHEIGHT) AS INTEGER
    CLS
    selected = 1
    status = sGUESS1
    COLOR 15
    LOCATE 1, 1
    PRINT " QBASIC Matchup"
    LOCATE 23, 1
    COLOR 1
    PRINT "(X = Exit)"
    COLOR 15
    FOR i = 1 TO (cWIDTH * cHEIGHT)
        cards(i) = 0
        mask(i) = mHIDE
    NEXT i
    DIM r
    FOR i = 1 TO ((cWIDTH * cHEIGHT) / 2)
        GOSUB RandCard
        GOSUB RandCard
    NEXT i
    TIMER ON
    RETURN

RandCard:
    r = (RND * ((cWIDTH * cHEIGHT) - 1)) + 1
    IF cards(r) <> 0 THEN
        GOTO RandCard
    END IF
    cards(r) = chars(i)
    RETURN

DrawGrid:
    x = 4
    y = 4
    LOCATE x, y + 1
    FOR i = 1 TO cWIDTH
        PRINT CHR$(64 + i);
        PRINT " ";
    NEXT i
    'PRINT "A B C D E F G H"
    x = x + 1
    LOCATE x + 1, y - 1
    PRINT "1";
    LOCATE x, y
    PRINT CHR$(&HC9);
    FOR i = 1 TO cWIDTH - 1
        PRINT CHR$(&HCD);
        PRINT CHR$(&HD1);
    NEXT i
    PRINT CHR$(&HCD);
    PRINT CHR$(&HBB);
    r = 49
    FOR j = 1 TO cHEIGHT - 1
    LOCATE x + 1, y - 1
    PRINT CHR$(r);
    r = r + 1
    x = x + 1
    LOCATE x, y
    PRINT CHR$(&HBA);
    FOR i = 1 TO cWIDTH - 1
        PRINT " ";
        PRINT CHR$(&HB3);
    NEXT i
    PRINT " ";
    PRINT CHR$(&HBA);
    x = x + 1
    LOCATE x, y
    PRINT CHR$(&HC7);
    FOR i = 1 TO cWIDTH - 1
        PRINT CHR$(&HC4);
        PRINT CHR$(&HC5);
    NEXT i
    PRINT CHR$(&HC4);
    PRINT CHR$(&HB6);
    NEXT j
    LOCATE x + 1, y - 1
    PRINT CHR$(r);
    x = x + 1
    LOCATE x, y
    PRINT CHR$(&HBA);
    FOR i = 1 TO cWIDTH - 1
        PRINT " ";
        PRINT CHR$(&HB3);
    NEXT i
    PRINT " ";
    PRINT CHR$(&HBA);
    x = x + 1
    LOCATE x, y
    PRINT CHR$(&HC8);
    FOR i = 1 TO cWIDTH - 1
        PRINT CHR$(&HCD);
        PRINT CHR$(&HCF);
    NEXT i
    PRINT CHR$(&HCD);
    PRINT CHR$(&HBC);
    COLOR 15
    LOCATE 4, 23: PRINT "GUESSES: -";
    LOCATE 6, 23: PRINT "TIME: -";
    RETURN

DrawCards:
    LOCATE 23, 20
    PRINT "                "
   
    x = 1
    y = 1
    DIM c
    c = 1

    FOR y = 1 TO (cWIDTH * 2) STEP 2
        FOR x = 1 TO (cHEIGHT * 2) STEP 2
            LOCATE x + 5, y + 4
            IF mask(c) = mHIDE THEN
                IF c = selected THEN
                    COLOR 14
                ELSE
                    COLOR 2
                END IF
                PRINT CHR$(177);
            ELSEIF mask(c) = mFOUND THEN
                IF c = selected THEN
                    COLOR 3
                ELSE
                    COLOR 1
                END IF
                PRINT CHR$(cards(c));
            ELSE
                COLOR 15
                PRINT CHR$(cards(c));
            END IF
            c = c + 1
        NEXT x
    NEXT y
    RETURN

TimeUpdate:
    cTIME = cTIME + 1
    LOCATE 6, 23: PRINT "TIME: "; : PRINT cTIME;
    RETURN

