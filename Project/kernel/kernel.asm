
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b9010113          	addi	sp,sp,-1136 # 80008b90 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	9fe70713          	addi	a4,a4,-1538 # 80008a50 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c3c78793          	addi	a5,a5,-964 # 80005ca0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc53f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	408080e7          	jalr	1032(ra) # 80002534 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	a0650513          	addi	a0,a0,-1530 # 80010b90 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9f648493          	addi	s1,s1,-1546 # 80010b90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a8690913          	addi	s2,s2,-1402 # 80010c28 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1b6080e7          	jalr	438(ra) # 8000237e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ef4080e7          	jalr	-268(ra) # 800020ca <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2cc080e7          	jalr	716(ra) # 800024de <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	96a50513          	addi	a0,a0,-1686 # 80010b90 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	95450513          	addi	a0,a0,-1708 # 80010b90 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	9af72b23          	sw	a5,-1610(a4) # 80010c28 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	8c450513          	addi	a0,a0,-1852 # 80010b90 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	298080e7          	jalr	664(ra) # 8000258a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	89650513          	addi	a0,a0,-1898 # 80010b90 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	87270713          	addi	a4,a4,-1934 # 80010b90 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	84878793          	addi	a5,a5,-1976 # 80010b90 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8b27a783          	lw	a5,-1870(a5) # 80010c28 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	80670713          	addi	a4,a4,-2042 # 80010b90 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7f648493          	addi	s1,s1,2038 # 80010b90 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	7ba70713          	addi	a4,a4,1978 # 80010b90 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	84f72223          	sw	a5,-1980(a4) # 80010c30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	77e78793          	addi	a5,a5,1918 # 80010b90 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7ec7ab23          	sw	a2,2038(a5) # 80010c2c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7ea50513          	addi	a0,a0,2026 # 80010c28 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	ce8080e7          	jalr	-792(ra) # 8000212e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	73050513          	addi	a0,a0,1840 # 80010b90 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	cb078793          	addi	a5,a5,-848 # 80021128 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	7007a323          	sw	zero,1798(a5) # 80010c50 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	48f72923          	sw	a5,1170(a4) # 80008a10 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	696dad83          	lw	s11,1686(s11) # 80010c50 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	64050513          	addi	a0,a0,1600 # 80010c38 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	4e250513          	addi	a0,a0,1250 # 80010c38 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	4c648493          	addi	s1,s1,1222 # 80010c38 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	48650513          	addi	a0,a0,1158 # 80010c58 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	2127a783          	lw	a5,530(a5) # 80008a10 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	1e27b783          	ld	a5,482(a5) # 80008a18 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	1e273703          	ld	a4,482(a4) # 80008a20 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	3f8a0a13          	addi	s4,s4,1016 # 80010c58 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	1b048493          	addi	s1,s1,432 # 80008a18 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	1b098993          	addi	s3,s3,432 # 80008a20 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	89c080e7          	jalr	-1892(ra) # 8000212e <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	38a50513          	addi	a0,a0,906 # 80010c58 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	1327a783          	lw	a5,306(a5) # 80008a10 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	13873703          	ld	a4,312(a4) # 80008a20 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	1287b783          	ld	a5,296(a5) # 80008a18 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	35c98993          	addi	s3,s3,860 # 80010c58 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	11448493          	addi	s1,s1,276 # 80008a18 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	11490913          	addi	s2,s2,276 # 80008a20 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	7ae080e7          	jalr	1966(ra) # 800020ca <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	32648493          	addi	s1,s1,806 # 80010c58 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	0ce7bd23          	sd	a4,218(a5) # 80008a20 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	29c48493          	addi	s1,s1,668 # 80010c58 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	8c278793          	addi	a5,a5,-1854 # 800222c0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	27290913          	addi	s2,s2,626 # 80010c90 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	1d650513          	addi	a0,a0,470 # 80010c90 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	7f250513          	addi	a0,a0,2034 # 800222c0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	1a048493          	addi	s1,s1,416 # 80010c90 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	18850513          	addi	a0,a0,392 # 80010c90 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	15c50513          	addi	a0,a0,348 # 80010c90 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ba070713          	addi	a4,a4,-1120 # 80008a28 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	814080e7          	jalr	-2028(ra) # 800026d2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e1a080e7          	jalr	-486(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	04a080e7          	jalr	74(ra) # 80001f18 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	774080e7          	jalr	1908(ra) # 800026aa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	794080e7          	jalr	1940(ra) # 800026d2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	d84080e7          	jalr	-636(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d92080e7          	jalr	-622(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	f30080e7          	jalr	-208(ra) # 80002e86 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	5d4080e7          	jalr	1492(ra) # 80003532 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	572080e7          	jalr	1394(ra) # 800044d8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	e7a080e7          	jalr	-390(ra) # 80005de8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d1e080e7          	jalr	-738(ra) # 80001c94 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	aaf72223          	sw	a5,-1372(a4) # 80008a28 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	a987b783          	ld	a5,-1384(a5) # 80008a30 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	7ca7be23          	sd	a0,2012(a5) # 80008a30 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	89448493          	addi	s1,s1,-1900 # 800110e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	67aa0a13          	addi	s4,s4,1658 # 80016ee0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17848493          	addi	s1,s1,376
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	3c850513          	addi	a0,a0,968 # 80010cb0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	3c850513          	addi	a0,a0,968 # 80010cc8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	7d048493          	addi	s1,s1,2000 # 800110e0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	5ae98993          	addi	s3,s3,1454 # 80016ee0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17848493          	addi	s1,s1,376
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	34450513          	addi	a0,a0,836 # 80010ce0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	2ec70713          	addi	a4,a4,748 # 80010cb0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	f147a783          	lw	a5,-236(a5) # 80008910 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	ce4080e7          	jalr	-796(ra) # 800026ea <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	ee07ad23          	sw	zero,-262(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	a92080e7          	jalr	-1390(ra) # 800034b2 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	27a90913          	addi	s2,s2,634 # 80010cb0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	ecc78793          	addi	a5,a5,-308 # 80008914 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	51e48493          	addi	s1,s1,1310 # 800110e0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	31690913          	addi	s2,s2,790 # 80016ee0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	17848493          	addi	s1,s1,376
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a08d                	j	80001c56 <allocproc+0xa0>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c931                	beqz	a0,80001c64 <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	cd31                	beqz	a0,80001c7c <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime=0;
    80001c46:	1604a623          	sw	zero,364(s1)
  p->ctime = ticks;
    80001c4a:	00007797          	auipc	a5,0x7
    80001c4e:	df67a783          	lw	a5,-522(a5) # 80008a40 <ticks>
    80001c52:	16f4a823          	sw	a5,368(s1)
}
    80001c56:	8526                	mv	a0,s1
    80001c58:	60e2                	ld	ra,24(sp)
    80001c5a:	6442                	ld	s0,16(sp)
    80001c5c:	64a2                	ld	s1,8(sp)
    80001c5e:	6902                	ld	s2,0(sp)
    80001c60:	6105                	addi	sp,sp,32
    80001c62:	8082                	ret
    freeproc(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	ef8080e7          	jalr	-264(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	01a080e7          	jalr	26(ra) # 80000c8a <release>
    return 0;
    80001c78:	84ca                	mv	s1,s2
    80001c7a:	bff1                	j	80001c56 <allocproc+0xa0>
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	ee0080e7          	jalr	-288(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	002080e7          	jalr	2(ra) # 80000c8a <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	b7d1                	j	80001c56 <allocproc+0xa0>

0000000080001c94 <userinit>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	f18080e7          	jalr	-232(ra) # 80001bb6 <allocproc>
    80001ca6:	84aa                	mv	s1,a0
  initproc = p;
    80001ca8:	00007797          	auipc	a5,0x7
    80001cac:	d8a7b823          	sd	a0,-624(a5) # 80008a38 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb0:	03400613          	li	a2,52
    80001cb4:	00007597          	auipc	a1,0x7
    80001cb8:	c6c58593          	addi	a1,a1,-916 # 80008920 <initcode>
    80001cbc:	6928                	ld	a0,80(a0)
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	698080e7          	jalr	1688(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cc6:	6785                	lui	a5,0x1
    80001cc8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cca:	6cb8                	ld	a4,88(s1)
    80001ccc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd0:	6cb8                	ld	a4,88(s1)
    80001cd2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd4:	4641                	li	a2,16
    80001cd6:	00006597          	auipc	a1,0x6
    80001cda:	52a58593          	addi	a1,a1,1322 # 80008200 <digits+0x1c0>
    80001cde:	15848513          	addi	a0,s1,344
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	13a080e7          	jalr	314(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cea:	00006517          	auipc	a0,0x6
    80001cee:	52650513          	addi	a0,a0,1318 # 80008210 <digits+0x1d0>
    80001cf2:	00002097          	auipc	ra,0x2
    80001cf6:	1e2080e7          	jalr	482(ra) # 80003ed4 <namei>
    80001cfa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfe:	478d                	li	a5,3
    80001d00:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f86080e7          	jalr	-122(ra) # 80000c8a <release>
}
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret

0000000080001d16 <growproc>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
    80001d22:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	c88080e7          	jalr	-888(ra) # 800019ac <myproc>
    80001d2c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d2e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d30:	01204c63          	bgtz	s2,80001d48 <growproc+0x32>
  } else if(n < 0){
    80001d34:	02094663          	bltz	s2,80001d60 <growproc+0x4a>
  p->sz = sz;
    80001d38:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3a:	4501                	li	a0,0
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6902                	ld	s2,0(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d48:	4691                	li	a3,4
    80001d4a:	00b90633          	add	a2,s2,a1
    80001d4e:	6928                	ld	a0,80(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	6c0080e7          	jalr	1728(ra) # 80001410 <uvmalloc>
    80001d58:	85aa                	mv	a1,a0
    80001d5a:	fd79                	bnez	a0,80001d38 <growproc+0x22>
      return -1;
    80001d5c:	557d                	li	a0,-1
    80001d5e:	bff9                	j	80001d3c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d60:	00b90633          	add	a2,s2,a1
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	662080e7          	jalr	1634(ra) # 800013c8 <uvmdealloc>
    80001d6e:	85aa                	mv	a1,a0
    80001d70:	b7e1                	j	80001d38 <growproc+0x22>

0000000080001d72 <fork>:
{
    80001d72:	7139                	addi	sp,sp,-64
    80001d74:	fc06                	sd	ra,56(sp)
    80001d76:	f822                	sd	s0,48(sp)
    80001d78:	f426                	sd	s1,40(sp)
    80001d7a:	f04a                	sd	s2,32(sp)
    80001d7c:	ec4e                	sd	s3,24(sp)
    80001d7e:	e852                	sd	s4,16(sp)
    80001d80:	e456                	sd	s5,8(sp)
    80001d82:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	c28080e7          	jalr	-984(ra) # 800019ac <myproc>
    80001d8c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	e28080e7          	jalr	-472(ra) # 80001bb6 <allocproc>
    80001d96:	12050063          	beqz	a0,80001eb6 <fork+0x144>
    80001d9a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d9c:	048ab603          	ld	a2,72(s5)
    80001da0:	692c                	ld	a1,80(a0)
    80001da2:	050ab503          	ld	a0,80(s5)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	7be080e7          	jalr	1982(ra) # 80001564 <uvmcopy>
    80001dae:	04054c63          	bltz	a0,80001e06 <fork+0x94>
  np->sz = p->sz;
    80001db2:	048ab783          	ld	a5,72(s5)
    80001db6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dba:	058ab683          	ld	a3,88(s5)
    80001dbe:	87b6                	mv	a5,a3
    80001dc0:	0589b703          	ld	a4,88(s3)
    80001dc4:	12068693          	addi	a3,a3,288
    80001dc8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dcc:	6788                	ld	a0,8(a5)
    80001dce:	6b8c                	ld	a1,16(a5)
    80001dd0:	6f90                	ld	a2,24(a5)
    80001dd2:	01073023          	sd	a6,0(a4)
    80001dd6:	e708                	sd	a0,8(a4)
    80001dd8:	eb0c                	sd	a1,16(a4)
    80001dda:	ef10                	sd	a2,24(a4)
    80001ddc:	02078793          	addi	a5,a5,32
    80001de0:	02070713          	addi	a4,a4,32
    80001de4:	fed792e3          	bne	a5,a3,80001dc8 <fork+0x56>
  np->syscall_tracebits = p->syscall_tracebits;
    80001de8:	168aa783          	lw	a5,360(s5)
    80001dec:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001df0:	0589b783          	ld	a5,88(s3)
    80001df4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001df8:	0d0a8493          	addi	s1,s5,208
    80001dfc:	0d098913          	addi	s2,s3,208
    80001e00:	150a8a13          	addi	s4,s5,336
    80001e04:	a00d                	j	80001e26 <fork+0xb4>
    freeproc(np);
    80001e06:	854e                	mv	a0,s3
    80001e08:	00000097          	auipc	ra,0x0
    80001e0c:	d56080e7          	jalr	-682(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e10:	854e                	mv	a0,s3
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	e78080e7          	jalr	-392(ra) # 80000c8a <release>
    return -1;
    80001e1a:	597d                	li	s2,-1
    80001e1c:	a059                	j	80001ea2 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e1e:	04a1                	addi	s1,s1,8
    80001e20:	0921                	addi	s2,s2,8
    80001e22:	01448b63          	beq	s1,s4,80001e38 <fork+0xc6>
    if(p->ofile[i])
    80001e26:	6088                	ld	a0,0(s1)
    80001e28:	d97d                	beqz	a0,80001e1e <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2a:	00002097          	auipc	ra,0x2
    80001e2e:	740080e7          	jalr	1856(ra) # 8000456a <filedup>
    80001e32:	00a93023          	sd	a0,0(s2)
    80001e36:	b7e5                	j	80001e1e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e38:	150ab503          	ld	a0,336(s5)
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	8b4080e7          	jalr	-1868(ra) # 800036f0 <idup>
    80001e44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e48:	4641                	li	a2,16
    80001e4a:	158a8593          	addi	a1,s5,344
    80001e4e:	15898513          	addi	a0,s3,344
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fca080e7          	jalr	-54(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e5a:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e5e:	854e                	mv	a0,s3
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e2a080e7          	jalr	-470(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e68:	0000f497          	auipc	s1,0xf
    80001e6c:	e6048493          	addi	s1,s1,-416 # 80010cc8 <wait_lock>
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e7a:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e0a080e7          	jalr	-502(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d4c080e7          	jalr	-692(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e92:	478d                	li	a5,3
    80001e94:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	df0080e7          	jalr	-528(ra) # 80000c8a <release>
}
    80001ea2:	854a                	mv	a0,s2
    80001ea4:	70e2                	ld	ra,56(sp)
    80001ea6:	7442                	ld	s0,48(sp)
    80001ea8:	74a2                	ld	s1,40(sp)
    80001eaa:	7902                	ld	s2,32(sp)
    80001eac:	69e2                	ld	s3,24(sp)
    80001eae:	6a42                	ld	s4,16(sp)
    80001eb0:	6aa2                	ld	s5,8(sp)
    80001eb2:	6121                	addi	sp,sp,64
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	597d                	li	s2,-1
    80001eb8:	b7ed                	j	80001ea2 <fork+0x130>

0000000080001eba <update_time>:
{
    80001eba:	7179                	addi	sp,sp,-48
    80001ebc:	f406                	sd	ra,40(sp)
    80001ebe:	f022                	sd	s0,32(sp)
    80001ec0:	ec26                	sd	s1,24(sp)
    80001ec2:	e84a                	sd	s2,16(sp)
    80001ec4:	e44e                	sd	s3,8(sp)
    80001ec6:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ec8:	0000f497          	auipc	s1,0xf
    80001ecc:	21848493          	addi	s1,s1,536 # 800110e0 <proc>
    if (p->state == RUNNING) {
    80001ed0:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ed2:	00015917          	auipc	s2,0x15
    80001ed6:	00e90913          	addi	s2,s2,14 # 80016ee0 <tickslock>
    80001eda:	a811                	j	80001eee <update_time+0x34>
    release(&p->lock); 
    80001edc:	8526                	mv	a0,s1
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dac080e7          	jalr	-596(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	17848493          	addi	s1,s1,376
    80001eea:	03248063          	beq	s1,s2,80001f0a <update_time+0x50>
    acquire(&p->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	ce6080e7          	jalr	-794(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING) {
    80001ef8:	4c9c                	lw	a5,24(s1)
    80001efa:	ff3791e3          	bne	a5,s3,80001edc <update_time+0x22>
      p->rtime++;
    80001efe:	16c4a783          	lw	a5,364(s1)
    80001f02:	2785                	addiw	a5,a5,1
    80001f04:	16f4a623          	sw	a5,364(s1)
    80001f08:	bfd1                	j	80001edc <update_time+0x22>
}
    80001f0a:	70a2                	ld	ra,40(sp)
    80001f0c:	7402                	ld	s0,32(sp)
    80001f0e:	64e2                	ld	s1,24(sp)
    80001f10:	6942                	ld	s2,16(sp)
    80001f12:	69a2                	ld	s3,8(sp)
    80001f14:	6145                	addi	sp,sp,48
    80001f16:	8082                	ret

0000000080001f18 <scheduler>:
{
    80001f18:	7139                	addi	sp,sp,-64
    80001f1a:	fc06                	sd	ra,56(sp)
    80001f1c:	f822                	sd	s0,48(sp)
    80001f1e:	f426                	sd	s1,40(sp)
    80001f20:	f04a                	sd	s2,32(sp)
    80001f22:	ec4e                	sd	s3,24(sp)
    80001f24:	e852                	sd	s4,16(sp)
    80001f26:	e456                	sd	s5,8(sp)
    80001f28:	e05a                	sd	s6,0(sp)
    80001f2a:	0080                	addi	s0,sp,64
    80001f2c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f2e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f30:	00779a93          	slli	s5,a5,0x7
    80001f34:	0000f717          	auipc	a4,0xf
    80001f38:	d7c70713          	addi	a4,a4,-644 # 80010cb0 <pid_lock>
    80001f3c:	9756                	add	a4,a4,s5
    80001f3e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f42:	0000f717          	auipc	a4,0xf
    80001f46:	da670713          	addi	a4,a4,-602 # 80010ce8 <cpus+0x8>
    80001f4a:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f4c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f4e:	4b11                	li	s6,4
        c->proc = p;
    80001f50:	079e                	slli	a5,a5,0x7
    80001f52:	0000fa17          	auipc	s4,0xf
    80001f56:	d5ea0a13          	addi	s4,s4,-674 # 80010cb0 <pid_lock>
    80001f5a:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f5c:	00015917          	auipc	s2,0x15
    80001f60:	f8490913          	addi	s2,s2,-124 # 80016ee0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6c:	10079073          	csrw	sstatus,a5
    80001f70:	0000f497          	auipc	s1,0xf
    80001f74:	17048493          	addi	s1,s1,368 # 800110e0 <proc>
    80001f78:	a811                	j	80001f8c <scheduler+0x74>
      release(&p->lock);
    80001f7a:	8526                	mv	a0,s1
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	d0e080e7          	jalr	-754(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f84:	17848493          	addi	s1,s1,376
    80001f88:	fd248ee3          	beq	s1,s2,80001f64 <scheduler+0x4c>
      acquire(&p->lock);
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	c48080e7          	jalr	-952(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f96:	4c9c                	lw	a5,24(s1)
    80001f98:	ff3791e3          	bne	a5,s3,80001f7a <scheduler+0x62>
        p->state = RUNNING;
    80001f9c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fa0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fa4:	06048593          	addi	a1,s1,96
    80001fa8:	8556                	mv	a0,s5
    80001faa:	00000097          	auipc	ra,0x0
    80001fae:	696080e7          	jalr	1686(ra) # 80002640 <swtch>
        c->proc = 0;
    80001fb2:	020a3823          	sd	zero,48(s4)
    80001fb6:	b7d1                	j	80001f7a <scheduler+0x62>

0000000080001fb8 <sched>:
{
    80001fb8:	7179                	addi	sp,sp,-48
    80001fba:	f406                	sd	ra,40(sp)
    80001fbc:	f022                	sd	s0,32(sp)
    80001fbe:	ec26                	sd	s1,24(sp)
    80001fc0:	e84a                	sd	s2,16(sp)
    80001fc2:	e44e                	sd	s3,8(sp)
    80001fc4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	9e6080e7          	jalr	-1562(ra) # 800019ac <myproc>
    80001fce:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	b8c080e7          	jalr	-1140(ra) # 80000b5c <holding>
    80001fd8:	c93d                	beqz	a0,8000204e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fda:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fdc:	2781                	sext.w	a5,a5
    80001fde:	079e                	slli	a5,a5,0x7
    80001fe0:	0000f717          	auipc	a4,0xf
    80001fe4:	cd070713          	addi	a4,a4,-816 # 80010cb0 <pid_lock>
    80001fe8:	97ba                	add	a5,a5,a4
    80001fea:	0a87a703          	lw	a4,168(a5)
    80001fee:	4785                	li	a5,1
    80001ff0:	06f71763          	bne	a4,a5,8000205e <sched+0xa6>
  if(p->state == RUNNING)
    80001ff4:	4c98                	lw	a4,24(s1)
    80001ff6:	4791                	li	a5,4
    80001ff8:	06f70b63          	beq	a4,a5,8000206e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002000:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002002:	efb5                	bnez	a5,8000207e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002004:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002006:	0000f917          	auipc	s2,0xf
    8000200a:	caa90913          	addi	s2,s2,-854 # 80010cb0 <pid_lock>
    8000200e:	2781                	sext.w	a5,a5
    80002010:	079e                	slli	a5,a5,0x7
    80002012:	97ca                	add	a5,a5,s2
    80002014:	0ac7a983          	lw	s3,172(a5)
    80002018:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	0000f597          	auipc	a1,0xf
    80002022:	cca58593          	addi	a1,a1,-822 # 80010ce8 <cpus+0x8>
    80002026:	95be                	add	a1,a1,a5
    80002028:	06048513          	addi	a0,s1,96
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	614080e7          	jalr	1556(ra) # 80002640 <swtch>
    80002034:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	97ca                	add	a5,a5,s2
    8000203c:	0b37a623          	sw	s3,172(a5)
}
    80002040:	70a2                	ld	ra,40(sp)
    80002042:	7402                	ld	s0,32(sp)
    80002044:	64e2                	ld	s1,24(sp)
    80002046:	6942                	ld	s2,16(sp)
    80002048:	69a2                	ld	s3,8(sp)
    8000204a:	6145                	addi	sp,sp,48
    8000204c:	8082                	ret
    panic("sched p->lock");
    8000204e:	00006517          	auipc	a0,0x6
    80002052:	1ca50513          	addi	a0,a0,458 # 80008218 <digits+0x1d8>
    80002056:	ffffe097          	auipc	ra,0xffffe
    8000205a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
    panic("sched locks");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	1ca50513          	addi	a0,a0,458 # 80008228 <digits+0x1e8>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>
    panic("sched running");
    8000206e:	00006517          	auipc	a0,0x6
    80002072:	1ca50513          	addi	a0,a0,458 # 80008238 <digits+0x1f8>
    80002076:	ffffe097          	auipc	ra,0xffffe
    8000207a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1ca50513          	addi	a0,a0,458 # 80008248 <digits+0x208>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4b8080e7          	jalr	1208(ra) # 8000053e <panic>

000000008000208e <yield>:
{
    8000208e:	1101                	addi	sp,sp,-32
    80002090:	ec06                	sd	ra,24(sp)
    80002092:	e822                	sd	s0,16(sp)
    80002094:	e426                	sd	s1,8(sp)
    80002096:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	914080e7          	jalr	-1772(ra) # 800019ac <myproc>
    800020a0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020aa:	478d                	li	a5,3
    800020ac:	cc9c                	sw	a5,24(s1)
  sched();
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	f0a080e7          	jalr	-246(ra) # 80001fb8 <sched>
  release(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bd2080e7          	jalr	-1070(ra) # 80000c8a <release>
}
    800020c0:	60e2                	ld	ra,24(sp)
    800020c2:	6442                	ld	s0,16(sp)
    800020c4:	64a2                	ld	s1,8(sp)
    800020c6:	6105                	addi	sp,sp,32
    800020c8:	8082                	ret

00000000800020ca <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ca:	7179                	addi	sp,sp,-48
    800020cc:	f406                	sd	ra,40(sp)
    800020ce:	f022                	sd	s0,32(sp)
    800020d0:	ec26                	sd	s1,24(sp)
    800020d2:	e84a                	sd	s2,16(sp)
    800020d4:	e44e                	sd	s3,8(sp)
    800020d6:	1800                	addi	s0,sp,48
    800020d8:	89aa                	mv	s3,a0
    800020da:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	8d0080e7          	jalr	-1840(ra) # 800019ac <myproc>
    800020e4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	af0080e7          	jalr	-1296(ra) # 80000bd6 <acquire>
  release(lk);
    800020ee:	854a                	mv	a0,s2
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b9a080e7          	jalr	-1126(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020f8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fc:	4789                	li	a5,2
    800020fe:	cc9c                	sw	a5,24(s1)

  sched();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	eb8080e7          	jalr	-328(ra) # 80001fb8 <sched>

  // Tidy up.
  p->chan = 0;
    80002108:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b7c080e7          	jalr	-1156(ra) # 80000c8a <release>
  acquire(lk);
    80002116:	854a                	mv	a0,s2
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	abe080e7          	jalr	-1346(ra) # 80000bd6 <acquire>
}
    80002120:	70a2                	ld	ra,40(sp)
    80002122:	7402                	ld	s0,32(sp)
    80002124:	64e2                	ld	s1,24(sp)
    80002126:	6942                	ld	s2,16(sp)
    80002128:	69a2                	ld	s3,8(sp)
    8000212a:	6145                	addi	sp,sp,48
    8000212c:	8082                	ret

000000008000212e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000212e:	7139                	addi	sp,sp,-64
    80002130:	fc06                	sd	ra,56(sp)
    80002132:	f822                	sd	s0,48(sp)
    80002134:	f426                	sd	s1,40(sp)
    80002136:	f04a                	sd	s2,32(sp)
    80002138:	ec4e                	sd	s3,24(sp)
    8000213a:	e852                	sd	s4,16(sp)
    8000213c:	e456                	sd	s5,8(sp)
    8000213e:	0080                	addi	s0,sp,64
    80002140:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002142:	0000f497          	auipc	s1,0xf
    80002146:	f9e48493          	addi	s1,s1,-98 # 800110e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000214a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000214c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000214e:	00015917          	auipc	s2,0x15
    80002152:	d9290913          	addi	s2,s2,-622 # 80016ee0 <tickslock>
    80002156:	a811                	j	8000216a <wakeup+0x3c>
      }
      release(&p->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b30080e7          	jalr	-1232(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002162:	17848493          	addi	s1,s1,376
    80002166:	03248663          	beq	s1,s2,80002192 <wakeup+0x64>
    if(p != myproc()){
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	842080e7          	jalr	-1982(ra) # 800019ac <myproc>
    80002172:	fea488e3          	beq	s1,a0,80002162 <wakeup+0x34>
      acquire(&p->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	a5e080e7          	jalr	-1442(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002180:	4c9c                	lw	a5,24(s1)
    80002182:	fd379be3          	bne	a5,s3,80002158 <wakeup+0x2a>
    80002186:	709c                	ld	a5,32(s1)
    80002188:	fd4798e3          	bne	a5,s4,80002158 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000218c:	0154ac23          	sw	s5,24(s1)
    80002190:	b7e1                	j	80002158 <wakeup+0x2a>
    }
  }
}
    80002192:	70e2                	ld	ra,56(sp)
    80002194:	7442                	ld	s0,48(sp)
    80002196:	74a2                	ld	s1,40(sp)
    80002198:	7902                	ld	s2,32(sp)
    8000219a:	69e2                	ld	s3,24(sp)
    8000219c:	6a42                	ld	s4,16(sp)
    8000219e:	6aa2                	ld	s5,8(sp)
    800021a0:	6121                	addi	sp,sp,64
    800021a2:	8082                	ret

00000000800021a4 <reparent>:
{
    800021a4:	7179                	addi	sp,sp,-48
    800021a6:	f406                	sd	ra,40(sp)
    800021a8:	f022                	sd	s0,32(sp)
    800021aa:	ec26                	sd	s1,24(sp)
    800021ac:	e84a                	sd	s2,16(sp)
    800021ae:	e44e                	sd	s3,8(sp)
    800021b0:	e052                	sd	s4,0(sp)
    800021b2:	1800                	addi	s0,sp,48
    800021b4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b6:	0000f497          	auipc	s1,0xf
    800021ba:	f2a48493          	addi	s1,s1,-214 # 800110e0 <proc>
      pp->parent = initproc;
    800021be:	00007a17          	auipc	s4,0x7
    800021c2:	87aa0a13          	addi	s4,s4,-1926 # 80008a38 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021c6:	00015997          	auipc	s3,0x15
    800021ca:	d1a98993          	addi	s3,s3,-742 # 80016ee0 <tickslock>
    800021ce:	a029                	j	800021d8 <reparent+0x34>
    800021d0:	17848493          	addi	s1,s1,376
    800021d4:	01348d63          	beq	s1,s3,800021ee <reparent+0x4a>
    if(pp->parent == p){
    800021d8:	7c9c                	ld	a5,56(s1)
    800021da:	ff279be3          	bne	a5,s2,800021d0 <reparent+0x2c>
      pp->parent = initproc;
    800021de:	000a3503          	ld	a0,0(s4)
    800021e2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	f4a080e7          	jalr	-182(ra) # 8000212e <wakeup>
    800021ec:	b7d5                	j	800021d0 <reparent+0x2c>
}
    800021ee:	70a2                	ld	ra,40(sp)
    800021f0:	7402                	ld	s0,32(sp)
    800021f2:	64e2                	ld	s1,24(sp)
    800021f4:	6942                	ld	s2,16(sp)
    800021f6:	69a2                	ld	s3,8(sp)
    800021f8:	6a02                	ld	s4,0(sp)
    800021fa:	6145                	addi	sp,sp,48
    800021fc:	8082                	ret

00000000800021fe <exit>:
{
    800021fe:	7179                	addi	sp,sp,-48
    80002200:	f406                	sd	ra,40(sp)
    80002202:	f022                	sd	s0,32(sp)
    80002204:	ec26                	sd	s1,24(sp)
    80002206:	e84a                	sd	s2,16(sp)
    80002208:	e44e                	sd	s3,8(sp)
    8000220a:	e052                	sd	s4,0(sp)
    8000220c:	1800                	addi	s0,sp,48
    8000220e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	79c080e7          	jalr	1948(ra) # 800019ac <myproc>
    80002218:	89aa                	mv	s3,a0
  if(p == initproc)
    8000221a:	00007797          	auipc	a5,0x7
    8000221e:	81e7b783          	ld	a5,-2018(a5) # 80008a38 <initproc>
    80002222:	0d050493          	addi	s1,a0,208
    80002226:	15050913          	addi	s2,a0,336
    8000222a:	02a79363          	bne	a5,a0,80002250 <exit+0x52>
    panic("init exiting");
    8000222e:	00006517          	auipc	a0,0x6
    80002232:	03250513          	addi	a0,a0,50 # 80008260 <digits+0x220>
    80002236:	ffffe097          	auipc	ra,0xffffe
    8000223a:	308080e7          	jalr	776(ra) # 8000053e <panic>
      fileclose(f);
    8000223e:	00002097          	auipc	ra,0x2
    80002242:	37e080e7          	jalr	894(ra) # 800045bc <fileclose>
      p->ofile[fd] = 0;
    80002246:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000224a:	04a1                	addi	s1,s1,8
    8000224c:	01248563          	beq	s1,s2,80002256 <exit+0x58>
    if(p->ofile[fd]){
    80002250:	6088                	ld	a0,0(s1)
    80002252:	f575                	bnez	a0,8000223e <exit+0x40>
    80002254:	bfdd                	j	8000224a <exit+0x4c>
  begin_op();
    80002256:	00002097          	auipc	ra,0x2
    8000225a:	e9a080e7          	jalr	-358(ra) # 800040f0 <begin_op>
  iput(p->cwd);
    8000225e:	1509b503          	ld	a0,336(s3)
    80002262:	00001097          	auipc	ra,0x1
    80002266:	686080e7          	jalr	1670(ra) # 800038e8 <iput>
  end_op();
    8000226a:	00002097          	auipc	ra,0x2
    8000226e:	f06080e7          	jalr	-250(ra) # 80004170 <end_op>
  p->cwd = 0;
    80002272:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002276:	0000f497          	auipc	s1,0xf
    8000227a:	a5248493          	addi	s1,s1,-1454 # 80010cc8 <wait_lock>
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
  reparent(p);
    80002288:	854e                	mv	a0,s3
    8000228a:	00000097          	auipc	ra,0x0
    8000228e:	f1a080e7          	jalr	-230(ra) # 800021a4 <reparent>
  wakeup(p->parent);
    80002292:	0389b503          	ld	a0,56(s3)
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	e98080e7          	jalr	-360(ra) # 8000212e <wakeup>
  acquire(&p->lock);
    8000229e:	854e                	mv	a0,s3
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022a8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ac:	4795                	li	a5,5
    800022ae:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022b2:	00006797          	auipc	a5,0x6
    800022b6:	78e7a783          	lw	a5,1934(a5) # 80008a40 <ticks>
    800022ba:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	9ca080e7          	jalr	-1590(ra) # 80000c8a <release>
  sched();
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	cf0080e7          	jalr	-784(ra) # 80001fb8 <sched>
  panic("zombie exit");
    800022d0:	00006517          	auipc	a0,0x6
    800022d4:	fa050513          	addi	a0,a0,-96 # 80008270 <digits+0x230>
    800022d8:	ffffe097          	auipc	ra,0xffffe
    800022dc:	266080e7          	jalr	614(ra) # 8000053e <panic>

00000000800022e0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	1800                	addi	s0,sp,48
    800022ee:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022f0:	0000f497          	auipc	s1,0xf
    800022f4:	df048493          	addi	s1,s1,-528 # 800110e0 <proc>
    800022f8:	00015997          	auipc	s3,0x15
    800022fc:	be898993          	addi	s3,s3,-1048 # 80016ee0 <tickslock>
    acquire(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	8d4080e7          	jalr	-1836(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000230a:	589c                	lw	a5,48(s1)
    8000230c:	01278d63          	beq	a5,s2,80002326 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	978080e7          	jalr	-1672(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000231a:	17848493          	addi	s1,s1,376
    8000231e:	ff3491e3          	bne	s1,s3,80002300 <kill+0x20>
  }
  return -1;
    80002322:	557d                	li	a0,-1
    80002324:	a829                	j	8000233e <kill+0x5e>
      p->killed = 1;
    80002326:	4785                	li	a5,1
    80002328:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000232a:	4c98                	lw	a4,24(s1)
    8000232c:	4789                	li	a5,2
    8000232e:	00f70f63          	beq	a4,a5,8000234c <kill+0x6c>
      release(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	956080e7          	jalr	-1706(ra) # 80000c8a <release>
      return 0;
    8000233c:	4501                	li	a0,0
}
    8000233e:	70a2                	ld	ra,40(sp)
    80002340:	7402                	ld	s0,32(sp)
    80002342:	64e2                	ld	s1,24(sp)
    80002344:	6942                	ld	s2,16(sp)
    80002346:	69a2                	ld	s3,8(sp)
    80002348:	6145                	addi	sp,sp,48
    8000234a:	8082                	ret
        p->state = RUNNABLE;
    8000234c:	478d                	li	a5,3
    8000234e:	cc9c                	sw	a5,24(s1)
    80002350:	b7cd                	j	80002332 <kill+0x52>

0000000080002352 <setkilled>:

void
setkilled(struct proc *p)
{
    80002352:	1101                	addi	sp,sp,-32
    80002354:	ec06                	sd	ra,24(sp)
    80002356:	e822                	sd	s0,16(sp)
    80002358:	e426                	sd	s1,8(sp)
    8000235a:	1000                	addi	s0,sp,32
    8000235c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	878080e7          	jalr	-1928(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002366:	4785                	li	a5,1
    80002368:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
}
    80002374:	60e2                	ld	ra,24(sp)
    80002376:	6442                	ld	s0,16(sp)
    80002378:	64a2                	ld	s1,8(sp)
    8000237a:	6105                	addi	sp,sp,32
    8000237c:	8082                	ret

000000008000237e <killed>:

int
killed(struct proc *p)
{
    8000237e:	1101                	addi	sp,sp,-32
    80002380:	ec06                	sd	ra,24(sp)
    80002382:	e822                	sd	s0,16(sp)
    80002384:	e426                	sd	s1,8(sp)
    80002386:	e04a                	sd	s2,0(sp)
    80002388:	1000                	addi	s0,sp,32
    8000238a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	84a080e7          	jalr	-1974(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002394:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	8f0080e7          	jalr	-1808(ra) # 80000c8a <release>
  return k;
}
    800023a2:	854a                	mv	a0,s2
    800023a4:	60e2                	ld	ra,24(sp)
    800023a6:	6442                	ld	s0,16(sp)
    800023a8:	64a2                	ld	s1,8(sp)
    800023aa:	6902                	ld	s2,0(sp)
    800023ac:	6105                	addi	sp,sp,32
    800023ae:	8082                	ret

00000000800023b0 <wait>:
{
    800023b0:	715d                	addi	sp,sp,-80
    800023b2:	e486                	sd	ra,72(sp)
    800023b4:	e0a2                	sd	s0,64(sp)
    800023b6:	fc26                	sd	s1,56(sp)
    800023b8:	f84a                	sd	s2,48(sp)
    800023ba:	f44e                	sd	s3,40(sp)
    800023bc:	f052                	sd	s4,32(sp)
    800023be:	ec56                	sd	s5,24(sp)
    800023c0:	e85a                	sd	s6,16(sp)
    800023c2:	e45e                	sd	s7,8(sp)
    800023c4:	e062                	sd	s8,0(sp)
    800023c6:	0880                	addi	s0,sp,80
    800023c8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	5e2080e7          	jalr	1506(ra) # 800019ac <myproc>
    800023d2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	8f450513          	addi	a0,a0,-1804 # 80010cc8 <wait_lock>
    800023dc:	ffffe097          	auipc	ra,0xffffe
    800023e0:	7fa080e7          	jalr	2042(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023e4:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023e6:	4a15                	li	s4,5
        havekids = 1;
    800023e8:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ea:	00015997          	auipc	s3,0x15
    800023ee:	af698993          	addi	s3,s3,-1290 # 80016ee0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023f2:	0000fc17          	auipc	s8,0xf
    800023f6:	8d6c0c13          	addi	s8,s8,-1834 # 80010cc8 <wait_lock>
    havekids = 0;
    800023fa:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fc:	0000f497          	auipc	s1,0xf
    80002400:	ce448493          	addi	s1,s1,-796 # 800110e0 <proc>
    80002404:	a0bd                	j	80002472 <wait+0xc2>
          pid = pp->pid;
    80002406:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000240a:	000b0e63          	beqz	s6,80002426 <wait+0x76>
    8000240e:	4691                	li	a3,4
    80002410:	02c48613          	addi	a2,s1,44
    80002414:	85da                	mv	a1,s6
    80002416:	05093503          	ld	a0,80(s2)
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	24e080e7          	jalr	590(ra) # 80001668 <copyout>
    80002422:	02054563          	bltz	a0,8000244c <wait+0x9c>
          freeproc(pp);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	736080e7          	jalr	1846(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	858080e7          	jalr	-1960(ra) # 80000c8a <release>
          release(&wait_lock);
    8000243a:	0000f517          	auipc	a0,0xf
    8000243e:	88e50513          	addi	a0,a0,-1906 # 80010cc8 <wait_lock>
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	848080e7          	jalr	-1976(ra) # 80000c8a <release>
          return pid;
    8000244a:	a0b5                	j	800024b6 <wait+0x106>
            release(&pp->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	83c080e7          	jalr	-1988(ra) # 80000c8a <release>
            release(&wait_lock);
    80002456:	0000f517          	auipc	a0,0xf
    8000245a:	87250513          	addi	a0,a0,-1934 # 80010cc8 <wait_lock>
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	82c080e7          	jalr	-2004(ra) # 80000c8a <release>
            return -1;
    80002466:	59fd                	li	s3,-1
    80002468:	a0b9                	j	800024b6 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246a:	17848493          	addi	s1,s1,376
    8000246e:	03348463          	beq	s1,s3,80002496 <wait+0xe6>
      if(pp->parent == p){
    80002472:	7c9c                	ld	a5,56(s1)
    80002474:	ff279be3          	bne	a5,s2,8000246a <wait+0xba>
        acquire(&pp->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	75c080e7          	jalr	1884(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002482:	4c9c                	lw	a5,24(s1)
    80002484:	f94781e3          	beq	a5,s4,80002406 <wait+0x56>
        release(&pp->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	800080e7          	jalr	-2048(ra) # 80000c8a <release>
        havekids = 1;
    80002492:	8756                	mv	a4,s5
    80002494:	bfd9                	j	8000246a <wait+0xba>
    if(!havekids || killed(p)){
    80002496:	c719                	beqz	a4,800024a4 <wait+0xf4>
    80002498:	854a                	mv	a0,s2
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	ee4080e7          	jalr	-284(ra) # 8000237e <killed>
    800024a2:	c51d                	beqz	a0,800024d0 <wait+0x120>
      release(&wait_lock);
    800024a4:	0000f517          	auipc	a0,0xf
    800024a8:	82450513          	addi	a0,a0,-2012 # 80010cc8 <wait_lock>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7de080e7          	jalr	2014(ra) # 80000c8a <release>
      return -1;
    800024b4:	59fd                	li	s3,-1
}
    800024b6:	854e                	mv	a0,s3
    800024b8:	60a6                	ld	ra,72(sp)
    800024ba:	6406                	ld	s0,64(sp)
    800024bc:	74e2                	ld	s1,56(sp)
    800024be:	7942                	ld	s2,48(sp)
    800024c0:	79a2                	ld	s3,40(sp)
    800024c2:	7a02                	ld	s4,32(sp)
    800024c4:	6ae2                	ld	s5,24(sp)
    800024c6:	6b42                	ld	s6,16(sp)
    800024c8:	6ba2                	ld	s7,8(sp)
    800024ca:	6c02                	ld	s8,0(sp)
    800024cc:	6161                	addi	sp,sp,80
    800024ce:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d0:	85e2                	mv	a1,s8
    800024d2:	854a                	mv	a0,s2
    800024d4:	00000097          	auipc	ra,0x0
    800024d8:	bf6080e7          	jalr	-1034(ra) # 800020ca <sleep>
    havekids = 0;
    800024dc:	bf39                	j	800023fa <wait+0x4a>

00000000800024de <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024de:	7179                	addi	sp,sp,-48
    800024e0:	f406                	sd	ra,40(sp)
    800024e2:	f022                	sd	s0,32(sp)
    800024e4:	ec26                	sd	s1,24(sp)
    800024e6:	e84a                	sd	s2,16(sp)
    800024e8:	e44e                	sd	s3,8(sp)
    800024ea:	e052                	sd	s4,0(sp)
    800024ec:	1800                	addi	s0,sp,48
    800024ee:	84aa                	mv	s1,a0
    800024f0:	892e                	mv	s2,a1
    800024f2:	89b2                	mv	s3,a2
    800024f4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	4b6080e7          	jalr	1206(ra) # 800019ac <myproc>
  if(user_dst){
    800024fe:	c08d                	beqz	s1,80002520 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002500:	86d2                	mv	a3,s4
    80002502:	864e                	mv	a2,s3
    80002504:	85ca                	mv	a1,s2
    80002506:	6928                	ld	a0,80(a0)
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	160080e7          	jalr	352(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002510:	70a2                	ld	ra,40(sp)
    80002512:	7402                	ld	s0,32(sp)
    80002514:	64e2                	ld	s1,24(sp)
    80002516:	6942                	ld	s2,16(sp)
    80002518:	69a2                	ld	s3,8(sp)
    8000251a:	6a02                	ld	s4,0(sp)
    8000251c:	6145                	addi	sp,sp,48
    8000251e:	8082                	ret
    memmove((char *)dst, src, len);
    80002520:	000a061b          	sext.w	a2,s4
    80002524:	85ce                	mv	a1,s3
    80002526:	854a                	mv	a0,s2
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	806080e7          	jalr	-2042(ra) # 80000d2e <memmove>
    return 0;
    80002530:	8526                	mv	a0,s1
    80002532:	bff9                	j	80002510 <either_copyout+0x32>

0000000080002534 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002534:	7179                	addi	sp,sp,-48
    80002536:	f406                	sd	ra,40(sp)
    80002538:	f022                	sd	s0,32(sp)
    8000253a:	ec26                	sd	s1,24(sp)
    8000253c:	e84a                	sd	s2,16(sp)
    8000253e:	e44e                	sd	s3,8(sp)
    80002540:	e052                	sd	s4,0(sp)
    80002542:	1800                	addi	s0,sp,48
    80002544:	892a                	mv	s2,a0
    80002546:	84ae                	mv	s1,a1
    80002548:	89b2                	mv	s3,a2
    8000254a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	460080e7          	jalr	1120(ra) # 800019ac <myproc>
  if(user_src){
    80002554:	c08d                	beqz	s1,80002576 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002556:	86d2                	mv	a3,s4
    80002558:	864e                	mv	a2,s3
    8000255a:	85ca                	mv	a1,s2
    8000255c:	6928                	ld	a0,80(a0)
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	196080e7          	jalr	406(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002566:	70a2                	ld	ra,40(sp)
    80002568:	7402                	ld	s0,32(sp)
    8000256a:	64e2                	ld	s1,24(sp)
    8000256c:	6942                	ld	s2,16(sp)
    8000256e:	69a2                	ld	s3,8(sp)
    80002570:	6a02                	ld	s4,0(sp)
    80002572:	6145                	addi	sp,sp,48
    80002574:	8082                	ret
    memmove(dst, (char*)src, len);
    80002576:	000a061b          	sext.w	a2,s4
    8000257a:	85ce                	mv	a1,s3
    8000257c:	854a                	mv	a0,s2
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	7b0080e7          	jalr	1968(ra) # 80000d2e <memmove>
    return 0;
    80002586:	8526                	mv	a0,s1
    80002588:	bff9                	j	80002566 <either_copyin+0x32>

000000008000258a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000258a:	715d                	addi	sp,sp,-80
    8000258c:	e486                	sd	ra,72(sp)
    8000258e:	e0a2                	sd	s0,64(sp)
    80002590:	fc26                	sd	s1,56(sp)
    80002592:	f84a                	sd	s2,48(sp)
    80002594:	f44e                	sd	s3,40(sp)
    80002596:	f052                	sd	s4,32(sp)
    80002598:	ec56                	sd	s5,24(sp)
    8000259a:	e85a                	sd	s6,16(sp)
    8000259c:	e45e                	sd	s7,8(sp)
    8000259e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025a0:	00006517          	auipc	a0,0x6
    800025a4:	b2850513          	addi	a0,a0,-1240 # 800080c8 <digits+0x88>
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	fe0080e7          	jalr	-32(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b0:	0000f497          	auipc	s1,0xf
    800025b4:	c8848493          	addi	s1,s1,-888 # 80011238 <proc+0x158>
    800025b8:	00015917          	auipc	s2,0x15
    800025bc:	a8090913          	addi	s2,s2,-1408 # 80017038 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025c2:	00006997          	auipc	s3,0x6
    800025c6:	cbe98993          	addi	s3,s3,-834 # 80008280 <digits+0x240>
    printf("%d %s %s %d %d %d", p->pid, state, p->name,p->ctime,p->rtime,p->etime);
    800025ca:	00006a97          	auipc	s5,0x6
    800025ce:	cbea8a93          	addi	s5,s5,-834 # 80008288 <digits+0x248>
    printf("\n");
    800025d2:	00006a17          	auipc	s4,0x6
    800025d6:	af6a0a13          	addi	s4,s4,-1290 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025da:	00006b97          	auipc	s7,0x6
    800025de:	cf6b8b93          	addi	s7,s7,-778 # 800082d0 <states.0>
    800025e2:	a02d                	j	8000260c <procdump+0x82>
    printf("%d %s %s %d %d %d", p->pid, state, p->name,p->ctime,p->rtime,p->etime);
    800025e4:	01c6a803          	lw	a6,28(a3)
    800025e8:	4adc                	lw	a5,20(a3)
    800025ea:	4e98                	lw	a4,24(a3)
    800025ec:	ed86a583          	lw	a1,-296(a3)
    800025f0:	8556                	mv	a0,s5
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	f96080e7          	jalr	-106(ra) # 80000588 <printf>
    printf("\n");
    800025fa:	8552                	mv	a0,s4
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	f8c080e7          	jalr	-116(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002604:	17848493          	addi	s1,s1,376
    80002608:	03248163          	beq	s1,s2,8000262a <procdump+0xa0>
    if(p->state == UNUSED)
    8000260c:	86a6                	mv	a3,s1
    8000260e:	ec04a783          	lw	a5,-320(s1)
    80002612:	dbed                	beqz	a5,80002604 <procdump+0x7a>
      state = "???";
    80002614:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002616:	fcfb67e3          	bltu	s6,a5,800025e4 <procdump+0x5a>
    8000261a:	1782                	slli	a5,a5,0x20
    8000261c:	9381                	srli	a5,a5,0x20
    8000261e:	078e                	slli	a5,a5,0x3
    80002620:	97de                	add	a5,a5,s7
    80002622:	6390                	ld	a2,0(a5)
    80002624:	f261                	bnez	a2,800025e4 <procdump+0x5a>
      state = "???";
    80002626:	864e                	mv	a2,s3
    80002628:	bf75                	j	800025e4 <procdump+0x5a>
  }
}
    8000262a:	60a6                	ld	ra,72(sp)
    8000262c:	6406                	ld	s0,64(sp)
    8000262e:	74e2                	ld	s1,56(sp)
    80002630:	7942                	ld	s2,48(sp)
    80002632:	79a2                	ld	s3,40(sp)
    80002634:	7a02                	ld	s4,32(sp)
    80002636:	6ae2                	ld	s5,24(sp)
    80002638:	6b42                	ld	s6,16(sp)
    8000263a:	6ba2                	ld	s7,8(sp)
    8000263c:	6161                	addi	sp,sp,80
    8000263e:	8082                	ret

0000000080002640 <swtch>:
    80002640:	00153023          	sd	ra,0(a0)
    80002644:	00253423          	sd	sp,8(a0)
    80002648:	e900                	sd	s0,16(a0)
    8000264a:	ed04                	sd	s1,24(a0)
    8000264c:	03253023          	sd	s2,32(a0)
    80002650:	03353423          	sd	s3,40(a0)
    80002654:	03453823          	sd	s4,48(a0)
    80002658:	03553c23          	sd	s5,56(a0)
    8000265c:	05653023          	sd	s6,64(a0)
    80002660:	05753423          	sd	s7,72(a0)
    80002664:	05853823          	sd	s8,80(a0)
    80002668:	05953c23          	sd	s9,88(a0)
    8000266c:	07a53023          	sd	s10,96(a0)
    80002670:	07b53423          	sd	s11,104(a0)
    80002674:	0005b083          	ld	ra,0(a1)
    80002678:	0085b103          	ld	sp,8(a1)
    8000267c:	6980                	ld	s0,16(a1)
    8000267e:	6d84                	ld	s1,24(a1)
    80002680:	0205b903          	ld	s2,32(a1)
    80002684:	0285b983          	ld	s3,40(a1)
    80002688:	0305ba03          	ld	s4,48(a1)
    8000268c:	0385ba83          	ld	s5,56(a1)
    80002690:	0405bb03          	ld	s6,64(a1)
    80002694:	0485bb83          	ld	s7,72(a1)
    80002698:	0505bc03          	ld	s8,80(a1)
    8000269c:	0585bc83          	ld	s9,88(a1)
    800026a0:	0605bd03          	ld	s10,96(a1)
    800026a4:	0685bd83          	ld	s11,104(a1)
    800026a8:	8082                	ret

00000000800026aa <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026aa:	1141                	addi	sp,sp,-16
    800026ac:	e406                	sd	ra,8(sp)
    800026ae:	e022                	sd	s0,0(sp)
    800026b0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026b2:	00006597          	auipc	a1,0x6
    800026b6:	c4e58593          	addi	a1,a1,-946 # 80008300 <states.0+0x30>
    800026ba:	00015517          	auipc	a0,0x15
    800026be:	82650513          	addi	a0,a0,-2010 # 80016ee0 <tickslock>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	484080e7          	jalr	1156(ra) # 80000b46 <initlock>
}
    800026ca:	60a2                	ld	ra,8(sp)
    800026cc:	6402                	ld	s0,0(sp)
    800026ce:	0141                	addi	sp,sp,16
    800026d0:	8082                	ret

00000000800026d2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026d2:	1141                	addi	sp,sp,-16
    800026d4:	e422                	sd	s0,8(sp)
    800026d6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d8:	00003797          	auipc	a5,0x3
    800026dc:	53878793          	addi	a5,a5,1336 # 80005c10 <kernelvec>
    800026e0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026e4:	6422                	ld	s0,8(sp)
    800026e6:	0141                	addi	sp,sp,16
    800026e8:	8082                	ret

00000000800026ea <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ea:	1141                	addi	sp,sp,-16
    800026ec:	e406                	sd	ra,8(sp)
    800026ee:	e022                	sd	s0,0(sp)
    800026f0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	2ba080e7          	jalr	698(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002700:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002704:	00005617          	auipc	a2,0x5
    80002708:	8fc60613          	addi	a2,a2,-1796 # 80007000 <_trampoline>
    8000270c:	00005697          	auipc	a3,0x5
    80002710:	8f468693          	addi	a3,a3,-1804 # 80007000 <_trampoline>
    80002714:	8e91                	sub	a3,a3,a2
    80002716:	040007b7          	lui	a5,0x4000
    8000271a:	17fd                	addi	a5,a5,-1
    8000271c:	07b2                	slli	a5,a5,0xc
    8000271e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002724:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002726:	180026f3          	csrr	a3,satp
    8000272a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000272c:	6d38                	ld	a4,88(a0)
    8000272e:	6134                	ld	a3,64(a0)
    80002730:	6585                	lui	a1,0x1
    80002732:	96ae                	add	a3,a3,a1
    80002734:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002736:	6d38                	ld	a4,88(a0)
    80002738:	00000697          	auipc	a3,0x0
    8000273c:	13e68693          	addi	a3,a3,318 # 80002876 <usertrap>
    80002740:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002744:	8692                	mv	a3,tp
    80002746:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002748:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000274c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002750:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002754:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002758:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000275a:	6f18                	ld	a4,24(a4)
    8000275c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002760:	6928                	ld	a0,80(a0)
    80002762:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002764:	00005717          	auipc	a4,0x5
    80002768:	93870713          	addi	a4,a4,-1736 # 8000709c <userret>
    8000276c:	8f11                	sub	a4,a4,a2
    8000276e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002770:	577d                	li	a4,-1
    80002772:	177e                	slli	a4,a4,0x3f
    80002774:	8d59                	or	a0,a0,a4
    80002776:	9782                	jalr	a5
}
    80002778:	60a2                	ld	ra,8(sp)
    8000277a:	6402                	ld	s0,0(sp)
    8000277c:	0141                	addi	sp,sp,16
    8000277e:	8082                	ret

0000000080002780 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002780:	1101                	addi	sp,sp,-32
    80002782:	ec06                	sd	ra,24(sp)
    80002784:	e822                	sd	s0,16(sp)
    80002786:	e426                	sd	s1,8(sp)
    80002788:	e04a                	sd	s2,0(sp)
    8000278a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000278c:	00014917          	auipc	s2,0x14
    80002790:	75490913          	addi	s2,s2,1876 # 80016ee0 <tickslock>
    80002794:	854a                	mv	a0,s2
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	440080e7          	jalr	1088(ra) # 80000bd6 <acquire>
  ticks++;
    8000279e:	00006497          	auipc	s1,0x6
    800027a2:	2a248493          	addi	s1,s1,674 # 80008a40 <ticks>
    800027a6:	409c                	lw	a5,0(s1)
    800027a8:	2785                	addiw	a5,a5,1
    800027aa:	c09c                	sw	a5,0(s1)
  update_time();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	70e080e7          	jalr	1806(ra) # 80001eba <update_time>
  wakeup(&ticks);
    800027b4:	8526                	mv	a0,s1
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	978080e7          	jalr	-1672(ra) # 8000212e <wakeup>
  release(&tickslock);
    800027be:	854a                	mv	a0,s2
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4ca080e7          	jalr	1226(ra) # 80000c8a <release>
}
    800027c8:	60e2                	ld	ra,24(sp)
    800027ca:	6442                	ld	s0,16(sp)
    800027cc:	64a2                	ld	s1,8(sp)
    800027ce:	6902                	ld	s2,0(sp)
    800027d0:	6105                	addi	sp,sp,32
    800027d2:	8082                	ret

00000000800027d4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027d4:	1101                	addi	sp,sp,-32
    800027d6:	ec06                	sd	ra,24(sp)
    800027d8:	e822                	sd	s0,16(sp)
    800027da:	e426                	sd	s1,8(sp)
    800027dc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027de:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027e2:	00074d63          	bltz	a4,800027fc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027e6:	57fd                	li	a5,-1
    800027e8:	17fe                	slli	a5,a5,0x3f
    800027ea:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027ec:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027ee:	06f70363          	beq	a4,a5,80002854 <devintr+0x80>
  }
}
    800027f2:	60e2                	ld	ra,24(sp)
    800027f4:	6442                	ld	s0,16(sp)
    800027f6:	64a2                	ld	s1,8(sp)
    800027f8:	6105                	addi	sp,sp,32
    800027fa:	8082                	ret
     (scause & 0xff) == 9){
    800027fc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002800:	46a5                	li	a3,9
    80002802:	fed792e3          	bne	a5,a3,800027e6 <devintr+0x12>
    int irq = plic_claim();
    80002806:	00003097          	auipc	ra,0x3
    8000280a:	512080e7          	jalr	1298(ra) # 80005d18 <plic_claim>
    8000280e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002810:	47a9                	li	a5,10
    80002812:	02f50763          	beq	a0,a5,80002840 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002816:	4785                	li	a5,1
    80002818:	02f50963          	beq	a0,a5,8000284a <devintr+0x76>
    return 1;
    8000281c:	4505                	li	a0,1
    } else if(irq){
    8000281e:	d8f1                	beqz	s1,800027f2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002820:	85a6                	mv	a1,s1
    80002822:	00006517          	auipc	a0,0x6
    80002826:	ae650513          	addi	a0,a0,-1306 # 80008308 <states.0+0x38>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d5e080e7          	jalr	-674(ra) # 80000588 <printf>
      plic_complete(irq);
    80002832:	8526                	mv	a0,s1
    80002834:	00003097          	auipc	ra,0x3
    80002838:	508080e7          	jalr	1288(ra) # 80005d3c <plic_complete>
    return 1;
    8000283c:	4505                	li	a0,1
    8000283e:	bf55                	j	800027f2 <devintr+0x1e>
      uartintr();
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	15a080e7          	jalr	346(ra) # 8000099a <uartintr>
    80002848:	b7ed                	j	80002832 <devintr+0x5e>
      virtio_disk_intr();
    8000284a:	00004097          	auipc	ra,0x4
    8000284e:	9be080e7          	jalr	-1602(ra) # 80006208 <virtio_disk_intr>
    80002852:	b7c5                	j	80002832 <devintr+0x5e>
    if(cpuid() == 0){
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	12c080e7          	jalr	300(ra) # 80001980 <cpuid>
    8000285c:	c901                	beqz	a0,8000286c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000285e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002862:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002864:	14479073          	csrw	sip,a5
    return 2;
    80002868:	4509                	li	a0,2
    8000286a:	b761                	j	800027f2 <devintr+0x1e>
      clockintr();
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	f14080e7          	jalr	-236(ra) # 80002780 <clockintr>
    80002874:	b7ed                	j	8000285e <devintr+0x8a>

0000000080002876 <usertrap>:
{
    80002876:	1101                	addi	sp,sp,-32
    80002878:	ec06                	sd	ra,24(sp)
    8000287a:	e822                	sd	s0,16(sp)
    8000287c:	e426                	sd	s1,8(sp)
    8000287e:	e04a                	sd	s2,0(sp)
    80002880:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002882:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002886:	1007f793          	andi	a5,a5,256
    8000288a:	e3b1                	bnez	a5,800028ce <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288c:	00003797          	auipc	a5,0x3
    80002890:	38478793          	addi	a5,a5,900 # 80005c10 <kernelvec>
    80002894:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	114080e7          	jalr	276(ra) # 800019ac <myproc>
    800028a0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028a2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a4:	14102773          	csrr	a4,sepc
    800028a8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028aa:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ae:	47a1                	li	a5,8
    800028b0:	02f70763          	beq	a4,a5,800028de <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	f20080e7          	jalr	-224(ra) # 800027d4 <devintr>
    800028bc:	892a                	mv	s2,a0
    800028be:	c151                	beqz	a0,80002942 <usertrap+0xcc>
  if(killed(p))
    800028c0:	8526                	mv	a0,s1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	abc080e7          	jalr	-1348(ra) # 8000237e <killed>
    800028ca:	c929                	beqz	a0,8000291c <usertrap+0xa6>
    800028cc:	a099                	j	80002912 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	a5a50513          	addi	a0,a0,-1446 # 80008328 <states.0+0x58>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>
    if(killed(p))
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	aa0080e7          	jalr	-1376(ra) # 8000237e <killed>
    800028e6:	e921                	bnez	a0,80002936 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028e8:	6cb8                	ld	a4,88(s1)
    800028ea:	6f1c                	ld	a5,24(a4)
    800028ec:	0791                	addi	a5,a5,4
    800028ee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028f4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f8:	10079073          	csrw	sstatus,a5
    syscall();
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	2d4080e7          	jalr	724(ra) # 80002bd0 <syscall>
  if(killed(p))
    80002904:	8526                	mv	a0,s1
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	a78080e7          	jalr	-1416(ra) # 8000237e <killed>
    8000290e:	c911                	beqz	a0,80002922 <usertrap+0xac>
    80002910:	4901                	li	s2,0
    exit(-1);
    80002912:	557d                	li	a0,-1
    80002914:	00000097          	auipc	ra,0x0
    80002918:	8ea080e7          	jalr	-1814(ra) # 800021fe <exit>
  if(which_dev == 2)
    8000291c:	4789                	li	a5,2
    8000291e:	04f90f63          	beq	s2,a5,8000297c <usertrap+0x106>
  usertrapret();
    80002922:	00000097          	auipc	ra,0x0
    80002926:	dc8080e7          	jalr	-568(ra) # 800026ea <usertrapret>
}
    8000292a:	60e2                	ld	ra,24(sp)
    8000292c:	6442                	ld	s0,16(sp)
    8000292e:	64a2                	ld	s1,8(sp)
    80002930:	6902                	ld	s2,0(sp)
    80002932:	6105                	addi	sp,sp,32
    80002934:	8082                	ret
      exit(-1);
    80002936:	557d                	li	a0,-1
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	8c6080e7          	jalr	-1850(ra) # 800021fe <exit>
    80002940:	b765                	j	800028e8 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002942:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002946:	5890                	lw	a2,48(s1)
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	a0050513          	addi	a0,a0,-1536 # 80008348 <states.0+0x78>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	c38080e7          	jalr	-968(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002958:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a1850513          	addi	a0,a0,-1512 # 80008378 <states.0+0xa8>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c20080e7          	jalr	-992(ra) # 80000588 <printf>
    setkilled(p);
    80002970:	8526                	mv	a0,s1
    80002972:	00000097          	auipc	ra,0x0
    80002976:	9e0080e7          	jalr	-1568(ra) # 80002352 <setkilled>
    8000297a:	b769                	j	80002904 <usertrap+0x8e>
    yield();
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	712080e7          	jalr	1810(ra) # 8000208e <yield>
    80002984:	bf79                	j	80002922 <usertrap+0xac>

0000000080002986 <kerneltrap>:
{
    80002986:	7179                	addi	sp,sp,-48
    80002988:	f406                	sd	ra,40(sp)
    8000298a:	f022                	sd	s0,32(sp)
    8000298c:	ec26                	sd	s1,24(sp)
    8000298e:	e84a                	sd	s2,16(sp)
    80002990:	e44e                	sd	s3,8(sp)
    80002992:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002994:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002998:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a0:	1004f793          	andi	a5,s1,256
    800029a4:	cb85                	beqz	a5,800029d4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029aa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ac:	ef85                	bnez	a5,800029e4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	e26080e7          	jalr	-474(ra) # 800027d4 <devintr>
    800029b6:	cd1d                	beqz	a0,800029f4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b8:	4789                	li	a5,2
    800029ba:	06f50a63          	beq	a0,a5,80002a2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029be:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10049073          	csrw	sstatus,s1
}
    800029c6:	70a2                	ld	ra,40(sp)
    800029c8:	7402                	ld	s0,32(sp)
    800029ca:	64e2                	ld	s1,24(sp)
    800029cc:	6942                	ld	s2,16(sp)
    800029ce:	69a2                	ld	s3,8(sp)
    800029d0:	6145                	addi	sp,sp,48
    800029d2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9c450513          	addi	a0,a0,-1596 # 80008398 <states.0+0xc8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b62080e7          	jalr	-1182(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	9dc50513          	addi	a0,a0,-1572 # 800083c0 <states.0+0xf0>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029f4:	85ce                	mv	a1,s3
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	9ea50513          	addi	a0,a0,-1558 # 800083e0 <states.0+0x110>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b8a080e7          	jalr	-1142(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9e250513          	addi	a0,a0,-1566 # 800083f0 <states.0+0x120>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b72080e7          	jalr	-1166(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	9ea50513          	addi	a0,a0,-1558 # 80008408 <states.0+0x138>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b18080e7          	jalr	-1256(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	f7e080e7          	jalr	-130(ra) # 800019ac <myproc>
    80002a36:	d541                	beqz	a0,800029be <kerneltrap+0x38>
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	f74080e7          	jalr	-140(ra) # 800019ac <myproc>
    80002a40:	4d18                	lw	a4,24(a0)
    80002a42:	4791                	li	a5,4
    80002a44:	f6f71de3          	bne	a4,a5,800029be <kerneltrap+0x38>
    yield();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	646080e7          	jalr	1606(ra) # 8000208e <yield>
    80002a50:	b7bd                	j	800029be <kerneltrap+0x38>

0000000080002a52 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
    80002a5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	f4e080e7          	jalr	-178(ra) # 800019ac <myproc>
  switch (n) {
    80002a66:	4795                	li	a5,5
    80002a68:	0497e163          	bltu	a5,s1,80002aaa <argraw+0x58>
    80002a6c:	048a                	slli	s1,s1,0x2
    80002a6e:	00006717          	auipc	a4,0x6
    80002a72:	a9270713          	addi	a4,a4,-1390 # 80008500 <states.0+0x230>
    80002a76:	94ba                	add	s1,s1,a4
    80002a78:	409c                	lw	a5,0(s1)
    80002a7a:	97ba                	add	a5,a5,a4
    80002a7c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
    return p->trapframe->a1;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	7fa8                	ld	a0,120(a5)
    80002a90:	bfcd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a2;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	63c8                	ld	a0,128(a5)
    80002a96:	b7f5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a3;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	67c8                	ld	a0,136(a5)
    80002a9c:	b7dd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a4;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	6bc8                	ld	a0,144(a5)
    80002aa2:	b7c5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a5;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	6fc8                	ld	a0,152(a5)
    80002aa8:	bfe9                	j	80002a82 <argraw+0x30>
  panic("argraw");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	96e50513          	addi	a0,a0,-1682 # 80008418 <states.0+0x148>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>

0000000080002aba <fetchaddr>:
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84aa                	mv	s1,a0
    80002ac8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	ee2080e7          	jalr	-286(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ad2:	653c                	ld	a5,72(a0)
    80002ad4:	02f4f863          	bgeu	s1,a5,80002b04 <fetchaddr+0x4a>
    80002ad8:	00848713          	addi	a4,s1,8
    80002adc:	02e7e663          	bltu	a5,a4,80002b08 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae0:	46a1                	li	a3,8
    80002ae2:	8626                	mv	a2,s1
    80002ae4:	85ca                	mv	a1,s2
    80002ae6:	6928                	ld	a0,80(a0)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	c0c080e7          	jalr	-1012(ra) # 800016f4 <copyin>
    80002af0:	00a03533          	snez	a0,a0
    80002af4:	40a00533          	neg	a0,a0
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6902                	ld	s2,0(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
    return -1;
    80002b04:	557d                	li	a0,-1
    80002b06:	bfcd                	j	80002af8 <fetchaddr+0x3e>
    80002b08:	557d                	li	a0,-1
    80002b0a:	b7fd                	j	80002af8 <fetchaddr+0x3e>

0000000080002b0c <fetchstr>:
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	e84a                	sd	s2,16(sp)
    80002b16:	e44e                	sd	s3,8(sp)
    80002b18:	1800                	addi	s0,sp,48
    80002b1a:	892a                	mv	s2,a0
    80002b1c:	84ae                	mv	s1,a1
    80002b1e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	e8c080e7          	jalr	-372(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b28:	86ce                	mv	a3,s3
    80002b2a:	864a                	mv	a2,s2
    80002b2c:	85a6                	mv	a1,s1
    80002b2e:	6928                	ld	a0,80(a0)
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	c52080e7          	jalr	-942(ra) # 80001782 <copyinstr>
    80002b38:	00054e63          	bltz	a0,80002b54 <fetchstr+0x48>
  return strlen(buf);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	310080e7          	jalr	784(ra) # 80000e4e <strlen>
}
    80002b46:	70a2                	ld	ra,40(sp)
    80002b48:	7402                	ld	s0,32(sp)
    80002b4a:	64e2                	ld	s1,24(sp)
    80002b4c:	6942                	ld	s2,16(sp)
    80002b4e:	69a2                	ld	s3,8(sp)
    80002b50:	6145                	addi	sp,sp,48
    80002b52:	8082                	ret
    return -1;
    80002b54:	557d                	li	a0,-1
    80002b56:	bfc5                	j	80002b46 <fetchstr+0x3a>

0000000080002b58 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
    80002b62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	eee080e7          	jalr	-274(ra) # 80002a52 <argraw>
    80002b6c:	c088                	sw	a0,0(s1)
}
    80002b6e:	60e2                	ld	ra,24(sp)
    80002b70:	6442                	ld	s0,16(sp)
    80002b72:	64a2                	ld	s1,8(sp)
    80002b74:	6105                	addi	sp,sp,32
    80002b76:	8082                	ret

0000000080002b78 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b78:	1101                	addi	sp,sp,-32
    80002b7a:	ec06                	sd	ra,24(sp)
    80002b7c:	e822                	sd	s0,16(sp)
    80002b7e:	e426                	sd	s1,8(sp)
    80002b80:	1000                	addi	s0,sp,32
    80002b82:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	ece080e7          	jalr	-306(ra) # 80002a52 <argraw>
    80002b8c:	e088                	sd	a0,0(s1)
}
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6105                	addi	sp,sp,32
    80002b96:	8082                	ret

0000000080002b98 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b98:	7179                	addi	sp,sp,-48
    80002b9a:	f406                	sd	ra,40(sp)
    80002b9c:	f022                	sd	s0,32(sp)
    80002b9e:	ec26                	sd	s1,24(sp)
    80002ba0:	e84a                	sd	s2,16(sp)
    80002ba2:	1800                	addi	s0,sp,48
    80002ba4:	84ae                	mv	s1,a1
    80002ba6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ba8:	fd840593          	addi	a1,s0,-40
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	fcc080e7          	jalr	-52(ra) # 80002b78 <argaddr>
  return fetchstr(addr, buf, max);
    80002bb4:	864a                	mv	a2,s2
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	fd843503          	ld	a0,-40(s0)
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	f50080e7          	jalr	-176(ra) # 80002b0c <fetchstr>
}
    80002bc4:	70a2                	ld	ra,40(sp)
    80002bc6:	7402                	ld	s0,32(sp)
    80002bc8:	64e2                	ld	s1,24(sp)
    80002bca:	6942                	ld	s2,16(sp)
    80002bcc:	6145                	addi	sp,sp,48
    80002bce:	8082                	ret

0000000080002bd0 <syscall>:
[SYS_trace]   "trace"
};

void
syscall(void)
{
    80002bd0:	7179                	addi	sp,sp,-48
    80002bd2:	f406                	sd	ra,40(sp)
    80002bd4:	f022                	sd	s0,32(sp)
    80002bd6:	ec26                	sd	s1,24(sp)
    80002bd8:	e84a                	sd	s2,16(sp)
    80002bda:	e44e                	sd	s3,8(sp)
    80002bdc:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	dce080e7          	jalr	-562(ra) # 800019ac <myproc>
    80002be6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002be8:	05853903          	ld	s2,88(a0)
    80002bec:	0a893783          	ld	a5,168(s2)
    80002bf0:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bf4:	37fd                	addiw	a5,a5,-1
    80002bf6:	4755                	li	a4,21
    80002bf8:	04f76863          	bltu	a4,a5,80002c48 <syscall+0x78>
    80002bfc:	00399713          	slli	a4,s3,0x3
    80002c00:	00006797          	auipc	a5,0x6
    80002c04:	91878793          	addi	a5,a5,-1768 # 80008518 <syscalls>
    80002c08:	97ba                	add	a5,a5,a4
    80002c0a:	639c                	ld	a5,0(a5)
    80002c0c:	cf95                	beqz	a5,80002c48 <syscall+0x78>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c0e:	9782                	jalr	a5
    80002c10:	06a93823          	sd	a0,112(s2)

    if((p->syscall_tracebits) & (1 << num)){ // is the syscall depicted by num asked to be traced.
    80002c14:	1684a783          	lw	a5,360(s1)
    80002c18:	4137d7bb          	sraw	a5,a5,s3
    80002c1c:	8b85                	andi	a5,a5,1
    80002c1e:	c7a1                	beqz	a5,80002c66 <syscall+0x96>
      printf("%d: syscall %s -> %d\n",p->pid,syscalls_names[num],p->trapframe->a0);
    80002c20:	6cb8                	ld	a4,88(s1)
    80002c22:	098e                	slli	s3,s3,0x3
    80002c24:	00006797          	auipc	a5,0x6
    80002c28:	d3478793          	addi	a5,a5,-716 # 80008958 <syscalls_names>
    80002c2c:	99be                	add	s3,s3,a5
    80002c2e:	7b34                	ld	a3,112(a4)
    80002c30:	0009b603          	ld	a2,0(s3)
    80002c34:	588c                	lw	a1,48(s1)
    80002c36:	00005517          	auipc	a0,0x5
    80002c3a:	7ea50513          	addi	a0,a0,2026 # 80008420 <states.0+0x150>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	94a080e7          	jalr	-1718(ra) # 80000588 <printf>
    80002c46:	a005                	j	80002c66 <syscall+0x96>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c48:	86ce                	mv	a3,s3
    80002c4a:	15848613          	addi	a2,s1,344
    80002c4e:	588c                	lw	a1,48(s1)
    80002c50:	00005517          	auipc	a0,0x5
    80002c54:	7e850513          	addi	a0,a0,2024 # 80008438 <states.0+0x168>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	930080e7          	jalr	-1744(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c60:	6cbc                	ld	a5,88(s1)
    80002c62:	577d                	li	a4,-1
    80002c64:	fbb8                	sd	a4,112(a5)
  }
}
    80002c66:	70a2                	ld	ra,40(sp)
    80002c68:	7402                	ld	s0,32(sp)
    80002c6a:	64e2                	ld	s1,24(sp)
    80002c6c:	6942                	ld	s2,16(sp)
    80002c6e:	69a2                	ld	s3,8(sp)
    80002c70:	6145                	addi	sp,sp,48
    80002c72:	8082                	ret

0000000080002c74 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c74:	1101                	addi	sp,sp,-32
    80002c76:	ec06                	sd	ra,24(sp)
    80002c78:	e822                	sd	s0,16(sp)
    80002c7a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c7c:	fec40593          	addi	a1,s0,-20
    80002c80:	4501                	li	a0,0
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	ed6080e7          	jalr	-298(ra) # 80002b58 <argint>
  exit(n);
    80002c8a:	fec42503          	lw	a0,-20(s0)
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	570080e7          	jalr	1392(ra) # 800021fe <exit>
  return 0;  // not reached
}
    80002c96:	4501                	li	a0,0
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ca0:	1141                	addi	sp,sp,-16
    80002ca2:	e406                	sd	ra,8(sp)
    80002ca4:	e022                	sd	s0,0(sp)
    80002ca6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	d04080e7          	jalr	-764(ra) # 800019ac <myproc>
}
    80002cb0:	5908                	lw	a0,48(a0)
    80002cb2:	60a2                	ld	ra,8(sp)
    80002cb4:	6402                	ld	s0,0(sp)
    80002cb6:	0141                	addi	sp,sp,16
    80002cb8:	8082                	ret

0000000080002cba <sys_fork>:

uint64
sys_fork(void)
{
    80002cba:	1141                	addi	sp,sp,-16
    80002cbc:	e406                	sd	ra,8(sp)
    80002cbe:	e022                	sd	s0,0(sp)
    80002cc0:	0800                	addi	s0,sp,16
  return fork();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	0b0080e7          	jalr	176(ra) # 80001d72 <fork>
}
    80002cca:	60a2                	ld	ra,8(sp)
    80002ccc:	6402                	ld	s0,0(sp)
    80002cce:	0141                	addi	sp,sp,16
    80002cd0:	8082                	ret

0000000080002cd2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cd2:	1101                	addi	sp,sp,-32
    80002cd4:	ec06                	sd	ra,24(sp)
    80002cd6:	e822                	sd	s0,16(sp)
    80002cd8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cda:	fe840593          	addi	a1,s0,-24
    80002cde:	4501                	li	a0,0
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	e98080e7          	jalr	-360(ra) # 80002b78 <argaddr>
  return wait(p);
    80002ce8:	fe843503          	ld	a0,-24(s0)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	6c4080e7          	jalr	1732(ra) # 800023b0 <wait>
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cfc:	7179                	addi	sp,sp,-48
    80002cfe:	f406                	sd	ra,40(sp)
    80002d00:	f022                	sd	s0,32(sp)
    80002d02:	ec26                	sd	s1,24(sp)
    80002d04:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d06:	fdc40593          	addi	a1,s0,-36
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	e4c080e7          	jalr	-436(ra) # 80002b58 <argint>
  addr = myproc()->sz;
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80002d1c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d1e:	fdc42503          	lw	a0,-36(s0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	ff4080e7          	jalr	-12(ra) # 80001d16 <growproc>
    80002d2a:	00054863          	bltz	a0,80002d3a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d2e:	8526                	mv	a0,s1
    80002d30:	70a2                	ld	ra,40(sp)
    80002d32:	7402                	ld	s0,32(sp)
    80002d34:	64e2                	ld	s1,24(sp)
    80002d36:	6145                	addi	sp,sp,48
    80002d38:	8082                	ret
    return -1;
    80002d3a:	54fd                	li	s1,-1
    80002d3c:	bfcd                	j	80002d2e <sys_sbrk+0x32>

0000000080002d3e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d3e:	7139                	addi	sp,sp,-64
    80002d40:	fc06                	sd	ra,56(sp)
    80002d42:	f822                	sd	s0,48(sp)
    80002d44:	f426                	sd	s1,40(sp)
    80002d46:	f04a                	sd	s2,32(sp)
    80002d48:	ec4e                	sd	s3,24(sp)
    80002d4a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d4c:	fcc40593          	addi	a1,s0,-52
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	e06080e7          	jalr	-506(ra) # 80002b58 <argint>
  acquire(&tickslock);
    80002d5a:	00014517          	auipc	a0,0x14
    80002d5e:	18650513          	addi	a0,a0,390 # 80016ee0 <tickslock>
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	e74080e7          	jalr	-396(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d6a:	00006917          	auipc	s2,0x6
    80002d6e:	cd692903          	lw	s2,-810(s2) # 80008a40 <ticks>
  while(ticks - ticks0 < n){
    80002d72:	fcc42783          	lw	a5,-52(s0)
    80002d76:	cf9d                	beqz	a5,80002db4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d78:	00014997          	auipc	s3,0x14
    80002d7c:	16898993          	addi	s3,s3,360 # 80016ee0 <tickslock>
    80002d80:	00006497          	auipc	s1,0x6
    80002d84:	cc048493          	addi	s1,s1,-832 # 80008a40 <ticks>
    if(killed(myproc())){
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	5ee080e7          	jalr	1518(ra) # 8000237e <killed>
    80002d98:	ed15                	bnez	a0,80002dd4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d9a:	85ce                	mv	a1,s3
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	32c080e7          	jalr	812(ra) # 800020ca <sleep>
  while(ticks - ticks0 < n){
    80002da6:	409c                	lw	a5,0(s1)
    80002da8:	412787bb          	subw	a5,a5,s2
    80002dac:	fcc42703          	lw	a4,-52(s0)
    80002db0:	fce7ece3          	bltu	a5,a4,80002d88 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002db4:	00014517          	auipc	a0,0x14
    80002db8:	12c50513          	addi	a0,a0,300 # 80016ee0 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	ece080e7          	jalr	-306(ra) # 80000c8a <release>
  return 0;
    80002dc4:	4501                	li	a0,0
}
    80002dc6:	70e2                	ld	ra,56(sp)
    80002dc8:	7442                	ld	s0,48(sp)
    80002dca:	74a2                	ld	s1,40(sp)
    80002dcc:	7902                	ld	s2,32(sp)
    80002dce:	69e2                	ld	s3,24(sp)
    80002dd0:	6121                	addi	sp,sp,64
    80002dd2:	8082                	ret
      release(&tickslock);
    80002dd4:	00014517          	auipc	a0,0x14
    80002dd8:	10c50513          	addi	a0,a0,268 # 80016ee0 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	eae080e7          	jalr	-338(ra) # 80000c8a <release>
      return -1;
    80002de4:	557d                	li	a0,-1
    80002de6:	b7c5                	j	80002dc6 <sys_sleep+0x88>

0000000080002de8 <sys_kill>:

uint64
sys_kill(void)
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002df0:	fec40593          	addi	a1,s0,-20
    80002df4:	4501                	li	a0,0
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	d62080e7          	jalr	-670(ra) # 80002b58 <argint>
  return kill(pid);
    80002dfe:	fec42503          	lw	a0,-20(s0)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	4de080e7          	jalr	1246(ra) # 800022e0 <kill>
}
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret

0000000080002e12 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e1c:	00014517          	auipc	a0,0x14
    80002e20:	0c450513          	addi	a0,a0,196 # 80016ee0 <tickslock>
    80002e24:	ffffe097          	auipc	ra,0xffffe
    80002e28:	db2080e7          	jalr	-590(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e2c:	00006497          	auipc	s1,0x6
    80002e30:	c144a483          	lw	s1,-1004(s1) # 80008a40 <ticks>
  release(&tickslock);
    80002e34:	00014517          	auipc	a0,0x14
    80002e38:	0ac50513          	addi	a0,a0,172 # 80016ee0 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	e4e080e7          	jalr	-434(ra) # 80000c8a <release>
  return xticks;
}
    80002e44:	02049513          	slli	a0,s1,0x20
    80002e48:	9101                	srli	a0,a0,0x20
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	64a2                	ld	s1,8(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <sys_trace>:

uint64
sys_trace(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	e426                	sd	s1,8(sp)
    80002e5c:	1000                	addi	s0,sp,32
  struct proc* p = myproc();
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	b4e080e7          	jalr	-1202(ra) # 800019ac <myproc>
    80002e66:	84aa                	mv	s1,a0
  argint(0, &(p->syscall_tracebits));
    80002e68:	16850593          	addi	a1,a0,360
    80002e6c:	4501                	li	a0,0
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	cea080e7          	jalr	-790(ra) # 80002b58 <argint>
  if (p->syscall_tracebits < 0)
    80002e76:	1684a503          	lw	a0,360(s1)
    return -1;
  return 0;
    80002e7a:	957d                	srai	a0,a0,0x3f
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	64a2                	ld	s1,8(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e86:	7179                	addi	sp,sp,-48
    80002e88:	f406                	sd	ra,40(sp)
    80002e8a:	f022                	sd	s0,32(sp)
    80002e8c:	ec26                	sd	s1,24(sp)
    80002e8e:	e84a                	sd	s2,16(sp)
    80002e90:	e44e                	sd	s3,8(sp)
    80002e92:	e052                	sd	s4,0(sp)
    80002e94:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e96:	00005597          	auipc	a1,0x5
    80002e9a:	73a58593          	addi	a1,a1,1850 # 800085d0 <syscalls+0xb8>
    80002e9e:	00014517          	auipc	a0,0x14
    80002ea2:	05a50513          	addi	a0,a0,90 # 80016ef8 <bcache>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	ca0080e7          	jalr	-864(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eae:	0001c797          	auipc	a5,0x1c
    80002eb2:	04a78793          	addi	a5,a5,74 # 8001eef8 <bcache+0x8000>
    80002eb6:	0001c717          	auipc	a4,0x1c
    80002eba:	2aa70713          	addi	a4,a4,682 # 8001f160 <bcache+0x8268>
    80002ebe:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ec2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ec6:	00014497          	auipc	s1,0x14
    80002eca:	04a48493          	addi	s1,s1,74 # 80016f10 <bcache+0x18>
    b->next = bcache.head.next;
    80002ece:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ed0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ed2:	00005a17          	auipc	s4,0x5
    80002ed6:	706a0a13          	addi	s4,s4,1798 # 800085d8 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002eda:	2b893783          	ld	a5,696(s2)
    80002ede:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ee0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ee4:	85d2                	mv	a1,s4
    80002ee6:	01048513          	addi	a0,s1,16
    80002eea:	00001097          	auipc	ra,0x1
    80002eee:	4c4080e7          	jalr	1220(ra) # 800043ae <initsleeplock>
    bcache.head.next->prev = b;
    80002ef2:	2b893783          	ld	a5,696(s2)
    80002ef6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ef8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002efc:	45848493          	addi	s1,s1,1112
    80002f00:	fd349de3          	bne	s1,s3,80002eda <binit+0x54>
  }
}
    80002f04:	70a2                	ld	ra,40(sp)
    80002f06:	7402                	ld	s0,32(sp)
    80002f08:	64e2                	ld	s1,24(sp)
    80002f0a:	6942                	ld	s2,16(sp)
    80002f0c:	69a2                	ld	s3,8(sp)
    80002f0e:	6a02                	ld	s4,0(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret

0000000080002f14 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f14:	7179                	addi	sp,sp,-48
    80002f16:	f406                	sd	ra,40(sp)
    80002f18:	f022                	sd	s0,32(sp)
    80002f1a:	ec26                	sd	s1,24(sp)
    80002f1c:	e84a                	sd	s2,16(sp)
    80002f1e:	e44e                	sd	s3,8(sp)
    80002f20:	1800                	addi	s0,sp,48
    80002f22:	892a                	mv	s2,a0
    80002f24:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f26:	00014517          	auipc	a0,0x14
    80002f2a:	fd250513          	addi	a0,a0,-46 # 80016ef8 <bcache>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	ca8080e7          	jalr	-856(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f36:	0001c497          	auipc	s1,0x1c
    80002f3a:	27a4b483          	ld	s1,634(s1) # 8001f1b0 <bcache+0x82b8>
    80002f3e:	0001c797          	auipc	a5,0x1c
    80002f42:	22278793          	addi	a5,a5,546 # 8001f160 <bcache+0x8268>
    80002f46:	02f48f63          	beq	s1,a5,80002f84 <bread+0x70>
    80002f4a:	873e                	mv	a4,a5
    80002f4c:	a021                	j	80002f54 <bread+0x40>
    80002f4e:	68a4                	ld	s1,80(s1)
    80002f50:	02e48a63          	beq	s1,a4,80002f84 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f54:	449c                	lw	a5,8(s1)
    80002f56:	ff279ce3          	bne	a5,s2,80002f4e <bread+0x3a>
    80002f5a:	44dc                	lw	a5,12(s1)
    80002f5c:	ff3799e3          	bne	a5,s3,80002f4e <bread+0x3a>
      b->refcnt++;
    80002f60:	40bc                	lw	a5,64(s1)
    80002f62:	2785                	addiw	a5,a5,1
    80002f64:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f66:	00014517          	auipc	a0,0x14
    80002f6a:	f9250513          	addi	a0,a0,-110 # 80016ef8 <bcache>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f76:	01048513          	addi	a0,s1,16
    80002f7a:	00001097          	auipc	ra,0x1
    80002f7e:	46e080e7          	jalr	1134(ra) # 800043e8 <acquiresleep>
      return b;
    80002f82:	a8b9                	j	80002fe0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f84:	0001c497          	auipc	s1,0x1c
    80002f88:	2244b483          	ld	s1,548(s1) # 8001f1a8 <bcache+0x82b0>
    80002f8c:	0001c797          	auipc	a5,0x1c
    80002f90:	1d478793          	addi	a5,a5,468 # 8001f160 <bcache+0x8268>
    80002f94:	00f48863          	beq	s1,a5,80002fa4 <bread+0x90>
    80002f98:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f9a:	40bc                	lw	a5,64(s1)
    80002f9c:	cf81                	beqz	a5,80002fb4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f9e:	64a4                	ld	s1,72(s1)
    80002fa0:	fee49de3          	bne	s1,a4,80002f9a <bread+0x86>
  panic("bget: no buffers");
    80002fa4:	00005517          	auipc	a0,0x5
    80002fa8:	63c50513          	addi	a0,a0,1596 # 800085e0 <syscalls+0xc8>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>
      b->dev = dev;
    80002fb4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fb8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fbc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fc0:	4785                	li	a5,1
    80002fc2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc4:	00014517          	auipc	a0,0x14
    80002fc8:	f3450513          	addi	a0,a0,-204 # 80016ef8 <bcache>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	cbe080e7          	jalr	-834(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002fd4:	01048513          	addi	a0,s1,16
    80002fd8:	00001097          	auipc	ra,0x1
    80002fdc:	410080e7          	jalr	1040(ra) # 800043e8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fe0:	409c                	lw	a5,0(s1)
    80002fe2:	cb89                	beqz	a5,80002ff4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fe4:	8526                	mv	a0,s1
    80002fe6:	70a2                	ld	ra,40(sp)
    80002fe8:	7402                	ld	s0,32(sp)
    80002fea:	64e2                	ld	s1,24(sp)
    80002fec:	6942                	ld	s2,16(sp)
    80002fee:	69a2                	ld	s3,8(sp)
    80002ff0:	6145                	addi	sp,sp,48
    80002ff2:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ff4:	4581                	li	a1,0
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	00003097          	auipc	ra,0x3
    80002ffc:	fdc080e7          	jalr	-36(ra) # 80005fd4 <virtio_disk_rw>
    b->valid = 1;
    80003000:	4785                	li	a5,1
    80003002:	c09c                	sw	a5,0(s1)
  return b;
    80003004:	b7c5                	j	80002fe4 <bread+0xd0>

0000000080003006 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	e426                	sd	s1,8(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003012:	0541                	addi	a0,a0,16
    80003014:	00001097          	auipc	ra,0x1
    80003018:	46e080e7          	jalr	1134(ra) # 80004482 <holdingsleep>
    8000301c:	cd01                	beqz	a0,80003034 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000301e:	4585                	li	a1,1
    80003020:	8526                	mv	a0,s1
    80003022:	00003097          	auipc	ra,0x3
    80003026:	fb2080e7          	jalr	-78(ra) # 80005fd4 <virtio_disk_rw>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret
    panic("bwrite");
    80003034:	00005517          	auipc	a0,0x5
    80003038:	5c450513          	addi	a0,a0,1476 # 800085f8 <syscalls+0xe0>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	502080e7          	jalr	1282(ra) # 8000053e <panic>

0000000080003044 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	e04a                	sd	s2,0(sp)
    8000304e:	1000                	addi	s0,sp,32
    80003050:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003052:	01050913          	addi	s2,a0,16
    80003056:	854a                	mv	a0,s2
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	42a080e7          	jalr	1066(ra) # 80004482 <holdingsleep>
    80003060:	c92d                	beqz	a0,800030d2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003062:	854a                	mv	a0,s2
    80003064:	00001097          	auipc	ra,0x1
    80003068:	3da080e7          	jalr	986(ra) # 8000443e <releasesleep>

  acquire(&bcache.lock);
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	e8c50513          	addi	a0,a0,-372 # 80016ef8 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	b62080e7          	jalr	-1182(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000307c:	40bc                	lw	a5,64(s1)
    8000307e:	37fd                	addiw	a5,a5,-1
    80003080:	0007871b          	sext.w	a4,a5
    80003084:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003086:	eb05                	bnez	a4,800030b6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003088:	68bc                	ld	a5,80(s1)
    8000308a:	64b8                	ld	a4,72(s1)
    8000308c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000308e:	64bc                	ld	a5,72(s1)
    80003090:	68b8                	ld	a4,80(s1)
    80003092:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003094:	0001c797          	auipc	a5,0x1c
    80003098:	e6478793          	addi	a5,a5,-412 # 8001eef8 <bcache+0x8000>
    8000309c:	2b87b703          	ld	a4,696(a5)
    800030a0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030a2:	0001c717          	auipc	a4,0x1c
    800030a6:	0be70713          	addi	a4,a4,190 # 8001f160 <bcache+0x8268>
    800030aa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ac:	2b87b703          	ld	a4,696(a5)
    800030b0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030b2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030b6:	00014517          	auipc	a0,0x14
    800030ba:	e4250513          	addi	a0,a0,-446 # 80016ef8 <bcache>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	bcc080e7          	jalr	-1076(ra) # 80000c8a <release>
}
    800030c6:	60e2                	ld	ra,24(sp)
    800030c8:	6442                	ld	s0,16(sp)
    800030ca:	64a2                	ld	s1,8(sp)
    800030cc:	6902                	ld	s2,0(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret
    panic("brelse");
    800030d2:	00005517          	auipc	a0,0x5
    800030d6:	52e50513          	addi	a0,a0,1326 # 80008600 <syscalls+0xe8>
    800030da:	ffffd097          	auipc	ra,0xffffd
    800030de:	464080e7          	jalr	1124(ra) # 8000053e <panic>

00000000800030e2 <bpin>:

void
bpin(struct buf *b) {
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	1000                	addi	s0,sp,32
    800030ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	e0a50513          	addi	a0,a0,-502 # 80016ef8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	ae0080e7          	jalr	-1312(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	2785                	addiw	a5,a5,1
    80003102:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003104:	00014517          	auipc	a0,0x14
    80003108:	df450513          	addi	a0,a0,-524 # 80016ef8 <bcache>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	b7e080e7          	jalr	-1154(ra) # 80000c8a <release>
}
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	64a2                	ld	s1,8(sp)
    8000311a:	6105                	addi	sp,sp,32
    8000311c:	8082                	ret

000000008000311e <bunpin>:

void
bunpin(struct buf *b) {
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312a:	00014517          	auipc	a0,0x14
    8000312e:	dce50513          	addi	a0,a0,-562 # 80016ef8 <bcache>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	aa4080e7          	jalr	-1372(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000313a:	40bc                	lw	a5,64(s1)
    8000313c:	37fd                	addiw	a5,a5,-1
    8000313e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003140:	00014517          	auipc	a0,0x14
    80003144:	db850513          	addi	a0,a0,-584 # 80016ef8 <bcache>
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	b42080e7          	jalr	-1214(ra) # 80000c8a <release>
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6105                	addi	sp,sp,32
    80003158:	8082                	ret

000000008000315a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	e426                	sd	s1,8(sp)
    80003162:	e04a                	sd	s2,0(sp)
    80003164:	1000                	addi	s0,sp,32
    80003166:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003168:	00d5d59b          	srliw	a1,a1,0xd
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	4687a783          	lw	a5,1128(a5) # 8001f5d4 <sb+0x1c>
    80003174:	9dbd                	addw	a1,a1,a5
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	d9e080e7          	jalr	-610(ra) # 80002f14 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000317e:	0074f713          	andi	a4,s1,7
    80003182:	4785                	li	a5,1
    80003184:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003188:	14ce                	slli	s1,s1,0x33
    8000318a:	90d9                	srli	s1,s1,0x36
    8000318c:	00950733          	add	a4,a0,s1
    80003190:	05874703          	lbu	a4,88(a4)
    80003194:	00e7f6b3          	and	a3,a5,a4
    80003198:	c69d                	beqz	a3,800031c6 <bfree+0x6c>
    8000319a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000319c:	94aa                	add	s1,s1,a0
    8000319e:	fff7c793          	not	a5,a5
    800031a2:	8ff9                	and	a5,a5,a4
    800031a4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	120080e7          	jalr	288(ra) # 800042c8 <log_write>
  brelse(bp);
    800031b0:	854a                	mv	a0,s2
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	e92080e7          	jalr	-366(ra) # 80003044 <brelse>
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6902                	ld	s2,0(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret
    panic("freeing free block");
    800031c6:	00005517          	auipc	a0,0x5
    800031ca:	44250513          	addi	a0,a0,1090 # 80008608 <syscalls+0xf0>
    800031ce:	ffffd097          	auipc	ra,0xffffd
    800031d2:	370080e7          	jalr	880(ra) # 8000053e <panic>

00000000800031d6 <balloc>:
{
    800031d6:	711d                	addi	sp,sp,-96
    800031d8:	ec86                	sd	ra,88(sp)
    800031da:	e8a2                	sd	s0,80(sp)
    800031dc:	e4a6                	sd	s1,72(sp)
    800031de:	e0ca                	sd	s2,64(sp)
    800031e0:	fc4e                	sd	s3,56(sp)
    800031e2:	f852                	sd	s4,48(sp)
    800031e4:	f456                	sd	s5,40(sp)
    800031e6:	f05a                	sd	s6,32(sp)
    800031e8:	ec5e                	sd	s7,24(sp)
    800031ea:	e862                	sd	s8,16(sp)
    800031ec:	e466                	sd	s9,8(sp)
    800031ee:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031f0:	0001c797          	auipc	a5,0x1c
    800031f4:	3cc7a783          	lw	a5,972(a5) # 8001f5bc <sb+0x4>
    800031f8:	10078163          	beqz	a5,800032fa <balloc+0x124>
    800031fc:	8baa                	mv	s7,a0
    800031fe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003200:	0001cb17          	auipc	s6,0x1c
    80003204:	3b8b0b13          	addi	s6,s6,952 # 8001f5b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003208:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000320a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000320e:	6c89                	lui	s9,0x2
    80003210:	a061                	j	80003298 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003212:	974a                	add	a4,a4,s2
    80003214:	8fd5                	or	a5,a5,a3
    80003216:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	0ac080e7          	jalr	172(ra) # 800042c8 <log_write>
        brelse(bp);
    80003224:	854a                	mv	a0,s2
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	e1e080e7          	jalr	-482(ra) # 80003044 <brelse>
  bp = bread(dev, bno);
    8000322e:	85a6                	mv	a1,s1
    80003230:	855e                	mv	a0,s7
    80003232:	00000097          	auipc	ra,0x0
    80003236:	ce2080e7          	jalr	-798(ra) # 80002f14 <bread>
    8000323a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000323c:	40000613          	li	a2,1024
    80003240:	4581                	li	a1,0
    80003242:	05850513          	addi	a0,a0,88
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	a8c080e7          	jalr	-1396(ra) # 80000cd2 <memset>
  log_write(bp);
    8000324e:	854a                	mv	a0,s2
    80003250:	00001097          	auipc	ra,0x1
    80003254:	078080e7          	jalr	120(ra) # 800042c8 <log_write>
  brelse(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	dea080e7          	jalr	-534(ra) # 80003044 <brelse>
}
    80003262:	8526                	mv	a0,s1
    80003264:	60e6                	ld	ra,88(sp)
    80003266:	6446                	ld	s0,80(sp)
    80003268:	64a6                	ld	s1,72(sp)
    8000326a:	6906                	ld	s2,64(sp)
    8000326c:	79e2                	ld	s3,56(sp)
    8000326e:	7a42                	ld	s4,48(sp)
    80003270:	7aa2                	ld	s5,40(sp)
    80003272:	7b02                	ld	s6,32(sp)
    80003274:	6be2                	ld	s7,24(sp)
    80003276:	6c42                	ld	s8,16(sp)
    80003278:	6ca2                	ld	s9,8(sp)
    8000327a:	6125                	addi	sp,sp,96
    8000327c:	8082                	ret
    brelse(bp);
    8000327e:	854a                	mv	a0,s2
    80003280:	00000097          	auipc	ra,0x0
    80003284:	dc4080e7          	jalr	-572(ra) # 80003044 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003288:	015c87bb          	addw	a5,s9,s5
    8000328c:	00078a9b          	sext.w	s5,a5
    80003290:	004b2703          	lw	a4,4(s6)
    80003294:	06eaf363          	bgeu	s5,a4,800032fa <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003298:	41fad79b          	sraiw	a5,s5,0x1f
    8000329c:	0137d79b          	srliw	a5,a5,0x13
    800032a0:	015787bb          	addw	a5,a5,s5
    800032a4:	40d7d79b          	sraiw	a5,a5,0xd
    800032a8:	01cb2583          	lw	a1,28(s6)
    800032ac:	9dbd                	addw	a1,a1,a5
    800032ae:	855e                	mv	a0,s7
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	c64080e7          	jalr	-924(ra) # 80002f14 <bread>
    800032b8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ba:	004b2503          	lw	a0,4(s6)
    800032be:	000a849b          	sext.w	s1,s5
    800032c2:	8662                	mv	a2,s8
    800032c4:	faa4fde3          	bgeu	s1,a0,8000327e <balloc+0xa8>
      m = 1 << (bi % 8);
    800032c8:	41f6579b          	sraiw	a5,a2,0x1f
    800032cc:	01d7d69b          	srliw	a3,a5,0x1d
    800032d0:	00c6873b          	addw	a4,a3,a2
    800032d4:	00777793          	andi	a5,a4,7
    800032d8:	9f95                	subw	a5,a5,a3
    800032da:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032de:	4037571b          	sraiw	a4,a4,0x3
    800032e2:	00e906b3          	add	a3,s2,a4
    800032e6:	0586c683          	lbu	a3,88(a3)
    800032ea:	00d7f5b3          	and	a1,a5,a3
    800032ee:	d195                	beqz	a1,80003212 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f0:	2605                	addiw	a2,a2,1
    800032f2:	2485                	addiw	s1,s1,1
    800032f4:	fd4618e3          	bne	a2,s4,800032c4 <balloc+0xee>
    800032f8:	b759                	j	8000327e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800032fa:	00005517          	auipc	a0,0x5
    800032fe:	32650513          	addi	a0,a0,806 # 80008620 <syscalls+0x108>
    80003302:	ffffd097          	auipc	ra,0xffffd
    80003306:	286080e7          	jalr	646(ra) # 80000588 <printf>
  return 0;
    8000330a:	4481                	li	s1,0
    8000330c:	bf99                	j	80003262 <balloc+0x8c>

000000008000330e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000330e:	7179                	addi	sp,sp,-48
    80003310:	f406                	sd	ra,40(sp)
    80003312:	f022                	sd	s0,32(sp)
    80003314:	ec26                	sd	s1,24(sp)
    80003316:	e84a                	sd	s2,16(sp)
    80003318:	e44e                	sd	s3,8(sp)
    8000331a:	e052                	sd	s4,0(sp)
    8000331c:	1800                	addi	s0,sp,48
    8000331e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003320:	47ad                	li	a5,11
    80003322:	02b7e763          	bltu	a5,a1,80003350 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003326:	02059493          	slli	s1,a1,0x20
    8000332a:	9081                	srli	s1,s1,0x20
    8000332c:	048a                	slli	s1,s1,0x2
    8000332e:	94aa                	add	s1,s1,a0
    80003330:	0504a903          	lw	s2,80(s1)
    80003334:	06091e63          	bnez	s2,800033b0 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003338:	4108                	lw	a0,0(a0)
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	e9c080e7          	jalr	-356(ra) # 800031d6 <balloc>
    80003342:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003346:	06090563          	beqz	s2,800033b0 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000334a:	0524a823          	sw	s2,80(s1)
    8000334e:	a08d                	j	800033b0 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003350:	ff45849b          	addiw	s1,a1,-12
    80003354:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003358:	0ff00793          	li	a5,255
    8000335c:	08e7e563          	bltu	a5,a4,800033e6 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003360:	08052903          	lw	s2,128(a0)
    80003364:	00091d63          	bnez	s2,8000337e <bmap+0x70>
      addr = balloc(ip->dev);
    80003368:	4108                	lw	a0,0(a0)
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	e6c080e7          	jalr	-404(ra) # 800031d6 <balloc>
    80003372:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003376:	02090d63          	beqz	s2,800033b0 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000337a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000337e:	85ca                	mv	a1,s2
    80003380:	0009a503          	lw	a0,0(s3)
    80003384:	00000097          	auipc	ra,0x0
    80003388:	b90080e7          	jalr	-1136(ra) # 80002f14 <bread>
    8000338c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000338e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003392:	02049593          	slli	a1,s1,0x20
    80003396:	9181                	srli	a1,a1,0x20
    80003398:	058a                	slli	a1,a1,0x2
    8000339a:	00b784b3          	add	s1,a5,a1
    8000339e:	0004a903          	lw	s2,0(s1)
    800033a2:	02090063          	beqz	s2,800033c2 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033a6:	8552                	mv	a0,s4
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	c9c080e7          	jalr	-868(ra) # 80003044 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033b0:	854a                	mv	a0,s2
    800033b2:	70a2                	ld	ra,40(sp)
    800033b4:	7402                	ld	s0,32(sp)
    800033b6:	64e2                	ld	s1,24(sp)
    800033b8:	6942                	ld	s2,16(sp)
    800033ba:	69a2                	ld	s3,8(sp)
    800033bc:	6a02                	ld	s4,0(sp)
    800033be:	6145                	addi	sp,sp,48
    800033c0:	8082                	ret
      addr = balloc(ip->dev);
    800033c2:	0009a503          	lw	a0,0(s3)
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	e10080e7          	jalr	-496(ra) # 800031d6 <balloc>
    800033ce:	0005091b          	sext.w	s2,a0
      if(addr){
    800033d2:	fc090ae3          	beqz	s2,800033a6 <bmap+0x98>
        a[bn] = addr;
    800033d6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033da:	8552                	mv	a0,s4
    800033dc:	00001097          	auipc	ra,0x1
    800033e0:	eec080e7          	jalr	-276(ra) # 800042c8 <log_write>
    800033e4:	b7c9                	j	800033a6 <bmap+0x98>
  panic("bmap: out of range");
    800033e6:	00005517          	auipc	a0,0x5
    800033ea:	25250513          	addi	a0,a0,594 # 80008638 <syscalls+0x120>
    800033ee:	ffffd097          	auipc	ra,0xffffd
    800033f2:	150080e7          	jalr	336(ra) # 8000053e <panic>

00000000800033f6 <iget>:
{
    800033f6:	7179                	addi	sp,sp,-48
    800033f8:	f406                	sd	ra,40(sp)
    800033fa:	f022                	sd	s0,32(sp)
    800033fc:	ec26                	sd	s1,24(sp)
    800033fe:	e84a                	sd	s2,16(sp)
    80003400:	e44e                	sd	s3,8(sp)
    80003402:	e052                	sd	s4,0(sp)
    80003404:	1800                	addi	s0,sp,48
    80003406:	89aa                	mv	s3,a0
    80003408:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000340a:	0001c517          	auipc	a0,0x1c
    8000340e:	1ce50513          	addi	a0,a0,462 # 8001f5d8 <itable>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	7c4080e7          	jalr	1988(ra) # 80000bd6 <acquire>
  empty = 0;
    8000341a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000341c:	0001c497          	auipc	s1,0x1c
    80003420:	1d448493          	addi	s1,s1,468 # 8001f5f0 <itable+0x18>
    80003424:	0001e697          	auipc	a3,0x1e
    80003428:	c5c68693          	addi	a3,a3,-932 # 80021080 <log>
    8000342c:	a039                	j	8000343a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000342e:	02090b63          	beqz	s2,80003464 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003432:	08848493          	addi	s1,s1,136
    80003436:	02d48a63          	beq	s1,a3,8000346a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000343a:	449c                	lw	a5,8(s1)
    8000343c:	fef059e3          	blez	a5,8000342e <iget+0x38>
    80003440:	4098                	lw	a4,0(s1)
    80003442:	ff3716e3          	bne	a4,s3,8000342e <iget+0x38>
    80003446:	40d8                	lw	a4,4(s1)
    80003448:	ff4713e3          	bne	a4,s4,8000342e <iget+0x38>
      ip->ref++;
    8000344c:	2785                	addiw	a5,a5,1
    8000344e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003450:	0001c517          	auipc	a0,0x1c
    80003454:	18850513          	addi	a0,a0,392 # 8001f5d8 <itable>
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	832080e7          	jalr	-1998(ra) # 80000c8a <release>
      return ip;
    80003460:	8926                	mv	s2,s1
    80003462:	a03d                	j	80003490 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003464:	f7f9                	bnez	a5,80003432 <iget+0x3c>
    80003466:	8926                	mv	s2,s1
    80003468:	b7e9                	j	80003432 <iget+0x3c>
  if(empty == 0)
    8000346a:	02090c63          	beqz	s2,800034a2 <iget+0xac>
  ip->dev = dev;
    8000346e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003472:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003476:	4785                	li	a5,1
    80003478:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000347c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003480:	0001c517          	auipc	a0,0x1c
    80003484:	15850513          	addi	a0,a0,344 # 8001f5d8 <itable>
    80003488:	ffffe097          	auipc	ra,0xffffe
    8000348c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
}
    80003490:	854a                	mv	a0,s2
    80003492:	70a2                	ld	ra,40(sp)
    80003494:	7402                	ld	s0,32(sp)
    80003496:	64e2                	ld	s1,24(sp)
    80003498:	6942                	ld	s2,16(sp)
    8000349a:	69a2                	ld	s3,8(sp)
    8000349c:	6a02                	ld	s4,0(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    panic("iget: no inodes");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	1ae50513          	addi	a0,a0,430 # 80008650 <syscalls+0x138>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	094080e7          	jalr	148(ra) # 8000053e <panic>

00000000800034b2 <fsinit>:
fsinit(int dev) {
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	1800                	addi	s0,sp,48
    800034c0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034c2:	4585                	li	a1,1
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	a50080e7          	jalr	-1456(ra) # 80002f14 <bread>
    800034cc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ce:	0001c997          	auipc	s3,0x1c
    800034d2:	0ea98993          	addi	s3,s3,234 # 8001f5b8 <sb>
    800034d6:	02000613          	li	a2,32
    800034da:	05850593          	addi	a1,a0,88
    800034de:	854e                	mv	a0,s3
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	84e080e7          	jalr	-1970(ra) # 80000d2e <memmove>
  brelse(bp);
    800034e8:	8526                	mv	a0,s1
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	b5a080e7          	jalr	-1190(ra) # 80003044 <brelse>
  if(sb.magic != FSMAGIC)
    800034f2:	0009a703          	lw	a4,0(s3)
    800034f6:	102037b7          	lui	a5,0x10203
    800034fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034fe:	02f71263          	bne	a4,a5,80003522 <fsinit+0x70>
  initlog(dev, &sb);
    80003502:	0001c597          	auipc	a1,0x1c
    80003506:	0b658593          	addi	a1,a1,182 # 8001f5b8 <sb>
    8000350a:	854a                	mv	a0,s2
    8000350c:	00001097          	auipc	ra,0x1
    80003510:	b40080e7          	jalr	-1216(ra) # 8000404c <initlog>
}
    80003514:	70a2                	ld	ra,40(sp)
    80003516:	7402                	ld	s0,32(sp)
    80003518:	64e2                	ld	s1,24(sp)
    8000351a:	6942                	ld	s2,16(sp)
    8000351c:	69a2                	ld	s3,8(sp)
    8000351e:	6145                	addi	sp,sp,48
    80003520:	8082                	ret
    panic("invalid file system");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	13e50513          	addi	a0,a0,318 # 80008660 <syscalls+0x148>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	014080e7          	jalr	20(ra) # 8000053e <panic>

0000000080003532 <iinit>:
{
    80003532:	7179                	addi	sp,sp,-48
    80003534:	f406                	sd	ra,40(sp)
    80003536:	f022                	sd	s0,32(sp)
    80003538:	ec26                	sd	s1,24(sp)
    8000353a:	e84a                	sd	s2,16(sp)
    8000353c:	e44e                	sd	s3,8(sp)
    8000353e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003540:	00005597          	auipc	a1,0x5
    80003544:	13858593          	addi	a1,a1,312 # 80008678 <syscalls+0x160>
    80003548:	0001c517          	auipc	a0,0x1c
    8000354c:	09050513          	addi	a0,a0,144 # 8001f5d8 <itable>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	5f6080e7          	jalr	1526(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003558:	0001c497          	auipc	s1,0x1c
    8000355c:	0a848493          	addi	s1,s1,168 # 8001f600 <itable+0x28>
    80003560:	0001e997          	auipc	s3,0x1e
    80003564:	b3098993          	addi	s3,s3,-1232 # 80021090 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003568:	00005917          	auipc	s2,0x5
    8000356c:	11890913          	addi	s2,s2,280 # 80008680 <syscalls+0x168>
    80003570:	85ca                	mv	a1,s2
    80003572:	8526                	mv	a0,s1
    80003574:	00001097          	auipc	ra,0x1
    80003578:	e3a080e7          	jalr	-454(ra) # 800043ae <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000357c:	08848493          	addi	s1,s1,136
    80003580:	ff3498e3          	bne	s1,s3,80003570 <iinit+0x3e>
}
    80003584:	70a2                	ld	ra,40(sp)
    80003586:	7402                	ld	s0,32(sp)
    80003588:	64e2                	ld	s1,24(sp)
    8000358a:	6942                	ld	s2,16(sp)
    8000358c:	69a2                	ld	s3,8(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret

0000000080003592 <ialloc>:
{
    80003592:	715d                	addi	sp,sp,-80
    80003594:	e486                	sd	ra,72(sp)
    80003596:	e0a2                	sd	s0,64(sp)
    80003598:	fc26                	sd	s1,56(sp)
    8000359a:	f84a                	sd	s2,48(sp)
    8000359c:	f44e                	sd	s3,40(sp)
    8000359e:	f052                	sd	s4,32(sp)
    800035a0:	ec56                	sd	s5,24(sp)
    800035a2:	e85a                	sd	s6,16(sp)
    800035a4:	e45e                	sd	s7,8(sp)
    800035a6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a8:	0001c717          	auipc	a4,0x1c
    800035ac:	01c72703          	lw	a4,28(a4) # 8001f5c4 <sb+0xc>
    800035b0:	4785                	li	a5,1
    800035b2:	04e7fa63          	bgeu	a5,a4,80003606 <ialloc+0x74>
    800035b6:	8aaa                	mv	s5,a0
    800035b8:	8bae                	mv	s7,a1
    800035ba:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035bc:	0001ca17          	auipc	s4,0x1c
    800035c0:	ffca0a13          	addi	s4,s4,-4 # 8001f5b8 <sb>
    800035c4:	00048b1b          	sext.w	s6,s1
    800035c8:	0044d793          	srli	a5,s1,0x4
    800035cc:	018a2583          	lw	a1,24(s4)
    800035d0:	9dbd                	addw	a1,a1,a5
    800035d2:	8556                	mv	a0,s5
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	940080e7          	jalr	-1728(ra) # 80002f14 <bread>
    800035dc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035de:	05850993          	addi	s3,a0,88
    800035e2:	00f4f793          	andi	a5,s1,15
    800035e6:	079a                	slli	a5,a5,0x6
    800035e8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ea:	00099783          	lh	a5,0(s3)
    800035ee:	c3a1                	beqz	a5,8000362e <ialloc+0x9c>
    brelse(bp);
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	a54080e7          	jalr	-1452(ra) # 80003044 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f8:	0485                	addi	s1,s1,1
    800035fa:	00ca2703          	lw	a4,12(s4)
    800035fe:	0004879b          	sext.w	a5,s1
    80003602:	fce7e1e3          	bltu	a5,a4,800035c4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003606:	00005517          	auipc	a0,0x5
    8000360a:	08250513          	addi	a0,a0,130 # 80008688 <syscalls+0x170>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	f7a080e7          	jalr	-134(ra) # 80000588 <printf>
  return 0;
    80003616:	4501                	li	a0,0
}
    80003618:	60a6                	ld	ra,72(sp)
    8000361a:	6406                	ld	s0,64(sp)
    8000361c:	74e2                	ld	s1,56(sp)
    8000361e:	7942                	ld	s2,48(sp)
    80003620:	79a2                	ld	s3,40(sp)
    80003622:	7a02                	ld	s4,32(sp)
    80003624:	6ae2                	ld	s5,24(sp)
    80003626:	6b42                	ld	s6,16(sp)
    80003628:	6ba2                	ld	s7,8(sp)
    8000362a:	6161                	addi	sp,sp,80
    8000362c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000362e:	04000613          	li	a2,64
    80003632:	4581                	li	a1,0
    80003634:	854e                	mv	a0,s3
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	69c080e7          	jalr	1692(ra) # 80000cd2 <memset>
      dip->type = type;
    8000363e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003642:	854a                	mv	a0,s2
    80003644:	00001097          	auipc	ra,0x1
    80003648:	c84080e7          	jalr	-892(ra) # 800042c8 <log_write>
      brelse(bp);
    8000364c:	854a                	mv	a0,s2
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	9f6080e7          	jalr	-1546(ra) # 80003044 <brelse>
      return iget(dev, inum);
    80003656:	85da                	mv	a1,s6
    80003658:	8556                	mv	a0,s5
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	d9c080e7          	jalr	-612(ra) # 800033f6 <iget>
    80003662:	bf5d                	j	80003618 <ialloc+0x86>

0000000080003664 <iupdate>:
{
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	e426                	sd	s1,8(sp)
    8000366c:	e04a                	sd	s2,0(sp)
    8000366e:	1000                	addi	s0,sp,32
    80003670:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003672:	415c                	lw	a5,4(a0)
    80003674:	0047d79b          	srliw	a5,a5,0x4
    80003678:	0001c597          	auipc	a1,0x1c
    8000367c:	f585a583          	lw	a1,-168(a1) # 8001f5d0 <sb+0x18>
    80003680:	9dbd                	addw	a1,a1,a5
    80003682:	4108                	lw	a0,0(a0)
    80003684:	00000097          	auipc	ra,0x0
    80003688:	890080e7          	jalr	-1904(ra) # 80002f14 <bread>
    8000368c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000368e:	05850793          	addi	a5,a0,88
    80003692:	40c8                	lw	a0,4(s1)
    80003694:	893d                	andi	a0,a0,15
    80003696:	051a                	slli	a0,a0,0x6
    80003698:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000369a:	04449703          	lh	a4,68(s1)
    8000369e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036a2:	04649703          	lh	a4,70(s1)
    800036a6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036aa:	04849703          	lh	a4,72(s1)
    800036ae:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036b2:	04a49703          	lh	a4,74(s1)
    800036b6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036ba:	44f8                	lw	a4,76(s1)
    800036bc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036be:	03400613          	li	a2,52
    800036c2:	05048593          	addi	a1,s1,80
    800036c6:	0531                	addi	a0,a0,12
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	666080e7          	jalr	1638(ra) # 80000d2e <memmove>
  log_write(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	bf6080e7          	jalr	-1034(ra) # 800042c8 <log_write>
  brelse(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	968080e7          	jalr	-1688(ra) # 80003044 <brelse>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6902                	ld	s2,0(sp)
    800036ec:	6105                	addi	sp,sp,32
    800036ee:	8082                	ret

00000000800036f0 <idup>:
{
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	e426                	sd	s1,8(sp)
    800036f8:	1000                	addi	s0,sp,32
    800036fa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036fc:	0001c517          	auipc	a0,0x1c
    80003700:	edc50513          	addi	a0,a0,-292 # 8001f5d8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	4d2080e7          	jalr	1234(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000370c:	449c                	lw	a5,8(s1)
    8000370e:	2785                	addiw	a5,a5,1
    80003710:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003712:	0001c517          	auipc	a0,0x1c
    80003716:	ec650513          	addi	a0,a0,-314 # 8001f5d8 <itable>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	570080e7          	jalr	1392(ra) # 80000c8a <release>
}
    80003722:	8526                	mv	a0,s1
    80003724:	60e2                	ld	ra,24(sp)
    80003726:	6442                	ld	s0,16(sp)
    80003728:	64a2                	ld	s1,8(sp)
    8000372a:	6105                	addi	sp,sp,32
    8000372c:	8082                	ret

000000008000372e <ilock>:
{
    8000372e:	1101                	addi	sp,sp,-32
    80003730:	ec06                	sd	ra,24(sp)
    80003732:	e822                	sd	s0,16(sp)
    80003734:	e426                	sd	s1,8(sp)
    80003736:	e04a                	sd	s2,0(sp)
    80003738:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000373a:	c115                	beqz	a0,8000375e <ilock+0x30>
    8000373c:	84aa                	mv	s1,a0
    8000373e:	451c                	lw	a5,8(a0)
    80003740:	00f05f63          	blez	a5,8000375e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003744:	0541                	addi	a0,a0,16
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	ca2080e7          	jalr	-862(ra) # 800043e8 <acquiresleep>
  if(ip->valid == 0){
    8000374e:	40bc                	lw	a5,64(s1)
    80003750:	cf99                	beqz	a5,8000376e <ilock+0x40>
}
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	64a2                	ld	s1,8(sp)
    80003758:	6902                	ld	s2,0(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret
    panic("ilock");
    8000375e:	00005517          	auipc	a0,0x5
    80003762:	f4250513          	addi	a0,a0,-190 # 800086a0 <syscalls+0x188>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	dd8080e7          	jalr	-552(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000376e:	40dc                	lw	a5,4(s1)
    80003770:	0047d79b          	srliw	a5,a5,0x4
    80003774:	0001c597          	auipc	a1,0x1c
    80003778:	e5c5a583          	lw	a1,-420(a1) # 8001f5d0 <sb+0x18>
    8000377c:	9dbd                	addw	a1,a1,a5
    8000377e:	4088                	lw	a0,0(s1)
    80003780:	fffff097          	auipc	ra,0xfffff
    80003784:	794080e7          	jalr	1940(ra) # 80002f14 <bread>
    80003788:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000378a:	05850593          	addi	a1,a0,88
    8000378e:	40dc                	lw	a5,4(s1)
    80003790:	8bbd                	andi	a5,a5,15
    80003792:	079a                	slli	a5,a5,0x6
    80003794:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003796:	00059783          	lh	a5,0(a1)
    8000379a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000379e:	00259783          	lh	a5,2(a1)
    800037a2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037a6:	00459783          	lh	a5,4(a1)
    800037aa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ae:	00659783          	lh	a5,6(a1)
    800037b2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037b6:	459c                	lw	a5,8(a1)
    800037b8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ba:	03400613          	li	a2,52
    800037be:	05b1                	addi	a1,a1,12
    800037c0:	05048513          	addi	a0,s1,80
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	56a080e7          	jalr	1386(ra) # 80000d2e <memmove>
    brelse(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	876080e7          	jalr	-1930(ra) # 80003044 <brelse>
    ip->valid = 1;
    800037d6:	4785                	li	a5,1
    800037d8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037da:	04449783          	lh	a5,68(s1)
    800037de:	fbb5                	bnez	a5,80003752 <ilock+0x24>
      panic("ilock: no type");
    800037e0:	00005517          	auipc	a0,0x5
    800037e4:	ec850513          	addi	a0,a0,-312 # 800086a8 <syscalls+0x190>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>

00000000800037f0 <iunlock>:
{
    800037f0:	1101                	addi	sp,sp,-32
    800037f2:	ec06                	sd	ra,24(sp)
    800037f4:	e822                	sd	s0,16(sp)
    800037f6:	e426                	sd	s1,8(sp)
    800037f8:	e04a                	sd	s2,0(sp)
    800037fa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037fc:	c905                	beqz	a0,8000382c <iunlock+0x3c>
    800037fe:	84aa                	mv	s1,a0
    80003800:	01050913          	addi	s2,a0,16
    80003804:	854a                	mv	a0,s2
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	c7c080e7          	jalr	-900(ra) # 80004482 <holdingsleep>
    8000380e:	cd19                	beqz	a0,8000382c <iunlock+0x3c>
    80003810:	449c                	lw	a5,8(s1)
    80003812:	00f05d63          	blez	a5,8000382c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003816:	854a                	mv	a0,s2
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	c26080e7          	jalr	-986(ra) # 8000443e <releasesleep>
}
    80003820:	60e2                	ld	ra,24(sp)
    80003822:	6442                	ld	s0,16(sp)
    80003824:	64a2                	ld	s1,8(sp)
    80003826:	6902                	ld	s2,0(sp)
    80003828:	6105                	addi	sp,sp,32
    8000382a:	8082                	ret
    panic("iunlock");
    8000382c:	00005517          	auipc	a0,0x5
    80003830:	e8c50513          	addi	a0,a0,-372 # 800086b8 <syscalls+0x1a0>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d0a080e7          	jalr	-758(ra) # 8000053e <panic>

000000008000383c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000383c:	7179                	addi	sp,sp,-48
    8000383e:	f406                	sd	ra,40(sp)
    80003840:	f022                	sd	s0,32(sp)
    80003842:	ec26                	sd	s1,24(sp)
    80003844:	e84a                	sd	s2,16(sp)
    80003846:	e44e                	sd	s3,8(sp)
    80003848:	e052                	sd	s4,0(sp)
    8000384a:	1800                	addi	s0,sp,48
    8000384c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000384e:	05050493          	addi	s1,a0,80
    80003852:	08050913          	addi	s2,a0,128
    80003856:	a021                	j	8000385e <itrunc+0x22>
    80003858:	0491                	addi	s1,s1,4
    8000385a:	01248d63          	beq	s1,s2,80003874 <itrunc+0x38>
    if(ip->addrs[i]){
    8000385e:	408c                	lw	a1,0(s1)
    80003860:	dde5                	beqz	a1,80003858 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003862:	0009a503          	lw	a0,0(s3)
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	8f4080e7          	jalr	-1804(ra) # 8000315a <bfree>
      ip->addrs[i] = 0;
    8000386e:	0004a023          	sw	zero,0(s1)
    80003872:	b7dd                	j	80003858 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003874:	0809a583          	lw	a1,128(s3)
    80003878:	e185                	bnez	a1,80003898 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000387a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000387e:	854e                	mv	a0,s3
    80003880:	00000097          	auipc	ra,0x0
    80003884:	de4080e7          	jalr	-540(ra) # 80003664 <iupdate>
}
    80003888:	70a2                	ld	ra,40(sp)
    8000388a:	7402                	ld	s0,32(sp)
    8000388c:	64e2                	ld	s1,24(sp)
    8000388e:	6942                	ld	s2,16(sp)
    80003890:	69a2                	ld	s3,8(sp)
    80003892:	6a02                	ld	s4,0(sp)
    80003894:	6145                	addi	sp,sp,48
    80003896:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003898:	0009a503          	lw	a0,0(s3)
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	678080e7          	jalr	1656(ra) # 80002f14 <bread>
    800038a4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038a6:	05850493          	addi	s1,a0,88
    800038aa:	45850913          	addi	s2,a0,1112
    800038ae:	a021                	j	800038b6 <itrunc+0x7a>
    800038b0:	0491                	addi	s1,s1,4
    800038b2:	01248b63          	beq	s1,s2,800038c8 <itrunc+0x8c>
      if(a[j])
    800038b6:	408c                	lw	a1,0(s1)
    800038b8:	dde5                	beqz	a1,800038b0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	89c080e7          	jalr	-1892(ra) # 8000315a <bfree>
    800038c6:	b7ed                	j	800038b0 <itrunc+0x74>
    brelse(bp);
    800038c8:	8552                	mv	a0,s4
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	77a080e7          	jalr	1914(ra) # 80003044 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038d2:	0809a583          	lw	a1,128(s3)
    800038d6:	0009a503          	lw	a0,0(s3)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	880080e7          	jalr	-1920(ra) # 8000315a <bfree>
    ip->addrs[NDIRECT] = 0;
    800038e2:	0809a023          	sw	zero,128(s3)
    800038e6:	bf51                	j	8000387a <itrunc+0x3e>

00000000800038e8 <iput>:
{
    800038e8:	1101                	addi	sp,sp,-32
    800038ea:	ec06                	sd	ra,24(sp)
    800038ec:	e822                	sd	s0,16(sp)
    800038ee:	e426                	sd	s1,8(sp)
    800038f0:	e04a                	sd	s2,0(sp)
    800038f2:	1000                	addi	s0,sp,32
    800038f4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038f6:	0001c517          	auipc	a0,0x1c
    800038fa:	ce250513          	addi	a0,a0,-798 # 8001f5d8 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	2d8080e7          	jalr	728(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003906:	4498                	lw	a4,8(s1)
    80003908:	4785                	li	a5,1
    8000390a:	02f70363          	beq	a4,a5,80003930 <iput+0x48>
  ip->ref--;
    8000390e:	449c                	lw	a5,8(s1)
    80003910:	37fd                	addiw	a5,a5,-1
    80003912:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003914:	0001c517          	auipc	a0,0x1c
    80003918:	cc450513          	addi	a0,a0,-828 # 8001f5d8 <itable>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	36e080e7          	jalr	878(ra) # 80000c8a <release>
}
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6902                	ld	s2,0(sp)
    8000392c:	6105                	addi	sp,sp,32
    8000392e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003930:	40bc                	lw	a5,64(s1)
    80003932:	dff1                	beqz	a5,8000390e <iput+0x26>
    80003934:	04a49783          	lh	a5,74(s1)
    80003938:	fbf9                	bnez	a5,8000390e <iput+0x26>
    acquiresleep(&ip->lock);
    8000393a:	01048913          	addi	s2,s1,16
    8000393e:	854a                	mv	a0,s2
    80003940:	00001097          	auipc	ra,0x1
    80003944:	aa8080e7          	jalr	-1368(ra) # 800043e8 <acquiresleep>
    release(&itable.lock);
    80003948:	0001c517          	auipc	a0,0x1c
    8000394c:	c9050513          	addi	a0,a0,-880 # 8001f5d8 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	33a080e7          	jalr	826(ra) # 80000c8a <release>
    itrunc(ip);
    80003958:	8526                	mv	a0,s1
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	ee2080e7          	jalr	-286(ra) # 8000383c <itrunc>
    ip->type = 0;
    80003962:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003966:	8526                	mv	a0,s1
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	cfc080e7          	jalr	-772(ra) # 80003664 <iupdate>
    ip->valid = 0;
    80003970:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003974:	854a                	mv	a0,s2
    80003976:	00001097          	auipc	ra,0x1
    8000397a:	ac8080e7          	jalr	-1336(ra) # 8000443e <releasesleep>
    acquire(&itable.lock);
    8000397e:	0001c517          	auipc	a0,0x1c
    80003982:	c5a50513          	addi	a0,a0,-934 # 8001f5d8 <itable>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
    8000398e:	b741                	j	8000390e <iput+0x26>

0000000080003990 <iunlockput>:
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	1000                	addi	s0,sp,32
    8000399a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	e54080e7          	jalr	-428(ra) # 800037f0 <iunlock>
  iput(ip);
    800039a4:	8526                	mv	a0,s1
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	f42080e7          	jalr	-190(ra) # 800038e8 <iput>
}
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret

00000000800039b8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039b8:	1141                	addi	sp,sp,-16
    800039ba:	e422                	sd	s0,8(sp)
    800039bc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039be:	411c                	lw	a5,0(a0)
    800039c0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039c2:	415c                	lw	a5,4(a0)
    800039c4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039c6:	04451783          	lh	a5,68(a0)
    800039ca:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ce:	04a51783          	lh	a5,74(a0)
    800039d2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039d6:	04c56783          	lwu	a5,76(a0)
    800039da:	e99c                	sd	a5,16(a1)
}
    800039dc:	6422                	ld	s0,8(sp)
    800039de:	0141                	addi	sp,sp,16
    800039e0:	8082                	ret

00000000800039e2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039e2:	457c                	lw	a5,76(a0)
    800039e4:	0ed7e963          	bltu	a5,a3,80003ad6 <readi+0xf4>
{
    800039e8:	7159                	addi	sp,sp,-112
    800039ea:	f486                	sd	ra,104(sp)
    800039ec:	f0a2                	sd	s0,96(sp)
    800039ee:	eca6                	sd	s1,88(sp)
    800039f0:	e8ca                	sd	s2,80(sp)
    800039f2:	e4ce                	sd	s3,72(sp)
    800039f4:	e0d2                	sd	s4,64(sp)
    800039f6:	fc56                	sd	s5,56(sp)
    800039f8:	f85a                	sd	s6,48(sp)
    800039fa:	f45e                	sd	s7,40(sp)
    800039fc:	f062                	sd	s8,32(sp)
    800039fe:	ec66                	sd	s9,24(sp)
    80003a00:	e86a                	sd	s10,16(sp)
    80003a02:	e46e                	sd	s11,8(sp)
    80003a04:	1880                	addi	s0,sp,112
    80003a06:	8b2a                	mv	s6,a0
    80003a08:	8bae                	mv	s7,a1
    80003a0a:	8a32                	mv	s4,a2
    80003a0c:	84b6                	mv	s1,a3
    80003a0e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a10:	9f35                	addw	a4,a4,a3
    return 0;
    80003a12:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a14:	0ad76063          	bltu	a4,a3,80003ab4 <readi+0xd2>
  if(off + n > ip->size)
    80003a18:	00e7f463          	bgeu	a5,a4,80003a20 <readi+0x3e>
    n = ip->size - off;
    80003a1c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a20:	0a0a8963          	beqz	s5,80003ad2 <readi+0xf0>
    80003a24:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a26:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a2a:	5c7d                	li	s8,-1
    80003a2c:	a82d                	j	80003a66 <readi+0x84>
    80003a2e:	020d1d93          	slli	s11,s10,0x20
    80003a32:	020ddd93          	srli	s11,s11,0x20
    80003a36:	05890793          	addi	a5,s2,88
    80003a3a:	86ee                	mv	a3,s11
    80003a3c:	963e                	add	a2,a2,a5
    80003a3e:	85d2                	mv	a1,s4
    80003a40:	855e                	mv	a0,s7
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	a9c080e7          	jalr	-1380(ra) # 800024de <either_copyout>
    80003a4a:	05850d63          	beq	a0,s8,80003aa4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a4e:	854a                	mv	a0,s2
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	5f4080e7          	jalr	1524(ra) # 80003044 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a58:	013d09bb          	addw	s3,s10,s3
    80003a5c:	009d04bb          	addw	s1,s10,s1
    80003a60:	9a6e                	add	s4,s4,s11
    80003a62:	0559f763          	bgeu	s3,s5,80003ab0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a66:	00a4d59b          	srliw	a1,s1,0xa
    80003a6a:	855a                	mv	a0,s6
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	8a2080e7          	jalr	-1886(ra) # 8000330e <bmap>
    80003a74:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a78:	cd85                	beqz	a1,80003ab0 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a7a:	000b2503          	lw	a0,0(s6)
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	496080e7          	jalr	1174(ra) # 80002f14 <bread>
    80003a86:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a88:	3ff4f613          	andi	a2,s1,1023
    80003a8c:	40cc87bb          	subw	a5,s9,a2
    80003a90:	413a873b          	subw	a4,s5,s3
    80003a94:	8d3e                	mv	s10,a5
    80003a96:	2781                	sext.w	a5,a5
    80003a98:	0007069b          	sext.w	a3,a4
    80003a9c:	f8f6f9e3          	bgeu	a3,a5,80003a2e <readi+0x4c>
    80003aa0:	8d3a                	mv	s10,a4
    80003aa2:	b771                	j	80003a2e <readi+0x4c>
      brelse(bp);
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	59e080e7          	jalr	1438(ra) # 80003044 <brelse>
      tot = -1;
    80003aae:	59fd                	li	s3,-1
  }
  return tot;
    80003ab0:	0009851b          	sext.w	a0,s3
}
    80003ab4:	70a6                	ld	ra,104(sp)
    80003ab6:	7406                	ld	s0,96(sp)
    80003ab8:	64e6                	ld	s1,88(sp)
    80003aba:	6946                	ld	s2,80(sp)
    80003abc:	69a6                	ld	s3,72(sp)
    80003abe:	6a06                	ld	s4,64(sp)
    80003ac0:	7ae2                	ld	s5,56(sp)
    80003ac2:	7b42                	ld	s6,48(sp)
    80003ac4:	7ba2                	ld	s7,40(sp)
    80003ac6:	7c02                	ld	s8,32(sp)
    80003ac8:	6ce2                	ld	s9,24(sp)
    80003aca:	6d42                	ld	s10,16(sp)
    80003acc:	6da2                	ld	s11,8(sp)
    80003ace:	6165                	addi	sp,sp,112
    80003ad0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad2:	89d6                	mv	s3,s5
    80003ad4:	bff1                	j	80003ab0 <readi+0xce>
    return 0;
    80003ad6:	4501                	li	a0,0
}
    80003ad8:	8082                	ret

0000000080003ada <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ada:	457c                	lw	a5,76(a0)
    80003adc:	10d7e863          	bltu	a5,a3,80003bec <writei+0x112>
{
    80003ae0:	7159                	addi	sp,sp,-112
    80003ae2:	f486                	sd	ra,104(sp)
    80003ae4:	f0a2                	sd	s0,96(sp)
    80003ae6:	eca6                	sd	s1,88(sp)
    80003ae8:	e8ca                	sd	s2,80(sp)
    80003aea:	e4ce                	sd	s3,72(sp)
    80003aec:	e0d2                	sd	s4,64(sp)
    80003aee:	fc56                	sd	s5,56(sp)
    80003af0:	f85a                	sd	s6,48(sp)
    80003af2:	f45e                	sd	s7,40(sp)
    80003af4:	f062                	sd	s8,32(sp)
    80003af6:	ec66                	sd	s9,24(sp)
    80003af8:	e86a                	sd	s10,16(sp)
    80003afa:	e46e                	sd	s11,8(sp)
    80003afc:	1880                	addi	s0,sp,112
    80003afe:	8aaa                	mv	s5,a0
    80003b00:	8bae                	mv	s7,a1
    80003b02:	8a32                	mv	s4,a2
    80003b04:	8936                	mv	s2,a3
    80003b06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b08:	00e687bb          	addw	a5,a3,a4
    80003b0c:	0ed7e263          	bltu	a5,a3,80003bf0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b10:	00043737          	lui	a4,0x43
    80003b14:	0ef76063          	bltu	a4,a5,80003bf4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b18:	0c0b0863          	beqz	s6,80003be8 <writei+0x10e>
    80003b1c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b22:	5c7d                	li	s8,-1
    80003b24:	a091                	j	80003b68 <writei+0x8e>
    80003b26:	020d1d93          	slli	s11,s10,0x20
    80003b2a:	020ddd93          	srli	s11,s11,0x20
    80003b2e:	05848793          	addi	a5,s1,88
    80003b32:	86ee                	mv	a3,s11
    80003b34:	8652                	mv	a2,s4
    80003b36:	85de                	mv	a1,s7
    80003b38:	953e                	add	a0,a0,a5
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	9fa080e7          	jalr	-1542(ra) # 80002534 <either_copyin>
    80003b42:	07850263          	beq	a0,s8,80003ba6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b46:	8526                	mv	a0,s1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	780080e7          	jalr	1920(ra) # 800042c8 <log_write>
    brelse(bp);
    80003b50:	8526                	mv	a0,s1
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	4f2080e7          	jalr	1266(ra) # 80003044 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5a:	013d09bb          	addw	s3,s10,s3
    80003b5e:	012d093b          	addw	s2,s10,s2
    80003b62:	9a6e                	add	s4,s4,s11
    80003b64:	0569f663          	bgeu	s3,s6,80003bb0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b68:	00a9559b          	srliw	a1,s2,0xa
    80003b6c:	8556                	mv	a0,s5
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	7a0080e7          	jalr	1952(ra) # 8000330e <bmap>
    80003b76:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b7a:	c99d                	beqz	a1,80003bb0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b7c:	000aa503          	lw	a0,0(s5)
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	394080e7          	jalr	916(ra) # 80002f14 <bread>
    80003b88:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8a:	3ff97513          	andi	a0,s2,1023
    80003b8e:	40ac87bb          	subw	a5,s9,a0
    80003b92:	413b073b          	subw	a4,s6,s3
    80003b96:	8d3e                	mv	s10,a5
    80003b98:	2781                	sext.w	a5,a5
    80003b9a:	0007069b          	sext.w	a3,a4
    80003b9e:	f8f6f4e3          	bgeu	a3,a5,80003b26 <writei+0x4c>
    80003ba2:	8d3a                	mv	s10,a4
    80003ba4:	b749                	j	80003b26 <writei+0x4c>
      brelse(bp);
    80003ba6:	8526                	mv	a0,s1
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	49c080e7          	jalr	1180(ra) # 80003044 <brelse>
  }

  if(off > ip->size)
    80003bb0:	04caa783          	lw	a5,76(s5)
    80003bb4:	0127f463          	bgeu	a5,s2,80003bbc <writei+0xe2>
    ip->size = off;
    80003bb8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bbc:	8556                	mv	a0,s5
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	aa6080e7          	jalr	-1370(ra) # 80003664 <iupdate>

  return tot;
    80003bc6:	0009851b          	sext.w	a0,s3
}
    80003bca:	70a6                	ld	ra,104(sp)
    80003bcc:	7406                	ld	s0,96(sp)
    80003bce:	64e6                	ld	s1,88(sp)
    80003bd0:	6946                	ld	s2,80(sp)
    80003bd2:	69a6                	ld	s3,72(sp)
    80003bd4:	6a06                	ld	s4,64(sp)
    80003bd6:	7ae2                	ld	s5,56(sp)
    80003bd8:	7b42                	ld	s6,48(sp)
    80003bda:	7ba2                	ld	s7,40(sp)
    80003bdc:	7c02                	ld	s8,32(sp)
    80003bde:	6ce2                	ld	s9,24(sp)
    80003be0:	6d42                	ld	s10,16(sp)
    80003be2:	6da2                	ld	s11,8(sp)
    80003be4:	6165                	addi	sp,sp,112
    80003be6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be8:	89da                	mv	s3,s6
    80003bea:	bfc9                	j	80003bbc <writei+0xe2>
    return -1;
    80003bec:	557d                	li	a0,-1
}
    80003bee:	8082                	ret
    return -1;
    80003bf0:	557d                	li	a0,-1
    80003bf2:	bfe1                	j	80003bca <writei+0xf0>
    return -1;
    80003bf4:	557d                	li	a0,-1
    80003bf6:	bfd1                	j	80003bca <writei+0xf0>

0000000080003bf8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bf8:	1141                	addi	sp,sp,-16
    80003bfa:	e406                	sd	ra,8(sp)
    80003bfc:	e022                	sd	s0,0(sp)
    80003bfe:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c00:	4639                	li	a2,14
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	1a0080e7          	jalr	416(ra) # 80000da2 <strncmp>
}
    80003c0a:	60a2                	ld	ra,8(sp)
    80003c0c:	6402                	ld	s0,0(sp)
    80003c0e:	0141                	addi	sp,sp,16
    80003c10:	8082                	ret

0000000080003c12 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c12:	7139                	addi	sp,sp,-64
    80003c14:	fc06                	sd	ra,56(sp)
    80003c16:	f822                	sd	s0,48(sp)
    80003c18:	f426                	sd	s1,40(sp)
    80003c1a:	f04a                	sd	s2,32(sp)
    80003c1c:	ec4e                	sd	s3,24(sp)
    80003c1e:	e852                	sd	s4,16(sp)
    80003c20:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c22:	04451703          	lh	a4,68(a0)
    80003c26:	4785                	li	a5,1
    80003c28:	00f71a63          	bne	a4,a5,80003c3c <dirlookup+0x2a>
    80003c2c:	892a                	mv	s2,a0
    80003c2e:	89ae                	mv	s3,a1
    80003c30:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c32:	457c                	lw	a5,76(a0)
    80003c34:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c36:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c38:	e79d                	bnez	a5,80003c66 <dirlookup+0x54>
    80003c3a:	a8a5                	j	80003cb2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c3c:	00005517          	auipc	a0,0x5
    80003c40:	a8450513          	addi	a0,a0,-1404 # 800086c0 <syscalls+0x1a8>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	8fa080e7          	jalr	-1798(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c4c:	00005517          	auipc	a0,0x5
    80003c50:	a8c50513          	addi	a0,a0,-1396 # 800086d8 <syscalls+0x1c0>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5c:	24c1                	addiw	s1,s1,16
    80003c5e:	04c92783          	lw	a5,76(s2)
    80003c62:	04f4f763          	bgeu	s1,a5,80003cb0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c66:	4741                	li	a4,16
    80003c68:	86a6                	mv	a3,s1
    80003c6a:	fc040613          	addi	a2,s0,-64
    80003c6e:	4581                	li	a1,0
    80003c70:	854a                	mv	a0,s2
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	d70080e7          	jalr	-656(ra) # 800039e2 <readi>
    80003c7a:	47c1                	li	a5,16
    80003c7c:	fcf518e3          	bne	a0,a5,80003c4c <dirlookup+0x3a>
    if(de.inum == 0)
    80003c80:	fc045783          	lhu	a5,-64(s0)
    80003c84:	dfe1                	beqz	a5,80003c5c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c86:	fc240593          	addi	a1,s0,-62
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	f6c080e7          	jalr	-148(ra) # 80003bf8 <namecmp>
    80003c94:	f561                	bnez	a0,80003c5c <dirlookup+0x4a>
      if(poff)
    80003c96:	000a0463          	beqz	s4,80003c9e <dirlookup+0x8c>
        *poff = off;
    80003c9a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c9e:	fc045583          	lhu	a1,-64(s0)
    80003ca2:	00092503          	lw	a0,0(s2)
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	750080e7          	jalr	1872(ra) # 800033f6 <iget>
    80003cae:	a011                	j	80003cb2 <dirlookup+0xa0>
  return 0;
    80003cb0:	4501                	li	a0,0
}
    80003cb2:	70e2                	ld	ra,56(sp)
    80003cb4:	7442                	ld	s0,48(sp)
    80003cb6:	74a2                	ld	s1,40(sp)
    80003cb8:	7902                	ld	s2,32(sp)
    80003cba:	69e2                	ld	s3,24(sp)
    80003cbc:	6a42                	ld	s4,16(sp)
    80003cbe:	6121                	addi	sp,sp,64
    80003cc0:	8082                	ret

0000000080003cc2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cc2:	711d                	addi	sp,sp,-96
    80003cc4:	ec86                	sd	ra,88(sp)
    80003cc6:	e8a2                	sd	s0,80(sp)
    80003cc8:	e4a6                	sd	s1,72(sp)
    80003cca:	e0ca                	sd	s2,64(sp)
    80003ccc:	fc4e                	sd	s3,56(sp)
    80003cce:	f852                	sd	s4,48(sp)
    80003cd0:	f456                	sd	s5,40(sp)
    80003cd2:	f05a                	sd	s6,32(sp)
    80003cd4:	ec5e                	sd	s7,24(sp)
    80003cd6:	e862                	sd	s8,16(sp)
    80003cd8:	e466                	sd	s9,8(sp)
    80003cda:	1080                	addi	s0,sp,96
    80003cdc:	84aa                	mv	s1,a0
    80003cde:	8aae                	mv	s5,a1
    80003ce0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ce2:	00054703          	lbu	a4,0(a0)
    80003ce6:	02f00793          	li	a5,47
    80003cea:	02f70363          	beq	a4,a5,80003d10 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cee:	ffffe097          	auipc	ra,0xffffe
    80003cf2:	cbe080e7          	jalr	-834(ra) # 800019ac <myproc>
    80003cf6:	15053503          	ld	a0,336(a0)
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	9f6080e7          	jalr	-1546(ra) # 800036f0 <idup>
    80003d02:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d04:	02f00913          	li	s2,47
  len = path - s;
    80003d08:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d0a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d0c:	4b85                	li	s7,1
    80003d0e:	a865                	j	80003dc6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d10:	4585                	li	a1,1
    80003d12:	4505                	li	a0,1
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	6e2080e7          	jalr	1762(ra) # 800033f6 <iget>
    80003d1c:	89aa                	mv	s3,a0
    80003d1e:	b7dd                	j	80003d04 <namex+0x42>
      iunlockput(ip);
    80003d20:	854e                	mv	a0,s3
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	c6e080e7          	jalr	-914(ra) # 80003990 <iunlockput>
      return 0;
    80003d2a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d2c:	854e                	mv	a0,s3
    80003d2e:	60e6                	ld	ra,88(sp)
    80003d30:	6446                	ld	s0,80(sp)
    80003d32:	64a6                	ld	s1,72(sp)
    80003d34:	6906                	ld	s2,64(sp)
    80003d36:	79e2                	ld	s3,56(sp)
    80003d38:	7a42                	ld	s4,48(sp)
    80003d3a:	7aa2                	ld	s5,40(sp)
    80003d3c:	7b02                	ld	s6,32(sp)
    80003d3e:	6be2                	ld	s7,24(sp)
    80003d40:	6c42                	ld	s8,16(sp)
    80003d42:	6ca2                	ld	s9,8(sp)
    80003d44:	6125                	addi	sp,sp,96
    80003d46:	8082                	ret
      iunlock(ip);
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	aa6080e7          	jalr	-1370(ra) # 800037f0 <iunlock>
      return ip;
    80003d52:	bfe9                	j	80003d2c <namex+0x6a>
      iunlockput(ip);
    80003d54:	854e                	mv	a0,s3
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	c3a080e7          	jalr	-966(ra) # 80003990 <iunlockput>
      return 0;
    80003d5e:	89e6                	mv	s3,s9
    80003d60:	b7f1                	j	80003d2c <namex+0x6a>
  len = path - s;
    80003d62:	40b48633          	sub	a2,s1,a1
    80003d66:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d6a:	099c5463          	bge	s8,s9,80003df2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d6e:	4639                	li	a2,14
    80003d70:	8552                	mv	a0,s4
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	fbc080e7          	jalr	-68(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003d7a:	0004c783          	lbu	a5,0(s1)
    80003d7e:	01279763          	bne	a5,s2,80003d8c <namex+0xca>
    path++;
    80003d82:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	ff278de3          	beq	a5,s2,80003d82 <namex+0xc0>
    ilock(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	9a0080e7          	jalr	-1632(ra) # 8000372e <ilock>
    if(ip->type != T_DIR){
    80003d96:	04499783          	lh	a5,68(s3)
    80003d9a:	f97793e3          	bne	a5,s7,80003d20 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d9e:	000a8563          	beqz	s5,80003da8 <namex+0xe6>
    80003da2:	0004c783          	lbu	a5,0(s1)
    80003da6:	d3cd                	beqz	a5,80003d48 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003da8:	865a                	mv	a2,s6
    80003daa:	85d2                	mv	a1,s4
    80003dac:	854e                	mv	a0,s3
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	e64080e7          	jalr	-412(ra) # 80003c12 <dirlookup>
    80003db6:	8caa                	mv	s9,a0
    80003db8:	dd51                	beqz	a0,80003d54 <namex+0x92>
    iunlockput(ip);
    80003dba:	854e                	mv	a0,s3
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	bd4080e7          	jalr	-1068(ra) # 80003990 <iunlockput>
    ip = next;
    80003dc4:	89e6                	mv	s3,s9
  while(*path == '/')
    80003dc6:	0004c783          	lbu	a5,0(s1)
    80003dca:	05279763          	bne	a5,s2,80003e18 <namex+0x156>
    path++;
    80003dce:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dd0:	0004c783          	lbu	a5,0(s1)
    80003dd4:	ff278de3          	beq	a5,s2,80003dce <namex+0x10c>
  if(*path == 0)
    80003dd8:	c79d                	beqz	a5,80003e06 <namex+0x144>
    path++;
    80003dda:	85a6                	mv	a1,s1
  len = path - s;
    80003ddc:	8cda                	mv	s9,s6
    80003dde:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003de0:	01278963          	beq	a5,s2,80003df2 <namex+0x130>
    80003de4:	dfbd                	beqz	a5,80003d62 <namex+0xa0>
    path++;
    80003de6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003de8:	0004c783          	lbu	a5,0(s1)
    80003dec:	ff279ce3          	bne	a5,s2,80003de4 <namex+0x122>
    80003df0:	bf8d                	j	80003d62 <namex+0xa0>
    memmove(name, s, len);
    80003df2:	2601                	sext.w	a2,a2
    80003df4:	8552                	mv	a0,s4
    80003df6:	ffffd097          	auipc	ra,0xffffd
    80003dfa:	f38080e7          	jalr	-200(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003dfe:	9cd2                	add	s9,s9,s4
    80003e00:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e04:	bf9d                	j	80003d7a <namex+0xb8>
  if(nameiparent){
    80003e06:	f20a83e3          	beqz	s5,80003d2c <namex+0x6a>
    iput(ip);
    80003e0a:	854e                	mv	a0,s3
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	adc080e7          	jalr	-1316(ra) # 800038e8 <iput>
    return 0;
    80003e14:	4981                	li	s3,0
    80003e16:	bf19                	j	80003d2c <namex+0x6a>
  if(*path == 0)
    80003e18:	d7fd                	beqz	a5,80003e06 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e1a:	0004c783          	lbu	a5,0(s1)
    80003e1e:	85a6                	mv	a1,s1
    80003e20:	b7d1                	j	80003de4 <namex+0x122>

0000000080003e22 <dirlink>:
{
    80003e22:	7139                	addi	sp,sp,-64
    80003e24:	fc06                	sd	ra,56(sp)
    80003e26:	f822                	sd	s0,48(sp)
    80003e28:	f426                	sd	s1,40(sp)
    80003e2a:	f04a                	sd	s2,32(sp)
    80003e2c:	ec4e                	sd	s3,24(sp)
    80003e2e:	e852                	sd	s4,16(sp)
    80003e30:	0080                	addi	s0,sp,64
    80003e32:	892a                	mv	s2,a0
    80003e34:	8a2e                	mv	s4,a1
    80003e36:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e38:	4601                	li	a2,0
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	dd8080e7          	jalr	-552(ra) # 80003c12 <dirlookup>
    80003e42:	e93d                	bnez	a0,80003eb8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e44:	04c92483          	lw	s1,76(s2)
    80003e48:	c49d                	beqz	s1,80003e76 <dirlink+0x54>
    80003e4a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e4c:	4741                	li	a4,16
    80003e4e:	86a6                	mv	a3,s1
    80003e50:	fc040613          	addi	a2,s0,-64
    80003e54:	4581                	li	a1,0
    80003e56:	854a                	mv	a0,s2
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	b8a080e7          	jalr	-1142(ra) # 800039e2 <readi>
    80003e60:	47c1                	li	a5,16
    80003e62:	06f51163          	bne	a0,a5,80003ec4 <dirlink+0xa2>
    if(de.inum == 0)
    80003e66:	fc045783          	lhu	a5,-64(s0)
    80003e6a:	c791                	beqz	a5,80003e76 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	24c1                	addiw	s1,s1,16
    80003e6e:	04c92783          	lw	a5,76(s2)
    80003e72:	fcf4ede3          	bltu	s1,a5,80003e4c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e76:	4639                	li	a2,14
    80003e78:	85d2                	mv	a1,s4
    80003e7a:	fc240513          	addi	a0,s0,-62
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	f60080e7          	jalr	-160(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e86:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8a:	4741                	li	a4,16
    80003e8c:	86a6                	mv	a3,s1
    80003e8e:	fc040613          	addi	a2,s0,-64
    80003e92:	4581                	li	a1,0
    80003e94:	854a                	mv	a0,s2
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	c44080e7          	jalr	-956(ra) # 80003ada <writei>
    80003e9e:	1541                	addi	a0,a0,-16
    80003ea0:	00a03533          	snez	a0,a0
    80003ea4:	40a00533          	neg	a0,a0
}
    80003ea8:	70e2                	ld	ra,56(sp)
    80003eaa:	7442                	ld	s0,48(sp)
    80003eac:	74a2                	ld	s1,40(sp)
    80003eae:	7902                	ld	s2,32(sp)
    80003eb0:	69e2                	ld	s3,24(sp)
    80003eb2:	6a42                	ld	s4,16(sp)
    80003eb4:	6121                	addi	sp,sp,64
    80003eb6:	8082                	ret
    iput(ip);
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	a30080e7          	jalr	-1488(ra) # 800038e8 <iput>
    return -1;
    80003ec0:	557d                	li	a0,-1
    80003ec2:	b7dd                	j	80003ea8 <dirlink+0x86>
      panic("dirlink read");
    80003ec4:	00005517          	auipc	a0,0x5
    80003ec8:	82450513          	addi	a0,a0,-2012 # 800086e8 <syscalls+0x1d0>
    80003ecc:	ffffc097          	auipc	ra,0xffffc
    80003ed0:	672080e7          	jalr	1650(ra) # 8000053e <panic>

0000000080003ed4 <namei>:

struct inode*
namei(char *path)
{
    80003ed4:	1101                	addi	sp,sp,-32
    80003ed6:	ec06                	sd	ra,24(sp)
    80003ed8:	e822                	sd	s0,16(sp)
    80003eda:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003edc:	fe040613          	addi	a2,s0,-32
    80003ee0:	4581                	li	a1,0
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	de0080e7          	jalr	-544(ra) # 80003cc2 <namex>
}
    80003eea:	60e2                	ld	ra,24(sp)
    80003eec:	6442                	ld	s0,16(sp)
    80003eee:	6105                	addi	sp,sp,32
    80003ef0:	8082                	ret

0000000080003ef2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ef2:	1141                	addi	sp,sp,-16
    80003ef4:	e406                	sd	ra,8(sp)
    80003ef6:	e022                	sd	s0,0(sp)
    80003ef8:	0800                	addi	s0,sp,16
    80003efa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003efc:	4585                	li	a1,1
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	dc4080e7          	jalr	-572(ra) # 80003cc2 <namex>
}
    80003f06:	60a2                	ld	ra,8(sp)
    80003f08:	6402                	ld	s0,0(sp)
    80003f0a:	0141                	addi	sp,sp,16
    80003f0c:	8082                	ret

0000000080003f0e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f0e:	1101                	addi	sp,sp,-32
    80003f10:	ec06                	sd	ra,24(sp)
    80003f12:	e822                	sd	s0,16(sp)
    80003f14:	e426                	sd	s1,8(sp)
    80003f16:	e04a                	sd	s2,0(sp)
    80003f18:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f1a:	0001d917          	auipc	s2,0x1d
    80003f1e:	16690913          	addi	s2,s2,358 # 80021080 <log>
    80003f22:	01892583          	lw	a1,24(s2)
    80003f26:	02892503          	lw	a0,40(s2)
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	fea080e7          	jalr	-22(ra) # 80002f14 <bread>
    80003f32:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f34:	02c92683          	lw	a3,44(s2)
    80003f38:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f3a:	02d05763          	blez	a3,80003f68 <write_head+0x5a>
    80003f3e:	0001d797          	auipc	a5,0x1d
    80003f42:	17278793          	addi	a5,a5,370 # 800210b0 <log+0x30>
    80003f46:	05c50713          	addi	a4,a0,92
    80003f4a:	36fd                	addiw	a3,a3,-1
    80003f4c:	1682                	slli	a3,a3,0x20
    80003f4e:	9281                	srli	a3,a3,0x20
    80003f50:	068a                	slli	a3,a3,0x2
    80003f52:	0001d617          	auipc	a2,0x1d
    80003f56:	16260613          	addi	a2,a2,354 # 800210b4 <log+0x34>
    80003f5a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f5c:	4390                	lw	a2,0(a5)
    80003f5e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f60:	0791                	addi	a5,a5,4
    80003f62:	0711                	addi	a4,a4,4
    80003f64:	fed79ce3          	bne	a5,a3,80003f5c <write_head+0x4e>
  }
  bwrite(buf);
    80003f68:	8526                	mv	a0,s1
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	09c080e7          	jalr	156(ra) # 80003006 <bwrite>
  brelse(buf);
    80003f72:	8526                	mv	a0,s1
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	0d0080e7          	jalr	208(ra) # 80003044 <brelse>
}
    80003f7c:	60e2                	ld	ra,24(sp)
    80003f7e:	6442                	ld	s0,16(sp)
    80003f80:	64a2                	ld	s1,8(sp)
    80003f82:	6902                	ld	s2,0(sp)
    80003f84:	6105                	addi	sp,sp,32
    80003f86:	8082                	ret

0000000080003f88 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f88:	0001d797          	auipc	a5,0x1d
    80003f8c:	1247a783          	lw	a5,292(a5) # 800210ac <log+0x2c>
    80003f90:	0af05d63          	blez	a5,8000404a <install_trans+0xc2>
{
    80003f94:	7139                	addi	sp,sp,-64
    80003f96:	fc06                	sd	ra,56(sp)
    80003f98:	f822                	sd	s0,48(sp)
    80003f9a:	f426                	sd	s1,40(sp)
    80003f9c:	f04a                	sd	s2,32(sp)
    80003f9e:	ec4e                	sd	s3,24(sp)
    80003fa0:	e852                	sd	s4,16(sp)
    80003fa2:	e456                	sd	s5,8(sp)
    80003fa4:	e05a                	sd	s6,0(sp)
    80003fa6:	0080                	addi	s0,sp,64
    80003fa8:	8b2a                	mv	s6,a0
    80003faa:	0001da97          	auipc	s5,0x1d
    80003fae:	106a8a93          	addi	s5,s5,262 # 800210b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fb4:	0001d997          	auipc	s3,0x1d
    80003fb8:	0cc98993          	addi	s3,s3,204 # 80021080 <log>
    80003fbc:	a00d                	j	80003fde <install_trans+0x56>
    brelse(lbuf);
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	084080e7          	jalr	132(ra) # 80003044 <brelse>
    brelse(dbuf);
    80003fc8:	8526                	mv	a0,s1
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	07a080e7          	jalr	122(ra) # 80003044 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd2:	2a05                	addiw	s4,s4,1
    80003fd4:	0a91                	addi	s5,s5,4
    80003fd6:	02c9a783          	lw	a5,44(s3)
    80003fda:	04fa5e63          	bge	s4,a5,80004036 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fde:	0189a583          	lw	a1,24(s3)
    80003fe2:	014585bb          	addw	a1,a1,s4
    80003fe6:	2585                	addiw	a1,a1,1
    80003fe8:	0289a503          	lw	a0,40(s3)
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	f28080e7          	jalr	-216(ra) # 80002f14 <bread>
    80003ff4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ff6:	000aa583          	lw	a1,0(s5)
    80003ffa:	0289a503          	lw	a0,40(s3)
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	f16080e7          	jalr	-234(ra) # 80002f14 <bread>
    80004006:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004008:	40000613          	li	a2,1024
    8000400c:	05890593          	addi	a1,s2,88
    80004010:	05850513          	addi	a0,a0,88
    80004014:	ffffd097          	auipc	ra,0xffffd
    80004018:	d1a080e7          	jalr	-742(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000401c:	8526                	mv	a0,s1
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	fe8080e7          	jalr	-24(ra) # 80003006 <bwrite>
    if(recovering == 0)
    80004026:	f80b1ce3          	bnez	s6,80003fbe <install_trans+0x36>
      bunpin(dbuf);
    8000402a:	8526                	mv	a0,s1
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	0f2080e7          	jalr	242(ra) # 8000311e <bunpin>
    80004034:	b769                	j	80003fbe <install_trans+0x36>
}
    80004036:	70e2                	ld	ra,56(sp)
    80004038:	7442                	ld	s0,48(sp)
    8000403a:	74a2                	ld	s1,40(sp)
    8000403c:	7902                	ld	s2,32(sp)
    8000403e:	69e2                	ld	s3,24(sp)
    80004040:	6a42                	ld	s4,16(sp)
    80004042:	6aa2                	ld	s5,8(sp)
    80004044:	6b02                	ld	s6,0(sp)
    80004046:	6121                	addi	sp,sp,64
    80004048:	8082                	ret
    8000404a:	8082                	ret

000000008000404c <initlog>:
{
    8000404c:	7179                	addi	sp,sp,-48
    8000404e:	f406                	sd	ra,40(sp)
    80004050:	f022                	sd	s0,32(sp)
    80004052:	ec26                	sd	s1,24(sp)
    80004054:	e84a                	sd	s2,16(sp)
    80004056:	e44e                	sd	s3,8(sp)
    80004058:	1800                	addi	s0,sp,48
    8000405a:	892a                	mv	s2,a0
    8000405c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000405e:	0001d497          	auipc	s1,0x1d
    80004062:	02248493          	addi	s1,s1,34 # 80021080 <log>
    80004066:	00004597          	auipc	a1,0x4
    8000406a:	69258593          	addi	a1,a1,1682 # 800086f8 <syscalls+0x1e0>
    8000406e:	8526                	mv	a0,s1
    80004070:	ffffd097          	auipc	ra,0xffffd
    80004074:	ad6080e7          	jalr	-1322(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004078:	0149a583          	lw	a1,20(s3)
    8000407c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000407e:	0109a783          	lw	a5,16(s3)
    80004082:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004084:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004088:	854a                	mv	a0,s2
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	e8a080e7          	jalr	-374(ra) # 80002f14 <bread>
  log.lh.n = lh->n;
    80004092:	4d34                	lw	a3,88(a0)
    80004094:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004096:	02d05563          	blez	a3,800040c0 <initlog+0x74>
    8000409a:	05c50793          	addi	a5,a0,92
    8000409e:	0001d717          	auipc	a4,0x1d
    800040a2:	01270713          	addi	a4,a4,18 # 800210b0 <log+0x30>
    800040a6:	36fd                	addiw	a3,a3,-1
    800040a8:	1682                	slli	a3,a3,0x20
    800040aa:	9281                	srli	a3,a3,0x20
    800040ac:	068a                	slli	a3,a3,0x2
    800040ae:	06050613          	addi	a2,a0,96
    800040b2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040b4:	4390                	lw	a2,0(a5)
    800040b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040b8:	0791                	addi	a5,a5,4
    800040ba:	0711                	addi	a4,a4,4
    800040bc:	fed79ce3          	bne	a5,a3,800040b4 <initlog+0x68>
  brelse(buf);
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	f84080e7          	jalr	-124(ra) # 80003044 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040c8:	4505                	li	a0,1
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	ebe080e7          	jalr	-322(ra) # 80003f88 <install_trans>
  log.lh.n = 0;
    800040d2:	0001d797          	auipc	a5,0x1d
    800040d6:	fc07ad23          	sw	zero,-38(a5) # 800210ac <log+0x2c>
  write_head(); // clear the log
    800040da:	00000097          	auipc	ra,0x0
    800040de:	e34080e7          	jalr	-460(ra) # 80003f0e <write_head>
}
    800040e2:	70a2                	ld	ra,40(sp)
    800040e4:	7402                	ld	s0,32(sp)
    800040e6:	64e2                	ld	s1,24(sp)
    800040e8:	6942                	ld	s2,16(sp)
    800040ea:	69a2                	ld	s3,8(sp)
    800040ec:	6145                	addi	sp,sp,48
    800040ee:	8082                	ret

00000000800040f0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040f0:	1101                	addi	sp,sp,-32
    800040f2:	ec06                	sd	ra,24(sp)
    800040f4:	e822                	sd	s0,16(sp)
    800040f6:	e426                	sd	s1,8(sp)
    800040f8:	e04a                	sd	s2,0(sp)
    800040fa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040fc:	0001d517          	auipc	a0,0x1d
    80004100:	f8450513          	addi	a0,a0,-124 # 80021080 <log>
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	ad2080e7          	jalr	-1326(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000410c:	0001d497          	auipc	s1,0x1d
    80004110:	f7448493          	addi	s1,s1,-140 # 80021080 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004114:	4979                	li	s2,30
    80004116:	a039                	j	80004124 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004118:	85a6                	mv	a1,s1
    8000411a:	8526                	mv	a0,s1
    8000411c:	ffffe097          	auipc	ra,0xffffe
    80004120:	fae080e7          	jalr	-82(ra) # 800020ca <sleep>
    if(log.committing){
    80004124:	50dc                	lw	a5,36(s1)
    80004126:	fbed                	bnez	a5,80004118 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004128:	509c                	lw	a5,32(s1)
    8000412a:	0017871b          	addiw	a4,a5,1
    8000412e:	0007069b          	sext.w	a3,a4
    80004132:	0027179b          	slliw	a5,a4,0x2
    80004136:	9fb9                	addw	a5,a5,a4
    80004138:	0017979b          	slliw	a5,a5,0x1
    8000413c:	54d8                	lw	a4,44(s1)
    8000413e:	9fb9                	addw	a5,a5,a4
    80004140:	00f95963          	bge	s2,a5,80004152 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004144:	85a6                	mv	a1,s1
    80004146:	8526                	mv	a0,s1
    80004148:	ffffe097          	auipc	ra,0xffffe
    8000414c:	f82080e7          	jalr	-126(ra) # 800020ca <sleep>
    80004150:	bfd1                	j	80004124 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004152:	0001d517          	auipc	a0,0x1d
    80004156:	f2e50513          	addi	a0,a0,-210 # 80021080 <log>
    8000415a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004164:	60e2                	ld	ra,24(sp)
    80004166:	6442                	ld	s0,16(sp)
    80004168:	64a2                	ld	s1,8(sp)
    8000416a:	6902                	ld	s2,0(sp)
    8000416c:	6105                	addi	sp,sp,32
    8000416e:	8082                	ret

0000000080004170 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004170:	7139                	addi	sp,sp,-64
    80004172:	fc06                	sd	ra,56(sp)
    80004174:	f822                	sd	s0,48(sp)
    80004176:	f426                	sd	s1,40(sp)
    80004178:	f04a                	sd	s2,32(sp)
    8000417a:	ec4e                	sd	s3,24(sp)
    8000417c:	e852                	sd	s4,16(sp)
    8000417e:	e456                	sd	s5,8(sp)
    80004180:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004182:	0001d497          	auipc	s1,0x1d
    80004186:	efe48493          	addi	s1,s1,-258 # 80021080 <log>
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004194:	509c                	lw	a5,32(s1)
    80004196:	37fd                	addiw	a5,a5,-1
    80004198:	0007891b          	sext.w	s2,a5
    8000419c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000419e:	50dc                	lw	a5,36(s1)
    800041a0:	e7b9                	bnez	a5,800041ee <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041a2:	04091e63          	bnez	s2,800041fe <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041a6:	0001d497          	auipc	s1,0x1d
    800041aa:	eda48493          	addi	s1,s1,-294 # 80021080 <log>
    800041ae:	4785                	li	a5,1
    800041b0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	ad6080e7          	jalr	-1322(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041bc:	54dc                	lw	a5,44(s1)
    800041be:	06f04763          	bgtz	a5,8000422c <end_op+0xbc>
    acquire(&log.lock);
    800041c2:	0001d497          	auipc	s1,0x1d
    800041c6:	ebe48493          	addi	s1,s1,-322 # 80021080 <log>
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	a0a080e7          	jalr	-1526(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800041d4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffe097          	auipc	ra,0xffffe
    800041de:	f54080e7          	jalr	-172(ra) # 8000212e <wakeup>
    release(&log.lock);
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	aa6080e7          	jalr	-1370(ra) # 80000c8a <release>
}
    800041ec:	a03d                	j	8000421a <end_op+0xaa>
    panic("log.committing");
    800041ee:	00004517          	auipc	a0,0x4
    800041f2:	51250513          	addi	a0,a0,1298 # 80008700 <syscalls+0x1e8>
    800041f6:	ffffc097          	auipc	ra,0xffffc
    800041fa:	348080e7          	jalr	840(ra) # 8000053e <panic>
    wakeup(&log);
    800041fe:	0001d497          	auipc	s1,0x1d
    80004202:	e8248493          	addi	s1,s1,-382 # 80021080 <log>
    80004206:	8526                	mv	a0,s1
    80004208:	ffffe097          	auipc	ra,0xffffe
    8000420c:	f26080e7          	jalr	-218(ra) # 8000212e <wakeup>
  release(&log.lock);
    80004210:	8526                	mv	a0,s1
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	a78080e7          	jalr	-1416(ra) # 80000c8a <release>
}
    8000421a:	70e2                	ld	ra,56(sp)
    8000421c:	7442                	ld	s0,48(sp)
    8000421e:	74a2                	ld	s1,40(sp)
    80004220:	7902                	ld	s2,32(sp)
    80004222:	69e2                	ld	s3,24(sp)
    80004224:	6a42                	ld	s4,16(sp)
    80004226:	6aa2                	ld	s5,8(sp)
    80004228:	6121                	addi	sp,sp,64
    8000422a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422c:	0001da97          	auipc	s5,0x1d
    80004230:	e84a8a93          	addi	s5,s5,-380 # 800210b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004234:	0001da17          	auipc	s4,0x1d
    80004238:	e4ca0a13          	addi	s4,s4,-436 # 80021080 <log>
    8000423c:	018a2583          	lw	a1,24(s4)
    80004240:	012585bb          	addw	a1,a1,s2
    80004244:	2585                	addiw	a1,a1,1
    80004246:	028a2503          	lw	a0,40(s4)
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	cca080e7          	jalr	-822(ra) # 80002f14 <bread>
    80004252:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004254:	000aa583          	lw	a1,0(s5)
    80004258:	028a2503          	lw	a0,40(s4)
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	cb8080e7          	jalr	-840(ra) # 80002f14 <bread>
    80004264:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004266:	40000613          	li	a2,1024
    8000426a:	05850593          	addi	a1,a0,88
    8000426e:	05848513          	addi	a0,s1,88
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	abc080e7          	jalr	-1348(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000427a:	8526                	mv	a0,s1
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	d8a080e7          	jalr	-630(ra) # 80003006 <bwrite>
    brelse(from);
    80004284:	854e                	mv	a0,s3
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	dbe080e7          	jalr	-578(ra) # 80003044 <brelse>
    brelse(to);
    8000428e:	8526                	mv	a0,s1
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	db4080e7          	jalr	-588(ra) # 80003044 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004298:	2905                	addiw	s2,s2,1
    8000429a:	0a91                	addi	s5,s5,4
    8000429c:	02ca2783          	lw	a5,44(s4)
    800042a0:	f8f94ee3          	blt	s2,a5,8000423c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	c6a080e7          	jalr	-918(ra) # 80003f0e <write_head>
    install_trans(0); // Now install writes to home locations
    800042ac:	4501                	li	a0,0
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	cda080e7          	jalr	-806(ra) # 80003f88 <install_trans>
    log.lh.n = 0;
    800042b6:	0001d797          	auipc	a5,0x1d
    800042ba:	de07ab23          	sw	zero,-522(a5) # 800210ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	c50080e7          	jalr	-944(ra) # 80003f0e <write_head>
    800042c6:	bdf5                	j	800041c2 <end_op+0x52>

00000000800042c8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042c8:	1101                	addi	sp,sp,-32
    800042ca:	ec06                	sd	ra,24(sp)
    800042cc:	e822                	sd	s0,16(sp)
    800042ce:	e426                	sd	s1,8(sp)
    800042d0:	e04a                	sd	s2,0(sp)
    800042d2:	1000                	addi	s0,sp,32
    800042d4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042d6:	0001d917          	auipc	s2,0x1d
    800042da:	daa90913          	addi	s2,s2,-598 # 80021080 <log>
    800042de:	854a                	mv	a0,s2
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	8f6080e7          	jalr	-1802(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042e8:	02c92603          	lw	a2,44(s2)
    800042ec:	47f5                	li	a5,29
    800042ee:	06c7c563          	blt	a5,a2,80004358 <log_write+0x90>
    800042f2:	0001d797          	auipc	a5,0x1d
    800042f6:	daa7a783          	lw	a5,-598(a5) # 8002109c <log+0x1c>
    800042fa:	37fd                	addiw	a5,a5,-1
    800042fc:	04f65e63          	bge	a2,a5,80004358 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004300:	0001d797          	auipc	a5,0x1d
    80004304:	da07a783          	lw	a5,-608(a5) # 800210a0 <log+0x20>
    80004308:	06f05063          	blez	a5,80004368 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000430c:	4781                	li	a5,0
    8000430e:	06c05563          	blez	a2,80004378 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004312:	44cc                	lw	a1,12(s1)
    80004314:	0001d717          	auipc	a4,0x1d
    80004318:	d9c70713          	addi	a4,a4,-612 # 800210b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000431c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000431e:	4314                	lw	a3,0(a4)
    80004320:	04b68c63          	beq	a3,a1,80004378 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004324:	2785                	addiw	a5,a5,1
    80004326:	0711                	addi	a4,a4,4
    80004328:	fef61be3          	bne	a2,a5,8000431e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000432c:	0621                	addi	a2,a2,8
    8000432e:	060a                	slli	a2,a2,0x2
    80004330:	0001d797          	auipc	a5,0x1d
    80004334:	d5078793          	addi	a5,a5,-688 # 80021080 <log>
    80004338:	963e                	add	a2,a2,a5
    8000433a:	44dc                	lw	a5,12(s1)
    8000433c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000433e:	8526                	mv	a0,s1
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	da2080e7          	jalr	-606(ra) # 800030e2 <bpin>
    log.lh.n++;
    80004348:	0001d717          	auipc	a4,0x1d
    8000434c:	d3870713          	addi	a4,a4,-712 # 80021080 <log>
    80004350:	575c                	lw	a5,44(a4)
    80004352:	2785                	addiw	a5,a5,1
    80004354:	d75c                	sw	a5,44(a4)
    80004356:	a835                	j	80004392 <log_write+0xca>
    panic("too big a transaction");
    80004358:	00004517          	auipc	a0,0x4
    8000435c:	3b850513          	addi	a0,a0,952 # 80008710 <syscalls+0x1f8>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004368:	00004517          	auipc	a0,0x4
    8000436c:	3c050513          	addi	a0,a0,960 # 80008728 <syscalls+0x210>
    80004370:	ffffc097          	auipc	ra,0xffffc
    80004374:	1ce080e7          	jalr	462(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004378:	00878713          	addi	a4,a5,8
    8000437c:	00271693          	slli	a3,a4,0x2
    80004380:	0001d717          	auipc	a4,0x1d
    80004384:	d0070713          	addi	a4,a4,-768 # 80021080 <log>
    80004388:	9736                	add	a4,a4,a3
    8000438a:	44d4                	lw	a3,12(s1)
    8000438c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000438e:	faf608e3          	beq	a2,a5,8000433e <log_write+0x76>
  }
  release(&log.lock);
    80004392:	0001d517          	auipc	a0,0x1d
    80004396:	cee50513          	addi	a0,a0,-786 # 80021080 <log>
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8f0080e7          	jalr	-1808(ra) # 80000c8a <release>
}
    800043a2:	60e2                	ld	ra,24(sp)
    800043a4:	6442                	ld	s0,16(sp)
    800043a6:	64a2                	ld	s1,8(sp)
    800043a8:	6902                	ld	s2,0(sp)
    800043aa:	6105                	addi	sp,sp,32
    800043ac:	8082                	ret

00000000800043ae <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043ae:	1101                	addi	sp,sp,-32
    800043b0:	ec06                	sd	ra,24(sp)
    800043b2:	e822                	sd	s0,16(sp)
    800043b4:	e426                	sd	s1,8(sp)
    800043b6:	e04a                	sd	s2,0(sp)
    800043b8:	1000                	addi	s0,sp,32
    800043ba:	84aa                	mv	s1,a0
    800043bc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043be:	00004597          	auipc	a1,0x4
    800043c2:	38a58593          	addi	a1,a1,906 # 80008748 <syscalls+0x230>
    800043c6:	0521                	addi	a0,a0,8
    800043c8:	ffffc097          	auipc	ra,0xffffc
    800043cc:	77e080e7          	jalr	1918(ra) # 80000b46 <initlock>
  lk->name = name;
    800043d0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d8:	0204a423          	sw	zero,40(s1)
}
    800043dc:	60e2                	ld	ra,24(sp)
    800043de:	6442                	ld	s0,16(sp)
    800043e0:	64a2                	ld	s1,8(sp)
    800043e2:	6902                	ld	s2,0(sp)
    800043e4:	6105                	addi	sp,sp,32
    800043e6:	8082                	ret

00000000800043e8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043e8:	1101                	addi	sp,sp,-32
    800043ea:	ec06                	sd	ra,24(sp)
    800043ec:	e822                	sd	s0,16(sp)
    800043ee:	e426                	sd	s1,8(sp)
    800043f0:	e04a                	sd	s2,0(sp)
    800043f2:	1000                	addi	s0,sp,32
    800043f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043f6:	00850913          	addi	s2,a0,8
    800043fa:	854a                	mv	a0,s2
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	7da080e7          	jalr	2010(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004404:	409c                	lw	a5,0(s1)
    80004406:	cb89                	beqz	a5,80004418 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004408:	85ca                	mv	a1,s2
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffe097          	auipc	ra,0xffffe
    80004410:	cbe080e7          	jalr	-834(ra) # 800020ca <sleep>
  while (lk->locked) {
    80004414:	409c                	lw	a5,0(s1)
    80004416:	fbed                	bnez	a5,80004408 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004418:	4785                	li	a5,1
    8000441a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	590080e7          	jalr	1424(ra) # 800019ac <myproc>
    80004424:	591c                	lw	a5,48(a0)
    80004426:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004428:	854a                	mv	a0,s2
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
}
    80004432:	60e2                	ld	ra,24(sp)
    80004434:	6442                	ld	s0,16(sp)
    80004436:	64a2                	ld	s1,8(sp)
    80004438:	6902                	ld	s2,0(sp)
    8000443a:	6105                	addi	sp,sp,32
    8000443c:	8082                	ret

000000008000443e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000443e:	1101                	addi	sp,sp,-32
    80004440:	ec06                	sd	ra,24(sp)
    80004442:	e822                	sd	s0,16(sp)
    80004444:	e426                	sd	s1,8(sp)
    80004446:	e04a                	sd	s2,0(sp)
    80004448:	1000                	addi	s0,sp,32
    8000444a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000444c:	00850913          	addi	s2,a0,8
    80004450:	854a                	mv	a0,s2
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	784080e7          	jalr	1924(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000445a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000445e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004462:	8526                	mv	a0,s1
    80004464:	ffffe097          	auipc	ra,0xffffe
    80004468:	cca080e7          	jalr	-822(ra) # 8000212e <wakeup>
  release(&lk->lk);
    8000446c:	854a                	mv	a0,s2
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	81c080e7          	jalr	-2020(ra) # 80000c8a <release>
}
    80004476:	60e2                	ld	ra,24(sp)
    80004478:	6442                	ld	s0,16(sp)
    8000447a:	64a2                	ld	s1,8(sp)
    8000447c:	6902                	ld	s2,0(sp)
    8000447e:	6105                	addi	sp,sp,32
    80004480:	8082                	ret

0000000080004482 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004482:	7179                	addi	sp,sp,-48
    80004484:	f406                	sd	ra,40(sp)
    80004486:	f022                	sd	s0,32(sp)
    80004488:	ec26                	sd	s1,24(sp)
    8000448a:	e84a                	sd	s2,16(sp)
    8000448c:	e44e                	sd	s3,8(sp)
    8000448e:	1800                	addi	s0,sp,48
    80004490:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004492:	00850913          	addi	s2,a0,8
    80004496:	854a                	mv	a0,s2
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	73e080e7          	jalr	1854(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a0:	409c                	lw	a5,0(s1)
    800044a2:	ef99                	bnez	a5,800044c0 <holdingsleep+0x3e>
    800044a4:	4481                	li	s1,0
  release(&lk->lk);
    800044a6:	854a                	mv	a0,s2
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	7e2080e7          	jalr	2018(ra) # 80000c8a <release>
  return r;
}
    800044b0:	8526                	mv	a0,s1
    800044b2:	70a2                	ld	ra,40(sp)
    800044b4:	7402                	ld	s0,32(sp)
    800044b6:	64e2                	ld	s1,24(sp)
    800044b8:	6942                	ld	s2,16(sp)
    800044ba:	69a2                	ld	s3,8(sp)
    800044bc:	6145                	addi	sp,sp,48
    800044be:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c0:	0284a983          	lw	s3,40(s1)
    800044c4:	ffffd097          	auipc	ra,0xffffd
    800044c8:	4e8080e7          	jalr	1256(ra) # 800019ac <myproc>
    800044cc:	5904                	lw	s1,48(a0)
    800044ce:	413484b3          	sub	s1,s1,s3
    800044d2:	0014b493          	seqz	s1,s1
    800044d6:	bfc1                	j	800044a6 <holdingsleep+0x24>

00000000800044d8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044d8:	1141                	addi	sp,sp,-16
    800044da:	e406                	sd	ra,8(sp)
    800044dc:	e022                	sd	s0,0(sp)
    800044de:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044e0:	00004597          	auipc	a1,0x4
    800044e4:	27858593          	addi	a1,a1,632 # 80008758 <syscalls+0x240>
    800044e8:	0001d517          	auipc	a0,0x1d
    800044ec:	ce050513          	addi	a0,a0,-800 # 800211c8 <ftable>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	656080e7          	jalr	1622(ra) # 80000b46 <initlock>
}
    800044f8:	60a2                	ld	ra,8(sp)
    800044fa:	6402                	ld	s0,0(sp)
    800044fc:	0141                	addi	sp,sp,16
    800044fe:	8082                	ret

0000000080004500 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004500:	1101                	addi	sp,sp,-32
    80004502:	ec06                	sd	ra,24(sp)
    80004504:	e822                	sd	s0,16(sp)
    80004506:	e426                	sd	s1,8(sp)
    80004508:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	cbe50513          	addi	a0,a0,-834 # 800211c8 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	6c4080e7          	jalr	1732(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000451a:	0001d497          	auipc	s1,0x1d
    8000451e:	cc648493          	addi	s1,s1,-826 # 800211e0 <ftable+0x18>
    80004522:	0001e717          	auipc	a4,0x1e
    80004526:	c5e70713          	addi	a4,a4,-930 # 80022180 <disk>
    if(f->ref == 0){
    8000452a:	40dc                	lw	a5,4(s1)
    8000452c:	cf99                	beqz	a5,8000454a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000452e:	02848493          	addi	s1,s1,40
    80004532:	fee49ce3          	bne	s1,a4,8000452a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004536:	0001d517          	auipc	a0,0x1d
    8000453a:	c9250513          	addi	a0,a0,-878 # 800211c8 <ftable>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	74c080e7          	jalr	1868(ra) # 80000c8a <release>
  return 0;
    80004546:	4481                	li	s1,0
    80004548:	a819                	j	8000455e <filealloc+0x5e>
      f->ref = 1;
    8000454a:	4785                	li	a5,1
    8000454c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000454e:	0001d517          	auipc	a0,0x1d
    80004552:	c7a50513          	addi	a0,a0,-902 # 800211c8 <ftable>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
}
    8000455e:	8526                	mv	a0,s1
    80004560:	60e2                	ld	ra,24(sp)
    80004562:	6442                	ld	s0,16(sp)
    80004564:	64a2                	ld	s1,8(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret

000000008000456a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	1000                	addi	s0,sp,32
    80004574:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004576:	0001d517          	auipc	a0,0x1d
    8000457a:	c5250513          	addi	a0,a0,-942 # 800211c8 <ftable>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	658080e7          	jalr	1624(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004586:	40dc                	lw	a5,4(s1)
    80004588:	02f05263          	blez	a5,800045ac <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000458c:	2785                	addiw	a5,a5,1
    8000458e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004590:	0001d517          	auipc	a0,0x1d
    80004594:	c3850513          	addi	a0,a0,-968 # 800211c8 <ftable>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	6f2080e7          	jalr	1778(ra) # 80000c8a <release>
  return f;
}
    800045a0:	8526                	mv	a0,s1
    800045a2:	60e2                	ld	ra,24(sp)
    800045a4:	6442                	ld	s0,16(sp)
    800045a6:	64a2                	ld	s1,8(sp)
    800045a8:	6105                	addi	sp,sp,32
    800045aa:	8082                	ret
    panic("filedup");
    800045ac:	00004517          	auipc	a0,0x4
    800045b0:	1b450513          	addi	a0,a0,436 # 80008760 <syscalls+0x248>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>

00000000800045bc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045bc:	7139                	addi	sp,sp,-64
    800045be:	fc06                	sd	ra,56(sp)
    800045c0:	f822                	sd	s0,48(sp)
    800045c2:	f426                	sd	s1,40(sp)
    800045c4:	f04a                	sd	s2,32(sp)
    800045c6:	ec4e                	sd	s3,24(sp)
    800045c8:	e852                	sd	s4,16(sp)
    800045ca:	e456                	sd	s5,8(sp)
    800045cc:	0080                	addi	s0,sp,64
    800045ce:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045d0:	0001d517          	auipc	a0,0x1d
    800045d4:	bf850513          	addi	a0,a0,-1032 # 800211c8 <ftable>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	5fe080e7          	jalr	1534(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045e0:	40dc                	lw	a5,4(s1)
    800045e2:	06f05163          	blez	a5,80004644 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045e6:	37fd                	addiw	a5,a5,-1
    800045e8:	0007871b          	sext.w	a4,a5
    800045ec:	c0dc                	sw	a5,4(s1)
    800045ee:	06e04363          	bgtz	a4,80004654 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045f2:	0004a903          	lw	s2,0(s1)
    800045f6:	0094ca83          	lbu	s5,9(s1)
    800045fa:	0104ba03          	ld	s4,16(s1)
    800045fe:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004602:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004606:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	bbe50513          	addi	a0,a0,-1090 # 800211c8 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	678080e7          	jalr	1656(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000461a:	4785                	li	a5,1
    8000461c:	04f90d63          	beq	s2,a5,80004676 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004620:	3979                	addiw	s2,s2,-2
    80004622:	4785                	li	a5,1
    80004624:	0527e063          	bltu	a5,s2,80004664 <fileclose+0xa8>
    begin_op();
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	ac8080e7          	jalr	-1336(ra) # 800040f0 <begin_op>
    iput(ff.ip);
    80004630:	854e                	mv	a0,s3
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	2b6080e7          	jalr	694(ra) # 800038e8 <iput>
    end_op();
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	b36080e7          	jalr	-1226(ra) # 80004170 <end_op>
    80004642:	a00d                	j	80004664 <fileclose+0xa8>
    panic("fileclose");
    80004644:	00004517          	auipc	a0,0x4
    80004648:	12450513          	addi	a0,a0,292 # 80008768 <syscalls+0x250>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004654:	0001d517          	auipc	a0,0x1d
    80004658:	b7450513          	addi	a0,a0,-1164 # 800211c8 <ftable>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	62e080e7          	jalr	1582(ra) # 80000c8a <release>
  }
}
    80004664:	70e2                	ld	ra,56(sp)
    80004666:	7442                	ld	s0,48(sp)
    80004668:	74a2                	ld	s1,40(sp)
    8000466a:	7902                	ld	s2,32(sp)
    8000466c:	69e2                	ld	s3,24(sp)
    8000466e:	6a42                	ld	s4,16(sp)
    80004670:	6aa2                	ld	s5,8(sp)
    80004672:	6121                	addi	sp,sp,64
    80004674:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004676:	85d6                	mv	a1,s5
    80004678:	8552                	mv	a0,s4
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	34c080e7          	jalr	844(ra) # 800049c6 <pipeclose>
    80004682:	b7cd                	j	80004664 <fileclose+0xa8>

0000000080004684 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004684:	715d                	addi	sp,sp,-80
    80004686:	e486                	sd	ra,72(sp)
    80004688:	e0a2                	sd	s0,64(sp)
    8000468a:	fc26                	sd	s1,56(sp)
    8000468c:	f84a                	sd	s2,48(sp)
    8000468e:	f44e                	sd	s3,40(sp)
    80004690:	0880                	addi	s0,sp,80
    80004692:	84aa                	mv	s1,a0
    80004694:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004696:	ffffd097          	auipc	ra,0xffffd
    8000469a:	316080e7          	jalr	790(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000469e:	409c                	lw	a5,0(s1)
    800046a0:	37f9                	addiw	a5,a5,-2
    800046a2:	4705                	li	a4,1
    800046a4:	04f76763          	bltu	a4,a5,800046f2 <filestat+0x6e>
    800046a8:	892a                	mv	s2,a0
    ilock(f->ip);
    800046aa:	6c88                	ld	a0,24(s1)
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	082080e7          	jalr	130(ra) # 8000372e <ilock>
    stati(f->ip, &st);
    800046b4:	fb840593          	addi	a1,s0,-72
    800046b8:	6c88                	ld	a0,24(s1)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	2fe080e7          	jalr	766(ra) # 800039b8 <stati>
    iunlock(f->ip);
    800046c2:	6c88                	ld	a0,24(s1)
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	12c080e7          	jalr	300(ra) # 800037f0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046cc:	46e1                	li	a3,24
    800046ce:	fb840613          	addi	a2,s0,-72
    800046d2:	85ce                	mv	a1,s3
    800046d4:	05093503          	ld	a0,80(s2)
    800046d8:	ffffd097          	auipc	ra,0xffffd
    800046dc:	f90080e7          	jalr	-112(ra) # 80001668 <copyout>
    800046e0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046e4:	60a6                	ld	ra,72(sp)
    800046e6:	6406                	ld	s0,64(sp)
    800046e8:	74e2                	ld	s1,56(sp)
    800046ea:	7942                	ld	s2,48(sp)
    800046ec:	79a2                	ld	s3,40(sp)
    800046ee:	6161                	addi	sp,sp,80
    800046f0:	8082                	ret
  return -1;
    800046f2:	557d                	li	a0,-1
    800046f4:	bfc5                	j	800046e4 <filestat+0x60>

00000000800046f6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046f6:	7179                	addi	sp,sp,-48
    800046f8:	f406                	sd	ra,40(sp)
    800046fa:	f022                	sd	s0,32(sp)
    800046fc:	ec26                	sd	s1,24(sp)
    800046fe:	e84a                	sd	s2,16(sp)
    80004700:	e44e                	sd	s3,8(sp)
    80004702:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004704:	00854783          	lbu	a5,8(a0)
    80004708:	c3d5                	beqz	a5,800047ac <fileread+0xb6>
    8000470a:	84aa                	mv	s1,a0
    8000470c:	89ae                	mv	s3,a1
    8000470e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004710:	411c                	lw	a5,0(a0)
    80004712:	4705                	li	a4,1
    80004714:	04e78963          	beq	a5,a4,80004766 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004718:	470d                	li	a4,3
    8000471a:	04e78d63          	beq	a5,a4,80004774 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000471e:	4709                	li	a4,2
    80004720:	06e79e63          	bne	a5,a4,8000479c <fileread+0xa6>
    ilock(f->ip);
    80004724:	6d08                	ld	a0,24(a0)
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	008080e7          	jalr	8(ra) # 8000372e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000472e:	874a                	mv	a4,s2
    80004730:	5094                	lw	a3,32(s1)
    80004732:	864e                	mv	a2,s3
    80004734:	4585                	li	a1,1
    80004736:	6c88                	ld	a0,24(s1)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	2aa080e7          	jalr	682(ra) # 800039e2 <readi>
    80004740:	892a                	mv	s2,a0
    80004742:	00a05563          	blez	a0,8000474c <fileread+0x56>
      f->off += r;
    80004746:	509c                	lw	a5,32(s1)
    80004748:	9fa9                	addw	a5,a5,a0
    8000474a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000474c:	6c88                	ld	a0,24(s1)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	0a2080e7          	jalr	162(ra) # 800037f0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004756:	854a                	mv	a0,s2
    80004758:	70a2                	ld	ra,40(sp)
    8000475a:	7402                	ld	s0,32(sp)
    8000475c:	64e2                	ld	s1,24(sp)
    8000475e:	6942                	ld	s2,16(sp)
    80004760:	69a2                	ld	s3,8(sp)
    80004762:	6145                	addi	sp,sp,48
    80004764:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004766:	6908                	ld	a0,16(a0)
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	3c6080e7          	jalr	966(ra) # 80004b2e <piperead>
    80004770:	892a                	mv	s2,a0
    80004772:	b7d5                	j	80004756 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004774:	02451783          	lh	a5,36(a0)
    80004778:	03079693          	slli	a3,a5,0x30
    8000477c:	92c1                	srli	a3,a3,0x30
    8000477e:	4725                	li	a4,9
    80004780:	02d76863          	bltu	a4,a3,800047b0 <fileread+0xba>
    80004784:	0792                	slli	a5,a5,0x4
    80004786:	0001d717          	auipc	a4,0x1d
    8000478a:	9a270713          	addi	a4,a4,-1630 # 80021128 <devsw>
    8000478e:	97ba                	add	a5,a5,a4
    80004790:	639c                	ld	a5,0(a5)
    80004792:	c38d                	beqz	a5,800047b4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004794:	4505                	li	a0,1
    80004796:	9782                	jalr	a5
    80004798:	892a                	mv	s2,a0
    8000479a:	bf75                	j	80004756 <fileread+0x60>
    panic("fileread");
    8000479c:	00004517          	auipc	a0,0x4
    800047a0:	fdc50513          	addi	a0,a0,-36 # 80008778 <syscalls+0x260>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	d9a080e7          	jalr	-614(ra) # 8000053e <panic>
    return -1;
    800047ac:	597d                	li	s2,-1
    800047ae:	b765                	j	80004756 <fileread+0x60>
      return -1;
    800047b0:	597d                	li	s2,-1
    800047b2:	b755                	j	80004756 <fileread+0x60>
    800047b4:	597d                	li	s2,-1
    800047b6:	b745                	j	80004756 <fileread+0x60>

00000000800047b8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047b8:	715d                	addi	sp,sp,-80
    800047ba:	e486                	sd	ra,72(sp)
    800047bc:	e0a2                	sd	s0,64(sp)
    800047be:	fc26                	sd	s1,56(sp)
    800047c0:	f84a                	sd	s2,48(sp)
    800047c2:	f44e                	sd	s3,40(sp)
    800047c4:	f052                	sd	s4,32(sp)
    800047c6:	ec56                	sd	s5,24(sp)
    800047c8:	e85a                	sd	s6,16(sp)
    800047ca:	e45e                	sd	s7,8(sp)
    800047cc:	e062                	sd	s8,0(sp)
    800047ce:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047d0:	00954783          	lbu	a5,9(a0)
    800047d4:	10078663          	beqz	a5,800048e0 <filewrite+0x128>
    800047d8:	892a                	mv	s2,a0
    800047da:	8aae                	mv	s5,a1
    800047dc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047de:	411c                	lw	a5,0(a0)
    800047e0:	4705                	li	a4,1
    800047e2:	02e78263          	beq	a5,a4,80004806 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e6:	470d                	li	a4,3
    800047e8:	02e78663          	beq	a5,a4,80004814 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ec:	4709                	li	a4,2
    800047ee:	0ee79163          	bne	a5,a4,800048d0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047f2:	0ac05d63          	blez	a2,800048ac <filewrite+0xf4>
    int i = 0;
    800047f6:	4981                	li	s3,0
    800047f8:	6b05                	lui	s6,0x1
    800047fa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047fe:	6b85                	lui	s7,0x1
    80004800:	c00b8b9b          	addiw	s7,s7,-1024
    80004804:	a861                	j	8000489c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004806:	6908                	ld	a0,16(a0)
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	22e080e7          	jalr	558(ra) # 80004a36 <pipewrite>
    80004810:	8a2a                	mv	s4,a0
    80004812:	a045                	j	800048b2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004814:	02451783          	lh	a5,36(a0)
    80004818:	03079693          	slli	a3,a5,0x30
    8000481c:	92c1                	srli	a3,a3,0x30
    8000481e:	4725                	li	a4,9
    80004820:	0cd76263          	bltu	a4,a3,800048e4 <filewrite+0x12c>
    80004824:	0792                	slli	a5,a5,0x4
    80004826:	0001d717          	auipc	a4,0x1d
    8000482a:	90270713          	addi	a4,a4,-1790 # 80021128 <devsw>
    8000482e:	97ba                	add	a5,a5,a4
    80004830:	679c                	ld	a5,8(a5)
    80004832:	cbdd                	beqz	a5,800048e8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004834:	4505                	li	a0,1
    80004836:	9782                	jalr	a5
    80004838:	8a2a                	mv	s4,a0
    8000483a:	a8a5                	j	800048b2 <filewrite+0xfa>
    8000483c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004840:	00000097          	auipc	ra,0x0
    80004844:	8b0080e7          	jalr	-1872(ra) # 800040f0 <begin_op>
      ilock(f->ip);
    80004848:	01893503          	ld	a0,24(s2)
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	ee2080e7          	jalr	-286(ra) # 8000372e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004854:	8762                	mv	a4,s8
    80004856:	02092683          	lw	a3,32(s2)
    8000485a:	01598633          	add	a2,s3,s5
    8000485e:	4585                	li	a1,1
    80004860:	01893503          	ld	a0,24(s2)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	276080e7          	jalr	630(ra) # 80003ada <writei>
    8000486c:	84aa                	mv	s1,a0
    8000486e:	00a05763          	blez	a0,8000487c <filewrite+0xc4>
        f->off += r;
    80004872:	02092783          	lw	a5,32(s2)
    80004876:	9fa9                	addw	a5,a5,a0
    80004878:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000487c:	01893503          	ld	a0,24(s2)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	f70080e7          	jalr	-144(ra) # 800037f0 <iunlock>
      end_op();
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	8e8080e7          	jalr	-1816(ra) # 80004170 <end_op>

      if(r != n1){
    80004890:	009c1f63          	bne	s8,s1,800048ae <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004894:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004898:	0149db63          	bge	s3,s4,800048ae <filewrite+0xf6>
      int n1 = n - i;
    8000489c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048a0:	84be                	mv	s1,a5
    800048a2:	2781                	sext.w	a5,a5
    800048a4:	f8fb5ce3          	bge	s6,a5,8000483c <filewrite+0x84>
    800048a8:	84de                	mv	s1,s7
    800048aa:	bf49                	j	8000483c <filewrite+0x84>
    int i = 0;
    800048ac:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048ae:	013a1f63          	bne	s4,s3,800048cc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048b2:	8552                	mv	a0,s4
    800048b4:	60a6                	ld	ra,72(sp)
    800048b6:	6406                	ld	s0,64(sp)
    800048b8:	74e2                	ld	s1,56(sp)
    800048ba:	7942                	ld	s2,48(sp)
    800048bc:	79a2                	ld	s3,40(sp)
    800048be:	7a02                	ld	s4,32(sp)
    800048c0:	6ae2                	ld	s5,24(sp)
    800048c2:	6b42                	ld	s6,16(sp)
    800048c4:	6ba2                	ld	s7,8(sp)
    800048c6:	6c02                	ld	s8,0(sp)
    800048c8:	6161                	addi	sp,sp,80
    800048ca:	8082                	ret
    ret = (i == n ? n : -1);
    800048cc:	5a7d                	li	s4,-1
    800048ce:	b7d5                	j	800048b2 <filewrite+0xfa>
    panic("filewrite");
    800048d0:	00004517          	auipc	a0,0x4
    800048d4:	eb850513          	addi	a0,a0,-328 # 80008788 <syscalls+0x270>
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>
    return -1;
    800048e0:	5a7d                	li	s4,-1
    800048e2:	bfc1                	j	800048b2 <filewrite+0xfa>
      return -1;
    800048e4:	5a7d                	li	s4,-1
    800048e6:	b7f1                	j	800048b2 <filewrite+0xfa>
    800048e8:	5a7d                	li	s4,-1
    800048ea:	b7e1                	j	800048b2 <filewrite+0xfa>

00000000800048ec <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048ec:	7179                	addi	sp,sp,-48
    800048ee:	f406                	sd	ra,40(sp)
    800048f0:	f022                	sd	s0,32(sp)
    800048f2:	ec26                	sd	s1,24(sp)
    800048f4:	e84a                	sd	s2,16(sp)
    800048f6:	e44e                	sd	s3,8(sp)
    800048f8:	e052                	sd	s4,0(sp)
    800048fa:	1800                	addi	s0,sp,48
    800048fc:	84aa                	mv	s1,a0
    800048fe:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004900:	0005b023          	sd	zero,0(a1)
    80004904:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	bf8080e7          	jalr	-1032(ra) # 80004500 <filealloc>
    80004910:	e088                	sd	a0,0(s1)
    80004912:	c551                	beqz	a0,8000499e <pipealloc+0xb2>
    80004914:	00000097          	auipc	ra,0x0
    80004918:	bec080e7          	jalr	-1044(ra) # 80004500 <filealloc>
    8000491c:	00aa3023          	sd	a0,0(s4)
    80004920:	c92d                	beqz	a0,80004992 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	1c4080e7          	jalr	452(ra) # 80000ae6 <kalloc>
    8000492a:	892a                	mv	s2,a0
    8000492c:	c125                	beqz	a0,8000498c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000492e:	4985                	li	s3,1
    80004930:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004934:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004938:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000493c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004940:	00004597          	auipc	a1,0x4
    80004944:	b3058593          	addi	a1,a1,-1232 # 80008470 <states.0+0x1a0>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	1fe080e7          	jalr	510(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004950:	609c                	ld	a5,0(s1)
    80004952:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004956:	609c                	ld	a5,0(s1)
    80004958:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000495c:	609c                	ld	a5,0(s1)
    8000495e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004962:	609c                	ld	a5,0(s1)
    80004964:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004968:	000a3783          	ld	a5,0(s4)
    8000496c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004970:	000a3783          	ld	a5,0(s4)
    80004974:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004978:	000a3783          	ld	a5,0(s4)
    8000497c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004980:	000a3783          	ld	a5,0(s4)
    80004984:	0127b823          	sd	s2,16(a5)
  return 0;
    80004988:	4501                	li	a0,0
    8000498a:	a025                	j	800049b2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000498c:	6088                	ld	a0,0(s1)
    8000498e:	e501                	bnez	a0,80004996 <pipealloc+0xaa>
    80004990:	a039                	j	8000499e <pipealloc+0xb2>
    80004992:	6088                	ld	a0,0(s1)
    80004994:	c51d                	beqz	a0,800049c2 <pipealloc+0xd6>
    fileclose(*f0);
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	c26080e7          	jalr	-986(ra) # 800045bc <fileclose>
  if(*f1)
    8000499e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049a2:	557d                	li	a0,-1
  if(*f1)
    800049a4:	c799                	beqz	a5,800049b2 <pipealloc+0xc6>
    fileclose(*f1);
    800049a6:	853e                	mv	a0,a5
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	c14080e7          	jalr	-1004(ra) # 800045bc <fileclose>
  return -1;
    800049b0:	557d                	li	a0,-1
}
    800049b2:	70a2                	ld	ra,40(sp)
    800049b4:	7402                	ld	s0,32(sp)
    800049b6:	64e2                	ld	s1,24(sp)
    800049b8:	6942                	ld	s2,16(sp)
    800049ba:	69a2                	ld	s3,8(sp)
    800049bc:	6a02                	ld	s4,0(sp)
    800049be:	6145                	addi	sp,sp,48
    800049c0:	8082                	ret
  return -1;
    800049c2:	557d                	li	a0,-1
    800049c4:	b7fd                	j	800049b2 <pipealloc+0xc6>

00000000800049c6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049c6:	1101                	addi	sp,sp,-32
    800049c8:	ec06                	sd	ra,24(sp)
    800049ca:	e822                	sd	s0,16(sp)
    800049cc:	e426                	sd	s1,8(sp)
    800049ce:	e04a                	sd	s2,0(sp)
    800049d0:	1000                	addi	s0,sp,32
    800049d2:	84aa                	mv	s1,a0
    800049d4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	200080e7          	jalr	512(ra) # 80000bd6 <acquire>
  if(writable){
    800049de:	02090d63          	beqz	s2,80004a18 <pipeclose+0x52>
    pi->writeopen = 0;
    800049e2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049e6:	21848513          	addi	a0,s1,536
    800049ea:	ffffd097          	auipc	ra,0xffffd
    800049ee:	744080e7          	jalr	1860(ra) # 8000212e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049f2:	2204b783          	ld	a5,544(s1)
    800049f6:	eb95                	bnez	a5,80004a2a <pipeclose+0x64>
    release(&pi->lock);
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	290080e7          	jalr	656(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a02:	8526                	mv	a0,s1
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	fe6080e7          	jalr	-26(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004a0c:	60e2                	ld	ra,24(sp)
    80004a0e:	6442                	ld	s0,16(sp)
    80004a10:	64a2                	ld	s1,8(sp)
    80004a12:	6902                	ld	s2,0(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret
    pi->readopen = 0;
    80004a18:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a1c:	21c48513          	addi	a0,s1,540
    80004a20:	ffffd097          	auipc	ra,0xffffd
    80004a24:	70e080e7          	jalr	1806(ra) # 8000212e <wakeup>
    80004a28:	b7e9                	j	800049f2 <pipeclose+0x2c>
    release(&pi->lock);
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	25e080e7          	jalr	606(ra) # 80000c8a <release>
}
    80004a34:	bfe1                	j	80004a0c <pipeclose+0x46>

0000000080004a36 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a36:	711d                	addi	sp,sp,-96
    80004a38:	ec86                	sd	ra,88(sp)
    80004a3a:	e8a2                	sd	s0,80(sp)
    80004a3c:	e4a6                	sd	s1,72(sp)
    80004a3e:	e0ca                	sd	s2,64(sp)
    80004a40:	fc4e                	sd	s3,56(sp)
    80004a42:	f852                	sd	s4,48(sp)
    80004a44:	f456                	sd	s5,40(sp)
    80004a46:	f05a                	sd	s6,32(sp)
    80004a48:	ec5e                	sd	s7,24(sp)
    80004a4a:	e862                	sd	s8,16(sp)
    80004a4c:	1080                	addi	s0,sp,96
    80004a4e:	84aa                	mv	s1,a0
    80004a50:	8aae                	mv	s5,a1
    80004a52:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a54:	ffffd097          	auipc	ra,0xffffd
    80004a58:	f58080e7          	jalr	-168(ra) # 800019ac <myproc>
    80004a5c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	176080e7          	jalr	374(ra) # 80000bd6 <acquire>
  while(i < n){
    80004a68:	0b405663          	blez	s4,80004b14 <pipewrite+0xde>
  int i = 0;
    80004a6c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a6e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a70:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a74:	21c48b93          	addi	s7,s1,540
    80004a78:	a089                	j	80004aba <pipewrite+0x84>
      release(&pi->lock);
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	20e080e7          	jalr	526(ra) # 80000c8a <release>
      return -1;
    80004a84:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a86:	854a                	mv	a0,s2
    80004a88:	60e6                	ld	ra,88(sp)
    80004a8a:	6446                	ld	s0,80(sp)
    80004a8c:	64a6                	ld	s1,72(sp)
    80004a8e:	6906                	ld	s2,64(sp)
    80004a90:	79e2                	ld	s3,56(sp)
    80004a92:	7a42                	ld	s4,48(sp)
    80004a94:	7aa2                	ld	s5,40(sp)
    80004a96:	7b02                	ld	s6,32(sp)
    80004a98:	6be2                	ld	s7,24(sp)
    80004a9a:	6c42                	ld	s8,16(sp)
    80004a9c:	6125                	addi	sp,sp,96
    80004a9e:	8082                	ret
      wakeup(&pi->nread);
    80004aa0:	8562                	mv	a0,s8
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	68c080e7          	jalr	1676(ra) # 8000212e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aaa:	85a6                	mv	a1,s1
    80004aac:	855e                	mv	a0,s7
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	61c080e7          	jalr	1564(ra) # 800020ca <sleep>
  while(i < n){
    80004ab6:	07495063          	bge	s2,s4,80004b16 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004aba:	2204a783          	lw	a5,544(s1)
    80004abe:	dfd5                	beqz	a5,80004a7a <pipewrite+0x44>
    80004ac0:	854e                	mv	a0,s3
    80004ac2:	ffffe097          	auipc	ra,0xffffe
    80004ac6:	8bc080e7          	jalr	-1860(ra) # 8000237e <killed>
    80004aca:	f945                	bnez	a0,80004a7a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004acc:	2184a783          	lw	a5,536(s1)
    80004ad0:	21c4a703          	lw	a4,540(s1)
    80004ad4:	2007879b          	addiw	a5,a5,512
    80004ad8:	fcf704e3          	beq	a4,a5,80004aa0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004adc:	4685                	li	a3,1
    80004ade:	01590633          	add	a2,s2,s5
    80004ae2:	faf40593          	addi	a1,s0,-81
    80004ae6:	0509b503          	ld	a0,80(s3)
    80004aea:	ffffd097          	auipc	ra,0xffffd
    80004aee:	c0a080e7          	jalr	-1014(ra) # 800016f4 <copyin>
    80004af2:	03650263          	beq	a0,s6,80004b16 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004af6:	21c4a783          	lw	a5,540(s1)
    80004afa:	0017871b          	addiw	a4,a5,1
    80004afe:	20e4ae23          	sw	a4,540(s1)
    80004b02:	1ff7f793          	andi	a5,a5,511
    80004b06:	97a6                	add	a5,a5,s1
    80004b08:	faf44703          	lbu	a4,-81(s0)
    80004b0c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b10:	2905                	addiw	s2,s2,1
    80004b12:	b755                	j	80004ab6 <pipewrite+0x80>
  int i = 0;
    80004b14:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b16:	21848513          	addi	a0,s1,536
    80004b1a:	ffffd097          	auipc	ra,0xffffd
    80004b1e:	614080e7          	jalr	1556(ra) # 8000212e <wakeup>
  release(&pi->lock);
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	166080e7          	jalr	358(ra) # 80000c8a <release>
  return i;
    80004b2c:	bfa9                	j	80004a86 <pipewrite+0x50>

0000000080004b2e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b2e:	715d                	addi	sp,sp,-80
    80004b30:	e486                	sd	ra,72(sp)
    80004b32:	e0a2                	sd	s0,64(sp)
    80004b34:	fc26                	sd	s1,56(sp)
    80004b36:	f84a                	sd	s2,48(sp)
    80004b38:	f44e                	sd	s3,40(sp)
    80004b3a:	f052                	sd	s4,32(sp)
    80004b3c:	ec56                	sd	s5,24(sp)
    80004b3e:	e85a                	sd	s6,16(sp)
    80004b40:	0880                	addi	s0,sp,80
    80004b42:	84aa                	mv	s1,a0
    80004b44:	892e                	mv	s2,a1
    80004b46:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	e64080e7          	jalr	-412(ra) # 800019ac <myproc>
    80004b50:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b52:	8526                	mv	a0,s1
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	082080e7          	jalr	130(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5c:	2184a703          	lw	a4,536(s1)
    80004b60:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b64:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b68:	02f71763          	bne	a4,a5,80004b96 <piperead+0x68>
    80004b6c:	2244a783          	lw	a5,548(s1)
    80004b70:	c39d                	beqz	a5,80004b96 <piperead+0x68>
    if(killed(pr)){
    80004b72:	8552                	mv	a0,s4
    80004b74:	ffffe097          	auipc	ra,0xffffe
    80004b78:	80a080e7          	jalr	-2038(ra) # 8000237e <killed>
    80004b7c:	e941                	bnez	a0,80004c0c <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b7e:	85a6                	mv	a1,s1
    80004b80:	854e                	mv	a0,s3
    80004b82:	ffffd097          	auipc	ra,0xffffd
    80004b86:	548080e7          	jalr	1352(ra) # 800020ca <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8a:	2184a703          	lw	a4,536(s1)
    80004b8e:	21c4a783          	lw	a5,540(s1)
    80004b92:	fcf70de3          	beq	a4,a5,80004b6c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b96:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b98:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b9a:	05505363          	blez	s5,80004be0 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004b9e:	2184a783          	lw	a5,536(s1)
    80004ba2:	21c4a703          	lw	a4,540(s1)
    80004ba6:	02f70d63          	beq	a4,a5,80004be0 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004baa:	0017871b          	addiw	a4,a5,1
    80004bae:	20e4ac23          	sw	a4,536(s1)
    80004bb2:	1ff7f793          	andi	a5,a5,511
    80004bb6:	97a6                	add	a5,a5,s1
    80004bb8:	0187c783          	lbu	a5,24(a5)
    80004bbc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc0:	4685                	li	a3,1
    80004bc2:	fbf40613          	addi	a2,s0,-65
    80004bc6:	85ca                	mv	a1,s2
    80004bc8:	050a3503          	ld	a0,80(s4)
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	a9c080e7          	jalr	-1380(ra) # 80001668 <copyout>
    80004bd4:	01650663          	beq	a0,s6,80004be0 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bd8:	2985                	addiw	s3,s3,1
    80004bda:	0905                	addi	s2,s2,1
    80004bdc:	fd3a91e3          	bne	s5,s3,80004b9e <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004be0:	21c48513          	addi	a0,s1,540
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	54a080e7          	jalr	1354(ra) # 8000212e <wakeup>
  release(&pi->lock);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
  return i;
}
    80004bf6:	854e                	mv	a0,s3
    80004bf8:	60a6                	ld	ra,72(sp)
    80004bfa:	6406                	ld	s0,64(sp)
    80004bfc:	74e2                	ld	s1,56(sp)
    80004bfe:	7942                	ld	s2,48(sp)
    80004c00:	79a2                	ld	s3,40(sp)
    80004c02:	7a02                	ld	s4,32(sp)
    80004c04:	6ae2                	ld	s5,24(sp)
    80004c06:	6b42                	ld	s6,16(sp)
    80004c08:	6161                	addi	sp,sp,80
    80004c0a:	8082                	ret
      release(&pi->lock);
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	07c080e7          	jalr	124(ra) # 80000c8a <release>
      return -1;
    80004c16:	59fd                	li	s3,-1
    80004c18:	bff9                	j	80004bf6 <piperead+0xc8>

0000000080004c1a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c1a:	1141                	addi	sp,sp,-16
    80004c1c:	e422                	sd	s0,8(sp)
    80004c1e:	0800                	addi	s0,sp,16
    80004c20:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c22:	8905                	andi	a0,a0,1
    80004c24:	c111                	beqz	a0,80004c28 <flags2perm+0xe>
      perm = PTE_X;
    80004c26:	4521                	li	a0,8
    if(flags & 0x2)
    80004c28:	8b89                	andi	a5,a5,2
    80004c2a:	c399                	beqz	a5,80004c30 <flags2perm+0x16>
      perm |= PTE_W;
    80004c2c:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c30:	6422                	ld	s0,8(sp)
    80004c32:	0141                	addi	sp,sp,16
    80004c34:	8082                	ret

0000000080004c36 <exec>:

int
exec(char *path, char **argv)
{
    80004c36:	de010113          	addi	sp,sp,-544
    80004c3a:	20113c23          	sd	ra,536(sp)
    80004c3e:	20813823          	sd	s0,528(sp)
    80004c42:	20913423          	sd	s1,520(sp)
    80004c46:	21213023          	sd	s2,512(sp)
    80004c4a:	ffce                	sd	s3,504(sp)
    80004c4c:	fbd2                	sd	s4,496(sp)
    80004c4e:	f7d6                	sd	s5,488(sp)
    80004c50:	f3da                	sd	s6,480(sp)
    80004c52:	efde                	sd	s7,472(sp)
    80004c54:	ebe2                	sd	s8,464(sp)
    80004c56:	e7e6                	sd	s9,456(sp)
    80004c58:	e3ea                	sd	s10,448(sp)
    80004c5a:	ff6e                	sd	s11,440(sp)
    80004c5c:	1400                	addi	s0,sp,544
    80004c5e:	892a                	mv	s2,a0
    80004c60:	dea43423          	sd	a0,-536(s0)
    80004c64:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	d44080e7          	jalr	-700(ra) # 800019ac <myproc>
    80004c70:	84aa                	mv	s1,a0

  begin_op();
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	47e080e7          	jalr	1150(ra) # 800040f0 <begin_op>

  if((ip = namei(path)) == 0){
    80004c7a:	854a                	mv	a0,s2
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	258080e7          	jalr	600(ra) # 80003ed4 <namei>
    80004c84:	c93d                	beqz	a0,80004cfa <exec+0xc4>
    80004c86:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	aa6080e7          	jalr	-1370(ra) # 8000372e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c90:	04000713          	li	a4,64
    80004c94:	4681                	li	a3,0
    80004c96:	e5040613          	addi	a2,s0,-432
    80004c9a:	4581                	li	a1,0
    80004c9c:	8556                	mv	a0,s5
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	d44080e7          	jalr	-700(ra) # 800039e2 <readi>
    80004ca6:	04000793          	li	a5,64
    80004caa:	00f51a63          	bne	a0,a5,80004cbe <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cae:	e5042703          	lw	a4,-432(s0)
    80004cb2:	464c47b7          	lui	a5,0x464c4
    80004cb6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cba:	04f70663          	beq	a4,a5,80004d06 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cbe:	8556                	mv	a0,s5
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	cd0080e7          	jalr	-816(ra) # 80003990 <iunlockput>
    end_op();
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	4a8080e7          	jalr	1192(ra) # 80004170 <end_op>
  }
  return -1;
    80004cd0:	557d                	li	a0,-1
}
    80004cd2:	21813083          	ld	ra,536(sp)
    80004cd6:	21013403          	ld	s0,528(sp)
    80004cda:	20813483          	ld	s1,520(sp)
    80004cde:	20013903          	ld	s2,512(sp)
    80004ce2:	79fe                	ld	s3,504(sp)
    80004ce4:	7a5e                	ld	s4,496(sp)
    80004ce6:	7abe                	ld	s5,488(sp)
    80004ce8:	7b1e                	ld	s6,480(sp)
    80004cea:	6bfe                	ld	s7,472(sp)
    80004cec:	6c5e                	ld	s8,464(sp)
    80004cee:	6cbe                	ld	s9,456(sp)
    80004cf0:	6d1e                	ld	s10,448(sp)
    80004cf2:	7dfa                	ld	s11,440(sp)
    80004cf4:	22010113          	addi	sp,sp,544
    80004cf8:	8082                	ret
    end_op();
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	476080e7          	jalr	1142(ra) # 80004170 <end_op>
    return -1;
    80004d02:	557d                	li	a0,-1
    80004d04:	b7f9                	j	80004cd2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	d68080e7          	jalr	-664(ra) # 80001a70 <proc_pagetable>
    80004d10:	8b2a                	mv	s6,a0
    80004d12:	d555                	beqz	a0,80004cbe <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d14:	e7042783          	lw	a5,-400(s0)
    80004d18:	e8845703          	lhu	a4,-376(s0)
    80004d1c:	c735                	beqz	a4,80004d88 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d1e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d20:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d24:	6a05                	lui	s4,0x1
    80004d26:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d2a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d2e:	6d85                	lui	s11,0x1
    80004d30:	7d7d                	lui	s10,0xfffff
    80004d32:	a481                	j	80004f72 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d34:	00004517          	auipc	a0,0x4
    80004d38:	a6450513          	addi	a0,a0,-1436 # 80008798 <syscalls+0x280>
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	802080e7          	jalr	-2046(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d44:	874a                	mv	a4,s2
    80004d46:	009c86bb          	addw	a3,s9,s1
    80004d4a:	4581                	li	a1,0
    80004d4c:	8556                	mv	a0,s5
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	c94080e7          	jalr	-876(ra) # 800039e2 <readi>
    80004d56:	2501                	sext.w	a0,a0
    80004d58:	1aa91a63          	bne	s2,a0,80004f0c <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d5c:	009d84bb          	addw	s1,s11,s1
    80004d60:	013d09bb          	addw	s3,s10,s3
    80004d64:	1f74f763          	bgeu	s1,s7,80004f52 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004d68:	02049593          	slli	a1,s1,0x20
    80004d6c:	9181                	srli	a1,a1,0x20
    80004d6e:	95e2                	add	a1,a1,s8
    80004d70:	855a                	mv	a0,s6
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	2ea080e7          	jalr	746(ra) # 8000105c <walkaddr>
    80004d7a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d7c:	dd45                	beqz	a0,80004d34 <exec+0xfe>
      n = PGSIZE;
    80004d7e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d80:	fd49f2e3          	bgeu	s3,s4,80004d44 <exec+0x10e>
      n = sz - i;
    80004d84:	894e                	mv	s2,s3
    80004d86:	bf7d                	j	80004d44 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d88:	4901                	li	s2,0
  iunlockput(ip);
    80004d8a:	8556                	mv	a0,s5
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	c04080e7          	jalr	-1020(ra) # 80003990 <iunlockput>
  end_op();
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	3dc080e7          	jalr	988(ra) # 80004170 <end_op>
  p = myproc();
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	c10080e7          	jalr	-1008(ra) # 800019ac <myproc>
    80004da4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004da6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004daa:	6785                	lui	a5,0x1
    80004dac:	17fd                	addi	a5,a5,-1
    80004dae:	993e                	add	s2,s2,a5
    80004db0:	77fd                	lui	a5,0xfffff
    80004db2:	00f977b3          	and	a5,s2,a5
    80004db6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dba:	4691                	li	a3,4
    80004dbc:	6609                	lui	a2,0x2
    80004dbe:	963e                	add	a2,a2,a5
    80004dc0:	85be                	mv	a1,a5
    80004dc2:	855a                	mv	a0,s6
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	64c080e7          	jalr	1612(ra) # 80001410 <uvmalloc>
    80004dcc:	8c2a                	mv	s8,a0
  ip = 0;
    80004dce:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dd0:	12050e63          	beqz	a0,80004f0c <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dd4:	75f9                	lui	a1,0xffffe
    80004dd6:	95aa                	add	a1,a1,a0
    80004dd8:	855a                	mv	a0,s6
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	85c080e7          	jalr	-1956(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80004de2:	7afd                	lui	s5,0xfffff
    80004de4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004de6:	df043783          	ld	a5,-528(s0)
    80004dea:	6388                	ld	a0,0(a5)
    80004dec:	c925                	beqz	a0,80004e5c <exec+0x226>
    80004dee:	e9040993          	addi	s3,s0,-368
    80004df2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004df6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004df8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	054080e7          	jalr	84(ra) # 80000e4e <strlen>
    80004e02:	0015079b          	addiw	a5,a0,1
    80004e06:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e0a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e0e:	13596663          	bltu	s2,s5,80004f3a <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e12:	df043d83          	ld	s11,-528(s0)
    80004e16:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e1a:	8552                	mv	a0,s4
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	032080e7          	jalr	50(ra) # 80000e4e <strlen>
    80004e24:	0015069b          	addiw	a3,a0,1
    80004e28:	8652                	mv	a2,s4
    80004e2a:	85ca                	mv	a1,s2
    80004e2c:	855a                	mv	a0,s6
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	83a080e7          	jalr	-1990(ra) # 80001668 <copyout>
    80004e36:	10054663          	bltz	a0,80004f42 <exec+0x30c>
    ustack[argc] = sp;
    80004e3a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e3e:	0485                	addi	s1,s1,1
    80004e40:	008d8793          	addi	a5,s11,8
    80004e44:	def43823          	sd	a5,-528(s0)
    80004e48:	008db503          	ld	a0,8(s11)
    80004e4c:	c911                	beqz	a0,80004e60 <exec+0x22a>
    if(argc >= MAXARG)
    80004e4e:	09a1                	addi	s3,s3,8
    80004e50:	fb3c95e3          	bne	s9,s3,80004dfa <exec+0x1c4>
  sz = sz1;
    80004e54:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e58:	4a81                	li	s5,0
    80004e5a:	a84d                	j	80004f0c <exec+0x2d6>
  sp = sz;
    80004e5c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e5e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e60:	00349793          	slli	a5,s1,0x3
    80004e64:	f9040713          	addi	a4,s0,-112
    80004e68:	97ba                	add	a5,a5,a4
    80004e6a:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcc40>
  sp -= (argc+1) * sizeof(uint64);
    80004e6e:	00148693          	addi	a3,s1,1
    80004e72:	068e                	slli	a3,a3,0x3
    80004e74:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e78:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e7c:	01597663          	bgeu	s2,s5,80004e88 <exec+0x252>
  sz = sz1;
    80004e80:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e84:	4a81                	li	s5,0
    80004e86:	a059                	j	80004f0c <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e88:	e9040613          	addi	a2,s0,-368
    80004e8c:	85ca                	mv	a1,s2
    80004e8e:	855a                	mv	a0,s6
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	7d8080e7          	jalr	2008(ra) # 80001668 <copyout>
    80004e98:	0a054963          	bltz	a0,80004f4a <exec+0x314>
  p->trapframe->a1 = sp;
    80004e9c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004ea0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ea4:	de843783          	ld	a5,-536(s0)
    80004ea8:	0007c703          	lbu	a4,0(a5)
    80004eac:	cf11                	beqz	a4,80004ec8 <exec+0x292>
    80004eae:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eb0:	02f00693          	li	a3,47
    80004eb4:	a039                	j	80004ec2 <exec+0x28c>
      last = s+1;
    80004eb6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004eba:	0785                	addi	a5,a5,1
    80004ebc:	fff7c703          	lbu	a4,-1(a5)
    80004ec0:	c701                	beqz	a4,80004ec8 <exec+0x292>
    if(*s == '/')
    80004ec2:	fed71ce3          	bne	a4,a3,80004eba <exec+0x284>
    80004ec6:	bfc5                	j	80004eb6 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ec8:	4641                	li	a2,16
    80004eca:	de843583          	ld	a1,-536(s0)
    80004ece:	158b8513          	addi	a0,s7,344
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	f4a080e7          	jalr	-182(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004eda:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ede:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ee2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ee6:	058bb783          	ld	a5,88(s7)
    80004eea:	e6843703          	ld	a4,-408(s0)
    80004eee:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ef0:	058bb783          	ld	a5,88(s7)
    80004ef4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ef8:	85ea                	mv	a1,s10
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	c12080e7          	jalr	-1006(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f02:	0004851b          	sext.w	a0,s1
    80004f06:	b3f1                	j	80004cd2 <exec+0x9c>
    80004f08:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f0c:	df843583          	ld	a1,-520(s0)
    80004f10:	855a                	mv	a0,s6
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	bfa080e7          	jalr	-1030(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f1a:	da0a92e3          	bnez	s5,80004cbe <exec+0x88>
  return -1;
    80004f1e:	557d                	li	a0,-1
    80004f20:	bb4d                	j	80004cd2 <exec+0x9c>
    80004f22:	df243c23          	sd	s2,-520(s0)
    80004f26:	b7dd                	j	80004f0c <exec+0x2d6>
    80004f28:	df243c23          	sd	s2,-520(s0)
    80004f2c:	b7c5                	j	80004f0c <exec+0x2d6>
    80004f2e:	df243c23          	sd	s2,-520(s0)
    80004f32:	bfe9                	j	80004f0c <exec+0x2d6>
    80004f34:	df243c23          	sd	s2,-520(s0)
    80004f38:	bfd1                	j	80004f0c <exec+0x2d6>
  sz = sz1;
    80004f3a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f3e:	4a81                	li	s5,0
    80004f40:	b7f1                	j	80004f0c <exec+0x2d6>
  sz = sz1;
    80004f42:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f46:	4a81                	li	s5,0
    80004f48:	b7d1                	j	80004f0c <exec+0x2d6>
  sz = sz1;
    80004f4a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4e:	4a81                	li	s5,0
    80004f50:	bf75                	j	80004f0c <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f52:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f56:	e0843783          	ld	a5,-504(s0)
    80004f5a:	0017869b          	addiw	a3,a5,1
    80004f5e:	e0d43423          	sd	a3,-504(s0)
    80004f62:	e0043783          	ld	a5,-512(s0)
    80004f66:	0387879b          	addiw	a5,a5,56
    80004f6a:	e8845703          	lhu	a4,-376(s0)
    80004f6e:	e0e6dee3          	bge	a3,a4,80004d8a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f72:	2781                	sext.w	a5,a5
    80004f74:	e0f43023          	sd	a5,-512(s0)
    80004f78:	03800713          	li	a4,56
    80004f7c:	86be                	mv	a3,a5
    80004f7e:	e1840613          	addi	a2,s0,-488
    80004f82:	4581                	li	a1,0
    80004f84:	8556                	mv	a0,s5
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	a5c080e7          	jalr	-1444(ra) # 800039e2 <readi>
    80004f8e:	03800793          	li	a5,56
    80004f92:	f6f51be3          	bne	a0,a5,80004f08 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80004f96:	e1842783          	lw	a5,-488(s0)
    80004f9a:	4705                	li	a4,1
    80004f9c:	fae79de3          	bne	a5,a4,80004f56 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80004fa0:	e4043483          	ld	s1,-448(s0)
    80004fa4:	e3843783          	ld	a5,-456(s0)
    80004fa8:	f6f4ede3          	bltu	s1,a5,80004f22 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fac:	e2843783          	ld	a5,-472(s0)
    80004fb0:	94be                	add	s1,s1,a5
    80004fb2:	f6f4ebe3          	bltu	s1,a5,80004f28 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80004fb6:	de043703          	ld	a4,-544(s0)
    80004fba:	8ff9                	and	a5,a5,a4
    80004fbc:	fbad                	bnez	a5,80004f2e <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fbe:	e1c42503          	lw	a0,-484(s0)
    80004fc2:	00000097          	auipc	ra,0x0
    80004fc6:	c58080e7          	jalr	-936(ra) # 80004c1a <flags2perm>
    80004fca:	86aa                	mv	a3,a0
    80004fcc:	8626                	mv	a2,s1
    80004fce:	85ca                	mv	a1,s2
    80004fd0:	855a                	mv	a0,s6
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	43e080e7          	jalr	1086(ra) # 80001410 <uvmalloc>
    80004fda:	dea43c23          	sd	a0,-520(s0)
    80004fde:	d939                	beqz	a0,80004f34 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fe0:	e2843c03          	ld	s8,-472(s0)
    80004fe4:	e2042c83          	lw	s9,-480(s0)
    80004fe8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fec:	f60b83e3          	beqz	s7,80004f52 <exec+0x31c>
    80004ff0:	89de                	mv	s3,s7
    80004ff2:	4481                	li	s1,0
    80004ff4:	bb95                	j	80004d68 <exec+0x132>

0000000080004ff6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ff6:	7179                	addi	sp,sp,-48
    80004ff8:	f406                	sd	ra,40(sp)
    80004ffa:	f022                	sd	s0,32(sp)
    80004ffc:	ec26                	sd	s1,24(sp)
    80004ffe:	e84a                	sd	s2,16(sp)
    80005000:	1800                	addi	s0,sp,48
    80005002:	892e                	mv	s2,a1
    80005004:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005006:	fdc40593          	addi	a1,s0,-36
    8000500a:	ffffe097          	auipc	ra,0xffffe
    8000500e:	b4e080e7          	jalr	-1202(ra) # 80002b58 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005012:	fdc42703          	lw	a4,-36(s0)
    80005016:	47bd                	li	a5,15
    80005018:	02e7eb63          	bltu	a5,a4,8000504e <argfd+0x58>
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	990080e7          	jalr	-1648(ra) # 800019ac <myproc>
    80005024:	fdc42703          	lw	a4,-36(s0)
    80005028:	01a70793          	addi	a5,a4,26
    8000502c:	078e                	slli	a5,a5,0x3
    8000502e:	953e                	add	a0,a0,a5
    80005030:	611c                	ld	a5,0(a0)
    80005032:	c385                	beqz	a5,80005052 <argfd+0x5c>
    return -1;
  if(pfd)
    80005034:	00090463          	beqz	s2,8000503c <argfd+0x46>
    *pfd = fd;
    80005038:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000503c:	4501                	li	a0,0
  if(pf)
    8000503e:	c091                	beqz	s1,80005042 <argfd+0x4c>
    *pf = f;
    80005040:	e09c                	sd	a5,0(s1)
}
    80005042:	70a2                	ld	ra,40(sp)
    80005044:	7402                	ld	s0,32(sp)
    80005046:	64e2                	ld	s1,24(sp)
    80005048:	6942                	ld	s2,16(sp)
    8000504a:	6145                	addi	sp,sp,48
    8000504c:	8082                	ret
    return -1;
    8000504e:	557d                	li	a0,-1
    80005050:	bfcd                	j	80005042 <argfd+0x4c>
    80005052:	557d                	li	a0,-1
    80005054:	b7fd                	j	80005042 <argfd+0x4c>

0000000080005056 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005056:	1101                	addi	sp,sp,-32
    80005058:	ec06                	sd	ra,24(sp)
    8000505a:	e822                	sd	s0,16(sp)
    8000505c:	e426                	sd	s1,8(sp)
    8000505e:	1000                	addi	s0,sp,32
    80005060:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	94a080e7          	jalr	-1718(ra) # 800019ac <myproc>
    8000506a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000506c:	0d050793          	addi	a5,a0,208
    80005070:	4501                	li	a0,0
    80005072:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005074:	6398                	ld	a4,0(a5)
    80005076:	cb19                	beqz	a4,8000508c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005078:	2505                	addiw	a0,a0,1
    8000507a:	07a1                	addi	a5,a5,8
    8000507c:	fed51ce3          	bne	a0,a3,80005074 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005080:	557d                	li	a0,-1
}
    80005082:	60e2                	ld	ra,24(sp)
    80005084:	6442                	ld	s0,16(sp)
    80005086:	64a2                	ld	s1,8(sp)
    80005088:	6105                	addi	sp,sp,32
    8000508a:	8082                	ret
      p->ofile[fd] = f;
    8000508c:	01a50793          	addi	a5,a0,26
    80005090:	078e                	slli	a5,a5,0x3
    80005092:	963e                	add	a2,a2,a5
    80005094:	e204                	sd	s1,0(a2)
      return fd;
    80005096:	b7f5                	j	80005082 <fdalloc+0x2c>

0000000080005098 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005098:	715d                	addi	sp,sp,-80
    8000509a:	e486                	sd	ra,72(sp)
    8000509c:	e0a2                	sd	s0,64(sp)
    8000509e:	fc26                	sd	s1,56(sp)
    800050a0:	f84a                	sd	s2,48(sp)
    800050a2:	f44e                	sd	s3,40(sp)
    800050a4:	f052                	sd	s4,32(sp)
    800050a6:	ec56                	sd	s5,24(sp)
    800050a8:	e85a                	sd	s6,16(sp)
    800050aa:	0880                	addi	s0,sp,80
    800050ac:	8b2e                	mv	s6,a1
    800050ae:	89b2                	mv	s3,a2
    800050b0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050b2:	fb040593          	addi	a1,s0,-80
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	e3c080e7          	jalr	-452(ra) # 80003ef2 <nameiparent>
    800050be:	84aa                	mv	s1,a0
    800050c0:	14050f63          	beqz	a0,8000521e <create+0x186>
    return 0;

  ilock(dp);
    800050c4:	ffffe097          	auipc	ra,0xffffe
    800050c8:	66a080e7          	jalr	1642(ra) # 8000372e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050cc:	4601                	li	a2,0
    800050ce:	fb040593          	addi	a1,s0,-80
    800050d2:	8526                	mv	a0,s1
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	b3e080e7          	jalr	-1218(ra) # 80003c12 <dirlookup>
    800050dc:	8aaa                	mv	s5,a0
    800050de:	c931                	beqz	a0,80005132 <create+0x9a>
    iunlockput(dp);
    800050e0:	8526                	mv	a0,s1
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	8ae080e7          	jalr	-1874(ra) # 80003990 <iunlockput>
    ilock(ip);
    800050ea:	8556                	mv	a0,s5
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	642080e7          	jalr	1602(ra) # 8000372e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050f4:	000b059b          	sext.w	a1,s6
    800050f8:	4789                	li	a5,2
    800050fa:	02f59563          	bne	a1,a5,80005124 <create+0x8c>
    800050fe:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcd84>
    80005102:	37f9                	addiw	a5,a5,-2
    80005104:	17c2                	slli	a5,a5,0x30
    80005106:	93c1                	srli	a5,a5,0x30
    80005108:	4705                	li	a4,1
    8000510a:	00f76d63          	bltu	a4,a5,80005124 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000510e:	8556                	mv	a0,s5
    80005110:	60a6                	ld	ra,72(sp)
    80005112:	6406                	ld	s0,64(sp)
    80005114:	74e2                	ld	s1,56(sp)
    80005116:	7942                	ld	s2,48(sp)
    80005118:	79a2                	ld	s3,40(sp)
    8000511a:	7a02                	ld	s4,32(sp)
    8000511c:	6ae2                	ld	s5,24(sp)
    8000511e:	6b42                	ld	s6,16(sp)
    80005120:	6161                	addi	sp,sp,80
    80005122:	8082                	ret
    iunlockput(ip);
    80005124:	8556                	mv	a0,s5
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	86a080e7          	jalr	-1942(ra) # 80003990 <iunlockput>
    return 0;
    8000512e:	4a81                	li	s5,0
    80005130:	bff9                	j	8000510e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005132:	85da                	mv	a1,s6
    80005134:	4088                	lw	a0,0(s1)
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	45c080e7          	jalr	1116(ra) # 80003592 <ialloc>
    8000513e:	8a2a                	mv	s4,a0
    80005140:	c539                	beqz	a0,8000518e <create+0xf6>
  ilock(ip);
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	5ec080e7          	jalr	1516(ra) # 8000372e <ilock>
  ip->major = major;
    8000514a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000514e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005152:	4905                	li	s2,1
    80005154:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005158:	8552                	mv	a0,s4
    8000515a:	ffffe097          	auipc	ra,0xffffe
    8000515e:	50a080e7          	jalr	1290(ra) # 80003664 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005162:	000b059b          	sext.w	a1,s6
    80005166:	03258b63          	beq	a1,s2,8000519c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000516a:	004a2603          	lw	a2,4(s4)
    8000516e:	fb040593          	addi	a1,s0,-80
    80005172:	8526                	mv	a0,s1
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	cae080e7          	jalr	-850(ra) # 80003e22 <dirlink>
    8000517c:	06054f63          	bltz	a0,800051fa <create+0x162>
  iunlockput(dp);
    80005180:	8526                	mv	a0,s1
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	80e080e7          	jalr	-2034(ra) # 80003990 <iunlockput>
  return ip;
    8000518a:	8ad2                	mv	s5,s4
    8000518c:	b749                	j	8000510e <create+0x76>
    iunlockput(dp);
    8000518e:	8526                	mv	a0,s1
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	800080e7          	jalr	-2048(ra) # 80003990 <iunlockput>
    return 0;
    80005198:	8ad2                	mv	s5,s4
    8000519a:	bf95                	j	8000510e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000519c:	004a2603          	lw	a2,4(s4)
    800051a0:	00003597          	auipc	a1,0x3
    800051a4:	61858593          	addi	a1,a1,1560 # 800087b8 <syscalls+0x2a0>
    800051a8:	8552                	mv	a0,s4
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	c78080e7          	jalr	-904(ra) # 80003e22 <dirlink>
    800051b2:	04054463          	bltz	a0,800051fa <create+0x162>
    800051b6:	40d0                	lw	a2,4(s1)
    800051b8:	00003597          	auipc	a1,0x3
    800051bc:	60858593          	addi	a1,a1,1544 # 800087c0 <syscalls+0x2a8>
    800051c0:	8552                	mv	a0,s4
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	c60080e7          	jalr	-928(ra) # 80003e22 <dirlink>
    800051ca:	02054863          	bltz	a0,800051fa <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ce:	004a2603          	lw	a2,4(s4)
    800051d2:	fb040593          	addi	a1,s0,-80
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	c4a080e7          	jalr	-950(ra) # 80003e22 <dirlink>
    800051e0:	00054d63          	bltz	a0,800051fa <create+0x162>
    dp->nlink++;  // for ".."
    800051e4:	04a4d783          	lhu	a5,74(s1)
    800051e8:	2785                	addiw	a5,a5,1
    800051ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051ee:	8526                	mv	a0,s1
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	474080e7          	jalr	1140(ra) # 80003664 <iupdate>
    800051f8:	b761                	j	80005180 <create+0xe8>
  ip->nlink = 0;
    800051fa:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800051fe:	8552                	mv	a0,s4
    80005200:	ffffe097          	auipc	ra,0xffffe
    80005204:	464080e7          	jalr	1124(ra) # 80003664 <iupdate>
  iunlockput(ip);
    80005208:	8552                	mv	a0,s4
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	786080e7          	jalr	1926(ra) # 80003990 <iunlockput>
  iunlockput(dp);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	77c080e7          	jalr	1916(ra) # 80003990 <iunlockput>
  return 0;
    8000521c:	bdcd                	j	8000510e <create+0x76>
    return 0;
    8000521e:	8aaa                	mv	s5,a0
    80005220:	b5fd                	j	8000510e <create+0x76>

0000000080005222 <sys_dup>:
{
    80005222:	7179                	addi	sp,sp,-48
    80005224:	f406                	sd	ra,40(sp)
    80005226:	f022                	sd	s0,32(sp)
    80005228:	ec26                	sd	s1,24(sp)
    8000522a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000522c:	fd840613          	addi	a2,s0,-40
    80005230:	4581                	li	a1,0
    80005232:	4501                	li	a0,0
    80005234:	00000097          	auipc	ra,0x0
    80005238:	dc2080e7          	jalr	-574(ra) # 80004ff6 <argfd>
    return -1;
    8000523c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000523e:	02054363          	bltz	a0,80005264 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005242:	fd843503          	ld	a0,-40(s0)
    80005246:	00000097          	auipc	ra,0x0
    8000524a:	e10080e7          	jalr	-496(ra) # 80005056 <fdalloc>
    8000524e:	84aa                	mv	s1,a0
    return -1;
    80005250:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005252:	00054963          	bltz	a0,80005264 <sys_dup+0x42>
  filedup(f);
    80005256:	fd843503          	ld	a0,-40(s0)
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	310080e7          	jalr	784(ra) # 8000456a <filedup>
  return fd;
    80005262:	87a6                	mv	a5,s1
}
    80005264:	853e                	mv	a0,a5
    80005266:	70a2                	ld	ra,40(sp)
    80005268:	7402                	ld	s0,32(sp)
    8000526a:	64e2                	ld	s1,24(sp)
    8000526c:	6145                	addi	sp,sp,48
    8000526e:	8082                	ret

0000000080005270 <sys_read>:
{
    80005270:	7179                	addi	sp,sp,-48
    80005272:	f406                	sd	ra,40(sp)
    80005274:	f022                	sd	s0,32(sp)
    80005276:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005278:	fd840593          	addi	a1,s0,-40
    8000527c:	4505                	li	a0,1
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	8fa080e7          	jalr	-1798(ra) # 80002b78 <argaddr>
  argint(2, &n);
    80005286:	fe440593          	addi	a1,s0,-28
    8000528a:	4509                	li	a0,2
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	8cc080e7          	jalr	-1844(ra) # 80002b58 <argint>
  if(argfd(0, 0, &f) < 0)
    80005294:	fe840613          	addi	a2,s0,-24
    80005298:	4581                	li	a1,0
    8000529a:	4501                	li	a0,0
    8000529c:	00000097          	auipc	ra,0x0
    800052a0:	d5a080e7          	jalr	-678(ra) # 80004ff6 <argfd>
    800052a4:	87aa                	mv	a5,a0
    return -1;
    800052a6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052a8:	0007cc63          	bltz	a5,800052c0 <sys_read+0x50>
  return fileread(f, p, n);
    800052ac:	fe442603          	lw	a2,-28(s0)
    800052b0:	fd843583          	ld	a1,-40(s0)
    800052b4:	fe843503          	ld	a0,-24(s0)
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	43e080e7          	jalr	1086(ra) # 800046f6 <fileread>
}
    800052c0:	70a2                	ld	ra,40(sp)
    800052c2:	7402                	ld	s0,32(sp)
    800052c4:	6145                	addi	sp,sp,48
    800052c6:	8082                	ret

00000000800052c8 <sys_write>:
{
    800052c8:	7179                	addi	sp,sp,-48
    800052ca:	f406                	sd	ra,40(sp)
    800052cc:	f022                	sd	s0,32(sp)
    800052ce:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052d0:	fd840593          	addi	a1,s0,-40
    800052d4:	4505                	li	a0,1
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	8a2080e7          	jalr	-1886(ra) # 80002b78 <argaddr>
  argint(2, &n);
    800052de:	fe440593          	addi	a1,s0,-28
    800052e2:	4509                	li	a0,2
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	874080e7          	jalr	-1932(ra) # 80002b58 <argint>
  if(argfd(0, 0, &f) < 0)
    800052ec:	fe840613          	addi	a2,s0,-24
    800052f0:	4581                	li	a1,0
    800052f2:	4501                	li	a0,0
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	d02080e7          	jalr	-766(ra) # 80004ff6 <argfd>
    800052fc:	87aa                	mv	a5,a0
    return -1;
    800052fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005300:	0007cc63          	bltz	a5,80005318 <sys_write+0x50>
  return filewrite(f, p, n);
    80005304:	fe442603          	lw	a2,-28(s0)
    80005308:	fd843583          	ld	a1,-40(s0)
    8000530c:	fe843503          	ld	a0,-24(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	4a8080e7          	jalr	1192(ra) # 800047b8 <filewrite>
}
    80005318:	70a2                	ld	ra,40(sp)
    8000531a:	7402                	ld	s0,32(sp)
    8000531c:	6145                	addi	sp,sp,48
    8000531e:	8082                	ret

0000000080005320 <sys_close>:
{
    80005320:	1101                	addi	sp,sp,-32
    80005322:	ec06                	sd	ra,24(sp)
    80005324:	e822                	sd	s0,16(sp)
    80005326:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005328:	fe040613          	addi	a2,s0,-32
    8000532c:	fec40593          	addi	a1,s0,-20
    80005330:	4501                	li	a0,0
    80005332:	00000097          	auipc	ra,0x0
    80005336:	cc4080e7          	jalr	-828(ra) # 80004ff6 <argfd>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000533c:	02054463          	bltz	a0,80005364 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	66c080e7          	jalr	1644(ra) # 800019ac <myproc>
    80005348:	fec42783          	lw	a5,-20(s0)
    8000534c:	07e9                	addi	a5,a5,26
    8000534e:	078e                	slli	a5,a5,0x3
    80005350:	97aa                	add	a5,a5,a0
    80005352:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005356:	fe043503          	ld	a0,-32(s0)
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	262080e7          	jalr	610(ra) # 800045bc <fileclose>
  return 0;
    80005362:	4781                	li	a5,0
}
    80005364:	853e                	mv	a0,a5
    80005366:	60e2                	ld	ra,24(sp)
    80005368:	6442                	ld	s0,16(sp)
    8000536a:	6105                	addi	sp,sp,32
    8000536c:	8082                	ret

000000008000536e <sys_fstat>:
{
    8000536e:	1101                	addi	sp,sp,-32
    80005370:	ec06                	sd	ra,24(sp)
    80005372:	e822                	sd	s0,16(sp)
    80005374:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005376:	fe040593          	addi	a1,s0,-32
    8000537a:	4505                	li	a0,1
    8000537c:	ffffd097          	auipc	ra,0xffffd
    80005380:	7fc080e7          	jalr	2044(ra) # 80002b78 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005384:	fe840613          	addi	a2,s0,-24
    80005388:	4581                	li	a1,0
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	c6a080e7          	jalr	-918(ra) # 80004ff6 <argfd>
    80005394:	87aa                	mv	a5,a0
    return -1;
    80005396:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005398:	0007ca63          	bltz	a5,800053ac <sys_fstat+0x3e>
  return filestat(f, st);
    8000539c:	fe043583          	ld	a1,-32(s0)
    800053a0:	fe843503          	ld	a0,-24(s0)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	2e0080e7          	jalr	736(ra) # 80004684 <filestat>
}
    800053ac:	60e2                	ld	ra,24(sp)
    800053ae:	6442                	ld	s0,16(sp)
    800053b0:	6105                	addi	sp,sp,32
    800053b2:	8082                	ret

00000000800053b4 <sys_link>:
{
    800053b4:	7169                	addi	sp,sp,-304
    800053b6:	f606                	sd	ra,296(sp)
    800053b8:	f222                	sd	s0,288(sp)
    800053ba:	ee26                	sd	s1,280(sp)
    800053bc:	ea4a                	sd	s2,272(sp)
    800053be:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c0:	08000613          	li	a2,128
    800053c4:	ed040593          	addi	a1,s0,-304
    800053c8:	4501                	li	a0,0
    800053ca:	ffffd097          	auipc	ra,0xffffd
    800053ce:	7ce080e7          	jalr	1998(ra) # 80002b98 <argstr>
    return -1;
    800053d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d4:	10054e63          	bltz	a0,800054f0 <sys_link+0x13c>
    800053d8:	08000613          	li	a2,128
    800053dc:	f5040593          	addi	a1,s0,-176
    800053e0:	4505                	li	a0,1
    800053e2:	ffffd097          	auipc	ra,0xffffd
    800053e6:	7b6080e7          	jalr	1974(ra) # 80002b98 <argstr>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ec:	10054263          	bltz	a0,800054f0 <sys_link+0x13c>
  begin_op();
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	d00080e7          	jalr	-768(ra) # 800040f0 <begin_op>
  if((ip = namei(old)) == 0){
    800053f8:	ed040513          	addi	a0,s0,-304
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	ad8080e7          	jalr	-1320(ra) # 80003ed4 <namei>
    80005404:	84aa                	mv	s1,a0
    80005406:	c551                	beqz	a0,80005492 <sys_link+0xde>
  ilock(ip);
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	326080e7          	jalr	806(ra) # 8000372e <ilock>
  if(ip->type == T_DIR){
    80005410:	04449703          	lh	a4,68(s1)
    80005414:	4785                	li	a5,1
    80005416:	08f70463          	beq	a4,a5,8000549e <sys_link+0xea>
  ip->nlink++;
    8000541a:	04a4d783          	lhu	a5,74(s1)
    8000541e:	2785                	addiw	a5,a5,1
    80005420:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	23e080e7          	jalr	574(ra) # 80003664 <iupdate>
  iunlock(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	3c0080e7          	jalr	960(ra) # 800037f0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005438:	fd040593          	addi	a1,s0,-48
    8000543c:	f5040513          	addi	a0,s0,-176
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	ab2080e7          	jalr	-1358(ra) # 80003ef2 <nameiparent>
    80005448:	892a                	mv	s2,a0
    8000544a:	c935                	beqz	a0,800054be <sys_link+0x10a>
  ilock(dp);
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	2e2080e7          	jalr	738(ra) # 8000372e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005454:	00092703          	lw	a4,0(s2)
    80005458:	409c                	lw	a5,0(s1)
    8000545a:	04f71d63          	bne	a4,a5,800054b4 <sys_link+0x100>
    8000545e:	40d0                	lw	a2,4(s1)
    80005460:	fd040593          	addi	a1,s0,-48
    80005464:	854a                	mv	a0,s2
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	9bc080e7          	jalr	-1604(ra) # 80003e22 <dirlink>
    8000546e:	04054363          	bltz	a0,800054b4 <sys_link+0x100>
  iunlockput(dp);
    80005472:	854a                	mv	a0,s2
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	51c080e7          	jalr	1308(ra) # 80003990 <iunlockput>
  iput(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	46a080e7          	jalr	1130(ra) # 800038e8 <iput>
  end_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	cea080e7          	jalr	-790(ra) # 80004170 <end_op>
  return 0;
    8000548e:	4781                	li	a5,0
    80005490:	a085                	j	800054f0 <sys_link+0x13c>
    end_op();
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	cde080e7          	jalr	-802(ra) # 80004170 <end_op>
    return -1;
    8000549a:	57fd                	li	a5,-1
    8000549c:	a891                	j	800054f0 <sys_link+0x13c>
    iunlockput(ip);
    8000549e:	8526                	mv	a0,s1
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	4f0080e7          	jalr	1264(ra) # 80003990 <iunlockput>
    end_op();
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	cc8080e7          	jalr	-824(ra) # 80004170 <end_op>
    return -1;
    800054b0:	57fd                	li	a5,-1
    800054b2:	a83d                	j	800054f0 <sys_link+0x13c>
    iunlockput(dp);
    800054b4:	854a                	mv	a0,s2
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	4da080e7          	jalr	1242(ra) # 80003990 <iunlockput>
  ilock(ip);
    800054be:	8526                	mv	a0,s1
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	26e080e7          	jalr	622(ra) # 8000372e <ilock>
  ip->nlink--;
    800054c8:	04a4d783          	lhu	a5,74(s1)
    800054cc:	37fd                	addiw	a5,a5,-1
    800054ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	190080e7          	jalr	400(ra) # 80003664 <iupdate>
  iunlockput(ip);
    800054dc:	8526                	mv	a0,s1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	4b2080e7          	jalr	1202(ra) # 80003990 <iunlockput>
  end_op();
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	c8a080e7          	jalr	-886(ra) # 80004170 <end_op>
  return -1;
    800054ee:	57fd                	li	a5,-1
}
    800054f0:	853e                	mv	a0,a5
    800054f2:	70b2                	ld	ra,296(sp)
    800054f4:	7412                	ld	s0,288(sp)
    800054f6:	64f2                	ld	s1,280(sp)
    800054f8:	6952                	ld	s2,272(sp)
    800054fa:	6155                	addi	sp,sp,304
    800054fc:	8082                	ret

00000000800054fe <sys_unlink>:
{
    800054fe:	7151                	addi	sp,sp,-240
    80005500:	f586                	sd	ra,232(sp)
    80005502:	f1a2                	sd	s0,224(sp)
    80005504:	eda6                	sd	s1,216(sp)
    80005506:	e9ca                	sd	s2,208(sp)
    80005508:	e5ce                	sd	s3,200(sp)
    8000550a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000550c:	08000613          	li	a2,128
    80005510:	f3040593          	addi	a1,s0,-208
    80005514:	4501                	li	a0,0
    80005516:	ffffd097          	auipc	ra,0xffffd
    8000551a:	682080e7          	jalr	1666(ra) # 80002b98 <argstr>
    8000551e:	18054163          	bltz	a0,800056a0 <sys_unlink+0x1a2>
  begin_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	bce080e7          	jalr	-1074(ra) # 800040f0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000552a:	fb040593          	addi	a1,s0,-80
    8000552e:	f3040513          	addi	a0,s0,-208
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	9c0080e7          	jalr	-1600(ra) # 80003ef2 <nameiparent>
    8000553a:	84aa                	mv	s1,a0
    8000553c:	c979                	beqz	a0,80005612 <sys_unlink+0x114>
  ilock(dp);
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	1f0080e7          	jalr	496(ra) # 8000372e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005546:	00003597          	auipc	a1,0x3
    8000554a:	27258593          	addi	a1,a1,626 # 800087b8 <syscalls+0x2a0>
    8000554e:	fb040513          	addi	a0,s0,-80
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	6a6080e7          	jalr	1702(ra) # 80003bf8 <namecmp>
    8000555a:	14050a63          	beqz	a0,800056ae <sys_unlink+0x1b0>
    8000555e:	00003597          	auipc	a1,0x3
    80005562:	26258593          	addi	a1,a1,610 # 800087c0 <syscalls+0x2a8>
    80005566:	fb040513          	addi	a0,s0,-80
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	68e080e7          	jalr	1678(ra) # 80003bf8 <namecmp>
    80005572:	12050e63          	beqz	a0,800056ae <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005576:	f2c40613          	addi	a2,s0,-212
    8000557a:	fb040593          	addi	a1,s0,-80
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	692080e7          	jalr	1682(ra) # 80003c12 <dirlookup>
    80005588:	892a                	mv	s2,a0
    8000558a:	12050263          	beqz	a0,800056ae <sys_unlink+0x1b0>
  ilock(ip);
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	1a0080e7          	jalr	416(ra) # 8000372e <ilock>
  if(ip->nlink < 1)
    80005596:	04a91783          	lh	a5,74(s2)
    8000559a:	08f05263          	blez	a5,8000561e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000559e:	04491703          	lh	a4,68(s2)
    800055a2:	4785                	li	a5,1
    800055a4:	08f70563          	beq	a4,a5,8000562e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055a8:	4641                	li	a2,16
    800055aa:	4581                	li	a1,0
    800055ac:	fc040513          	addi	a0,s0,-64
    800055b0:	ffffb097          	auipc	ra,0xffffb
    800055b4:	722080e7          	jalr	1826(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055b8:	4741                	li	a4,16
    800055ba:	f2c42683          	lw	a3,-212(s0)
    800055be:	fc040613          	addi	a2,s0,-64
    800055c2:	4581                	li	a1,0
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	514080e7          	jalr	1300(ra) # 80003ada <writei>
    800055ce:	47c1                	li	a5,16
    800055d0:	0af51563          	bne	a0,a5,8000567a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055d4:	04491703          	lh	a4,68(s2)
    800055d8:	4785                	li	a5,1
    800055da:	0af70863          	beq	a4,a5,8000568a <sys_unlink+0x18c>
  iunlockput(dp);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	3b0080e7          	jalr	944(ra) # 80003990 <iunlockput>
  ip->nlink--;
    800055e8:	04a95783          	lhu	a5,74(s2)
    800055ec:	37fd                	addiw	a5,a5,-1
    800055ee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055f2:	854a                	mv	a0,s2
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	070080e7          	jalr	112(ra) # 80003664 <iupdate>
  iunlockput(ip);
    800055fc:	854a                	mv	a0,s2
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	392080e7          	jalr	914(ra) # 80003990 <iunlockput>
  end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	b6a080e7          	jalr	-1174(ra) # 80004170 <end_op>
  return 0;
    8000560e:	4501                	li	a0,0
    80005610:	a84d                	j	800056c2 <sys_unlink+0x1c4>
    end_op();
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	b5e080e7          	jalr	-1186(ra) # 80004170 <end_op>
    return -1;
    8000561a:	557d                	li	a0,-1
    8000561c:	a05d                	j	800056c2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000561e:	00003517          	auipc	a0,0x3
    80005622:	1aa50513          	addi	a0,a0,426 # 800087c8 <syscalls+0x2b0>
    80005626:	ffffb097          	auipc	ra,0xffffb
    8000562a:	f18080e7          	jalr	-232(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000562e:	04c92703          	lw	a4,76(s2)
    80005632:	02000793          	li	a5,32
    80005636:	f6e7f9e3          	bgeu	a5,a4,800055a8 <sys_unlink+0xaa>
    8000563a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000563e:	4741                	li	a4,16
    80005640:	86ce                	mv	a3,s3
    80005642:	f1840613          	addi	a2,s0,-232
    80005646:	4581                	li	a1,0
    80005648:	854a                	mv	a0,s2
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	398080e7          	jalr	920(ra) # 800039e2 <readi>
    80005652:	47c1                	li	a5,16
    80005654:	00f51b63          	bne	a0,a5,8000566a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005658:	f1845783          	lhu	a5,-232(s0)
    8000565c:	e7a1                	bnez	a5,800056a4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565e:	29c1                	addiw	s3,s3,16
    80005660:	04c92783          	lw	a5,76(s2)
    80005664:	fcf9ede3          	bltu	s3,a5,8000563e <sys_unlink+0x140>
    80005668:	b781                	j	800055a8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000566a:	00003517          	auipc	a0,0x3
    8000566e:	17650513          	addi	a0,a0,374 # 800087e0 <syscalls+0x2c8>
    80005672:	ffffb097          	auipc	ra,0xffffb
    80005676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000567a:	00003517          	auipc	a0,0x3
    8000567e:	17e50513          	addi	a0,a0,382 # 800087f8 <syscalls+0x2e0>
    80005682:	ffffb097          	auipc	ra,0xffffb
    80005686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>
    dp->nlink--;
    8000568a:	04a4d783          	lhu	a5,74(s1)
    8000568e:	37fd                	addiw	a5,a5,-1
    80005690:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005694:	8526                	mv	a0,s1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	fce080e7          	jalr	-50(ra) # 80003664 <iupdate>
    8000569e:	b781                	j	800055de <sys_unlink+0xe0>
    return -1;
    800056a0:	557d                	li	a0,-1
    800056a2:	a005                	j	800056c2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	2ea080e7          	jalr	746(ra) # 80003990 <iunlockput>
  iunlockput(dp);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	2e0080e7          	jalr	736(ra) # 80003990 <iunlockput>
  end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	ab8080e7          	jalr	-1352(ra) # 80004170 <end_op>
  return -1;
    800056c0:	557d                	li	a0,-1
}
    800056c2:	70ae                	ld	ra,232(sp)
    800056c4:	740e                	ld	s0,224(sp)
    800056c6:	64ee                	ld	s1,216(sp)
    800056c8:	694e                	ld	s2,208(sp)
    800056ca:	69ae                	ld	s3,200(sp)
    800056cc:	616d                	addi	sp,sp,240
    800056ce:	8082                	ret

00000000800056d0 <sys_open>:

uint64
sys_open(void)
{
    800056d0:	7131                	addi	sp,sp,-192
    800056d2:	fd06                	sd	ra,184(sp)
    800056d4:	f922                	sd	s0,176(sp)
    800056d6:	f526                	sd	s1,168(sp)
    800056d8:	f14a                	sd	s2,160(sp)
    800056da:	ed4e                	sd	s3,152(sp)
    800056dc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056de:	f4c40593          	addi	a1,s0,-180
    800056e2:	4505                	li	a0,1
    800056e4:	ffffd097          	auipc	ra,0xffffd
    800056e8:	474080e7          	jalr	1140(ra) # 80002b58 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056ec:	08000613          	li	a2,128
    800056f0:	f5040593          	addi	a1,s0,-176
    800056f4:	4501                	li	a0,0
    800056f6:	ffffd097          	auipc	ra,0xffffd
    800056fa:	4a2080e7          	jalr	1186(ra) # 80002b98 <argstr>
    800056fe:	87aa                	mv	a5,a0
    return -1;
    80005700:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005702:	0a07c963          	bltz	a5,800057b4 <sys_open+0xe4>

  begin_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	9ea080e7          	jalr	-1558(ra) # 800040f0 <begin_op>

  if(omode & O_CREATE){
    8000570e:	f4c42783          	lw	a5,-180(s0)
    80005712:	2007f793          	andi	a5,a5,512
    80005716:	cfc5                	beqz	a5,800057ce <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005718:	4681                	li	a3,0
    8000571a:	4601                	li	a2,0
    8000571c:	4589                	li	a1,2
    8000571e:	f5040513          	addi	a0,s0,-176
    80005722:	00000097          	auipc	ra,0x0
    80005726:	976080e7          	jalr	-1674(ra) # 80005098 <create>
    8000572a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000572c:	c959                	beqz	a0,800057c2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000572e:	04449703          	lh	a4,68(s1)
    80005732:	478d                	li	a5,3
    80005734:	00f71763          	bne	a4,a5,80005742 <sys_open+0x72>
    80005738:	0464d703          	lhu	a4,70(s1)
    8000573c:	47a5                	li	a5,9
    8000573e:	0ce7ed63          	bltu	a5,a4,80005818 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	dbe080e7          	jalr	-578(ra) # 80004500 <filealloc>
    8000574a:	89aa                	mv	s3,a0
    8000574c:	10050363          	beqz	a0,80005852 <sys_open+0x182>
    80005750:	00000097          	auipc	ra,0x0
    80005754:	906080e7          	jalr	-1786(ra) # 80005056 <fdalloc>
    80005758:	892a                	mv	s2,a0
    8000575a:	0e054763          	bltz	a0,80005848 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000575e:	04449703          	lh	a4,68(s1)
    80005762:	478d                	li	a5,3
    80005764:	0cf70563          	beq	a4,a5,8000582e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005768:	4789                	li	a5,2
    8000576a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000576e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005772:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005776:	f4c42783          	lw	a5,-180(s0)
    8000577a:	0017c713          	xori	a4,a5,1
    8000577e:	8b05                	andi	a4,a4,1
    80005780:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005784:	0037f713          	andi	a4,a5,3
    80005788:	00e03733          	snez	a4,a4
    8000578c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005790:	4007f793          	andi	a5,a5,1024
    80005794:	c791                	beqz	a5,800057a0 <sys_open+0xd0>
    80005796:	04449703          	lh	a4,68(s1)
    8000579a:	4789                	li	a5,2
    8000579c:	0af70063          	beq	a4,a5,8000583c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	04e080e7          	jalr	78(ra) # 800037f0 <iunlock>
  end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	9c6080e7          	jalr	-1594(ra) # 80004170 <end_op>

  return fd;
    800057b2:	854a                	mv	a0,s2
}
    800057b4:	70ea                	ld	ra,184(sp)
    800057b6:	744a                	ld	s0,176(sp)
    800057b8:	74aa                	ld	s1,168(sp)
    800057ba:	790a                	ld	s2,160(sp)
    800057bc:	69ea                	ld	s3,152(sp)
    800057be:	6129                	addi	sp,sp,192
    800057c0:	8082                	ret
      end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	9ae080e7          	jalr	-1618(ra) # 80004170 <end_op>
      return -1;
    800057ca:	557d                	li	a0,-1
    800057cc:	b7e5                	j	800057b4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057ce:	f5040513          	addi	a0,s0,-176
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	702080e7          	jalr	1794(ra) # 80003ed4 <namei>
    800057da:	84aa                	mv	s1,a0
    800057dc:	c905                	beqz	a0,8000580c <sys_open+0x13c>
    ilock(ip);
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	f50080e7          	jalr	-176(ra) # 8000372e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057e6:	04449703          	lh	a4,68(s1)
    800057ea:	4785                	li	a5,1
    800057ec:	f4f711e3          	bne	a4,a5,8000572e <sys_open+0x5e>
    800057f0:	f4c42783          	lw	a5,-180(s0)
    800057f4:	d7b9                	beqz	a5,80005742 <sys_open+0x72>
      iunlockput(ip);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	198080e7          	jalr	408(ra) # 80003990 <iunlockput>
      end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	970080e7          	jalr	-1680(ra) # 80004170 <end_op>
      return -1;
    80005808:	557d                	li	a0,-1
    8000580a:	b76d                	j	800057b4 <sys_open+0xe4>
      end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	964080e7          	jalr	-1692(ra) # 80004170 <end_op>
      return -1;
    80005814:	557d                	li	a0,-1
    80005816:	bf79                	j	800057b4 <sys_open+0xe4>
    iunlockput(ip);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	176080e7          	jalr	374(ra) # 80003990 <iunlockput>
    end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	94e080e7          	jalr	-1714(ra) # 80004170 <end_op>
    return -1;
    8000582a:	557d                	li	a0,-1
    8000582c:	b761                	j	800057b4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000582e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005832:	04649783          	lh	a5,70(s1)
    80005836:	02f99223          	sh	a5,36(s3)
    8000583a:	bf25                	j	80005772 <sys_open+0xa2>
    itrunc(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	ffe080e7          	jalr	-2(ra) # 8000383c <itrunc>
    80005846:	bfa9                	j	800057a0 <sys_open+0xd0>
      fileclose(f);
    80005848:	854e                	mv	a0,s3
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	d72080e7          	jalr	-654(ra) # 800045bc <fileclose>
    iunlockput(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	13c080e7          	jalr	316(ra) # 80003990 <iunlockput>
    end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	914080e7          	jalr	-1772(ra) # 80004170 <end_op>
    return -1;
    80005864:	557d                	li	a0,-1
    80005866:	b7b9                	j	800057b4 <sys_open+0xe4>

0000000080005868 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005868:	7175                	addi	sp,sp,-144
    8000586a:	e506                	sd	ra,136(sp)
    8000586c:	e122                	sd	s0,128(sp)
    8000586e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	880080e7          	jalr	-1920(ra) # 800040f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005878:	08000613          	li	a2,128
    8000587c:	f7040593          	addi	a1,s0,-144
    80005880:	4501                	li	a0,0
    80005882:	ffffd097          	auipc	ra,0xffffd
    80005886:	316080e7          	jalr	790(ra) # 80002b98 <argstr>
    8000588a:	02054963          	bltz	a0,800058bc <sys_mkdir+0x54>
    8000588e:	4681                	li	a3,0
    80005890:	4601                	li	a2,0
    80005892:	4585                	li	a1,1
    80005894:	f7040513          	addi	a0,s0,-144
    80005898:	00000097          	auipc	ra,0x0
    8000589c:	800080e7          	jalr	-2048(ra) # 80005098 <create>
    800058a0:	cd11                	beqz	a0,800058bc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	0ee080e7          	jalr	238(ra) # 80003990 <iunlockput>
  end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	8c6080e7          	jalr	-1850(ra) # 80004170 <end_op>
  return 0;
    800058b2:	4501                	li	a0,0
}
    800058b4:	60aa                	ld	ra,136(sp)
    800058b6:	640a                	ld	s0,128(sp)
    800058b8:	6149                	addi	sp,sp,144
    800058ba:	8082                	ret
    end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	8b4080e7          	jalr	-1868(ra) # 80004170 <end_op>
    return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	b7fd                	j	800058b4 <sys_mkdir+0x4c>

00000000800058c8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058c8:	7135                	addi	sp,sp,-160
    800058ca:	ed06                	sd	ra,152(sp)
    800058cc:	e922                	sd	s0,144(sp)
    800058ce:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	820080e7          	jalr	-2016(ra) # 800040f0 <begin_op>
  argint(1, &major);
    800058d8:	f6c40593          	addi	a1,s0,-148
    800058dc:	4505                	li	a0,1
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	27a080e7          	jalr	634(ra) # 80002b58 <argint>
  argint(2, &minor);
    800058e6:	f6840593          	addi	a1,s0,-152
    800058ea:	4509                	li	a0,2
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	26c080e7          	jalr	620(ra) # 80002b58 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f4:	08000613          	li	a2,128
    800058f8:	f7040593          	addi	a1,s0,-144
    800058fc:	4501                	li	a0,0
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	29a080e7          	jalr	666(ra) # 80002b98 <argstr>
    80005906:	02054b63          	bltz	a0,8000593c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000590a:	f6841683          	lh	a3,-152(s0)
    8000590e:	f6c41603          	lh	a2,-148(s0)
    80005912:	458d                	li	a1,3
    80005914:	f7040513          	addi	a0,s0,-144
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	780080e7          	jalr	1920(ra) # 80005098 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005920:	cd11                	beqz	a0,8000593c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	06e080e7          	jalr	110(ra) # 80003990 <iunlockput>
  end_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	846080e7          	jalr	-1978(ra) # 80004170 <end_op>
  return 0;
    80005932:	4501                	li	a0,0
}
    80005934:	60ea                	ld	ra,152(sp)
    80005936:	644a                	ld	s0,144(sp)
    80005938:	610d                	addi	sp,sp,160
    8000593a:	8082                	ret
    end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	834080e7          	jalr	-1996(ra) # 80004170 <end_op>
    return -1;
    80005944:	557d                	li	a0,-1
    80005946:	b7fd                	j	80005934 <sys_mknod+0x6c>

0000000080005948 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005948:	7135                	addi	sp,sp,-160
    8000594a:	ed06                	sd	ra,152(sp)
    8000594c:	e922                	sd	s0,144(sp)
    8000594e:	e526                	sd	s1,136(sp)
    80005950:	e14a                	sd	s2,128(sp)
    80005952:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005954:	ffffc097          	auipc	ra,0xffffc
    80005958:	058080e7          	jalr	88(ra) # 800019ac <myproc>
    8000595c:	892a                	mv	s2,a0
  
  begin_op();
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	792080e7          	jalr	1938(ra) # 800040f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005966:	08000613          	li	a2,128
    8000596a:	f6040593          	addi	a1,s0,-160
    8000596e:	4501                	li	a0,0
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	228080e7          	jalr	552(ra) # 80002b98 <argstr>
    80005978:	04054b63          	bltz	a0,800059ce <sys_chdir+0x86>
    8000597c:	f6040513          	addi	a0,s0,-160
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	554080e7          	jalr	1364(ra) # 80003ed4 <namei>
    80005988:	84aa                	mv	s1,a0
    8000598a:	c131                	beqz	a0,800059ce <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	da2080e7          	jalr	-606(ra) # 8000372e <ilock>
  if(ip->type != T_DIR){
    80005994:	04449703          	lh	a4,68(s1)
    80005998:	4785                	li	a5,1
    8000599a:	04f71063          	bne	a4,a5,800059da <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	e50080e7          	jalr	-432(ra) # 800037f0 <iunlock>
  iput(p->cwd);
    800059a8:	15093503          	ld	a0,336(s2)
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	f3c080e7          	jalr	-196(ra) # 800038e8 <iput>
  end_op();
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	7bc080e7          	jalr	1980(ra) # 80004170 <end_op>
  p->cwd = ip;
    800059bc:	14993823          	sd	s1,336(s2)
  return 0;
    800059c0:	4501                	li	a0,0
}
    800059c2:	60ea                	ld	ra,152(sp)
    800059c4:	644a                	ld	s0,144(sp)
    800059c6:	64aa                	ld	s1,136(sp)
    800059c8:	690a                	ld	s2,128(sp)
    800059ca:	610d                	addi	sp,sp,160
    800059cc:	8082                	ret
    end_op();
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	7a2080e7          	jalr	1954(ra) # 80004170 <end_op>
    return -1;
    800059d6:	557d                	li	a0,-1
    800059d8:	b7ed                	j	800059c2 <sys_chdir+0x7a>
    iunlockput(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	fb4080e7          	jalr	-76(ra) # 80003990 <iunlockput>
    end_op();
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	78c080e7          	jalr	1932(ra) # 80004170 <end_op>
    return -1;
    800059ec:	557d                	li	a0,-1
    800059ee:	bfd1                	j	800059c2 <sys_chdir+0x7a>

00000000800059f0 <sys_exec>:

uint64
sys_exec(void)
{
    800059f0:	7145                	addi	sp,sp,-464
    800059f2:	e786                	sd	ra,456(sp)
    800059f4:	e3a2                	sd	s0,448(sp)
    800059f6:	ff26                	sd	s1,440(sp)
    800059f8:	fb4a                	sd	s2,432(sp)
    800059fa:	f74e                	sd	s3,424(sp)
    800059fc:	f352                	sd	s4,416(sp)
    800059fe:	ef56                	sd	s5,408(sp)
    80005a00:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a02:	e3840593          	addi	a1,s0,-456
    80005a06:	4505                	li	a0,1
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	170080e7          	jalr	368(ra) # 80002b78 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a10:	08000613          	li	a2,128
    80005a14:	f4040593          	addi	a1,s0,-192
    80005a18:	4501                	li	a0,0
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	17e080e7          	jalr	382(ra) # 80002b98 <argstr>
    80005a22:	87aa                	mv	a5,a0
    return -1;
    80005a24:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a26:	0c07c263          	bltz	a5,80005aea <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a2a:	10000613          	li	a2,256
    80005a2e:	4581                	li	a1,0
    80005a30:	e4040513          	addi	a0,s0,-448
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	29e080e7          	jalr	670(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a3c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a40:	89a6                	mv	s3,s1
    80005a42:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a44:	02000a13          	li	s4,32
    80005a48:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a4c:	00391793          	slli	a5,s2,0x3
    80005a50:	e3040593          	addi	a1,s0,-464
    80005a54:	e3843503          	ld	a0,-456(s0)
    80005a58:	953e                	add	a0,a0,a5
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	060080e7          	jalr	96(ra) # 80002aba <fetchaddr>
    80005a62:	02054a63          	bltz	a0,80005a96 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a66:	e3043783          	ld	a5,-464(s0)
    80005a6a:	c3b9                	beqz	a5,80005ab0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	07a080e7          	jalr	122(ra) # 80000ae6 <kalloc>
    80005a74:	85aa                	mv	a1,a0
    80005a76:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a7a:	cd11                	beqz	a0,80005a96 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a7c:	6605                	lui	a2,0x1
    80005a7e:	e3043503          	ld	a0,-464(s0)
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	08a080e7          	jalr	138(ra) # 80002b0c <fetchstr>
    80005a8a:	00054663          	bltz	a0,80005a96 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a8e:	0905                	addi	s2,s2,1
    80005a90:	09a1                	addi	s3,s3,8
    80005a92:	fb491be3          	bne	s2,s4,80005a48 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a96:	10048913          	addi	s2,s1,256
    80005a9a:	6088                	ld	a0,0(s1)
    80005a9c:	c531                	beqz	a0,80005ae8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	f4c080e7          	jalr	-180(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa6:	04a1                	addi	s1,s1,8
    80005aa8:	ff2499e3          	bne	s1,s2,80005a9a <sys_exec+0xaa>
  return -1;
    80005aac:	557d                	li	a0,-1
    80005aae:	a835                	j	80005aea <sys_exec+0xfa>
      argv[i] = 0;
    80005ab0:	0a8e                	slli	s5,s5,0x3
    80005ab2:	fc040793          	addi	a5,s0,-64
    80005ab6:	9abe                	add	s5,s5,a5
    80005ab8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005abc:	e4040593          	addi	a1,s0,-448
    80005ac0:	f4040513          	addi	a0,s0,-192
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	172080e7          	jalr	370(ra) # 80004c36 <exec>
    80005acc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	10048993          	addi	s3,s1,256
    80005ad2:	6088                	ld	a0,0(s1)
    80005ad4:	c901                	beqz	a0,80005ae4 <sys_exec+0xf4>
    kfree(argv[i]);
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	f14080e7          	jalr	-236(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	04a1                	addi	s1,s1,8
    80005ae0:	ff3499e3          	bne	s1,s3,80005ad2 <sys_exec+0xe2>
  return ret;
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	a011                	j	80005aea <sys_exec+0xfa>
  return -1;
    80005ae8:	557d                	li	a0,-1
}
    80005aea:	60be                	ld	ra,456(sp)
    80005aec:	641e                	ld	s0,448(sp)
    80005aee:	74fa                	ld	s1,440(sp)
    80005af0:	795a                	ld	s2,432(sp)
    80005af2:	79ba                	ld	s3,424(sp)
    80005af4:	7a1a                	ld	s4,416(sp)
    80005af6:	6afa                	ld	s5,408(sp)
    80005af8:	6179                	addi	sp,sp,464
    80005afa:	8082                	ret

0000000080005afc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005afc:	7139                	addi	sp,sp,-64
    80005afe:	fc06                	sd	ra,56(sp)
    80005b00:	f822                	sd	s0,48(sp)
    80005b02:	f426                	sd	s1,40(sp)
    80005b04:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	ea6080e7          	jalr	-346(ra) # 800019ac <myproc>
    80005b0e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b10:	fd840593          	addi	a1,s0,-40
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	062080e7          	jalr	98(ra) # 80002b78 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b1e:	fc840593          	addi	a1,s0,-56
    80005b22:	fd040513          	addi	a0,s0,-48
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	dc6080e7          	jalr	-570(ra) # 800048ec <pipealloc>
    return -1;
    80005b2e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b30:	0c054463          	bltz	a0,80005bf8 <sys_pipe+0xfc>
  fd0 = -1;
    80005b34:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b38:	fd043503          	ld	a0,-48(s0)
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	51a080e7          	jalr	1306(ra) # 80005056 <fdalloc>
    80005b44:	fca42223          	sw	a0,-60(s0)
    80005b48:	08054b63          	bltz	a0,80005bde <sys_pipe+0xe2>
    80005b4c:	fc843503          	ld	a0,-56(s0)
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	506080e7          	jalr	1286(ra) # 80005056 <fdalloc>
    80005b58:	fca42023          	sw	a0,-64(s0)
    80005b5c:	06054863          	bltz	a0,80005bcc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b60:	4691                	li	a3,4
    80005b62:	fc440613          	addi	a2,s0,-60
    80005b66:	fd843583          	ld	a1,-40(s0)
    80005b6a:	68a8                	ld	a0,80(s1)
    80005b6c:	ffffc097          	auipc	ra,0xffffc
    80005b70:	afc080e7          	jalr	-1284(ra) # 80001668 <copyout>
    80005b74:	02054063          	bltz	a0,80005b94 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b78:	4691                	li	a3,4
    80005b7a:	fc040613          	addi	a2,s0,-64
    80005b7e:	fd843583          	ld	a1,-40(s0)
    80005b82:	0591                	addi	a1,a1,4
    80005b84:	68a8                	ld	a0,80(s1)
    80005b86:	ffffc097          	auipc	ra,0xffffc
    80005b8a:	ae2080e7          	jalr	-1310(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b8e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b90:	06055463          	bgez	a0,80005bf8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b94:	fc442783          	lw	a5,-60(s0)
    80005b98:	07e9                	addi	a5,a5,26
    80005b9a:	078e                	slli	a5,a5,0x3
    80005b9c:	97a6                	add	a5,a5,s1
    80005b9e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ba2:	fc042503          	lw	a0,-64(s0)
    80005ba6:	0569                	addi	a0,a0,26
    80005ba8:	050e                	slli	a0,a0,0x3
    80005baa:	94aa                	add	s1,s1,a0
    80005bac:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bb0:	fd043503          	ld	a0,-48(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	a08080e7          	jalr	-1528(ra) # 800045bc <fileclose>
    fileclose(wf);
    80005bbc:	fc843503          	ld	a0,-56(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	9fc080e7          	jalr	-1540(ra) # 800045bc <fileclose>
    return -1;
    80005bc8:	57fd                	li	a5,-1
    80005bca:	a03d                	j	80005bf8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bcc:	fc442783          	lw	a5,-60(s0)
    80005bd0:	0007c763          	bltz	a5,80005bde <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bd4:	07e9                	addi	a5,a5,26
    80005bd6:	078e                	slli	a5,a5,0x3
    80005bd8:	94be                	add	s1,s1,a5
    80005bda:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bde:	fd043503          	ld	a0,-48(s0)
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	9da080e7          	jalr	-1574(ra) # 800045bc <fileclose>
    fileclose(wf);
    80005bea:	fc843503          	ld	a0,-56(s0)
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	9ce080e7          	jalr	-1586(ra) # 800045bc <fileclose>
    return -1;
    80005bf6:	57fd                	li	a5,-1
}
    80005bf8:	853e                	mv	a0,a5
    80005bfa:	70e2                	ld	ra,56(sp)
    80005bfc:	7442                	ld	s0,48(sp)
    80005bfe:	74a2                	ld	s1,40(sp)
    80005c00:	6121                	addi	sp,sp,64
    80005c02:	8082                	ret
	...

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d37fc0ef          	jal	ra,80002986 <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	6d0c                	ld	a1,24(a0)
    80005cac:	7110                	ld	a2,32(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	c98080e7          	jalr	-872(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	953e                	add	a0,a0,a5
    80005d0c:	00052023          	sw	zero,0(a0)
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	c60080e7          	jalr	-928(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5179b          	slliw	a5,a0,0xd
    80005d2c:	0c201537          	lui	a0,0xc201
    80005d30:	953e                	add	a0,a0,a5
  return irq;
}
    80005d32:	4148                	lw	a0,4(a0)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c38080e7          	jalr	-968(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	04a7cc63          	blt	a5,a0,80005dc8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d74:	0001c797          	auipc	a5,0x1c
    80005d78:	40c78793          	addi	a5,a5,1036 # 80022180 <disk>
    80005d7c:	97aa                	add	a5,a5,a0
    80005d7e:	0187c783          	lbu	a5,24(a5)
    80005d82:	ebb9                	bnez	a5,80005dd8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d84:	00451613          	slli	a2,a0,0x4
    80005d88:	0001c797          	auipc	a5,0x1c
    80005d8c:	3f878793          	addi	a5,a5,1016 # 80022180 <disk>
    80005d90:	6394                	ld	a3,0(a5)
    80005d92:	96b2                	add	a3,a3,a2
    80005d94:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d98:	6398                	ld	a4,0(a5)
    80005d9a:	9732                	add	a4,a4,a2
    80005d9c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005da0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005da4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005da8:	953e                	add	a0,a0,a5
    80005daa:	4785                	li	a5,1
    80005dac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005db0:	0001c517          	auipc	a0,0x1c
    80005db4:	3e850513          	addi	a0,a0,1000 # 80022198 <disk+0x18>
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	376080e7          	jalr	886(ra) # 8000212e <wakeup>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret
    panic("free_desc 1");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	a4050513          	addi	a0,a0,-1472 # 80008808 <syscalls+0x2f0>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	76e080e7          	jalr	1902(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	a4050513          	addi	a0,a0,-1472 # 80008818 <syscalls+0x300>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	75e080e7          	jalr	1886(ra) # 8000053e <panic>

0000000080005de8 <virtio_disk_init>:
{
    80005de8:	1101                	addi	sp,sp,-32
    80005dea:	ec06                	sd	ra,24(sp)
    80005dec:	e822                	sd	s0,16(sp)
    80005dee:	e426                	sd	s1,8(sp)
    80005df0:	e04a                	sd	s2,0(sp)
    80005df2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005df4:	00003597          	auipc	a1,0x3
    80005df8:	a3458593          	addi	a1,a1,-1484 # 80008828 <syscalls+0x310>
    80005dfc:	0001c517          	auipc	a0,0x1c
    80005e00:	4ac50513          	addi	a0,a0,1196 # 800222a8 <disk+0x128>
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	d42080e7          	jalr	-702(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	4398                	lw	a4,0(a5)
    80005e12:	2701                	sext.w	a4,a4
    80005e14:	747277b7          	lui	a5,0x74727
    80005e18:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e1c:	14f71c63          	bne	a4,a5,80005f74 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e20:	100017b7          	lui	a5,0x10001
    80005e24:	43dc                	lw	a5,4(a5)
    80005e26:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e28:	4709                	li	a4,2
    80005e2a:	14e79563          	bne	a5,a4,80005f74 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	479c                	lw	a5,8(a5)
    80005e34:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e36:	12e79f63          	bne	a5,a4,80005f74 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e3a:	100017b7          	lui	a5,0x10001
    80005e3e:	47d8                	lw	a4,12(a5)
    80005e40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e42:	554d47b7          	lui	a5,0x554d4
    80005e46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e4a:	12f71563          	bne	a4,a5,80005f74 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	4705                	li	a4,1
    80005e58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5a:	470d                	li	a4,3
    80005e5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e5e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e60:	c7ffe737          	lui	a4,0xc7ffe
    80005e64:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc49f>
    80005e68:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e6a:	2701                	sext.w	a4,a4
    80005e6c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	472d                	li	a4,11
    80005e70:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e72:	5bbc                	lw	a5,112(a5)
    80005e74:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e78:	8ba1                	andi	a5,a5,8
    80005e7a:	10078563          	beqz	a5,80005f84 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e86:	43fc                	lw	a5,68(a5)
    80005e88:	2781                	sext.w	a5,a5
    80005e8a:	10079563          	bnez	a5,80005f94 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e8e:	100017b7          	lui	a5,0x10001
    80005e92:	5bdc                	lw	a5,52(a5)
    80005e94:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e96:	10078763          	beqz	a5,80005fa4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005e9a:	471d                	li	a4,7
    80005e9c:	10f77c63          	bgeu	a4,a5,80005fb4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005ea0:	ffffb097          	auipc	ra,0xffffb
    80005ea4:	c46080e7          	jalr	-954(ra) # 80000ae6 <kalloc>
    80005ea8:	0001c497          	auipc	s1,0x1c
    80005eac:	2d848493          	addi	s1,s1,728 # 80022180 <disk>
    80005eb0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	c34080e7          	jalr	-972(ra) # 80000ae6 <kalloc>
    80005eba:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	c2a080e7          	jalr	-982(ra) # 80000ae6 <kalloc>
    80005ec4:	87aa                	mv	a5,a0
    80005ec6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ec8:	6088                	ld	a0,0(s1)
    80005eca:	cd6d                	beqz	a0,80005fc4 <virtio_disk_init+0x1dc>
    80005ecc:	0001c717          	auipc	a4,0x1c
    80005ed0:	2bc73703          	ld	a4,700(a4) # 80022188 <disk+0x8>
    80005ed4:	cb65                	beqz	a4,80005fc4 <virtio_disk_init+0x1dc>
    80005ed6:	c7fd                	beqz	a5,80005fc4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005ed8:	6605                	lui	a2,0x1
    80005eda:	4581                	li	a1,0
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	df6080e7          	jalr	-522(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ee4:	0001c497          	auipc	s1,0x1c
    80005ee8:	29c48493          	addi	s1,s1,668 # 80022180 <disk>
    80005eec:	6605                	lui	a2,0x1
    80005eee:	4581                	li	a1,0
    80005ef0:	6488                	ld	a0,8(s1)
    80005ef2:	ffffb097          	auipc	ra,0xffffb
    80005ef6:	de0080e7          	jalr	-544(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005efa:	6605                	lui	a2,0x1
    80005efc:	4581                	li	a1,0
    80005efe:	6888                	ld	a0,16(s1)
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	dd2080e7          	jalr	-558(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f08:	100017b7          	lui	a5,0x10001
    80005f0c:	4721                	li	a4,8
    80005f0e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f10:	4098                	lw	a4,0(s1)
    80005f12:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f16:	40d8                	lw	a4,4(s1)
    80005f18:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f1c:	6498                	ld	a4,8(s1)
    80005f1e:	0007069b          	sext.w	a3,a4
    80005f22:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f26:	9701                	srai	a4,a4,0x20
    80005f28:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f2c:	6898                	ld	a4,16(s1)
    80005f2e:	0007069b          	sext.w	a3,a4
    80005f32:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f36:	9701                	srai	a4,a4,0x20
    80005f38:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f3c:	4705                	li	a4,1
    80005f3e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f40:	00e48c23          	sb	a4,24(s1)
    80005f44:	00e48ca3          	sb	a4,25(s1)
    80005f48:	00e48d23          	sb	a4,26(s1)
    80005f4c:	00e48da3          	sb	a4,27(s1)
    80005f50:	00e48e23          	sb	a4,28(s1)
    80005f54:	00e48ea3          	sb	a4,29(s1)
    80005f58:	00e48f23          	sb	a4,30(s1)
    80005f5c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f60:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f64:	0727a823          	sw	s2,112(a5)
}
    80005f68:	60e2                	ld	ra,24(sp)
    80005f6a:	6442                	ld	s0,16(sp)
    80005f6c:	64a2                	ld	s1,8(sp)
    80005f6e:	6902                	ld	s2,0(sp)
    80005f70:	6105                	addi	sp,sp,32
    80005f72:	8082                	ret
    panic("could not find virtio disk");
    80005f74:	00003517          	auipc	a0,0x3
    80005f78:	8c450513          	addi	a0,a0,-1852 # 80008838 <syscalls+0x320>
    80005f7c:	ffffa097          	auipc	ra,0xffffa
    80005f80:	5c2080e7          	jalr	1474(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f84:	00003517          	auipc	a0,0x3
    80005f88:	8d450513          	addi	a0,a0,-1836 # 80008858 <syscalls+0x340>
    80005f8c:	ffffa097          	auipc	ra,0xffffa
    80005f90:	5b2080e7          	jalr	1458(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80005f94:	00003517          	auipc	a0,0x3
    80005f98:	8e450513          	addi	a0,a0,-1820 # 80008878 <syscalls+0x360>
    80005f9c:	ffffa097          	auipc	ra,0xffffa
    80005fa0:	5a2080e7          	jalr	1442(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005fa4:	00003517          	auipc	a0,0x3
    80005fa8:	8f450513          	addi	a0,a0,-1804 # 80008898 <syscalls+0x380>
    80005fac:	ffffa097          	auipc	ra,0xffffa
    80005fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005fb4:	00003517          	auipc	a0,0x3
    80005fb8:	90450513          	addi	a0,a0,-1788 # 800088b8 <syscalls+0x3a0>
    80005fbc:	ffffa097          	auipc	ra,0xffffa
    80005fc0:	582080e7          	jalr	1410(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80005fc4:	00003517          	auipc	a0,0x3
    80005fc8:	91450513          	addi	a0,a0,-1772 # 800088d8 <syscalls+0x3c0>
    80005fcc:	ffffa097          	auipc	ra,0xffffa
    80005fd0:	572080e7          	jalr	1394(ra) # 8000053e <panic>

0000000080005fd4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fd4:	7119                	addi	sp,sp,-128
    80005fd6:	fc86                	sd	ra,120(sp)
    80005fd8:	f8a2                	sd	s0,112(sp)
    80005fda:	f4a6                	sd	s1,104(sp)
    80005fdc:	f0ca                	sd	s2,96(sp)
    80005fde:	ecce                	sd	s3,88(sp)
    80005fe0:	e8d2                	sd	s4,80(sp)
    80005fe2:	e4d6                	sd	s5,72(sp)
    80005fe4:	e0da                	sd	s6,64(sp)
    80005fe6:	fc5e                	sd	s7,56(sp)
    80005fe8:	f862                	sd	s8,48(sp)
    80005fea:	f466                	sd	s9,40(sp)
    80005fec:	f06a                	sd	s10,32(sp)
    80005fee:	ec6e                	sd	s11,24(sp)
    80005ff0:	0100                	addi	s0,sp,128
    80005ff2:	8aaa                	mv	s5,a0
    80005ff4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ff6:	00c52d03          	lw	s10,12(a0)
    80005ffa:	001d1d1b          	slliw	s10,s10,0x1
    80005ffe:	1d02                	slli	s10,s10,0x20
    80006000:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006004:	0001c517          	auipc	a0,0x1c
    80006008:	2a450513          	addi	a0,a0,676 # 800222a8 <disk+0x128>
    8000600c:	ffffb097          	auipc	ra,0xffffb
    80006010:	bca080e7          	jalr	-1078(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006014:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006016:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006018:	0001cb97          	auipc	s7,0x1c
    8000601c:	168b8b93          	addi	s7,s7,360 # 80022180 <disk>
  for(int i = 0; i < 3; i++){
    80006020:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006022:	0001cc97          	auipc	s9,0x1c
    80006026:	286c8c93          	addi	s9,s9,646 # 800222a8 <disk+0x128>
    8000602a:	a08d                	j	8000608c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000602c:	00fb8733          	add	a4,s7,a5
    80006030:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006034:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006036:	0207c563          	bltz	a5,80006060 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000603a:	2905                	addiw	s2,s2,1
    8000603c:	0611                	addi	a2,a2,4
    8000603e:	05690c63          	beq	s2,s6,80006096 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006042:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006044:	0001c717          	auipc	a4,0x1c
    80006048:	13c70713          	addi	a4,a4,316 # 80022180 <disk>
    8000604c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000604e:	01874683          	lbu	a3,24(a4)
    80006052:	fee9                	bnez	a3,8000602c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006054:	2785                	addiw	a5,a5,1
    80006056:	0705                	addi	a4,a4,1
    80006058:	fe979be3          	bne	a5,s1,8000604e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000605c:	57fd                	li	a5,-1
    8000605e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006060:	01205d63          	blez	s2,8000607a <virtio_disk_rw+0xa6>
    80006064:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006066:	000a2503          	lw	a0,0(s4)
    8000606a:	00000097          	auipc	ra,0x0
    8000606e:	cfc080e7          	jalr	-772(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80006072:	2d85                	addiw	s11,s11,1
    80006074:	0a11                	addi	s4,s4,4
    80006076:	ffb918e3          	bne	s2,s11,80006066 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000607a:	85e6                	mv	a1,s9
    8000607c:	0001c517          	auipc	a0,0x1c
    80006080:	11c50513          	addi	a0,a0,284 # 80022198 <disk+0x18>
    80006084:	ffffc097          	auipc	ra,0xffffc
    80006088:	046080e7          	jalr	70(ra) # 800020ca <sleep>
  for(int i = 0; i < 3; i++){
    8000608c:	f8040a13          	addi	s4,s0,-128
{
    80006090:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006092:	894e                	mv	s2,s3
    80006094:	b77d                	j	80006042 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006096:	f8042583          	lw	a1,-128(s0)
    8000609a:	00a58793          	addi	a5,a1,10
    8000609e:	0792                	slli	a5,a5,0x4

  if(write)
    800060a0:	0001c617          	auipc	a2,0x1c
    800060a4:	0e060613          	addi	a2,a2,224 # 80022180 <disk>
    800060a8:	00f60733          	add	a4,a2,a5
    800060ac:	018036b3          	snez	a3,s8
    800060b0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060b2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800060b6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060ba:	f6078693          	addi	a3,a5,-160
    800060be:	6218                	ld	a4,0(a2)
    800060c0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060c2:	00878513          	addi	a0,a5,8
    800060c6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060c8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060ca:	6208                	ld	a0,0(a2)
    800060cc:	96aa                	add	a3,a3,a0
    800060ce:	4741                	li	a4,16
    800060d0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060d2:	4705                	li	a4,1
    800060d4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800060d8:	f8442703          	lw	a4,-124(s0)
    800060dc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060e0:	0712                	slli	a4,a4,0x4
    800060e2:	953a                	add	a0,a0,a4
    800060e4:	058a8693          	addi	a3,s5,88
    800060e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800060ea:	6208                	ld	a0,0(a2)
    800060ec:	972a                	add	a4,a4,a0
    800060ee:	40000693          	li	a3,1024
    800060f2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060f4:	001c3c13          	seqz	s8,s8
    800060f8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060fa:	001c6c13          	ori	s8,s8,1
    800060fe:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006102:	f8842603          	lw	a2,-120(s0)
    80006106:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000610a:	0001c697          	auipc	a3,0x1c
    8000610e:	07668693          	addi	a3,a3,118 # 80022180 <disk>
    80006112:	00258713          	addi	a4,a1,2
    80006116:	0712                	slli	a4,a4,0x4
    80006118:	9736                	add	a4,a4,a3
    8000611a:	587d                	li	a6,-1
    8000611c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006120:	0612                	slli	a2,a2,0x4
    80006122:	9532                	add	a0,a0,a2
    80006124:	f9078793          	addi	a5,a5,-112
    80006128:	97b6                	add	a5,a5,a3
    8000612a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000612c:	629c                	ld	a5,0(a3)
    8000612e:	97b2                	add	a5,a5,a2
    80006130:	4605                	li	a2,1
    80006132:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006134:	4509                	li	a0,2
    80006136:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000613a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000613e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006142:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006146:	6698                	ld	a4,8(a3)
    80006148:	00275783          	lhu	a5,2(a4)
    8000614c:	8b9d                	andi	a5,a5,7
    8000614e:	0786                	slli	a5,a5,0x1
    80006150:	97ba                	add	a5,a5,a4
    80006152:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006156:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000615a:	6698                	ld	a4,8(a3)
    8000615c:	00275783          	lhu	a5,2(a4)
    80006160:	2785                	addiw	a5,a5,1
    80006162:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006166:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000616a:	100017b7          	lui	a5,0x10001
    8000616e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006172:	004aa783          	lw	a5,4(s5)
    80006176:	02c79163          	bne	a5,a2,80006198 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000617a:	0001c917          	auipc	s2,0x1c
    8000617e:	12e90913          	addi	s2,s2,302 # 800222a8 <disk+0x128>
  while(b->disk == 1) {
    80006182:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006184:	85ca                	mv	a1,s2
    80006186:	8556                	mv	a0,s5
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	f42080e7          	jalr	-190(ra) # 800020ca <sleep>
  while(b->disk == 1) {
    80006190:	004aa783          	lw	a5,4(s5)
    80006194:	fe9788e3          	beq	a5,s1,80006184 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006198:	f8042903          	lw	s2,-128(s0)
    8000619c:	00290793          	addi	a5,s2,2
    800061a0:	00479713          	slli	a4,a5,0x4
    800061a4:	0001c797          	auipc	a5,0x1c
    800061a8:	fdc78793          	addi	a5,a5,-36 # 80022180 <disk>
    800061ac:	97ba                	add	a5,a5,a4
    800061ae:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061b2:	0001c997          	auipc	s3,0x1c
    800061b6:	fce98993          	addi	s3,s3,-50 # 80022180 <disk>
    800061ba:	00491713          	slli	a4,s2,0x4
    800061be:	0009b783          	ld	a5,0(s3)
    800061c2:	97ba                	add	a5,a5,a4
    800061c4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061c8:	854a                	mv	a0,s2
    800061ca:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061ce:	00000097          	auipc	ra,0x0
    800061d2:	b98080e7          	jalr	-1128(ra) # 80005d66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061d6:	8885                	andi	s1,s1,1
    800061d8:	f0ed                	bnez	s1,800061ba <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061da:	0001c517          	auipc	a0,0x1c
    800061de:	0ce50513          	addi	a0,a0,206 # 800222a8 <disk+0x128>
    800061e2:	ffffb097          	auipc	ra,0xffffb
    800061e6:	aa8080e7          	jalr	-1368(ra) # 80000c8a <release>
}
    800061ea:	70e6                	ld	ra,120(sp)
    800061ec:	7446                	ld	s0,112(sp)
    800061ee:	74a6                	ld	s1,104(sp)
    800061f0:	7906                	ld	s2,96(sp)
    800061f2:	69e6                	ld	s3,88(sp)
    800061f4:	6a46                	ld	s4,80(sp)
    800061f6:	6aa6                	ld	s5,72(sp)
    800061f8:	6b06                	ld	s6,64(sp)
    800061fa:	7be2                	ld	s7,56(sp)
    800061fc:	7c42                	ld	s8,48(sp)
    800061fe:	7ca2                	ld	s9,40(sp)
    80006200:	7d02                	ld	s10,32(sp)
    80006202:	6de2                	ld	s11,24(sp)
    80006204:	6109                	addi	sp,sp,128
    80006206:	8082                	ret

0000000080006208 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006208:	1101                	addi	sp,sp,-32
    8000620a:	ec06                	sd	ra,24(sp)
    8000620c:	e822                	sd	s0,16(sp)
    8000620e:	e426                	sd	s1,8(sp)
    80006210:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006212:	0001c497          	auipc	s1,0x1c
    80006216:	f6e48493          	addi	s1,s1,-146 # 80022180 <disk>
    8000621a:	0001c517          	auipc	a0,0x1c
    8000621e:	08e50513          	addi	a0,a0,142 # 800222a8 <disk+0x128>
    80006222:	ffffb097          	auipc	ra,0xffffb
    80006226:	9b4080e7          	jalr	-1612(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000622a:	10001737          	lui	a4,0x10001
    8000622e:	533c                	lw	a5,96(a4)
    80006230:	8b8d                	andi	a5,a5,3
    80006232:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006234:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006238:	689c                	ld	a5,16(s1)
    8000623a:	0204d703          	lhu	a4,32(s1)
    8000623e:	0027d783          	lhu	a5,2(a5)
    80006242:	04f70863          	beq	a4,a5,80006292 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006246:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000624a:	6898                	ld	a4,16(s1)
    8000624c:	0204d783          	lhu	a5,32(s1)
    80006250:	8b9d                	andi	a5,a5,7
    80006252:	078e                	slli	a5,a5,0x3
    80006254:	97ba                	add	a5,a5,a4
    80006256:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006258:	00278713          	addi	a4,a5,2
    8000625c:	0712                	slli	a4,a4,0x4
    8000625e:	9726                	add	a4,a4,s1
    80006260:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006264:	e721                	bnez	a4,800062ac <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006266:	0789                	addi	a5,a5,2
    80006268:	0792                	slli	a5,a5,0x4
    8000626a:	97a6                	add	a5,a5,s1
    8000626c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000626e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006272:	ffffc097          	auipc	ra,0xffffc
    80006276:	ebc080e7          	jalr	-324(ra) # 8000212e <wakeup>

    disk.used_idx += 1;
    8000627a:	0204d783          	lhu	a5,32(s1)
    8000627e:	2785                	addiw	a5,a5,1
    80006280:	17c2                	slli	a5,a5,0x30
    80006282:	93c1                	srli	a5,a5,0x30
    80006284:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006288:	6898                	ld	a4,16(s1)
    8000628a:	00275703          	lhu	a4,2(a4)
    8000628e:	faf71ce3          	bne	a4,a5,80006246 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006292:	0001c517          	auipc	a0,0x1c
    80006296:	01650513          	addi	a0,a0,22 # 800222a8 <disk+0x128>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	9f0080e7          	jalr	-1552(ra) # 80000c8a <release>
}
    800062a2:	60e2                	ld	ra,24(sp)
    800062a4:	6442                	ld	s0,16(sp)
    800062a6:	64a2                	ld	s1,8(sp)
    800062a8:	6105                	addi	sp,sp,32
    800062aa:	8082                	ret
      panic("virtio_disk_intr status");
    800062ac:	00002517          	auipc	a0,0x2
    800062b0:	64450513          	addi	a0,a0,1604 # 800088f0 <syscalls+0x3d8>
    800062b4:	ffffa097          	auipc	ra,0xffffa
    800062b8:	28a080e7          	jalr	650(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
