bits 64

global _myPrintf

SyntaxError equ  1
TooMany     equ  2


section .data

BCDOSX dd PrintPerc, 0, PrintBin, 0, PrintChar, 0, PrintDec, 0, PrintOct, 0, PrintStr, 0, PrintHex, 0
alph db '0123456789ABCDEF'
msg db 'hello', 10, 0
fmstr db '%c%c', 0

;****************************
section .bss               ;*
OldRBP resq 1
OldRSP resq 1
OldRBX resq 1
RetAdr resq 1
ProcessDataRet resq 1      ;*
;****************************



section .text

_myPrintf:
        
        mov qword [OldRBP], rbp                 ;save RBP
        mov qword [OldRBX], rbx                 ;save RBX

        pop rbp                                 ;ret adr
        mov [RetAdr], rbp
        pop rbp                                 ;old rsp
        mov [OldRSP], rbp

        push r9 
        push r8 
        push rcx 
        push rdx 
        push rsi
        mov rsi, rdi
        lea r9, [rsp + 8*5] ; r9 хранит rsp с которым надо будет вернуться 

        
        call ParseData

        xor rax, rax
        mov rbx, [OldRBX]
        mov rsp, r9
        mov rbp, [OldRSP]
        push rsp
        mov rbp, [RetAdr]
        push rbp
        mov rbp, [OldRBP]


        
        
        ret

	Exit:
        mov rax, 1
        mov rbx, 0
        int 0x80
     




;**********************************************************************************************
;ebp - начало строки, esi - конец строки, esp - данные                                       ;*
;rax - not used
;rbx - not used
;rcx - not used
;rdx - not used
;rsi - итерирует строку
;rdi - not used
;rbp - итерирует строку
;rsp - итерирует данные
ParseData:
        pop rbx
        mov [ProcessDataRet], rbx

        
        ;xor rcx, rcx
        mov rbp, rsi
    ParseDataLoop:
        
        cmp byte [rsi], '%'
        je ParseDataPrint
        cmp byte [rsi], 0
        je ParseDataEnd
        
        inc rsi
        
        jmp ParseDataLoop

    ParseDataPrint:
        push rdi
        push rsi

        mov rax, 1
        mov rdi, 1
        
        mov rdx, rsi
        sub rdx, rbp
        mov rsi, rbp
        

        syscall
        
        pop rsi
        pop rdi
        
        lodsw
        and rax, 0xFF00
        push rsi
        call UpdArray
        shr rax, 8
        call [BCDOSX + rax*8] ; вызываем процедуру, соответствующую процентику
        
        pop rbp
        jmp ParseDataLoop

    ParseDataEnd:
        
        mov rax, 1
        mov rdi, 1
        mov rdx, rsi
        sub rdx, rbp
        mov rsi, rbp
        syscall
        mov rbx, [ProcessDataRet]
        jmp rbx
                                                                                             ;*      
;**********************************************************************************************
        
        

;**********************************************************************************************
; ah := index( ['%','b','c','d','o','s','x'], ah )                                           ;*
; в случае ошибки возводит в 1 старший бит cx
UpdArray:
        cmp ah, 'd'
		ja UpdArrOSX
		jb UpdArrPBC
		mov ah, byte 3
		ret

	UpdArrOSX:
		cmp ah, 's'
		ja UpdArrMaybeX
		jb UpdArrMaybeO
		mov ah, byte 5
		ret

	UpdArrMaybeX:
		cmp ah, 'x'
		jne UpdArrUnknown
		mov ah, byte 6
		ret
	
	UpdArrMaybeO:
		cmp ah, 'o'
		jne UpdArrUnknown
		mov ah, byte 4
		ret

	UpdArrPBC:
		cmp ah, 'b'
		ja UpdArrMaybeC
        jb UpdArrMaybeP
        mov ah, byte 1
		ret
	
    UpdArrMaybeP:
        cmp ah, '%'
        jne UpdArrUnknown
        mov ah, byte 0
		ret

    UpdArrMaybeC:
        cmp ah, 'c'
        jne UpdArrUnknown
        mov ah, byte 2
		ret

	UpdArrUnknown:
		or cx, 8000h
		ret

;      
; end of UpdArray                                                                            ;*
;**********************************************************************************************






