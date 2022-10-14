// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

struct {
  struct spinlock lock;
  int count[PGROUNDUP(PHYSTOP)>>12];
} page_reference_counter;

void init_page_ref(){
  initlock(&page_reference_counter.lock, "page_ref");
  acquire(&page_reference_counter.lock);
  // for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
  //   page_reference_counter.count[i]=0;
  memset((void *)page_reference_counter.count,0,sizeof(page_reference_counter.count));
  release(&page_reference_counter.lock);
}


void dec_page_ref(void*pa){
  acquire(&page_reference_counter.lock);
  if(page_reference_counter.count[(uint64)pa>>12]<=0){
    panic("dec_page_ref");
  }
  page_reference_counter.count[(uint64)pa>>12]-=1;
  release(&page_reference_counter.lock);
}

void inc_page_ref(void*pa){
  acquire(&page_reference_counter.lock);
  if(page_reference_counter.count[(uint64)pa>>12]<0){
    panic("inc_page_ref");
  }
  page_reference_counter.count[(uint64)pa>>12]+=1;
  release(&page_reference_counter.lock);
}

int get_page_ref(void*pa){
  acquire(&page_reference_counter.lock);
  int res = page_reference_counter.count[(uint64)pa>>12];
  if(page_reference_counter.count[(uint64)pa>>12]<0){
    panic("get_page_ref");
  }
  release(&page_reference_counter.lock);
  return res;
}

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  init_page_ref();
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    inc_page_ref((void*) p);
    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");


  acquire(&page_reference_counter.lock);
  if(page_reference_counter.count[(uint64)pa>>12]<=0){
    panic("dec_page_ref");
  }
  page_reference_counter.count[(uint64)pa>>12]-=1;
  if(page_reference_counter.count[(uint64)pa>>12]>0){
    release(&page_reference_counter.lock);
    return;
  }
  release(&page_reference_counter.lock);

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    inc_page_ref((void *)r);
  }
  return (void*)r;
}
