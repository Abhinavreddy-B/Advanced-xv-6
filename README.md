# Spec 2 , FCFS
* add integer in struct proc
* turn of Interrupt
* disabled timer interrupt if `NON_PRE_EMPT` macro is defined (Project/kernel/trap.c : line 79 )

# Spec 1 :
## To ask:
* should we dry run the command? ( line should the command effectively be run or not?)
    ```
    $ strace 32 grep installed README
    3: syscall read -> 1023
    3: syscall read -> 961
    3: syscall read -> 321
    riscv64-softmmu.  Once they are installed, and in your shell
    3: syscall read -> 0
    ```