PrintChar:   ;ret adr | rsi | arg -> rsi
        
        mov rax, 1      ;write
        mov rdi, 1      ;stdout
        lea rsi, [rsp + 16]    ;pointer
        mov rdx, 1      ;len
        syscall

        pop rbx
        pop rsi
        add rsp, 8
        push rsi
        
        jmp rbx


PrintStr:    ;ret adr | rsi | arg -> rsi
        
        ;pop rbx
        mov rsi, [rsp + 16]
        call my_strlen
        mov rax, 1
        mov rdi, 1
        mov rsi, rcx
        syscall

        pop rbx
        pop rsi
        mov [rsp], rsi
        jmp rbx




PrintHex:       ;ret adr | rsi | arg -> rsi
        mov rbx, [rsp + 16]
        xor rdx, rdx

    PrintHexLoop:
        mov rcx, rbx
        and rcx, 0xF
        mov cl, [alph + rcx]
        dec rsp
        mov [rsp], byte cl
        inc rdx
        shr rbx, 4
        cmp rbx, 0
        jne PrintHexLoop


        mov rax, 1
        mov rdi, 1
        mov rsi, rsp
        syscall
        add rsp, rdx
        
        ;--
        pop rbx
        pop rsi
        mov [rsp], rsi
        jmp rbx

PrintOct:
        mov rbx, [rsp + 16]
        xor rdx, rdx

    PrintOctLoop:
        mov rcx, rbx
        and rcx, 0x7
        mov cl, [alph + rcx]
        dec rsp
        mov [rsp], byte cl
        inc rdx
        shr rbx, 3
        cmp rbx, 0
        jne PrintOctLoop


        mov rax, 1
        mov rdi, 1
        mov rsi, rsp
        syscall
        add rsp, rdx
        
        ;--
        pop rbx
        pop rsi
        mov [rsp], rsi
        jmp rbx

PrintBin:
        mov rbx, [rsp + 16]
        xor rdx, rdx

    PrintBinLoop:
        mov rcx, rbx
        and rcx, 0x1
        mov cl, [alph + rcx]
        dec rsp
        mov [rsp], byte cl
        inc rdx
        shr rbx, 1
        cmp rbx, 0
        jne PrintBinLoop


        mov rax, 1
        mov rdi, 1
        mov rsi, rsp
        syscall
        add rsp, rdx
        
        ;--
        pop rbx
        pop rsi
        mov [rsp], rsi
        jmp rbx 


;eax - число, edx - для нахождения остатка, ecx - счётчик цифр, ebx == 10
PrintDec:           ;ret adr | rsi | arg -> rsi
        
        mov rax, [rsp + 16]
        
        xor rcx, rcx
        mov rbx, 10

    PrintDecLoop:
        xor rdx, rdx
        div rbx  ; edx - остаток        
        mov dl, [alph + rdx]
        dec rsp
        mov [rsp], byte dl
        inc rcx
        cmp rax, 0
        jne PrintDecLoop

        ;mov rcx, rsi
        ;mov rbx, rdi
        mov rax, 1
        mov rdi, 1
        mov rdx, rcx
        mov rsi, rsp
        syscall
        add rsp, rdx
        ;mov rsi, rcx
    
        
        pop rbx
        pop rsi
        mov [rsp], rsi
        jmp rbx


PrintPerc:          ;ret adr | rsi | arg -> rsi
        pop rbx

        mov rax, 1
        mov rdi, 1
        dec rsp
        mov [rsp], byte '%'
        mov rsi, rsp
        mov rdx, 1
        syscall
        inc rsp

        jmp rbx     ;rsi corrupted



;**********************************************************************************************
;destr esi, ecx, eax, edx(?)                                                                 ;*
;returns: esi - last byte of string ([esi] == '\0'), edx - string length
;ecx - 1st byte of str
my_strlen:


        mov rdx, rsi
        mov rcx, rsi

        and rcx, 3
        cmp rcx, 0
        je Virovnyali

    SmallRepeat:
        mov rcx, rsi
        mov al, [rsi]
        cmp al, 0
        je Return
        inc rsi
        inc cx
        and cx, 3
        cmp cx, 0
        je SmallRepeat
    Virovnyali:
        mov rcx, 0xFEFEFEFEFEFEFEFF
        push rdx
    HugeRepeat:
        mov rdx, qword [rsi]
        mov rax, rdx
        add rdx, rcx
        not rax
        and rdx, rax
        and rdx, 0x8080808080808080
        cmp rdx, 0
        jne Check
        add rsi, 8
        jmp HugeRepeat
    
    Check:
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        cmp byte [rsi], 0
        je Return
        inc rsi
        jmp HugeRepeat

    Return:
        mov rdx, rsi
        pop rcx
        sub rdx, rcx
        ret
                                                                                             ;*
