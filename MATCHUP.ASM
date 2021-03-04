; MatchUp - A memory matching game
; developed in x86 asm to target a
; 512 byte floppy disk boot sector

; The COM file will be a slightly
; larger file with added features

; by Aron Hoekstra
; 2020-2021

%ifndef com_file
  com_file: equ 1
%endif


cards:        equ 0x0A00     ;mem loc for the randomized cards
mask:         equ 0x0A30     ;mem loc for card statuses
selected:     equ 0x0A90     ;mem loc for the currently selected card
guess1:       equ 0x0A92     ;mem loc for the 1st card guessed
guess2:       equ 0x0A94     ;mem loc for the 2nd card guessed
status:       equ 0x0A96     ;mem loc for the current status
lastact:      equ 0x0A98     ;mem loc for the last action
%if com_file
  lastkp:     equ 0x0A9A     ;mem loc for the last keypress (used for sound)
%endif

mHide:        equ 0          ;Hidden Status (shows card as a block symbol)
mGuess:       equ 1          ;Chosen Guess Status
mFound:       equ 2          ;Previous-found card status
gridStart:    equ 0x0144     ;Position on screen to start the grid drawing

gridWidth:    equ 6          ;How many cards wide should the grid be? (cols)
gridHeight:   equ 4          ;How many cards tall should the grid be? (rows)

;MUST result in an even number and be <= 48
gridSize:     equ (gridWidth*gridHeight)

%if com_file
  org 0x0100
%else
  org 0x7C00
%endif

start:
    mov ax,0x0000            ;Set screen mode 1
    int 0x10                 ;tell the BIOS to switch modes
    cld
    mov ax,0xb800
    mov ds,ax
    mov es,ax
    xor di,di
    mov si,clear_selection   ;SI as a space saver for CALL

%if com_file
title:
    mov di,0x001A
    mov ah,0x04
    mov al,'A'
    stosw
    mov al,'S'
    stosw
    mov al,'M'
    stosw
    mov al,' '
    stosw
    mov al,'M'
    stosw
    mov al,'a'
    stosw
    mov al,'t'
    stosw
    mov al,'c'
    stosw
    mov al,'h'
    stosw
    mov al,'-'
    stosw
    mov al,'U'
    stosw
    mov al,'p'
    stosw
%endif

; Randomize our cards, adding pairs to our memory addresses
; loop 24 times (48 cards/2 for pairs)
    call init
    call randomize
%if com_file
  call draw_grid
%endif

game_loop:
    call draw_cards
    call check_win
    call process_input
%if com_file
    call tone
%endif
    jmp game_loop

exit:
    mov ax,0x0002  ; set mode 80x25 text
    int 0x10       ; video interruption vector
    int 0x20       ; Exit to command line

process_input:
    mov ah,0x00    ; Load AH with code for keyboard read
    int 0x16       ; Call the BIOS for reading keyboard

    %if com_file
      mov bx,lastkp
    %endif
    cmp ah,0x48    ; up arrow
    je pi_up
    cmp ah,0x50    ; down arrow
    je pi_down
    cmp ah,0x4B    ; left arrow
    je pi_left
    cmp ah,0x4D    ; right arrow
    je pi_right
    cmp al,0x0D    ; enter key
    je pi_enter
    %if com_file
      cmp al,'x'     ; x for exit
      je exit
      cmp al,' '   ; space bar
      je pi_enter
    %endif
    jmp process_input
pi_up:
    %if com_file
      cs mov word [bx],6000
    %endif
    call si        ; clear_selection
    cs cmp byte [bx],gridWidth
    jb pi_cont
    cs sub byte [bx],gridWidth
    ret
pi_down:
    %if com_file
      cs mov word [bx],9000
    %endif
    call si        ; clear_selection
    cs cmp byte [bx],(gridSize-gridWidth-1)
    ja pi_cont
    cs add byte [bx],gridWidth
    ret
pi_left:
    %if com_file
      cs mov word [bx],8000
    %endif
    call si        ; clear_selection
    cs cmp byte [bx],0
    je pi_cont
    cs sub byte [bx],1
    ret
pi_right:
    %if com_file
      cs mov word [bx],7000
    %endif
    call si                  ; clear_selection
    cs cmp byte [bx],(gridSize-1)
    je pi_cont
    cs add word [bx],1
    ret
