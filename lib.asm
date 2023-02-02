section .text
global exit
global string_length
global print_char
global print_newline
global print_string
global print_error
global print_uint
global print_int
global string_equals
global parse_uint
global parse_int
global read_word
global string_copy

; Принимает код возврата и завершает текущий процесс
exit:
  mov rax, 60
  syscall


; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
  xor rax, rax
.loop:
  cmp byte [rdi+rax], 0
  je .end
  inc rax
  jmp .loop
.end:
  ret

; Принимает указатель на нуль-терминированную строку в rsi и код потока в rdi, выводит строку в поток, соответствующий коду
print_string:
  push rdi
  mov rdi, rsi
  call string_length
  pop rdi
  mov rdx, rax
  mov rax, 1
  syscall
  ret

; Принимает код символа в rsi и код потока в rdi, выводит символ в поток, соответствующий коду
print_char:
  push rsi
  mov rsi, rsp
  mov rdx, 1
  mov rax, 1
  syscall
  pop rsi
  ret

; Принимает код потока в rdi, переводит строку (выводит символ с кодом 0xA)
print_newline:
  mov rsi, 0xA
  jmp print_char

; Выводит беззнаковое 8-байтовое число в десятичном формате
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
  mov r8, rsp
  push 0
  mov rax, rdi
  mov r9, 10
.loop:
  xor rdx, rdx
  div r9
  xor rdx, 48
  dec rsp
  mov [rsp], dl
  cmp rax, 0
  ja .loop
  mov rdi, rsp
  push rsi
  push rdi
  push rdx
  push rax
  push r8
  call print_string
  pop r8
  pop rax
  pop rdx
  pop rdi
  pop rsi
  mov rsp, r8
  ret

; Выводит знаковое 8-байтовое число в десятичном формате
print_int:
  cmp rdi, 0
  je .zero
  mov r8, rsp
  push 0
  mov rax, rdi
  mov r9, 10
  jg .positive
  neg rax

.negative:
  xor rdx, rdx
  div r9
  add rdx, 48
  dec rsp
  mov [rsp], dl
  cmp rax, 0
  jg .negative
  mov rdx, 45
  dec rsp
  mov [rsp], dl
  jmp .end

.positive:
  xor rdx, rdx
  div r9
  add rdx, 48
  dec rsp
  mov [rsp], dl
  cmp rax, 0
  ja .positive

.end:
  mov rdi, rsp
  push rsi
  push rdi
  push rdx
  push rax
  push r8
  call print_string
  pop r8
  pop rax
  pop rdx
  pop rdi
  pop rsi
  mov rsp, r8
  ret

.zero:
  mov rdi, 48
  push rsi
  push rdx
  push rax
  call print_char
  pop rax
  pop rdx
  pop rsi
  ret



; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
.A:
  push r8
  push r9
  call string_length
  mov r8, rax
  push rdi
  mov rdi, rsi
  call string_length
  pop rdi
  mov r9, rax
  cmp r8, r9
  jne .NO
  xor rax, rax
  xor r8, r8
  xor r9, r9

.B:
  mov r8b, byte [rdi+rax]
  mov r9b, byte[rsi+rax]
  inc rax
  cmp r8b, r9b
  jne .NO
  cmp r8b, 0
  jne .B

.YES:
  mov rax, 1
  pop r9
  pop r8
  ret

.NO:
  xor rax, rax
  pop r9
  pop r8
  ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
  push 0
  xor rdi, rdi
  mov rdx, 1
  xor rax, rax
  mov rsi, rsp
  syscall
  mov rax, [rsp]
  pop rdi
  ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор
read_word:
.A:
  xor rdx, rdx
  push rdi
  push rsi
  push rdx
  call read_char
  pop rdx
  pop rsi
  pop rdi
  test rax, rax
  je .exit
  test rsi, rsi
  je .exit
  cmp rax, 0x20
  jz .A
  cmp rax, 0x9
  jz .A
  cmp rax, 0xA
  jz .A
  jmp .C

.B:
  push rdi
  push rsi
  push rdx
  call read_char
  pop rdx
  pop rsi
  pop rdi
  test rax, rax
  je .null
  test rsi, rsi
  je .null
  cmp rax, 0x20
  jz .null
  cmp rax, 0x9
  jz .null
  cmp rax, 0xA
  jz .null

.C:
  mov byte[rdx + rdi], al
  inc rdx
  cmp rdx, rsi
  jz .exit
  jmp .B

.null:
  mov byte[rdx + rdi], 0
  mov rax, rdi
  ret

.exit:
  xor rax, rax
  xor rdx, rdx
  ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
  xor r8, r8
  xor rcx, rcx
  mov r10, 10

.A:
  mov r8b, [rdi]
  inc rdi
  cmp r8b, 0x30
  jb .NO
  cmp r8b, 0x39
  ja .NO
  xor rax, rax
  sub r8b, 0x30
  mov al, r8b
  inc rcx

.B:
  mov r8b, [rdi]
  inc rdi
  cmp r8b, 0x30
  jb .OK
  cmp r8b, 0x39
  ja .OK
  inc rcx
  mul r10
  sub r8b, 0x30
  add rax, r8
  jmp .B

.OK:
  mov rdx, rcx
  ret

.NO:
  xor rdx, rdx
  ret


; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был)
; rdx = 0 если число прочитать не удалось
parse_int:
  push rdi
  xor r8, r8
  xor rax, rax

.space:
  mov r8b, [rdi]
  inc rdi
  cmp r8b, 0x20
  je .space

.sign:
  cmp r8b, '-'
  push r8
  push rcx
  push r10
  je .negative
  cmp r8b, '+'
  je .positive
  dec rdi
  call parse_uint
  jmp .end

.positive:
  call parse_uint
  inc rdx
  jmp .end

.negative:
  call parse_uint
  inc rdx
  neg rax

.end:
  pop rdi
  pop r10
  pop rcx
  pop r8
  ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
  xor rax, rax

.A:
  push rdi
  push rsi
  push rdx
  call string_length
  pop rdx
  pop rsi
  pop rdi
  cmp rax, rdx
  jg .over
  push rax
  push r8

.B:
  cmp rax, 0
  jl .end
  dec rax
  mov r8, [rdi+rax]
  mov [rsi+rax], r8
  cmp rax, 0
  jz .end
  jmp .B

.end:
  pop r8
  pop rax
  ret

.over:
  xor rax, rax
  ret