;**********************************************************************************************










;**********************************************************************************************
;*********************************Подпрограммы старых версий***********************************


;**********************************************************************************************
FormatString:       
                                                                                 ;*
        ;rsi - адрес начала данных
        xor rcx, rcx ; ecx - модификатор format
        mov rbp, rsi ; ebp is sticking

    RunThrBytes:
        cmp byte [rsi], '%'
        je UpdArrayCall
        cmp byte [rsi], 0
        je FormatStringEnd
        inc rsi
        jmp RunThrBytes

    UpdArrayCall:
        
        mov ax, [rsi]

        call UpdArray
        
        inc rsi
        mov [rsi], ah

        inc rcx
        inc rsi
        
        jmp RunThrBytes

    FormatStringSyntaxError:
		mov ax, SyntaxError
		ret
	
    FormatStringEnd:
        xor ax, ax
        ret
                                                                                             ;*
;**********************************************************************************************

;**********************************************************************************************
;в стеке лежит строка < %{b,c,d,o,s,x} несколько раз > < произвольные байты >                ;*
;подпрограмма достаёт из стека первую строку и заполняет параметрами массив format
;destr cx, ax, ebx
;returns ax - код ошибки (0 - успех)
;GetFormat:
;        pop ebx
;
;    ;esi - адрес начала данных
;        xor ecx, ecx
;
;	GetFormatRepeat:
;		pop ax
;		cmp al, '%'
;		jne GetFormatReturn
;		call UpdArray
;		cmp cx, 8000h
;		jle GetFormatSyntaxError
 ;       inc cx
;		cmp cx, MaxFlagsCnt
;		je GetFormatTooMany		
 ;   jmp GetFormatRepeat
;
;	GetFormatReturn:
;		push ax
;		xor ax, ax
 ;       mov [format + ecx], byte 0xFF
  ;      push ebx
	;	ret
;	GetFormatSyntaxError:
;		mov ax, SyntaxError
 ;       push ebx
	;	ret
	;GetFormatTooMany:
	;	mov ax, TooMany
     ;   push ebx
		;ret

;
; end of GetFormat                                                                           ;*
;**********************************************************************************************
;**********************************************************************************************
;destr cs, si                                                                                ;*
;ProcessData:
;        pop ebx
;        mov [ProcessDataRet], ebx
;		xor edi, edi
;        xor eax, eax
;        
;    ProcessDataRepeat:
;        mov al, [format + edi] 
;        cmp al, 0xFF
;        je ProcessDataReturn
;        
;        mov esi, dword [BCDOSX + eax * 4]
;        call esi
;        inc edi
;        jmp ProcessDataRepeat
;    
;    ProcessDataReturn:
;        mov ebx, [ProcessDataRet]
;        jmp ebx
;
; end of ProcessData                                                                         ;*
;**********************************************************************************************


;PrintBin: 
;        pop rdi
;        pop rbx
;        push rsi
;        
;        mov rcx, rbx
;        mov rax, 0x8000000000000000
;    Search1:
;        and rcx, rax
;        cmp rcx, 0
;        jne Found1
;        mov rcx, rbx
;        shr rax, 1
;        jmp Search1
;    Found1:
;        mov rcx, rax
;
;    FromPrint:
;        push rbx
;        push rdi
;        cmp rax, 0
;        lahf
;        and rax, 0x4000
;        shr rax, 14
;        neg rax
;        inc rax
;        lea rsi, [alph + rax]
;        mov rax, 4
;        mov rdi, 1
;        mov rdx, 1
;        syscall
;        pop rdi
;        pop rbx
;        shr rcx, 1
;        cmp rcx, 0
;        je PrintBinReturn
;        mov rax, rbx
;        and rax, rcx
;        jmp FromPrint
;        
;
;    PrintBinReturn:
;        pop rsi
;        jmp rdi
;
;




