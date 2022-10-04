#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/riscv.h"
#include "user/user.h"


int main(int argc,char* argv[]){
    int pid = fork();
    if(pid < 0){
        printf("fork failed\n");
    }else if(pid == 0){
        for (long long i = 0; i < 50000000000; i++)
        {
            i-=2;
            i+=2;
        }
    }else{
        printf("%d\n",pid);
        // int status;
        // wait(&status);
    }
    return 0;
}