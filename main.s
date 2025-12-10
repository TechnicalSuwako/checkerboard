; FreeBSDで、死すコール番号を調べるには：/usr/include/sys/syscall.h
; Linuxで、死すコール番号を調べるには：/usr/include/asm-generic/unistd.h
; 下記のコードはFreeBSD向けの物です。

bits 64
default rel

section .data

section .rodata
  outfile db "output.ppm", 0
  hdr db "P6", 10, "960 540", 10, "255", 10

  err db "開くに失敗", 10
  errlen equ $-err
  suc db "画像を「output.ppm」に出力しました。", 10
  suclen equ $-suc

  w equ 960
  h equ 540

section .bss
  buf resb 960*540*3

section .text
  global _start

_start:
  mov rax, 5          ; sys_openat
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

yloop:
  mov r8d, w

xloop:
  ; (x/60 + y/60) % 2の計算
  mov eax, r8d
  xor edx, edx
  mov ebx, 60
  div ebx             ; eax = x/60
  push rax

  mov eax, ecx
  xor edx, edx
  div ebx             ; eax = y/60
  pop rdx
  add eax, edx        ; x/60 + y/60
  and al, 1           ; % 2
  jz .black

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
  loop yloop          ; dec rcx, jnz yloop

  ; ピクセルデータの書き込み
  mov eax, 4
  mov rdi, r15
  lea rsi, [buf]
  mov edx, 960*540*3
  syscall

  mov rax, 4
  mov rdi, 1
  lea rsi, [suc]
  mov rdx, suclen
  syscall

close:
  mov rax, 6          ; sys_close
  mov rdi, r15
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
