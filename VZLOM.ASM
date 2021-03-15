.model tiny

.code

org 100h

Main:
    mov dx, offset input
    mov bx, dx
    mov al, 10
    mov byte ptr ds:[bx], al
    mov ah, 0ah
    int 21h
    inc dx
    inc dx

    xor di, di ; fctors
    xor bx, bx ; input
    mov cx, 'a'

Repeat:
    cmp input:[bx], cx
    jne NoPermission
    inc bx
    mov dx, input:[bx]
    mov si, dx
    mov ax, byte ptr fctors:[di]
    dec ax
    MRepeat:
        add dx, si
        dec ax
        cmp ax, 0
        jne MRepeat
    inc bx
    mov ax, input:[bx]
    add ax, dx
    xor dx, dx
    mov cx, 26
    div cx



    cmp input:[bx], 0dh

    inc bx
    mov byte ptr ax, ds:[bx]
    xor ah, ah
    inc bx
    inc dx
    add bx, ax
    mov cl, '$'
    mov byte ptr ds:[bx], cl
    sub bx, ax
    mov ah, 09h
    int 21h

    mov ax, 4c00h
    int 21h



input db 254 dup (0)
fctors db 'gh74uvxlolevangelion', 0


end Main




































;пароль - первый символ спрятан, каждый последующий получается по формуле
;symb -> (17*symb + 11) % 26 (0 - 'a', 1 - 'b', ...)

;первые 10 символов считаются паролем
