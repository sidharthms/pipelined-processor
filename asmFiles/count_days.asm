# set the address where you want this
# code segment
  org 0x0000

  ori   $2, $0, stack_init
  lw    $sp, 0($2)

count_days:
  ori   $1, $0, starting_year
  lw    $2, 0($1)
  ori   $1, $0, current_year
  lw    $3, 0($1)
  subu  $4, $3, $2
  push  $4
  ori   $1, $0, days_in_year
  lw    $2, 0($1)
  push  $2
  jal   mult

  ori   $2, $0, 1
  ori   $1, $0, current_month
  lw    $3, 0($1)
  subu  $4, $3, $2
  push  $4
  ori   $1, $0, days_in_month
  lw    $2, 0($1)
  push  $2
  jal   mult

  pop   $2
  pop   $3
  addu  $4, $3, $2
  ori   $1, $0, current_day
  lw    $2, 0($1)
  addu  $3, $4, $2
  push  $3

  halt

# Data
stack_init:
  cfw   0xFFFC
current_year:
  cfw   2014
current_month:
  cfw   8
current_day:
  cfw   28
days_in_month:
  cfw   30
days_in_year:
  cfw   365
starting_year:
  cfw   2000

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
  addu  $4, $4, $3

shifts:
  sll   $3, $3, 1
  srl   $2, $2, 1
  j     mult_loop

end:
  push  $4
  jr    $31
