# set the address where you want this
# code segment
  org 0x0000

  ori   $2, $0, stack_init
  lw    $sp, 0($2)

mult_procedure:
  ori   $3, $0, val1
  lw    $2, 0($3)
  push  $2
  ori   $3, $0, val2
  lw    $2, 0($3)
  push  $2
  jal   mult

  ori   $3, $0, val3
  lw    $2, 0($3)
  push  $2
  jal   mult

  ori   $3, $0, val4
  lw    $2, 0($3)
  push  $2
  jal   mult

  halt

# Data
stack_init:
  cfw   0xFFFC
val1:
  cfw   0x11
val2:
  cfw   0x2
val3:
  cfw   0x3
val4:
  cfw   0x10

# Multiply algorithm
mult:
  ori   $1, $0, 1
  pop   $2
  pop   $3

  # Store result in $4
  ori   $4, $0, 0

mult_loop:
  beq   $2, $0, end
  beq   $3, $0, end
  and   $5, $2, $1
  beq   $5, $0, shifts
  add   $4, $4, $3

shifts:
  sll   $3, $3, 1
  srl   $2, $2, 1
  j     mult_loop

end:
  push  $4
  jr    $31
