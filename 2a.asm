MyStack SEGMENT STACK
MyStack ENDS

;====================

MyData SEGMENT

single DB 0DAh, 0BFh, 0D9h, 0C0h, 0C4h, 0B3h
double DB 0C9h, 0BBh, 0BCh, 0C8h, 0CDh, 0BAh
uLCorner EQU 0
uRCorner EQU 1
bRCorner EQU 2
bLCorner EQU 3
horizontal EQU 4
vertical EQU 5

location DW 160*7+40
border DB 0
fgColor DB 0111b
bgColor DB 0101b
boxHeight DB 8
boxWidth DB 16

MyData ENDS

;====================

MyCode SEGMENT

myMain PROC
    
    ASSUME DS:MyData, CS:MyCode

    MOV AX, MyData 
    MOV DS, AX          ; DS point to data segment
    MOV AX, 0B800h
    MOV ES, AX          ; ES points to screen memory segment

    CALL clearBox
    CALL drawBox
    CALL changeBox

    MOV AH, 4Ch     ; exit
    INT 21h         ;

myMain ENDP


;====================


changeBox PROC

PUSH AX CX 


MOV CX, 1           ; while(true)
checkKeyLoop:

    MOV AH, 11h     ; check for key
    INT 16h         ;
    JZ noKeyReady   ; next loop and update spam character

    CALL clearBox   ; clear before next move

    MOV AH, 10h     ; get key
    INT 16h

    CMP AL, 1Bh     ; escape key
    JE escape       ; jump to exit program

    CMP AX, 48E0h   ; up arrow key
    JE moveUpJmp

    CMP AX, 50E0h   ; down arrow key
    JE moveDownJmp

    CMP AX, 4BE0h   ; left arrow key
    JE moveLeftJmp

    CMP AX, 4DE0h   ; right arrow key
    JE moveRightJmp

    ; had to change keys below to what worked for me - mac life :) 

    CMP AX, 1177h        ; W key
    JE growTallerJmp

    CMP AX, 1F73h        ; S key
    JE growShorterJmp

    CMP AX, 2064h        ; D key
    JE growWiderJmp

    CMP AX, 1E61h        ; A key
    JE growNarrowerJmp

    CMP AX, 3B00h        ; F1 key
    JE changeBorderJmp

    CMP AX, 3C00h        ; F2 key
    JE changeFgColorJmp

    CMP AX, 3D00h        ; F3 key
    JE changeBgColorJmp

    noKeyReady:
    INC BYTE PTR ES:[160 * 23 + 156]    ; change spam character

    nextLoop:  
    CALL drawBox    ; drawing the box

    CMP CX, 0       ; end of loop
    JA checkKeyLoop ;

    moveUpJmp:
    CALL moveUp
    JMP nextLoop

    moveDownJmp:
    CALL moveDown
    JMP nextLoop

    moveLeftJmp:
    CALL moveLeft
    JMP nextLoop

    moveRightJmp:
    CALL moveRight
    JMP nextLoop

    growTallerJmp:
    CALL growTaller
    JMP nextLoop

    growShorterJmp:
    CALL growShorter
    JMP nextLoop

    growWiderJmp:
    CALL growWider
    JMP nextLoop

    growNarrowerJmp:
    CALL growNarrower
    JMP nextLoop

    changeBorderJmp:
    CALL changeBorder
    JMP nextLoop

    changeFgColorJmp:
    CALL changeFgColor
    JMP nextLoop

    changeBgColorJmp:
    CALL changeBgColor
    JMP nextLoop

    escape:

    POP CX AX
    RET

changeBox ENDP


;====================


changeBorder PROC

NEG border      ; flip border (single and double)
ADD border, 1   ;

RET

changeBorder ENDP


;====================


moveUp PROC

CMP location, 160     ; check upper bound
JL moveUpReturn    
SUB location, 160     ; move up
moveUpReturn:

RET

moveUp ENDP


;====================


moveDown PROC

PUSH AX BX CX

MOV AL, [boxHeight]   ; inner height
ADD AL, 2             ; add corners
MOV BL, 160           
MUL BL                ; multiply 160 by height
MOV BX, 4000          
SUB BX, AX            ; get bottom left corner location
CMP location, BX      ; check lower bound
JGE moveDownReturn
ADD location, 160     ; move down
moveDownReturn:

POP CX BX AX
RET

moveDown ENDP


;====================


moveLeft PROC

PUSH AX BX DX

MOV AX, [location]
MOV BX, 160          
XOR DX, DX           ; clear DX
DIV BX               ; mod location by 160 to get column of top left corner
CMP DX, 2            ; check left bound
JL moveLeftReturn
SUB location, 2      ; move left
moveLeftReturn:

