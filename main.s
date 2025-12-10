; FreeBSDで、死すコール番号を調べるには：/usr/include/sys/syscall.h
; Linuxで、死すコール番号を調べるには：/usr/include/asm-generic/unistd.h
; 下記のコードはFreeBSD向けの物です。

bits 64
default rel

section .data
  hdr2 db "960 540", 10
  hdr3 db "255", 10

section .rodata
  outfile db "output.ppm", 0
  hdr1 db "P6", 10
  err db "開くに失敗", 10
  errlen equ $-err

  w equ 960
  h equ 540

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
  mov rbx, rax        ; ファイルディスクリプターをrbxに保存

  mov rax, 4          ; sys_write
  mov rdi, rbx        ; fd
  lea rsi, [hdr1]
  mov rdx, 3
  syscall

  mov rax, 4
  mov rdi, rbx
  lea rsi, [hdr2]
  mov rdx, 8
  syscall

  mov rax, 4
  mov rdi, rbx
  lea rsi, [hdr3]
  mov rdx, 4
  syscall

  mov rax, 6          ; sys_close
  mov rdi, rbx
  syscall

end:
  mov rax, 1          ; sys_exit
  xor rdi, rdi
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
