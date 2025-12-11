; FreeBSDで、シスコール番号を調べるには：/usr/include/sys/syscall.h
; Linuxで、シスコール番号を調べるには：/usr/include/asm-generic/unistd.h
; 下記のコードはFreeBSD向けの物です。

bits 64
default rel

section .data

section .rodata
  basename db "output-",0
  suffix db ".ppm", 0
  hdr db "P6", 10, "960 540", 10, "255", 10

  err db "開くに失敗", 10
  errlen equ $-err
  suc db "60フレームを作成しました。", 10
  suclen equ $-suc

  w equ 960
  h equ 540

section .bss
  buf resb 960*540*3
  outfile resb 64     ; "output-nn.ppm\0"

section .text
  global _start

_start:
  mov r12, 0          ; i = 0

frameloop:
  ; ファイル名
  lea rdi, [outfile]
  lea rsi, [basename]
  call strcpy

  ; iは2つの文字に変換
  mov rax, r12
  mov rcx, 10
  xor rdx, rdx
  div rcx             ; rax = 10, rdx = 01

  add al, '0'
  add dl, '0'
  mov [rdi], al  ; 10
  mov [rdi+1], dl; 01
  add rdi, 2

  lea rsi, [suffix]
  call strcpy         ; 「.ppm\0」の追加

  mov rax, 5          ; sys_open
  lea rdi, [outfile]
  mov rsi, 0x100601   ; 0x100601 = 0001 0000 0000 0110 0000 0001 = 1048576 + 1024 + 512 + 1 = 1050113
                      ;   O_WRONLY  = 0x0001
                      ;   O_CREAT   = 0x0200
                      ;   O_TRUNC   = 0x0400
                      ;   O_CLOEXEC = 0x010000
                      ; /usr/include/sys/fcntl.h
  mov rdx, 0o666      ; chmod 666
  syscall

  test rax, rax
  js error            ; エラーがあれば
  mov r15, rax        ; ファイルディスクリプターをrbxに保存

  ; ヘッダーの書き込み
  mov eax, 4          ; sys_write
  mov rdi, r15        ; fd
  lea rsi, [hdr]
  mov rdx, 18
  syscall

  ; チェッカーボードループ
  lea rdi, [buf]
  mov rcx, h
  xor r13, r13

yloop:
  mov r8d, w

xloop:
  ; (x/60 + y/60) % 2の計算
  mov eax, r8d        ; x
  add eax, r12d       ; x + i
  xor edx, edx
  mov ebx, 60
  div ebx             ; eax = (x + i)/60
  push rax

  mov eax, r13d
  add eax, r12d       ; y + i
  xor edx, edx
  div ebx             ; eax = (y + i)/60

  pop rdx
  add eax, edx        ; (x + i)/60 + (y + i)/60
  and al, 1           ; % 2
  jz .black

.green:
  mov al, 0
  stosb               ; R
  mov al, 0xFF
  stosb               ; G
  mov al, 0
  stosb               ; B
  jmp .next

.black:
  xor eax, eax
  stosb
  stosb
  stosb

.next:
  dec r8d
  jnz xloop

  inc r13d
  dec rcx
  jnz yloop

  ; ピクセルデータの書き込み
  mov eax, 4
  mov rdi, r15
  lea rsi, [buf]
  mov edx, 960*540*3
  syscall

close:
  mov rax, 6          ; sys_close
  mov rdi, r15
  syscall

  inc r12
  cmp r12, 60
  jb frameloop

  mov rax, 4
  mov rdi, 1
  lea rsi, [suc]
  mov rdx, suclen
  syscall

end:
  mov eax, 1          ; sys_exit
  xor edi, edi
  syscall

error:
  mov rax, 4
  mov rdi, 2          ; stderr
  lea rsi, [err]
  mov rdx, errlen
  syscall

  mov rax, 1
  mov rdi, 1
  syscall

strcpy:
.loop:
  mov al, [rsi]
  mov [rdi], al
  test al, al
  jz .done
  inc rdi
  inc rsi
  jmp .loop

.done:
  ret
