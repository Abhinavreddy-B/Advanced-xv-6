#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

extern struct Queue queues[];

#ifdef MLFQ_SCHED
void remove_from_queue(struct proc *p)
{
  p->isQueued = 0;
  if (p->queue_prev == 0)
  { // first element in the queue.
    queues[p->Queue_Num].front = p->queue_next;
  }
  else
  {
    p->queue_prev->queue_next = p->queue_next;
  }
  queues[p->Queue_Num].no_of_processes--;
  return;
}

void add_to_queue(struct proc *p, int queue_num)
{
  p->wtime_queue = 0;
  p->Queue_Num = queue_num;
  p->isQueued = 1;
  if (queues[queue_num].front == 0)
  { // no elements in queue
    p->queue_next = 0;
    p->queue_prev = 0;
    queues[queue_num].front = p;
    queues[queue_num].back = p;
  }
  else
  {
    queues[queue_num].back->queue_next = p;
    p->queue_prev = queues[queue_num].back;
    p->queue_next = 0;
    queues[queue_num].back = p;
  }

  queues[p->Queue_Num].no_of_processes++;
}
#endif