%include "words.inc"
%include "lib.inc"

global _start
extern find_word

section .rodata
  overflow: db "buffer overflow", 0
  key_not_found: db "key not found", 0

section .bss
  s_buf: resb 255

section .text

_start:
  xor rax, rax
  mov rdi, s_buf
  mov rsi, 255
  call read_word
  test rax, rax
  jnz .search
  mov rsi, overflow
  mov rdi, stderr
  push rdi
  call print_string
  pop rdi
  call print_newline
  call exit

.search:
  mov rdi, rax
  mov rsi, i5
  push rdi
  call find_word
  pop rdi
  test rax, rax
  jnz .key_found

.not_found:
  mov rsi, key_not_found
  mov rdi, stderr
  push rdi
  call print_string
  pop rdi
  call print_newline
  call exit

.key_found:
  add rax, 24
  mov rsi, rax
  mov rdi, stdout
  push rsi
  push rdi
  call print_string
  pop rdi
  pop rsi
  call exit
