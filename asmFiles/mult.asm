# set the address where you want this
# code segment
  org 0x0000

  ori   $sp,$0, 0xFFFC
  ori   $2, $0, 0x123
  ori   $3, $0, 0x20
  push  $2
  push  $3

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
  halt
