# Usage: nap [seconds]
#
# Command-line argument is optional. Defaults to 10 seconds.
#
# To build for aarch64 Linux:
# as nap-arm-v8.s -o nap-arm-v8.o && ld -m aarch64elf -o nap-arm-v8 nap-arm-v8.o
#
# To build with debug info:
# as nap-arm-v8.s --gdwarf-2 -o nap-arm-v8.o && ld -m aarch64elf -o nap-arm-v8 nap-arm-v8.o

.arch armv8-a
.align 4
.global _start

.text

_start:
  mov fp, sp                  // copy stack address to fp (x29)
  ldr x0, [fp]                // load argc to x0
  cmp x0, #2                  // we should have 1 argument (+ calling command)
  bne _bad_input              // if not, it's bad input

  ldr x1, [fp, 16]            // load argv[0] to x1
  bl  _atoi                   // convert argv[0] to int
  cmp x1, #0                  // if the value is zero
  beq _bad_input              // that's also bad input

  adr x2, timespec            // load address of timespec to x2
  str x1, [x2]                // store number of seconds to sleep in timespec (via x2)

  adr x1, start_msg           // load sleep message to x1
  mov x2, start_msg_len       // load sleep message length to x2
  bl  _print                  // display sleep message
  bl  _sleep                  // sleep

  mov x7, #0                  // set error code to 0
  b   _exit                   // exit

_bad_input:
  adr x1, bad_input_msg       // load bad input message to x1
  mov x2, bad_input_msg_len   // load bad input message length to x2
  bl  _print                  // print bad input message

  mov x1, #10                 // default to 10 seconds
  adr x2, timespec            // load address of timespec to x2
  str x1, [x2]                // store number of seconds to sleep in timespec (via x2)
  bl  _sleep                  // sleep for the default time period

  mov x7, #1                  // set error code to 1
  b   _exit                   // exit

# Print a message
# Usage:
#   (input)  x1: pointer to string
#            x2: int (string length)
_print:
  mov x8, sys_write           // write
  mov x0, #0                  // to stdout file 0
  svc 0                       // execute
  ret

# Convert a string to an integer
# Usage:
#   (input)  x1: pointer to string
#   (output) x1: int
#   bl _atoi
_atoi:
  mov  x3, #0                 // index
  mov  x4, #0                 // running total
  mov  x5, #10                // multiplier
_atoi_loop:
  ldrb w0, [x1, x3]           // load byte into x0
  cmp  x0, #0                 // is it null?
  beq  _atoi_end              //    if so, break
  mul  x6, x4, x5             // multiply current total
  mov  x4, x6                 // store it in the running total
  sub  x0, x0, #48            // parse next character
  cmp  x0, #9                 // is it higher than 9?
  bgt  _atoi_end              //    if so, break
  cmp  x0, #0                 // is it lower than 0?
  blt  _atoi_end              //    if so, break
  add  x4, x4, x0             // add to running total
  add  x3, x3, #1             // increment index
  b    _atoi_loop             // loop
_atoi_end:
  mov  x1, x4                 // copy total to output
  ret

# Call sys_nanoSleep using only the seconds portion of the timespec struct
# Automatically exits the program after execution
_sleep:
  adr x0, timespec            // put timespec address into x0
  adr x1, #0                  // blank x1
  mov x8, sys_nanoSleep       // setup to call nanoSleep
  svc 0                       // make the call
  ret

# Exit to system
# Usage:
#   (input)  x7: exit code (int)
_exit:
  adr x1, end_msg             // load the message text to x1
  mov x2, end_msg_len         // load the message length to x2
  bl _print                   // print the end of program message
  mov x0, x7                  // set exit code
  mov x8, sys_exit            // setup to call sys_exit
  svc 0                       // make the service call

.data

timespec: .dword 0, 0         // allocate timespec struct

start_msg: .ascii "Sleeping...\n"
start_msg_len = . - start_msg

end_msg: .ascii "Done!\n"
end_msg_len = . - end_msg

bad_input_msg: .ascii "Bad input. Sleeping for default of 10 seconds\n"
bad_input_msg_len = . - bad_input_msg

# Kernel system calls
.equ sys_write,           64
.equ sys_exit,            93
.equ sys_nanoSleep,       101
