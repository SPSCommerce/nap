; Usage: nap [seconds]
;
; Command-line argument is optional. Defaults to 10 seconds.
;
; To build for x86-64 Linux:
; nasm -f elf64 nap.asm && ld -m elf_x86_64 -o nap nap.o
;
; To build with debug info:
; nasm -f elf64 -F dwarf -g nap.asm && ld -m elf_x86_64 -o nap nap.o


; First we allocate memory to store our variables and constants
section .data

    exit_code               DD 0

    timeval:
      tv_sec                DD 10          ; Number of seconds to sleep. Default to 10.
      tv_usec               DD 0           ; Number of nanoseconds to sleep (this is added to seconds, above)

    ; All strings end with newline char (0xA) and null byte (0x0)
    start_msg               DB 'Sleeping...',0xA,0
    start_msg_len           EQU $ - start_msg
    end_msg                 DB 'Done!',0xA,0
    end_msg_len             EQU $ - end_msg
    bad_input_msg           DB 'Bad input. Sleeping for default of 10 seconds',0xA,0
    bad_input_msg_len       EQU $ - bad_input_msg
    input_overflow_msg      DB 'Input too large. Sleeping for default of 10 seconds',0xA,0
    input_overflow_msg_len  EQU $ - input_overflow_msg

; Executable code
section .text
global  _start

_start:

  ; Check for command-line argument and use it if we have one.
  ;
  ; When this program begins, the rsp stack-pointer register will hold the address of the argument count (argc in C).
  ; The addresses of the arguments (argv in C) are located at 16-byte offsets from rsp:
  ; argc = [rsp]
  ; argv = [rsp + 16 * ARG_NUMBER]
  mov r8, [rsp]            ; Store value of argc into register r8. This is the number of arguments, including the program name.
  cmp r8, 2                ; Check that we received exactly one command-line argument
  jnz .do_sleep            ; If not, we'll just use the default value: 10 seconds

  ; Convert first command-line argument from string to integer (in C, this is the atoi function).
  xor eax, eax             ; Initialize a register to zero to store our result
  mov r9, [rsp+16]         ; Store address of first command-line argument in register r9

  ; This label marks the top of the loop
  .begin:

  ; Copy next byte from argv[1] string into ecx register
  movzx ecx, byte[r9]

  ; A null-byte signifies the end of the string. We're done processing, so jump to end of loop
  cmp ecx, 0
  je .end

  ; Here we check for bad characters in the input. If we detect any bad characters, we just use the default sleep time.
  cmp ecx, '0'             ; If user entered a char below the ASCII integers, it's bad input.
  jb .bad_input            ; Jump-if-Below does an unsigned comparison
  cmp ecx, '9'             ; If user entered a char above the ASCII integers, it's bad input.
  ja .bad_input            ; Jump-if-Above does an unsigned comparison

  ; "Convert" character to its integer by subtracting ASCII '0'
  sub ecx, '0'

  ; Multiply the sum in EAX by 10 for the decimal place.
  ; (On the first time through the loop, EAX is 0, so this is still 0.)
  imul eax, 10

  ; Add the new integer to EAX
  add eax, ecx

  ; If the sign bit was set, the input was too large and EAX overflowed
  js .overflow

  ; Increment pointer to next byte in the argv[1] string
  inc r9

  ; Jump to top of loop to process the next character
  jmp .begin

  .end:
  mov dword [tv_sec], eax  ; Store the result

  .do_sleep:
  ; Print start message
  mov eax, 4                ; sys_write
  mov ebx, 1                ; write to the stdout stream
  mov ecx, start_msg
  mov edx, start_msg_len
  int 0x80

  ; Sleep for argv[1] seconds and 0 nanoseconds
  mov eax, 162              ; sys_nanosleep
  mov ebx, timeval
  mov ecx, 0
  int 0x80

  ; Print done message
  mov eax, 4                ; sys_write
  mov ebx, 1
  mov ecx, end_msg
  mov edx, end_msg_len
  int 0x80

  ; exit
  mov eax, 1                ; sys_exit
  mov ebx, [exit_code]      ; set exit status code
  int 0x80

  ; Set exit status code to 1 and print "bad input" message
  .bad_input:
  mov dword [exit_code], 1
  mov eax, 4                ; sys_write
  mov ebx, 2                ; write to std_error
  mov ecx, bad_input_msg
  mov edx, bad_input_msg_len
  int 0x80
  jmp .do_sleep

  ; Set exit status code to 2 and print "input too large" message
  .overflow:
  mov dword [exit_code], 2
  mov eax, 4                ; sys_write
  mov ebx, 2                ; write to std_error
  mov ecx, input_overflow_msg
  mov edx, input_overflow_msg_len
  int 0x80
  jmp .do_sleep
