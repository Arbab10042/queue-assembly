[org 0x0100]

push 0
call qcreate
pop ax

push 0
call qcreate
pop ax

push 0
call qcreate
pop ax

mov cx, 30

push 0
push 2
push 0x0
call qadd
pop ax

push 0
push 0
push 2
call qremove
pop dx
pop ax

push 0
push 0
push 2
call qremove
pop dx
pop ax

push ax
call qdestroy


mov ax, 0x4c00
int 0x21

qcreate:
        push bp
        mov bp, sp
        pusha

        mov ax, -1              ;intially no free space has been found 
        mov bx, [status]
        mov cx ,0

        _loop:
                shr bx, 1
                jnc setStatus

                add cx, 1
                cmp cx, 16
                jz end
                jmp _loop

        end:
                mov [bp+4], ax
                popa
                pop bp
                ret

        setStatus:
                mov ax, cx
                add cx, 1               ;shift at least once
                mov bx, 0               ;mask
                mov dx, 1
                shr dx, 1               ;setting carry flag

        setLoop:
                rcl bx, 1
                loop setLoop

                or [status], bx
                mov si, ax
                shl si, 1                       ;multiplying si by 2
                mov word [frontIndex+si], 0     ;set front and read index
                mov word [rearIndex+si], 2      ;rear index comes in the next memory after front
                jmp end

;--------------------------------------------------------

qdestroy:
        push bp
        mov bp, sp
        pusha
        
        mov ax, 0               ;mask
        mov cx, [bp+4]
        add cx, 1
        mov dx, 1
        shr dx, 1               ;set CF

        desLoop:
                rcl ax, 1
                loop desLoop

        xor [status], ax        ;sets bit of queue to 0

        push word [bp+4]
        call resetData

        popa
        pop bp
        ret 2

;--------------------------------------------------------

qadd:
        push bp
        mov bp, sp
        pusha

        mov cx, [bp+6]
        add cx, 1            ;if queue is not being used then return 0      
        push 0
        push cx
        call checkBit           ;checks bit in status corresponding to the value in cx 
        pop ax
        cmp ax, 0
        jz return   

        mov ax, 64              ;skip this many words according to the queue number
        mov si, [bp+6]          ;queue number in si
        mov di, [rearIndex+si]
        add word [rearIndex+si], 2
        cmp word [rearIndex+si], 64
        ja resizeRear
        jmp addData
        resizeRear:
                mov word [rearIndex+si], 2
                mov di, [rearIndex+si]
                add word [rearIndex+si], 2 
        addData:
                mul si
                mov si, ax

                mov dx, [bp+4]          ;value to be added moved to dx
                add si, di
                mov word [array+si], dx

        return:
                mov [bp+8], ax
                popa
                pop bp
                ret 4

;--------------------------------------------------------

qremove:
        push bp
        mov bp, sp
        pusha

        mov cx, [bp+4]          ;queue number in cx

        push 0
        add cx, 1
        push cx
        call checkBit           ;checks bit in status corresponding to the value in cx 
        pop dx

        cmp dx, 0
        jz Return

        push 0
        push word [bp+4]
        call removeData
        pop ax

        Return:
                mov [bp+8], ax
                mov [bp+6], dx
                popa
                pop bp
                ret 2

;--------------------------------------------------------

;This function checks if the status bit is on or off
;Returns 0 if bit is off, returns 1 if bit is on
checkBit:
        push bp
        mov bp, sp
        pusha

        mov cx, [bp+4]
        mov bx, [status]
        bitLoop:
                mov ax, 0               ;reset ax
                shr bx, 1
                rcl ax, 1               ;move carry in ax
                loop bitLoop

        mov word [bp+6], ax
        popa
        pop bp
        ret 2

;--------------------------------------------------------

;This functions changes the front index of queue
removeData:
        push bp
        mov bp, sp
        pusha

        mov ax, 64
        mov si, [bp+4]
        mov di, [frontIndex+si]
        add word [frontIndex+si], 2
        cmp word [frontIndex+si], 64
        jnz continueRemove
        mov word [frontIndex+si], 0
        
        continueRemove:
                mov di, [frontIndex+si]
                mul si
                mov si, ax
                add si, di
                mov ax, [array+si]
                mov word [array+si], 0

                mov [bp+6], ax
                popa
                pop bp
                ret 2

;--------------------------------------------------------

;This function resets data when a queue is destroyed
resetData:
        push bp
        mov bp, sp
        pusha

        mov si, [bp+4]
        mov word [frontIndex+si], -1
        mov word [rearIndex+si], -1
        mov ax, 64
        mul cx
        mov si, ax
        mov cx, 30
        resetLoop:
                mov word [array+si], 0
                add si, 2
                loop resetLoop

        popa
        pop bp
        ret 2
;--------------------------------------------------------

;16x32 words of data fo0r 16 queues 
array: times 512 dw 0
;front and rear index for each queue
frontIndex: times 16 db -1
rearIndex: times 16 db -1
status: dw 0000000000000000b