POP DX BX AX
RET

moveLeft ENDP


;====================


moveRight PROC

PUSH AX BX DX

MOV AX, [location]  ; top left location
MOV BX, 160         ; setup 160 for division
XOR DX, DX          ; clear dx
DIV BX              ; mod location by 160 to get column of top left corner
ADD DL, [boxWidth]  ; 2 * width + corners to get to top right corner
ADD DL, [boxWidth]  ; 
ADD DL, 4           ; add 4 for corners
CMP DX, 160         ; check right bound
JG moveRightReturn
ADD location, 2     ; move right
moveRightReturn:

POP DX BX AX
RET

moveRight ENDP


;====================


growTaller PROC

CMP boxHeight, 22       ; max height of box
JG growTallerReturn
ADD boxHeight, 1        ; grow taller
CALL moveUp             ; move up
growTallerReturn:

RET

growTaller ENDP


;====================


growShorter PROC

CMP boxHeight, 6        ; min height of box
JL growShorterReturn
SUB boxHeight, 1        ; grow shorter
growShorterReturn:

RET

growShorter ENDP


;====================


growWider PROC

CMP boxWidth, 78        ; max width
JG growWiderReturn
ADD boxWidth, 1         ; grow wider
CALL moveLeft           ; move left
growWiderReturn:

RET

growWider ENDP


;====================


growNarrower PROC

CMP boxWidth, 6         ; min width
JL growNarrowerReturn
SUB boxWidth, 1         ; grow narrower
growNarrowerReturn:

RET

growNarrower ENDP


;====================


clearBox PROC

PUSH AX CX DI

MOV DI, 0
MOV AX, 0720h   ; blank character
MOV CX, 2000    ; loop 2000 times

clearLoop:
    MOV ES:[DI], AX
    ADD DI, 2
    LOOP clearLoop

POP DI CX AX
RET

clearBox ENDP


;====================


changeFgColor PROC

MOV AL, fgColor
INC AL          ; increment fgColor
AND AL, 0111b   ; stop overflow
MOV fgColor, AL

RET

changeFgColor ENDP


;====================


changeBgColor PROC

MOV AL, bgColor
INC AL          ; increment bgColor
AND AL, 0111b   ; stop overflow
MOV bgColor, AL

RET

changeBgColor ENDP


;====================


drawBox PROC

PUSH AX BX CX SI DI

LEA SI, single              ; set SI to single line "array"
CMP border, 0
JE singleBorder
LEA SI, double              ; set SI to double line "array"
singleBorder:

MOV AH, [bgColor]           ; set background color
SHL AH, 4                   ; 
ADD AH, [fgColor]           ; set foreground color

MOV DI, location            ; set DI to upper left corner location on screen
MOV AL, [SI+uLCorner]       ; move upper left corner into AL
MOV ES:[DI], AX             ; print colored upper left corner
                
MOV BL, [boxWidth]          ; add to DI to get right column location
SHL BL, 1                   ; multiply by 2 

MOV AL, [SI+uRCorner]       ; move upper right corner into AL
MOV ES:[DI + BX], AX        ; print colored upper right corner

MOV DI, location            ; set DI to upper left corner location on screen
MOV AL, [SI+vertical]       ; move vertical piece into AL
MOV CL, [boxHeight]         ; set counter to inner height

leftRightLoop:
    ADD DI, 160             ; go to next row
    MOV ES:[DI], AX         ; print left
    MOV ES:[DI + BX], AX    ; print right

    LOOP leftRightLoop


ADD DI, 160                 ; go to next row
MOV AL, [SI+bLCorner]       ; move bottom left corner into AL
MOV ES:[DI], AX             ; print colored bottom left corner


MOV AL, [SI+bRCorner]       ; move bottom right corner into AL
MOV ES:[DI + BX], AX        ; print colored bottom right corner


MOV AL, [SI+horizontal]     ; move horizontal piece into AL
MOV CL, [boxWidth]          ; set counter to inner width
SUB CX, 1

bottomLoop:
    ADD DI, 2               ; go to next column
    MOV ES:[DI], AX         ; print 

    LOOP bottomLoop      


MOV DI, location            ; set DI to upper left corner
MOV CL, [boxWidth]          ; set counter to inner width (16)
SUB CX, 1

topLoop:
    ADD DI, 2               ; go to next column
    MOV ES:[DI], AX         ; print 

    LOOP topLoop   

POP DI SI CX BX AX
RET

drawBox ENDP


;====================


MyCode ENDS

;====================

end myMain