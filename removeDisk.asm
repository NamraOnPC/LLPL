Ejects a SCSI tape (or CD-ROM) from a drive
Shows a working example of a program which uses ASPI. 

;   eject a tape (or CD) from a device
;
; note that this is a VERY terse code sample!  It is assumed that the 
; reader is already familiar with SCSI and ASPI to some degree.
;
        .MODEL small
        .STACK 1000h
        .386

;*                               structures                                  *
SCSIRequestBlock struc
        CommandCode     db      2               ; SCSI request
        Status          db      0               ; returned after command
        HostAdapterNum  db      0               ; default is 0 (first adapter)
        SCSIReqFlags    db      0               ;
        Reserved1       db      4 dup (0)       ;
        TargetID        db      0               ; set to device target ID
        LUN             db      0               ; defaults to 0
        DataLength      dd      0               ;
        SenseLength     db      16              ; usu. sufficient length 
        DataPointer     dd      0               ; no data
        SRBLinkPointer  dd      0               ; no linking
        CDBLength       db      10              ; always sufficient length 
        AdapterStatus   db      0               ; 
        TargetStatus    db      0               ;
        PostRoutinePtr  dd      0               ; no post routine is default
        ASPIWorkspace   db      34 dup (0)      ; req'd but not used
        CDB             db      10 dup (0)      ; SCSI Command Descriptor Blk
        SenseData       db      16 dup (0)      ; 
SCSIRequestBlock ends

        .DATA

DOS_OPEN_HANDLE  = 03dh
DOS_CLOSE_HANDLE = 03eh
DOS_IOCTL        = 044h
IOCTL_RX_CTL_DATA = 02h
DOS_INT         = 21h

ASPI_Entry      dd      ?
SRB SCSIRequestBlock   <>
crlf    equ   13,10
ErrMsg          db      "ERROR:  no ASPI manager detected. ",crlf,'$'
OKMsg           db      "All is well.",crlf,'$'
SCSIMgrString   db      "SCSIMGR$",0

        .CODE
begin proc
        .STARTUP
        call    GetASPIAddress          ;
        jnb     @@AllOK                 ;
        mov     dx, OFFSET ErrMsg       ;
        jmp     @@ErrorExit             ;
@@AllOK:
;
; here's the eject sequence
;
        mov     [(SRB.CDB) + 0],01Bh    ; load/unload command
        mov     [(SRB.CDB) + 4],0       ; 00 = unload, 01=load, 02=retension
        mov     [(SRB.TargetID)], 2     ; SCSI ID of target device
        push    SEG SRB                 ;
        push    OFFSET SRB              ;
        call    [ASPI_Entry]            ; sometimes it takes 2 requests
        call    [ASPI_Entry]            ;
        add     sp,4                    ;
        mov     dx,OFFSET OKMsg         ;
        xor     ah,ah                   ;
        mov     al,[(SRB.Status)]       ;
@@ErrorExit:                            ; ds:dx ==> ASCIIZ error string
        push    ax
        mov     ah,9                    ;
        int     21h                     ;
        pop     ax                      ;
@@NoError:
        .EXIT 0
begin endp

GetASPIAddress proc C
        push    bx
        push    cx
        push    ds
        xor     ax,ax                   ;
        mov     WORD PTR [ASPI_Entry],ax    ;
        mov     WORD PTR [ASPI_Entry+2],ax  ;
        lea     dx,[SCSIMgrString]      ;ds:dx ==> 'SCSIMGR' string
        mov     ah,DOS_OPEN_HANDLE      ; open request
        int     DOS_INT                 ;
        jb      @@exit                  ;
        mov     dx,ss                   ;
        mov     ds,dx                   ;
        lea     dx,[ASPI_Entry]         ;
        mov     cx,4                    ;
        mov     bx,ax                   ;
        mov     ax,DOS_IOCTL SHL 8 OR IOCTL_RX_CTL_DATA
        int     DOS_INT                 ;
        jb      @@exit                  ;
        mov     ah,DOS_CLOSE_HANDLE     ;
        int     DOS_INT                 ;
@@exit:
        pop     ds
        pop     cx
        pop     bx
        ret                             ;
GetASPIAddress endp

        END