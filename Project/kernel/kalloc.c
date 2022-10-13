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

struct Ref_cnt {
  struct spinlock lock;
  uint cnt[PHYSTOP >> 12];
} page_ref_cnt;


void
init_ref_cnt(){
  printf("Hello\n");
  initlock(&page_ref_cnt.lock,"reference_count");
  acquire(&kmem.lock);
  memset(page_ref_cnt.cnt,0,sizeof(page_ref_cnt.cnt));
  release(&kmem.lock);
}

void
increment_ref_cnt(void* pa){
  page_ref_cnt.cnt[pa - (void *) 0]++;
}

void
decrement_ref_cnt(void* pa){
  page_ref_cnt.cnt[pa - (void *) 0]++;
}

void
increment_ref_cnt_safe(void* pa){
  acquire(&page_ref_cnt.lock);
  page_ref_cnt.cnt[pa - (void *) 0]++;
  release(&page_ref_cnt.lock);
}

void
decrement_ref_cnt_safe(void* pa){
  acquire(&page_ref_cnt.lock);
  page_ref_cnt.cnt[pa - (void *) 0]++;
  release(&page_ref_cnt.lock);
}

uint
get_ref_cnt(void * pa){
  return page_ref_cnt.cnt[pa - (void *) 0];
}

void
reset_ref_cnt(void *pa){
  acquire(&page_ref_cnt.lock);
  page_ref_cnt.cnt[pa - (void *) 0]=0;
  release(&page_ref_cnt.lock);
}

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
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

  // decrement count
  acquire(&page_ref_cnt.lock);
  decrement_ref_cnt(pa);
  if(get_ref_cnt(pa) > 0 ){
    // do nothing if there are some other processes algo using the same page.
    release(&page_ref_cnt.lock);
    return;
  }

  //if not process is using the page....
  reset_ref_cnt(pa);
  release(&page_ref_cnt.lock);

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
    acquire(&page_ref_cnt.lock);
    reset_ref_cnt((void*) r);
    increment_ref_cnt((void *) r);
    release(&page_ref_cnt.lock);
  }
  return (void*)r;
}