pi_enter:
    %if com_file
      cs mov word [bx],4000
    %endif
    call si                  ; clear_selection
    cs mov byte dl,[bx]      ; load the value

    mov bx,mask              ; load the card masks
    add bx,dx                ; set the right position

    cs mov cx,[bx]           ; load the current mask value
    cmp cl,mHide             ; make sure its mHide
    jne pi_cont              ; if not, make user pick another card
    cs mov byte [bx],mGuess  ; set it as a 'guess' (show the card)

    mov bx,status            ; load status
    cs cmp byte [bx],1       ; check if its 1
    ja pi_enter2             ; if so, go check if we have a match
    cs mov byte [bx],2       ; otherwise set status to 1
    mov bx,guess1            ;
    cs mov byte [bx],dl      ; store this as guess1
    ret
pi_enter2:
    cs mov byte [bx],1       ; set it back to 1
    mov bx,guess2            ;
    cs mov byte [bx],dl      ; store this as guess2
    mov bx,cards             ; load the cards
    push bx
    add bx,dx                ; set the position of this selected card
    cs mov byte cl,[bx]      ; put the card value into cx

    mov bx,guess1            ; load the first guess
    cs mov dx,[bx]           ; put the value in dx
    pop bx                   ; reload the cards
    add bx,dx                ; set the right position
    cs mov byte bl,[bx]      ; put the first card value into bx

    cmp byte bl,cl           ; see if they match
    je found_match
    ;no match found
    mov bx,lastact
    cs mov byte [bx],mHide   ; set last act as Hide

    jmp pi_cont
found_match:
    mov bx,lastact
    cs mov byte [bx],mFound   ; set last act as Found

    %if com_file
      mov bx,lastkp
      cs mov word [bx],1000
    %endif

    mov bx,guess1            ; load the first guess
    cs mov dx,[bx]           ; put the value in dx
    mov bx,mask              ; load the cards again
    push bx
    add bx,dx                ; set the right position
    cs mov byte [bx],mFound  ; put the first card value into bx
    mov bx,guess2            ; load the second guess
    cs mov dx,[bx]           ; put the value in dx
    pop bx                   ; reload the mask address
    add bx,dx                ; set the right position
    cs mov byte [bx],mFound  ; put the first card value into bx

pi_cont:
    ret

randomize:
    mov cx,0

lrc:
    call rand_card      ; call once for first card
    call rand_card      ; call again for its pair
    inc cx
    cmp cx,(gridSize/2)
    jne lrc
    ret

rand_card:
    push cx
rnc:
    in al,(0x40)   ; Read the timer counter

    mov cx,0xffff
