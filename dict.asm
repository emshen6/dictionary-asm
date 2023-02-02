global find_word

%include "lib.inc"

section .text

; принимает указатель на нуль-терминированную строку в rdi и указатель на начало словаря в rsi
; возращает в rax адрес начала вхождения в словарь, либо 0
find_word:
  xor rax, rax
.loop:
  push rdi
  push rsi
  add rsi, 8
  call string_equals
  pop rsi
  pop rdi
  test rax, rax
  jnz .success
  mov rsi, [rsi]
  test rsi, rsi
  jz .fail
  jmp .loop

.success:
  mov rax, rsi
  ret

.fail:
  xor rax, rax
  ret
