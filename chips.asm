Chips

;   calling convention:
;
;       int chips( void );
;
;   returns:
;
;       tucked away neatly in your AX....
;
;       you get back   8x if an 8088/8086
;                     18x if an 80186/80188
;                     28x if an 80286
;                     38x if an 80386
;                     20x for a NEC V20/V30
;                AND
;                     xx0 if NO NDP is found
;                     xx1 if an 8087
;                     xx2 if an 80287
;                     xx3 for an 80387
;
;   OR.....
;
;   >>> A return of 280 means you got an 80286 machine with no NDP, <<<
;   >>> 383 means you have an 80386/80387 rig to work with, and a   <<<
;   >>> return of 81 sez that you have 8088/8086 CPU with an 8087.  <<<
;   >>> A 200 tells you that you got an NEC V20/V30 without an NDP. <<<
;   >>> ETC., Etc., etc.                                            <<<
;
;   NOTE:
;
;       There are lotsa ways of handling the way this function returns
;       it's data.  For my purposes, I have elected this one because
;       it requires only int arithmetic on the caller's end to extract
;       all the info I need from the return value.  I think that I'm
;       well enough 'commented' in the following code so that you will
;       be able to tinker and Putz until you find the best return tech-
;       nique for Ur purposes without having to reinvent the wheel.
;
;     >>>>        Please see TEST.C, enclosed in this .ARC.      <<<<
;
;   REFERENCES:
;
;     _chips is made up of two PROC's, cpu_type and ndp_type.
;
;       cpu_type is based on uncopyrighted, published logic by
;         Clif (that's the way he spells it) Purkiser of Intel -
;         Santa Clara.
;
;       ndp_type is adopted from Ted Forgeron's article in PC
;         Tech Journal, Aug '87 p43.
;
;     In the event of subsequent republication of this function,
;       please carry forward reference to these two gentlemen as
;       original authors.
;
.MODEL SMALL
.CODE
        PUBLIC  _chips

_chips         PROC

control dw     0              ; control word needed for the NDP test

        push   BP             ; save where Ur at
        mov    BP,SP          ;   going in.....

        push   DI
        push   SI
        push   CX             ; not really needed for MSC but kinda
                              ;   nice to do cuz someone else might
                              ;   want to use the function and we do
                              ;   use CX later on

        call   cpu_type       ; find out what kinda CPU you got and
                              ;   and save it in DX for future reference
        call   ndp_type       ; check for math coprocessor (NDP) type
                              ;   and hold that result in AX

        add    AX,DX          ; add the two results together and hold
                              ;   'em in AX for Ur return to the caller

        pop    CX             ; put things back the way that you
        pop    SI             ;   found 'em when you started this
        pop    DI             ;   little drill off.....
        pop    BP
                              ; AND
        ret                   ; go back to where you came from....
                              ;   ( ===>  the calling program )
                              ;   with Ur results sittin' in AX !!
_chips         endp


cpu_type       PROC

        pushf                 ; pump Ur flags register onto the stack
        xor    DX,DX          ; blow out Ur DX and AX to start off
        xor    AX,AX          ;   with a clean slate
        push   AX             ; put AX on the stack
        popf                  ; bring it back in Ur flags
        pushf                 ; try to set bits 12 thru 15 to a zero
        pop    AX             ; get back Ur flags word in AX
        and    AX, 0f000h     ; if bits 12 thru 15 are set then you got
        cmp    AX, 0f000h     ;   an Intel 8018x or a 808x or maybe even
        jz     dig            ;   a NEC V20/V30 ??? - gotta look more...

; OTHERWISE....
;   Here's the BIG one.... 'tells the difference between an 80286 and
;   an 80386 !!

        mov    AX, 07000h     ; try to set FLAG bits 12 thru 14
                              ;   - NT, IOPL
        push   AX             ; put it onto the stack
        popf                  ;   and try to pump 07000H into Ur flags
        pushf                 ; push Ur flags, again
        pop    AX             ;   and bring back AX for a compare
        and    AX,07000h      ; if Ur bits 12 thru 14 are set
        jnz    got386         ;   then Ur workin' with an 80386
        mov    DX, 0280       ; save 280 in DX cuz it's an 80286
        jmp    SHORT CPUbye   ;   and bail out

got386: mov    DX, 0380       ; save 380 in DX cuz it's an Intel 80386
        jmp    SHORT CPUbye   ;   and bail out

; here's we try to figger out whether it's an 80188/80186, an 8088/8086
;   or an NEC V20/V30 - 'couple of slick tricks from Clif Purkiser.....

dig:    mov    AX, 0ffffh     ; load up AX
        mov    CL, 33         ; HERE's the FIRST TRICK.... this will
                              ;   shift everything 33 times if it's
                              ;   8088/8086, or once for a 80188/80186!
        shl    AX, CL         ; on a shift of 33, all bits get zeroed
        jz     digmor         ;   out so if anything is left ON it's
                              ;   gotta be an 80188/80186
        mov    DX,0180        ; save 180 in DX cuz it's an 80188/80186
        jmp    SHORT CPUbye   ;   and bail out

digmor: xor    AL,AL          ; clean out AL to set ZF
        mov    AL,40h         ; ANOTHER TRICK.... mul on an NEC duz NOT
        mul    AL             ;   effect the zero flag BUT on an Intel
        jz     gotNEC         ;   8088/8086, the zero flag gets thrown
        mov    DX,0080        ; 80 into DX cuz it's an Intel 8088/8086
        jmp    SHORT CPUbye   ;   and bail out

gotNEC: mov    DX,0200        ; it's an NEC V20/V30 so save 200 in DX

CPUbye: popf                  ; putchur flags back to where they were
        ret                   ;   and go back to where you came from
                              ;   (i.e., ===>  _chips) with the CPU type
                              ;   tucked away in DX for future reference
cpu_type       endp

; Check for an NDP.
;
; >>>>NOTE:  If you are using an MASM version < 5.0, don't forget to
; use the /R option or you will bomb cuz of the coprocessor instruc-
; tions.  /R is not needed for version 5.0.<<<<<<<<<<<<<<<<<<<<<<<<<

ndp_type       PROC

do_we:  fninit                          ; try to initialize the NDP
        mov    byte ptr control+1,0     ; clear memory byte
        fnstcw control                  ; put control word in memory
        mov    AH,byte ptr control+1    ; iff AH is 03h, you got
        cmp    AH,03h                   ;   an NDP on board !!
        je     chk_87                   ; found somethin', keep goin'
        xor    AX,AX                    ; clean out AX to show a zero
        jmp    SHORT NDPbye             ;   return (i.e., no NDP)

; 'got an 8087 ??

chk_87: and    control,NOT 0080h        ; turn ON interrupts (IEM = 0)
        fldcw  control                  ; load control word
        fdisi                           ; turn OFF interrupts (IEM = 1)
        fstcw  control                  ; store control word
        test   control,0080h            ; iff IEM=1, 8087
        jz     chk287                   ; 'guess not!  March on....
        mov    AX,0001                  ; set up for a 1 return to
        jmp    SHORT NDPbye             ;   show an 8087 is on board

; if not.... would you believe an 80287 maybe ??

chk287: finit                 ; set default infinity mode
        fld1                  ; make infinity
        fldz                  ;   by dividing
        fdiv                  ;   1 by zero !!
        fld    st             ; now make a
        fchs                  ;   negative infinity
        fcompp                ; compare Ur two infinities
        fstsw  control        ; iff, for 8087 or 80287
        fwait                 ; sit tight 'til status word is put away
        mov    AX,control     ; getchur control word
        sahf                  ; putchur AH into flags
        jnz    got387         ; NO GOOD.... march on !!
        mov    AX,0002        ; gotta be a 80287 cuz we already tested
        jmp    SHORT NDPbye   ;   for an 8087

; We KNOW that there is an NDP on board otherwise we would have bailed
; out after 'do_we'.  It isn't an 8087 or an 80287 or we wouldn't have
; gotten this far.  It's gotta be an 80387 !!

got387: mov    AX,0003        ; call it an 80387 and return 3

NDPbye: ret                   ; and go back where you came from
                              ;   (i.e., ===>  _chips) carrying the NDP
                              ;   type in Ur AX register
ndp_type       endp

_text   ends
        end