wat:
    nop
    loop wat

    mov ch,gridSize; 48 for limit
    mov ah,0       ; extend al to 16 bit
    div ch         ; do division
    mov al,ah      ; put 0-48 remainder in al (random #)
    cbw            ; convert al byte to word ax to use add
    mov bx,cards   ; load the cards array
    add bx,ax      ; get the random position
    cs mov al,[bx] ; load the value at this position
    cmp al,0       ; see if this value is null
    jne rnc        ; if not null (already filled) then choose a new random #

    pop cx         ; restore the char position
    push bx        ; save the random position

    mov bx,chars   ; load the chars
    add bx,cx      ; set the current position in chars
    cs mov al,[bx] ; get the char at that position

    pop bx         ; restore the random position
    cs mov [bx],al ; save the value of the char in the random position
    ret

init:
    mov bx,cards
    mov cx,155
ivc:
    cs mov byte [bx],0
    inc bx
    loop ivc

clear_selection:
    ;only run this if we're on the first guess
    mov bx,status
    cs cmp byte [bx],1       ; check if its 1
    jne cs1
    mov bx,lastact
    cs mov cx,[bx]

    mov bx,guess1            ; load the first guess
    cs mov dx,[bx]           ; put the value in dx
    mov bx,mask              ; load the mask
    push bx
    add bx,dx                ; set the right position
    cs mov byte [bx],cl      ; put the first card value into bx

    mov bx,guess2            ; load the second guess
    cs mov dx,[bx]           ; put the value in dx
    pop bx                   ; reload the mask
    add bx,dx                ; set the right position
    cs mov byte [bx],cl      ; put the first card value into bx
cs1:
    mov bx,selected          ; get the selected char
    ret

%if com_file
draw_grid:
    mov ah,0x0f
    mov di,gridStart
    call draw_grid_top
    add di,80-((gridWidth*4)+2)
    mov cx,gridHeight-1
dg:
    call draw_grid_empty
    add di,80-((gridWidth*4)+2)
    call draw_grid_separator
    add di,80-((gridWidth*4)+2)
    loop dg
    call draw_grid_empty
    add di,80-((gridWidth*4)+2)
    call draw_grid_bottom
    ret

draw_grid_top:
    mov al,0xC9 ;top left corner
    stosw
    push cx
    mov cx,gridWidth-1
dgt:
    mov al,0xCD
    stosw
    mov al,0xD1
    stosw
    loop dgt

    mov al,0xCD
    stosw
    mov al,0xBB
    stosw
    pop cx
    ret

draw_grid_empty:
    push cx
    mov al,0xBA
    stosw
    mov cx,gridWidth-1
dge:
    mov al,0x20
    stosw
    mov al,0xB3
    stosw
    loop dge
    mov al,0x20
    stosw
    mov al,0xBA
    stosw
    pop cx
    ret

draw_grid_separator:
    push cx
    mov al,0xC7
    stosw
    mov cx,gridWidth-1
dgs:
    mov al,0xC4
    stosw
    mov al,0xC5
    stosw
    loop dgs
    mov al,0xC4
    stosw
    mov al,0xB6
    stosw
    pop cx
    ret

draw_grid_bottom:
    mov al,0xC8 ;bottom left corner
    stosw
    push cx
    mov cx,gridWidth-1
dgb:
    mov al,0xCD
    stosw
    mov al,0xCF
    stosw
    loop dgb
    mov al,0xCD
    stosw
    mov al,0xBC
    stosw
    pop cx
    ret
%endif

draw_cards:
    mov di,gridStart+82 ; start at the first empty position
    mov ah,0x1F         ; set the color
    mov cx,gridWidth    ; counter for rows
    mov dx,0            ; counter for card index
dc1:
    mov bx,mask         ; load the card masks
    add bx,dx           ; go the right location
    cs mov al,[bx]      ; get the current card mask
    cmp al,mHide        ; should the card be hidden?
    je dc_hidden        ; jump to hide card
    mov bx,cards        ; load the cards
    add bx,dx           ; go to the right location
    mov ah,0x12         ; set default blue bg, green fg
    cmp al,mFound
    cs mov al,[bx]      ; grab the card
    jne dc2_1
    mov ah,0x08         ; set default blue bg, gray fg
    jmp dc2_2
dc_hidden:
    mov ax,0x12B1       ; set default blue bg, green fg, block chr 177
dc2_1:
    mov bx,selected     ; see if this card is curretly selected
    cs mov bl,[bx]      ; load the selected index
    cmp dl,bl           ; compare
    jne dc3             ; if not, jump & show using default
    mov ah,0x2E         ; selected - set 5blue bg, yellow fg
    jmp dc3
dc2_2:
    mov bx,selected     ; see if this card is curretly selected
    cs mov bl,[bx]      ; load the selected index
    cmp dl,bl           ; compare
    jne dc3             ; if not, jump & show using default
    mov ah,0x28         ; selected - set 5blue bg, yellow fg

dc3:
    stosw
    loop dc4            ; if cx=0
    add di,160-((gridWidth*4))
    mov cx,gridWidth    ; reset the row counter
dc4:
    add di,2            ; position to next space
    inc dx              ; increase our card index
    cmp dx,gridSize     ; see if we've processed all 48 cards
    jb dc1              ; if not, repeat for next card
    ret

check_win:
    mov bx,mask
    mov cx,gridSize
cw1:
    cs mov dl,[bx]
    cmp dl,mFound
    jne cw2
    inc bx
    loop cw1
    %if com_file
      mov cx,0x03
      mov bx,lastkp

cw3:
      mov bx,lastkp
      cs mov word [bx],3000
      push bx
      push cx
      call tone
      call tone
      call tone
      call tone
      call tone
      call tone
      pop cx
      pop bx
      cs mov word [bx],2000
      push bx
      push cx
      call tone
      call tone
      call tone
      call tone
      call tone
      call tone
      pop cx
      pop bx
      cs mov word [bx],1000
      push bx
      push cx
      call tone
      call tone
      call tone
      call tone
      call tone
      call tone
      pop cx
      pop bx
      loop cw3
    %endif

    jmp start
cw2:
    ret

%if com_file
tone:
    mov al,182
    out 0x43,al
    mov bx,lastkp
    cs mov ax,[bx]
    ;mov ax,250
    out 0x42,al
    mov al,ah
    out 0x42,al
    in  al,0x61
    or  al,00000011b
    out 0x61,al
    mov bx,5
.pause1:
    mov cx,65535
.pause2:
    dec cx
    jne .pause2
    dec bx
    jne .pause1
    in  al,0x61
    and al, 11111100b
    out 0x61,al
    ret
%endif

chars:        db 1,2,3,4,5,6,14,15,18,21,33,127,232,155,157,168,225,227,234,236,240,247,251,254

%if com_file
%else
  times 510-($-$$) db 0x4f
  db 0x55,0xaa
%endif
