
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	bd010113          	addi	sp,sp,-1072 # 80008bd0 <stack0>
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
    80000056:	a3e70713          	addi	a4,a4,-1474 # 80008a90 <timer_scratch>
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
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbeff>
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
    80000130:	44c080e7          	jalr	1100(ra) # 80002578 <either_copyin>
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
    8000018e:	a4650513          	addi	a0,a0,-1466 # 80010bd0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a3648493          	addi	s1,s1,-1482 # 80010bd0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	ac690913          	addi	s2,s2,-1338 # 80010c68 <cons+0x98>
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
    800001cc:	1fa080e7          	jalr	506(ra) # 800023c2 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f38080e7          	jalr	-200(ra) # 8000210e <sleep>
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
    80000216:	310080e7          	jalr	784(ra) # 80002522 <either_copyout>
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
    8000022a:	9aa50513          	addi	a0,a0,-1622 # 80010bd0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	99450513          	addi	a0,a0,-1644 # 80010bd0 <cons>
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
    80000276:	9ef72b23          	sw	a5,-1546(a4) # 80010c68 <cons+0x98>
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
    800002d0:	90450513          	addi	a0,a0,-1788 # 80010bd0 <cons>
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
    800002f6:	2dc080e7          	jalr	732(ra) # 800025ce <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	8d650513          	addi	a0,a0,-1834 # 80010bd0 <cons>
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
    80000322:	8b270713          	addi	a4,a4,-1870 # 80010bd0 <cons>
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
    8000034c:	88878793          	addi	a5,a5,-1912 # 80010bd0 <cons>
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
    8000037a:	8f27a783          	lw	a5,-1806(a5) # 80010c68 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	84670713          	addi	a4,a4,-1978 # 80010bd0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	83648493          	addi	s1,s1,-1994 # 80010bd0 <cons>
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
    800003da:	7fa70713          	addi	a4,a4,2042 # 80010bd0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	88f72223          	sw	a5,-1916(a4) # 80010c70 <cons+0xa0>
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
    80000416:	7be78793          	addi	a5,a5,1982 # 80010bd0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	82c7ab23          	sw	a2,-1994(a5) # 80010c6c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	82a50513          	addi	a0,a0,-2006 # 80010c68 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d2c080e7          	jalr	-724(ra) # 80002172 <wakeup>
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
    80000464:	77050513          	addi	a0,a0,1904 # 80010bd0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	2f078793          	addi	a5,a5,752 # 80021768 <devsw>
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
    8000054e:	7407a323          	sw	zero,1862(a5) # 80010c90 <pr+0x18>
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
    80000582:	4cf72923          	sw	a5,1234(a4) # 80008a50 <panicked>
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
    800005be:	6d6dad83          	lw	s11,1750(s11) # 80010c90 <pr+0x18>
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
    800005fc:	68050513          	addi	a0,a0,1664 # 80010c78 <pr>
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
    8000075a:	52250513          	addi	a0,a0,1314 # 80010c78 <pr>
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
    80000776:	50648493          	addi	s1,s1,1286 # 80010c78 <pr>
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
    800007d6:	4c650513          	addi	a0,a0,1222 # 80010c98 <uart_tx_lock>
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
    80000802:	2527a783          	lw	a5,594(a5) # 80008a50 <panicked>
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
    8000083a:	2227b783          	ld	a5,546(a5) # 80008a58 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	22273703          	ld	a4,546(a4) # 80008a60 <uart_tx_w>
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
    80000864:	438a0a13          	addi	s4,s4,1080 # 80010c98 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	1f048493          	addi	s1,s1,496 # 80008a58 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	1f098993          	addi	s3,s3,496 # 80008a60 <uart_tx_w>
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
    80000896:	8e0080e7          	jalr	-1824(ra) # 80002172 <wakeup>
    
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
    800008d2:	3ca50513          	addi	a0,a0,970 # 80010c98 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	1727a783          	lw	a5,370(a5) # 80008a50 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	17873703          	ld	a4,376(a4) # 80008a60 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	1687b783          	ld	a5,360(a5) # 80008a58 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	39c98993          	addi	s3,s3,924 # 80010c98 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	15448493          	addi	s1,s1,340 # 80008a58 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	15490913          	addi	s2,s2,340 # 80008a60 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	7f2080e7          	jalr	2034(ra) # 8000210e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	36648493          	addi	s1,s1,870 # 80010c98 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	10e7bd23          	sd	a4,282(a5) # 80008a60 <uart_tx_w>
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
    800009c0:	2dc48493          	addi	s1,s1,732 # 80010c98 <uart_tx_lock>
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
    80000a02:	f0278793          	addi	a5,a5,-254 # 80022900 <end>
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
    80000a22:	2b290913          	addi	s2,s2,690 # 80010cd0 <kmem>
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
    80000abe:	21650513          	addi	a0,a0,534 # 80010cd0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	e3250513          	addi	a0,a0,-462 # 80022900 <end>
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
    80000af4:	1e048493          	addi	s1,s1,480 # 80010cd0 <kmem>
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
    80000b0c:	1c850513          	addi	a0,a0,456 # 80010cd0 <kmem>
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
    80000b38:	19c50513          	addi	a0,a0,412 # 80010cd0 <kmem>
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
    80000e8c:	be070713          	addi	a4,a4,-1056 # 80008a68 <started>
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
    80000ec2:	85c080e7          	jalr	-1956(ra) # 8000271a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	f9a080e7          	jalr	-102(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	05a080e7          	jalr	90(ra) # 80001f28 <scheduler>
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
    80000f3a:	7bc080e7          	jalr	1980(ra) # 800026f2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7dc080e7          	jalr	2012(ra) # 8000271a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	f04080e7          	jalr	-252(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	f12080e7          	jalr	-238(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	0b4080e7          	jalr	180(ra) # 8000300a <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	758080e7          	jalr	1880(ra) # 800036b6 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	6f6080e7          	jalr	1782(ra) # 8000465c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	ffa080e7          	jalr	-6(ra) # 80005f68 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d2e080e7          	jalr	-722(ra) # 80001ca4 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	aef72223          	sw	a5,-1308(a4) # 80008a68 <started>
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
    80000f9c:	ad87b783          	ld	a5,-1320(a5) # 80008a70 <kernel_pagetable>
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
    80001254:	00008797          	auipc	a5,0x8
    80001258:	80a7be23          	sd	a0,-2020(a5) # 80008a70 <kernel_pagetable>
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
    80001850:	8d448493          	addi	s1,s1,-1836 # 80011120 <proc>
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
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	cbaa0a13          	addi	s4,s4,-838 # 80017520 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
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
    800018a0:	19048493          	addi	s1,s1,400
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
    800018ec:	40850513          	addi	a0,a0,1032 # 80010cf0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	40850513          	addi	a0,a0,1032 # 80010d08 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	81048493          	addi	s1,s1,-2032 # 80011120 <proc>
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
    80001932:	00016997          	auipc	s3,0x16
    80001936:	bee98993          	addi	s3,s3,-1042 # 80017520 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	19048493          	addi	s1,s1,400
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
    800019a0:	38450513          	addi	a0,a0,900 # 80010d20 <cpus>
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
    800019c8:	32c70713          	addi	a4,a4,812 # 80010cf0 <pid_lock>
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
    80001a00:	f447a783          	lw	a5,-188(a5) # 80008940 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	d2c080e7          	jalr	-724(ra) # 80002732 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f207a523          	sw	zero,-214(a5) # 80008940 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	c16080e7          	jalr	-1002(ra) # 80003636 <fsinit>
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
    80001a3a:	2ba90913          	addi	s2,s2,698 # 80010cf0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	efc78793          	addi	a5,a5,-260 # 80008944 <nextpid>
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
    80001bc6:	55e48493          	addi	s1,s1,1374 # 80011120 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	95690913          	addi	s2,s2,-1706 # 80017520 <tickslock>
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
    80001bea:	19048493          	addi	s1,s1,400
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a88d                	j	80001c66 <allocproc+0xb0>
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
    80001c10:	c135                	beqz	a0,80001c74 <allocproc+0xbe>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c535                	beqz	a0,80001c8c <allocproc+0xd6>
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
  p->etime=0;
    80001c4a:	1604aa23          	sw	zero,372(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	e327a783          	lw	a5,-462(a5) # 80008a80 <ticks>
    80001c56:	16f4a823          	sw	a5,368(s1)
  p->alarmdata.nticks=0;
    80001c5a:	1604ae23          	sw	zero,380(s1)
  p->alarmdata.trapframe_cpy=0;
    80001c5e:	1804b423          	sd	zero,392(s1)
  p->alarmdata.handlerfn=0;
    80001c62:	1804b023          	sd	zero,384(s1)
}
    80001c66:	8526                	mv	a0,s1
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret
    freeproc(p);
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	ee8080e7          	jalr	-280(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
    return 0;
    80001c88:	84ca                	mv	s1,s2
    80001c8a:	bff1                	j	80001c66 <allocproc+0xb0>
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ed0080e7          	jalr	-304(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	b7d1                	j	80001c66 <allocproc+0xb0>

0000000080001ca4 <userinit>:
{
    80001ca4:	1101                	addi	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f08080e7          	jalr	-248(ra) # 80001bb6 <allocproc>
    80001cb6:	84aa                	mv	s1,a0
  initproc = p;
    80001cb8:	00007797          	auipc	a5,0x7
    80001cbc:	dca7b023          	sd	a0,-576(a5) # 80008a78 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc0:	03400613          	li	a2,52
    80001cc4:	00007597          	auipc	a1,0x7
    80001cc8:	c8c58593          	addi	a1,a1,-884 # 80008950 <initcode>
    80001ccc:	6928                	ld	a0,80(a0)
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	688080e7          	jalr	1672(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cd6:	6785                	lui	a5,0x1
    80001cd8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce4:	4641                	li	a2,16
    80001ce6:	00006597          	auipc	a1,0x6
    80001cea:	51a58593          	addi	a1,a1,1306 # 80008200 <digits+0x1c0>
    80001cee:	15848513          	addi	a0,s1,344
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	12a080e7          	jalr	298(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cfa:	00006517          	auipc	a0,0x6
    80001cfe:	51650513          	addi	a0,a0,1302 # 80008210 <digits+0x1d0>
    80001d02:	00002097          	auipc	ra,0x2
    80001d06:	356080e7          	jalr	854(ra) # 80004058 <namei>
    80001d0a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d0e:	478d                	li	a5,3
    80001d10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	addi	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <growproc>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c78080e7          	jalr	-904(ra) # 800019ac <myproc>
    80001d3c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d3e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d40:	01204c63          	bgtz	s2,80001d58 <growproc+0x32>
  } else if(n < 0){
    80001d44:	02094663          	bltz	s2,80001d70 <growproc+0x4a>
  p->sz = sz;
    80001d48:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d4a:	4501                	li	a0,0
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d58:	4691                	li	a3,4
    80001d5a:	00b90633          	add	a2,s2,a1
    80001d5e:	6928                	ld	a0,80(a0)
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	6b0080e7          	jalr	1712(ra) # 80001410 <uvmalloc>
    80001d68:	85aa                	mv	a1,a0
    80001d6a:	fd79                	bnez	a0,80001d48 <growproc+0x22>
      return -1;
    80001d6c:	557d                	li	a0,-1
    80001d6e:	bff9                	j	80001d4c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d70:	00b90633          	add	a2,s2,a1
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	652080e7          	jalr	1618(ra) # 800013c8 <uvmdealloc>
    80001d7e:	85aa                	mv	a1,a0
    80001d80:	b7e1                	j	80001d48 <growproc+0x22>

0000000080001d82 <fork>:
{
    80001d82:	7139                	addi	sp,sp,-64
    80001d84:	fc06                	sd	ra,56(sp)
    80001d86:	f822                	sd	s0,48(sp)
    80001d88:	f426                	sd	s1,40(sp)
    80001d8a:	f04a                	sd	s2,32(sp)
    80001d8c:	ec4e                	sd	s3,24(sp)
    80001d8e:	e852                	sd	s4,16(sp)
    80001d90:	e456                	sd	s5,8(sp)
    80001d92:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c18080e7          	jalr	-1000(ra) # 800019ac <myproc>
    80001d9c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	e18080e7          	jalr	-488(ra) # 80001bb6 <allocproc>
    80001da6:	12050063          	beqz	a0,80001ec6 <fork+0x144>
    80001daa:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dac:	048ab603          	ld	a2,72(s5)
    80001db0:	692c                	ld	a1,80(a0)
    80001db2:	050ab503          	ld	a0,80(s5)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	7ae080e7          	jalr	1966(ra) # 80001564 <uvmcopy>
    80001dbe:	04054c63          	bltz	a0,80001e16 <fork+0x94>
  np->sz = p->sz;
    80001dc2:	048ab783          	ld	a5,72(s5)
    80001dc6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dca:	058ab683          	ld	a3,88(s5)
    80001dce:	87b6                	mv	a5,a3
    80001dd0:	0589b703          	ld	a4,88(s3)
    80001dd4:	12068693          	addi	a3,a3,288
    80001dd8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ddc:	6788                	ld	a0,8(a5)
    80001dde:	6b8c                	ld	a1,16(a5)
    80001de0:	6f90                	ld	a2,24(a5)
    80001de2:	01073023          	sd	a6,0(a4)
    80001de6:	e708                	sd	a0,8(a4)
    80001de8:	eb0c                	sd	a1,16(a4)
    80001dea:	ef10                	sd	a2,24(a4)
    80001dec:	02078793          	addi	a5,a5,32
    80001df0:	02070713          	addi	a4,a4,32
    80001df4:	fed792e3          	bne	a5,a3,80001dd8 <fork+0x56>
  np->syscall_tracebits = p->syscall_tracebits;
    80001df8:	168aa783          	lw	a5,360(s5)
    80001dfc:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001e00:	0589b783          	ld	a5,88(s3)
    80001e04:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e08:	0d0a8493          	addi	s1,s5,208
    80001e0c:	0d098913          	addi	s2,s3,208
    80001e10:	150a8a13          	addi	s4,s5,336
    80001e14:	a00d                	j	80001e36 <fork+0xb4>
    freeproc(np);
    80001e16:	854e                	mv	a0,s3
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	d46080e7          	jalr	-698(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e20:	854e                	mv	a0,s3
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	e68080e7          	jalr	-408(ra) # 80000c8a <release>
    return -1;
    80001e2a:	597d                	li	s2,-1
    80001e2c:	a059                	j	80001eb2 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e2e:	04a1                	addi	s1,s1,8
    80001e30:	0921                	addi	s2,s2,8
    80001e32:	01448b63          	beq	s1,s4,80001e48 <fork+0xc6>
    if(p->ofile[i])
    80001e36:	6088                	ld	a0,0(s1)
    80001e38:	d97d                	beqz	a0,80001e2e <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3a:	00003097          	auipc	ra,0x3
    80001e3e:	8b4080e7          	jalr	-1868(ra) # 800046ee <filedup>
    80001e42:	00a93023          	sd	a0,0(s2)
    80001e46:	b7e5                	j	80001e2e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e48:	150ab503          	ld	a0,336(s5)
    80001e4c:	00002097          	auipc	ra,0x2
    80001e50:	a28080e7          	jalr	-1496(ra) # 80003874 <idup>
    80001e54:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e58:	4641                	li	a2,16
    80001e5a:	158a8593          	addi	a1,s5,344
    80001e5e:	15898513          	addi	a0,s3,344
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	fba080e7          	jalr	-70(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e6a:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e6e:	854e                	mv	a0,s3
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	e1a080e7          	jalr	-486(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e78:	0000f497          	auipc	s1,0xf
    80001e7c:	e9048493          	addi	s1,s1,-368 # 80010d08 <wait_lock>
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	d54080e7          	jalr	-684(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e8a:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ea2:	478d                	li	a5,3
    80001ea4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea8:	854e                	mv	a0,s3
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	de0080e7          	jalr	-544(ra) # 80000c8a <release>
}
    80001eb2:	854a                	mv	a0,s2
    80001eb4:	70e2                	ld	ra,56(sp)
    80001eb6:	7442                	ld	s0,48(sp)
    80001eb8:	74a2                	ld	s1,40(sp)
    80001eba:	7902                	ld	s2,32(sp)
    80001ebc:	69e2                	ld	s3,24(sp)
    80001ebe:	6a42                	ld	s4,16(sp)
    80001ec0:	6aa2                	ld	s5,8(sp)
    80001ec2:	6121                	addi	sp,sp,64
    80001ec4:	8082                	ret
    return -1;
    80001ec6:	597d                	li	s2,-1
    80001ec8:	b7ed                	j	80001eb2 <fork+0x130>

0000000080001eca <update_time>:
{
    80001eca:	7179                	addi	sp,sp,-48
    80001ecc:	f406                	sd	ra,40(sp)
    80001ece:	f022                	sd	s0,32(sp)
    80001ed0:	ec26                	sd	s1,24(sp)
    80001ed2:	e84a                	sd	s2,16(sp)
    80001ed4:	e44e                	sd	s3,8(sp)
    80001ed6:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ed8:	0000f497          	auipc	s1,0xf
    80001edc:	24848493          	addi	s1,s1,584 # 80011120 <proc>
    if (p->state == RUNNING) {
    80001ee0:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ee2:	00015917          	auipc	s2,0x15
    80001ee6:	63e90913          	addi	s2,s2,1598 # 80017520 <tickslock>
    80001eea:	a811                	j	80001efe <update_time+0x34>
    release(&p->lock);
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	d9c080e7          	jalr	-612(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ef6:	19048493          	addi	s1,s1,400
    80001efa:	03248063          	beq	s1,s2,80001f1a <update_time+0x50>
    acquire(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	cd6080e7          	jalr	-810(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING) {
    80001f08:	4c9c                	lw	a5,24(s1)
    80001f0a:	ff3791e3          	bne	a5,s3,80001eec <update_time+0x22>
      p->rtime++;
    80001f0e:	16c4a783          	lw	a5,364(s1)
    80001f12:	2785                	addiw	a5,a5,1
    80001f14:	16f4a623          	sw	a5,364(s1)
    80001f18:	bfd1                	j	80001eec <update_time+0x22>
}
    80001f1a:	70a2                	ld	ra,40(sp)
    80001f1c:	7402                	ld	s0,32(sp)
    80001f1e:	64e2                	ld	s1,24(sp)
    80001f20:	6942                	ld	s2,16(sp)
    80001f22:	69a2                	ld	s3,8(sp)
    80001f24:	6145                	addi	sp,sp,48
    80001f26:	8082                	ret

0000000080001f28 <scheduler>:
{
    80001f28:	7139                	addi	sp,sp,-64
    80001f2a:	fc06                	sd	ra,56(sp)
    80001f2c:	f822                	sd	s0,48(sp)
    80001f2e:	f426                	sd	s1,40(sp)
    80001f30:	f04a                	sd	s2,32(sp)
    80001f32:	ec4e                	sd	s3,24(sp)
    80001f34:	e852                	sd	s4,16(sp)
    80001f36:	e456                	sd	s5,8(sp)
    80001f38:	e05a                	sd	s6,0(sp)
    80001f3a:	0080                	addi	s0,sp,64
    80001f3c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f3e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f40:	00779693          	slli	a3,a5,0x7
    80001f44:	0000f717          	auipc	a4,0xf
    80001f48:	dac70713          	addi	a4,a4,-596 # 80010cf0 <pid_lock>
    80001f4c:	9736                	add	a4,a4,a3
    80001f4e:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &p->context);
    80001f52:	0000f717          	auipc	a4,0xf
    80001f56:	dd670713          	addi	a4,a4,-554 # 80010d28 <cpus+0x8>
    80001f5a:	00e68b33          	add	s6,a3,a4
    struct proc *next_process = 0;
    80001f5e:	4a01                	li	s4,0
      if (p->state == RUNNABLE)
    80001f60:	448d                	li	s1,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001f62:	00015917          	auipc	s2,0x15
    80001f66:	5be90913          	addi	s2,s2,1470 # 80017520 <tickslock>
      c->proc = p;
    80001f6a:	0000fa97          	auipc	s5,0xf
    80001f6e:	d86a8a93          	addi	s5,s5,-634 # 80010cf0 <pid_lock>
    80001f72:	9ab6                	add	s5,s5,a3
    80001f74:	a80d                	j	80001fa6 <scheduler+0x7e>
        if(next_process == 0 || p->ctime < next_process->ctime){
    80001f76:	08098163          	beqz	s3,80001ff8 <scheduler+0xd0>
    80001f7a:	fe07a583          	lw	a1,-32(a5)
    80001f7e:	1709a683          	lw	a3,368(s3)
    80001f82:	00d5f363          	bgeu	a1,a3,80001f88 <scheduler+0x60>
    80001f86:	89b2                	mv	s3,a2
    for (p = proc; p < &proc[NPROC]; p++)
    80001f88:	03277b63          	bgeu	a4,s2,80001fbe <scheduler+0x96>
    80001f8c:	19078793          	addi	a5,a5,400
    80001f90:	e7078613          	addi	a2,a5,-400
      if (p->state == RUNNABLE)
    80001f94:	873e                	mv	a4,a5
    80001f96:	e887a683          	lw	a3,-376(a5)
    80001f9a:	fc968ee3          	beq	a3,s1,80001f76 <scheduler+0x4e>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f9e:	ff27e7e3          	bltu	a5,s2,80001f8c <scheduler+0x64>
    if (p != 0 && p->state == RUNNABLE)
    80001fa2:	00099e63          	bnez	s3,80001fbe <scheduler+0x96>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001faa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fae:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001fb2:	0000f797          	auipc	a5,0xf
    80001fb6:	2fe78793          	addi	a5,a5,766 # 800112b0 <proc+0x190>
    struct proc *next_process = 0;
    80001fba:	89d2                	mv	s3,s4
    80001fbc:	bfd1                	j	80001f90 <scheduler+0x68>
    if (p != 0 && p->state == RUNNABLE)
    80001fbe:	0189a783          	lw	a5,24(s3)
    80001fc2:	fe9792e3          	bne	a5,s1,80001fa6 <scheduler+0x7e>
      acquire(&p->lock);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	c0e080e7          	jalr	-1010(ra) # 80000bd6 <acquire>
      p->state = RUNNING;
    80001fd0:	4791                	li	a5,4
    80001fd2:	00f9ac23          	sw	a5,24(s3)
      c->proc = p;
    80001fd6:	033ab823          	sd	s3,48(s5)
      swtch(&c->context, &p->context);
    80001fda:	06098593          	addi	a1,s3,96
    80001fde:	855a                	mv	a0,s6
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	6a8080e7          	jalr	1704(ra) # 80002688 <swtch>
      c->proc = 0;
    80001fe8:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80001fec:	854e                	mv	a0,s3
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	c9c080e7          	jalr	-868(ra) # 80000c8a <release>
    80001ff6:	bf45                	j	80001fa6 <scheduler+0x7e>
    80001ff8:	89b2                	mv	s3,a2
    80001ffa:	b779                	j	80001f88 <scheduler+0x60>

0000000080001ffc <sched>:
{
    80001ffc:	7179                	addi	sp,sp,-48
    80001ffe:	f406                	sd	ra,40(sp)
    80002000:	f022                	sd	s0,32(sp)
    80002002:	ec26                	sd	s1,24(sp)
    80002004:	e84a                	sd	s2,16(sp)
    80002006:	e44e                	sd	s3,8(sp)
    80002008:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	9a2080e7          	jalr	-1630(ra) # 800019ac <myproc>
    80002012:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	b48080e7          	jalr	-1208(ra) # 80000b5c <holding>
    8000201c:	c93d                	beqz	a0,80002092 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002020:	2781                	sext.w	a5,a5
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	0000f717          	auipc	a4,0xf
    80002028:	ccc70713          	addi	a4,a4,-820 # 80010cf0 <pid_lock>
    8000202c:	97ba                	add	a5,a5,a4
    8000202e:	0a87a703          	lw	a4,168(a5)
    80002032:	4785                	li	a5,1
    80002034:	06f71763          	bne	a4,a5,800020a2 <sched+0xa6>
  if(p->state == RUNNING)
    80002038:	4c98                	lw	a4,24(s1)
    8000203a:	4791                	li	a5,4
    8000203c:	06f70b63          	beq	a4,a5,800020b2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002040:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002044:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002046:	efb5                	bnez	a5,800020c2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002048:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000204a:	0000f917          	auipc	s2,0xf
    8000204e:	ca690913          	addi	s2,s2,-858 # 80010cf0 <pid_lock>
    80002052:	2781                	sext.w	a5,a5
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	97ca                	add	a5,a5,s2
    80002058:	0ac7a983          	lw	s3,172(a5)
    8000205c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205e:	2781                	sext.w	a5,a5
    80002060:	079e                	slli	a5,a5,0x7
    80002062:	0000f597          	auipc	a1,0xf
    80002066:	cc658593          	addi	a1,a1,-826 # 80010d28 <cpus+0x8>
    8000206a:	95be                	add	a1,a1,a5
    8000206c:	06048513          	addi	a0,s1,96
    80002070:	00000097          	auipc	ra,0x0
    80002074:	618080e7          	jalr	1560(ra) # 80002688 <swtch>
    80002078:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	97ca                	add	a5,a5,s2
    80002080:	0b37a623          	sw	s3,172(a5)
}
    80002084:	70a2                	ld	ra,40(sp)
    80002086:	7402                	ld	s0,32(sp)
    80002088:	64e2                	ld	s1,24(sp)
    8000208a:	6942                	ld	s2,16(sp)
    8000208c:	69a2                	ld	s3,8(sp)
    8000208e:	6145                	addi	sp,sp,48
    80002090:	8082                	ret
    panic("sched p->lock");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	18650513          	addi	a0,a0,390 # 80008218 <digits+0x1d8>
    8000209a:	ffffe097          	auipc	ra,0xffffe
    8000209e:	4a4080e7          	jalr	1188(ra) # 8000053e <panic>
    panic("sched locks");
    800020a2:	00006517          	auipc	a0,0x6
    800020a6:	18650513          	addi	a0,a0,390 # 80008228 <digits+0x1e8>
    800020aa:	ffffe097          	auipc	ra,0xffffe
    800020ae:	494080e7          	jalr	1172(ra) # 8000053e <panic>
    panic("sched running");
    800020b2:	00006517          	auipc	a0,0x6
    800020b6:	18650513          	addi	a0,a0,390 # 80008238 <digits+0x1f8>
    800020ba:	ffffe097          	auipc	ra,0xffffe
    800020be:	484080e7          	jalr	1156(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	18650513          	addi	a0,a0,390 # 80008248 <digits+0x208>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	474080e7          	jalr	1140(ra) # 8000053e <panic>

00000000800020d2 <yield>:
{
    800020d2:	1101                	addi	sp,sp,-32
    800020d4:	ec06                	sd	ra,24(sp)
    800020d6:	e822                	sd	s0,16(sp)
    800020d8:	e426                	sd	s1,8(sp)
    800020da:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	8d0080e7          	jalr	-1840(ra) # 800019ac <myproc>
    800020e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	af0080e7          	jalr	-1296(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020ee:	478d                	li	a5,3
    800020f0:	cc9c                	sw	a5,24(s1)
  sched();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	f0a080e7          	jalr	-246(ra) # 80001ffc <sched>
  release(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	b8e080e7          	jalr	-1138(ra) # 80000c8a <release>
}
    80002104:	60e2                	ld	ra,24(sp)
    80002106:	6442                	ld	s0,16(sp)
    80002108:	64a2                	ld	s1,8(sp)
    8000210a:	6105                	addi	sp,sp,32
    8000210c:	8082                	ret

000000008000210e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000210e:	7179                	addi	sp,sp,-48
    80002110:	f406                	sd	ra,40(sp)
    80002112:	f022                	sd	s0,32(sp)
    80002114:	ec26                	sd	s1,24(sp)
    80002116:	e84a                	sd	s2,16(sp)
    80002118:	e44e                	sd	s3,8(sp)
    8000211a:	1800                	addi	s0,sp,48
    8000211c:	89aa                	mv	s3,a0
    8000211e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002120:	00000097          	auipc	ra,0x0
    80002124:	88c080e7          	jalr	-1908(ra) # 800019ac <myproc>
    80002128:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	aac080e7          	jalr	-1364(ra) # 80000bd6 <acquire>
  release(lk);
    80002132:	854a                	mv	a0,s2
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b56080e7          	jalr	-1194(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000213c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002140:	4789                	li	a5,2
    80002142:	cc9c                	sw	a5,24(s1)

  sched();
    80002144:	00000097          	auipc	ra,0x0
    80002148:	eb8080e7          	jalr	-328(ra) # 80001ffc <sched>

  // Tidy up.
  p->chan = 0;
    8000214c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b38080e7          	jalr	-1224(ra) # 80000c8a <release>
  acquire(lk);
    8000215a:	854a                	mv	a0,s2
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a7a080e7          	jalr	-1414(ra) # 80000bd6 <acquire>
}
    80002164:	70a2                	ld	ra,40(sp)
    80002166:	7402                	ld	s0,32(sp)
    80002168:	64e2                	ld	s1,24(sp)
    8000216a:	6942                	ld	s2,16(sp)
    8000216c:	69a2                	ld	s3,8(sp)
    8000216e:	6145                	addi	sp,sp,48
    80002170:	8082                	ret

0000000080002172 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002172:	7139                	addi	sp,sp,-64
    80002174:	fc06                	sd	ra,56(sp)
    80002176:	f822                	sd	s0,48(sp)
    80002178:	f426                	sd	s1,40(sp)
    8000217a:	f04a                	sd	s2,32(sp)
    8000217c:	ec4e                	sd	s3,24(sp)
    8000217e:	e852                	sd	s4,16(sp)
    80002180:	e456                	sd	s5,8(sp)
    80002182:	0080                	addi	s0,sp,64
    80002184:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002186:	0000f497          	auipc	s1,0xf
    8000218a:	f9a48493          	addi	s1,s1,-102 # 80011120 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000218e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002190:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	00015917          	auipc	s2,0x15
    80002196:	38e90913          	addi	s2,s2,910 # 80017520 <tickslock>
    8000219a:	a811                	j	800021ae <wakeup+0x3c>
      }
      release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	aec080e7          	jalr	-1300(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	19048493          	addi	s1,s1,400
    800021aa:	03248663          	beq	s1,s2,800021d6 <wakeup+0x64>
    if(p != myproc()){
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	7fe080e7          	jalr	2046(ra) # 800019ac <myproc>
    800021b6:	fea488e3          	beq	s1,a0,800021a6 <wakeup+0x34>
      acquire(&p->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a1a080e7          	jalr	-1510(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021c4:	4c9c                	lw	a5,24(s1)
    800021c6:	fd379be3          	bne	a5,s3,8000219c <wakeup+0x2a>
    800021ca:	709c                	ld	a5,32(s1)
    800021cc:	fd4798e3          	bne	a5,s4,8000219c <wakeup+0x2a>
        p->state = RUNNABLE;
    800021d0:	0154ac23          	sw	s5,24(s1)
    800021d4:	b7e1                	j	8000219c <wakeup+0x2a>
    }
  }
}
    800021d6:	70e2                	ld	ra,56(sp)
    800021d8:	7442                	ld	s0,48(sp)
    800021da:	74a2                	ld	s1,40(sp)
    800021dc:	7902                	ld	s2,32(sp)
    800021de:	69e2                	ld	s3,24(sp)
    800021e0:	6a42                	ld	s4,16(sp)
    800021e2:	6aa2                	ld	s5,8(sp)
    800021e4:	6121                	addi	sp,sp,64
    800021e6:	8082                	ret

00000000800021e8 <reparent>:
{
    800021e8:	7179                	addi	sp,sp,-48
    800021ea:	f406                	sd	ra,40(sp)
    800021ec:	f022                	sd	s0,32(sp)
    800021ee:	ec26                	sd	s1,24(sp)
    800021f0:	e84a                	sd	s2,16(sp)
    800021f2:	e44e                	sd	s3,8(sp)
    800021f4:	e052                	sd	s4,0(sp)
    800021f6:	1800                	addi	s0,sp,48
    800021f8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	f2648493          	addi	s1,s1,-218 # 80011120 <proc>
      pp->parent = initproc;
    80002202:	00007a17          	auipc	s4,0x7
    80002206:	876a0a13          	addi	s4,s4,-1930 # 80008a78 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000220a:	00015997          	auipc	s3,0x15
    8000220e:	31698993          	addi	s3,s3,790 # 80017520 <tickslock>
    80002212:	a029                	j	8000221c <reparent+0x34>
    80002214:	19048493          	addi	s1,s1,400
    80002218:	01348d63          	beq	s1,s3,80002232 <reparent+0x4a>
    if(pp->parent == p){
    8000221c:	7c9c                	ld	a5,56(s1)
    8000221e:	ff279be3          	bne	a5,s2,80002214 <reparent+0x2c>
      pp->parent = initproc;
    80002222:	000a3503          	ld	a0,0(s4)
    80002226:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	f4a080e7          	jalr	-182(ra) # 80002172 <wakeup>
    80002230:	b7d5                	j	80002214 <reparent+0x2c>
}
    80002232:	70a2                	ld	ra,40(sp)
    80002234:	7402                	ld	s0,32(sp)
    80002236:	64e2                	ld	s1,24(sp)
    80002238:	6942                	ld	s2,16(sp)
    8000223a:	69a2                	ld	s3,8(sp)
    8000223c:	6a02                	ld	s4,0(sp)
    8000223e:	6145                	addi	sp,sp,48
    80002240:	8082                	ret

0000000080002242 <exit>:
{
    80002242:	7179                	addi	sp,sp,-48
    80002244:	f406                	sd	ra,40(sp)
    80002246:	f022                	sd	s0,32(sp)
    80002248:	ec26                	sd	s1,24(sp)
    8000224a:	e84a                	sd	s2,16(sp)
    8000224c:	e44e                	sd	s3,8(sp)
    8000224e:	e052                	sd	s4,0(sp)
    80002250:	1800                	addi	s0,sp,48
    80002252:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	758080e7          	jalr	1880(ra) # 800019ac <myproc>
    8000225c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000225e:	00007797          	auipc	a5,0x7
    80002262:	81a7b783          	ld	a5,-2022(a5) # 80008a78 <initproc>
    80002266:	0d050493          	addi	s1,a0,208
    8000226a:	15050913          	addi	s2,a0,336
    8000226e:	02a79363          	bne	a5,a0,80002294 <exit+0x52>
    panic("init exiting");
    80002272:	00006517          	auipc	a0,0x6
    80002276:	fee50513          	addi	a0,a0,-18 # 80008260 <digits+0x220>
    8000227a:	ffffe097          	auipc	ra,0xffffe
    8000227e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>
      fileclose(f);
    80002282:	00002097          	auipc	ra,0x2
    80002286:	4be080e7          	jalr	1214(ra) # 80004740 <fileclose>
      p->ofile[fd] = 0;
    8000228a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000228e:	04a1                	addi	s1,s1,8
    80002290:	01248563          	beq	s1,s2,8000229a <exit+0x58>
    if(p->ofile[fd]){
    80002294:	6088                	ld	a0,0(s1)
    80002296:	f575                	bnez	a0,80002282 <exit+0x40>
    80002298:	bfdd                	j	8000228e <exit+0x4c>
  begin_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	fda080e7          	jalr	-38(ra) # 80004274 <begin_op>
  iput(p->cwd);
    800022a2:	1509b503          	ld	a0,336(s3)
    800022a6:	00001097          	auipc	ra,0x1
    800022aa:	7c6080e7          	jalr	1990(ra) # 80003a6c <iput>
  end_op();
    800022ae:	00002097          	auipc	ra,0x2
    800022b2:	046080e7          	jalr	70(ra) # 800042f4 <end_op>
  p->cwd = 0;
    800022b6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022ba:	0000f497          	auipc	s1,0xf
    800022be:	a4e48493          	addi	s1,s1,-1458 # 80010d08 <wait_lock>
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	912080e7          	jalr	-1774(ra) # 80000bd6 <acquire>
  reparent(p);
    800022cc:	854e                	mv	a0,s3
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	f1a080e7          	jalr	-230(ra) # 800021e8 <reparent>
  wakeup(p->parent);
    800022d6:	0389b503          	ld	a0,56(s3)
    800022da:	00000097          	auipc	ra,0x0
    800022de:	e98080e7          	jalr	-360(ra) # 80002172 <wakeup>
  acquire(&p->lock);
    800022e2:	854e                	mv	a0,s3
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	8f2080e7          	jalr	-1806(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022ec:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022f0:	4795                	li	a5,5
    800022f2:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022f6:	00006797          	auipc	a5,0x6
    800022fa:	78a7a783          	lw	a5,1930(a5) # 80008a80 <ticks>
    800022fe:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	986080e7          	jalr	-1658(ra) # 80000c8a <release>
  sched();
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	cf0080e7          	jalr	-784(ra) # 80001ffc <sched>
  panic("zombie exit");
    80002314:	00006517          	auipc	a0,0x6
    80002318:	f5c50513          	addi	a0,a0,-164 # 80008270 <digits+0x230>
    8000231c:	ffffe097          	auipc	ra,0xffffe
    80002320:	222080e7          	jalr	546(ra) # 8000053e <panic>

0000000080002324 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002324:	7179                	addi	sp,sp,-48
    80002326:	f406                	sd	ra,40(sp)
    80002328:	f022                	sd	s0,32(sp)
    8000232a:	ec26                	sd	s1,24(sp)
    8000232c:	e84a                	sd	s2,16(sp)
    8000232e:	e44e                	sd	s3,8(sp)
    80002330:	1800                	addi	s0,sp,48
    80002332:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002334:	0000f497          	auipc	s1,0xf
    80002338:	dec48493          	addi	s1,s1,-532 # 80011120 <proc>
    8000233c:	00015997          	auipc	s3,0x15
    80002340:	1e498993          	addi	s3,s3,484 # 80017520 <tickslock>
    acquire(&p->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	890080e7          	jalr	-1904(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000234e:	589c                	lw	a5,48(s1)
    80002350:	01278d63          	beq	a5,s2,8000236a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000235e:	19048493          	addi	s1,s1,400
    80002362:	ff3491e3          	bne	s1,s3,80002344 <kill+0x20>
  }
  return -1;
    80002366:	557d                	li	a0,-1
    80002368:	a829                	j	80002382 <kill+0x5e>
      p->killed = 1;
    8000236a:	4785                	li	a5,1
    8000236c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000236e:	4c98                	lw	a4,24(s1)
    80002370:	4789                	li	a5,2
    80002372:	00f70f63          	beq	a4,a5,80002390 <kill+0x6c>
      release(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	912080e7          	jalr	-1774(ra) # 80000c8a <release>
      return 0;
    80002380:	4501                	li	a0,0
}
    80002382:	70a2                	ld	ra,40(sp)
    80002384:	7402                	ld	s0,32(sp)
    80002386:	64e2                	ld	s1,24(sp)
    80002388:	6942                	ld	s2,16(sp)
    8000238a:	69a2                	ld	s3,8(sp)
    8000238c:	6145                	addi	sp,sp,48
    8000238e:	8082                	ret
        p->state = RUNNABLE;
    80002390:	478d                	li	a5,3
    80002392:	cc9c                	sw	a5,24(s1)
    80002394:	b7cd                	j	80002376 <kill+0x52>

0000000080002396 <setkilled>:

void
setkilled(struct proc *p)
{
    80002396:	1101                	addi	sp,sp,-32
    80002398:	ec06                	sd	ra,24(sp)
    8000239a:	e822                	sd	s0,16(sp)
    8000239c:	e426                	sd	s1,8(sp)
    8000239e:	1000                	addi	s0,sp,32
    800023a0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	834080e7          	jalr	-1996(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800023aa:	4785                	li	a5,1
    800023ac:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
}
    800023b8:	60e2                	ld	ra,24(sp)
    800023ba:	6442                	ld	s0,16(sp)
    800023bc:	64a2                	ld	s1,8(sp)
    800023be:	6105                	addi	sp,sp,32
    800023c0:	8082                	ret

00000000800023c2 <killed>:

int
killed(struct proc *p)
{
    800023c2:	1101                	addi	sp,sp,-32
    800023c4:	ec06                	sd	ra,24(sp)
    800023c6:	e822                	sd	s0,16(sp)
    800023c8:	e426                	sd	s1,8(sp)
    800023ca:	e04a                	sd	s2,0(sp)
    800023cc:	1000                	addi	s0,sp,32
    800023ce:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023d8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ac080e7          	jalr	-1876(ra) # 80000c8a <release>
  return k;
}
    800023e6:	854a                	mv	a0,s2
    800023e8:	60e2                	ld	ra,24(sp)
    800023ea:	6442                	ld	s0,16(sp)
    800023ec:	64a2                	ld	s1,8(sp)
    800023ee:	6902                	ld	s2,0(sp)
    800023f0:	6105                	addi	sp,sp,32
    800023f2:	8082                	ret

00000000800023f4 <wait>:
{
    800023f4:	715d                	addi	sp,sp,-80
    800023f6:	e486                	sd	ra,72(sp)
    800023f8:	e0a2                	sd	s0,64(sp)
    800023fa:	fc26                	sd	s1,56(sp)
    800023fc:	f84a                	sd	s2,48(sp)
    800023fe:	f44e                	sd	s3,40(sp)
    80002400:	f052                	sd	s4,32(sp)
    80002402:	ec56                	sd	s5,24(sp)
    80002404:	e85a                	sd	s6,16(sp)
    80002406:	e45e                	sd	s7,8(sp)
    80002408:	e062                	sd	s8,0(sp)
    8000240a:	0880                	addi	s0,sp,80
    8000240c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	59e080e7          	jalr	1438(ra) # 800019ac <myproc>
    80002416:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002418:	0000f517          	auipc	a0,0xf
    8000241c:	8f050513          	addi	a0,a0,-1808 # 80010d08 <wait_lock>
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7b6080e7          	jalr	1974(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002428:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000242a:	4a15                	li	s4,5
        havekids = 1;
    8000242c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242e:	00015997          	auipc	s3,0x15
    80002432:	0f298993          	addi	s3,s3,242 # 80017520 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002436:	0000fc17          	auipc	s8,0xf
    8000243a:	8d2c0c13          	addi	s8,s8,-1838 # 80010d08 <wait_lock>
    havekids = 0;
    8000243e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002440:	0000f497          	auipc	s1,0xf
    80002444:	ce048493          	addi	s1,s1,-800 # 80011120 <proc>
    80002448:	a0bd                	j	800024b6 <wait+0xc2>
          pid = pp->pid;
    8000244a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000244e:	000b0e63          	beqz	s6,8000246a <wait+0x76>
    80002452:	4691                	li	a3,4
    80002454:	02c48613          	addi	a2,s1,44
    80002458:	85da                	mv	a1,s6
    8000245a:	05093503          	ld	a0,80(s2)
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	20a080e7          	jalr	522(ra) # 80001668 <copyout>
    80002466:	02054563          	bltz	a0,80002490 <wait+0x9c>
          freeproc(pp);
    8000246a:	8526                	mv	a0,s1
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	6f2080e7          	jalr	1778(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	814080e7          	jalr	-2028(ra) # 80000c8a <release>
          release(&wait_lock);
    8000247e:	0000f517          	auipc	a0,0xf
    80002482:	88a50513          	addi	a0,a0,-1910 # 80010d08 <wait_lock>
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	804080e7          	jalr	-2044(ra) # 80000c8a <release>
          return pid;
    8000248e:	a0b5                	j	800024fa <wait+0x106>
            release(&pp->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	7f8080e7          	jalr	2040(ra) # 80000c8a <release>
            release(&wait_lock);
    8000249a:	0000f517          	auipc	a0,0xf
    8000249e:	86e50513          	addi	a0,a0,-1938 # 80010d08 <wait_lock>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7e8080e7          	jalr	2024(ra) # 80000c8a <release>
            return -1;
    800024aa:	59fd                	li	s3,-1
    800024ac:	a0b9                	j	800024fa <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ae:	19048493          	addi	s1,s1,400
    800024b2:	03348463          	beq	s1,s3,800024da <wait+0xe6>
      if(pp->parent == p){
    800024b6:	7c9c                	ld	a5,56(s1)
    800024b8:	ff279be3          	bne	a5,s2,800024ae <wait+0xba>
        acquire(&pp->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	718080e7          	jalr	1816(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800024c6:	4c9c                	lw	a5,24(s1)
    800024c8:	f94781e3          	beq	a5,s4,8000244a <wait+0x56>
        release(&pp->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7bc080e7          	jalr	1980(ra) # 80000c8a <release>
        havekids = 1;
    800024d6:	8756                	mv	a4,s5
    800024d8:	bfd9                	j	800024ae <wait+0xba>
    if(!havekids || killed(p)){
    800024da:	c719                	beqz	a4,800024e8 <wait+0xf4>
    800024dc:	854a                	mv	a0,s2
    800024de:	00000097          	auipc	ra,0x0
    800024e2:	ee4080e7          	jalr	-284(ra) # 800023c2 <killed>
    800024e6:	c51d                	beqz	a0,80002514 <wait+0x120>
      release(&wait_lock);
    800024e8:	0000f517          	auipc	a0,0xf
    800024ec:	82050513          	addi	a0,a0,-2016 # 80010d08 <wait_lock>
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	79a080e7          	jalr	1946(ra) # 80000c8a <release>
      return -1;
    800024f8:	59fd                	li	s3,-1
}
    800024fa:	854e                	mv	a0,s3
    800024fc:	60a6                	ld	ra,72(sp)
    800024fe:	6406                	ld	s0,64(sp)
    80002500:	74e2                	ld	s1,56(sp)
    80002502:	7942                	ld	s2,48(sp)
    80002504:	79a2                	ld	s3,40(sp)
    80002506:	7a02                	ld	s4,32(sp)
    80002508:	6ae2                	ld	s5,24(sp)
    8000250a:	6b42                	ld	s6,16(sp)
    8000250c:	6ba2                	ld	s7,8(sp)
    8000250e:	6c02                	ld	s8,0(sp)
    80002510:	6161                	addi	sp,sp,80
    80002512:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002514:	85e2                	mv	a1,s8
    80002516:	854a                	mv	a0,s2
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	bf6080e7          	jalr	-1034(ra) # 8000210e <sleep>
    havekids = 0;
    80002520:	bf39                	j	8000243e <wait+0x4a>

0000000080002522 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002522:	7179                	addi	sp,sp,-48
    80002524:	f406                	sd	ra,40(sp)
    80002526:	f022                	sd	s0,32(sp)
    80002528:	ec26                	sd	s1,24(sp)
    8000252a:	e84a                	sd	s2,16(sp)
    8000252c:	e44e                	sd	s3,8(sp)
    8000252e:	e052                	sd	s4,0(sp)
    80002530:	1800                	addi	s0,sp,48
    80002532:	84aa                	mv	s1,a0
    80002534:	892e                	mv	s2,a1
    80002536:	89b2                	mv	s3,a2
    80002538:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	472080e7          	jalr	1138(ra) # 800019ac <myproc>
  if(user_dst){
    80002542:	c08d                	beqz	s1,80002564 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002544:	86d2                	mv	a3,s4
    80002546:	864e                	mv	a2,s3
    80002548:	85ca                	mv	a1,s2
    8000254a:	6928                	ld	a0,80(a0)
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	11c080e7          	jalr	284(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6a02                	ld	s4,0(sp)
    80002560:	6145                	addi	sp,sp,48
    80002562:	8082                	ret
    memmove((char *)dst, src, len);
    80002564:	000a061b          	sext.w	a2,s4
    80002568:	85ce                	mv	a1,s3
    8000256a:	854a                	mv	a0,s2
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	7c2080e7          	jalr	1986(ra) # 80000d2e <memmove>
    return 0;
    80002574:	8526                	mv	a0,s1
    80002576:	bff9                	j	80002554 <either_copyout+0x32>

0000000080002578 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002578:	7179                	addi	sp,sp,-48
    8000257a:	f406                	sd	ra,40(sp)
    8000257c:	f022                	sd	s0,32(sp)
    8000257e:	ec26                	sd	s1,24(sp)
    80002580:	e84a                	sd	s2,16(sp)
    80002582:	e44e                	sd	s3,8(sp)
    80002584:	e052                	sd	s4,0(sp)
    80002586:	1800                	addi	s0,sp,48
    80002588:	892a                	mv	s2,a0
    8000258a:	84ae                	mv	s1,a1
    8000258c:	89b2                	mv	s3,a2
    8000258e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	41c080e7          	jalr	1052(ra) # 800019ac <myproc>
  if(user_src){
    80002598:	c08d                	beqz	s1,800025ba <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000259a:	86d2                	mv	a3,s4
    8000259c:	864e                	mv	a2,s3
    8000259e:	85ca                	mv	a1,s2
    800025a0:	6928                	ld	a0,80(a0)
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	152080e7          	jalr	338(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6a02                	ld	s4,0(sp)
    800025b6:	6145                	addi	sp,sp,48
    800025b8:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ba:	000a061b          	sext.w	a2,s4
    800025be:	85ce                	mv	a1,s3
    800025c0:	854a                	mv	a0,s2
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	76c080e7          	jalr	1900(ra) # 80000d2e <memmove>
    return 0;
    800025ca:	8526                	mv	a0,s1
    800025cc:	bff9                	j	800025aa <either_copyin+0x32>

00000000800025ce <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ce:	715d                	addi	sp,sp,-80
    800025d0:	e486                	sd	ra,72(sp)
    800025d2:	e0a2                	sd	s0,64(sp)
    800025d4:	fc26                	sd	s1,56(sp)
    800025d6:	f84a                	sd	s2,48(sp)
    800025d8:	f44e                	sd	s3,40(sp)
    800025da:	f052                	sd	s4,32(sp)
    800025dc:	ec56                	sd	s5,24(sp)
    800025de:	e85a                	sd	s6,16(sp)
    800025e0:	e45e                	sd	s7,8(sp)
    800025e2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025e4:	00006517          	auipc	a0,0x6
    800025e8:	ae450513          	addi	a0,a0,-1308 # 800080c8 <digits+0x88>
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	f9c080e7          	jalr	-100(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	c8448493          	addi	s1,s1,-892 # 80011278 <proc+0x158>
    800025fc:	00015917          	auipc	s2,0x15
    80002600:	07c90913          	addi	s2,s2,124 # 80017678 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002604:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002606:	00006997          	auipc	s3,0x6
    8000260a:	c7a98993          	addi	s3,s3,-902 # 80008280 <digits+0x240>
    printf("%d %s %d %d %d %s", p->pid, state,p->ctime,p->rtime,p->etime, p->name);
    8000260e:	00006a97          	auipc	s5,0x6
    80002612:	c7aa8a93          	addi	s5,s5,-902 # 80008288 <digits+0x248>
    printf("\n");
    80002616:	00006a17          	auipc	s4,0x6
    8000261a:	ab2a0a13          	addi	s4,s4,-1358 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261e:	00006b97          	auipc	s7,0x6
    80002622:	cb2b8b93          	addi	s7,s7,-846 # 800082d0 <states.0>
    80002626:	a03d                	j	80002654 <procdump+0x86>
    printf("%d %s %d %d %d %s", p->pid, state,p->ctime,p->rtime,p->etime, p->name);
    80002628:	01c82783          	lw	a5,28(a6)
    8000262c:	01482703          	lw	a4,20(a6)
    80002630:	01882683          	lw	a3,24(a6)
    80002634:	ed882583          	lw	a1,-296(a6)
    80002638:	8556                	mv	a0,s5
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f4e080e7          	jalr	-178(ra) # 80000588 <printf>
    printf("\n");
    80002642:	8552                	mv	a0,s4
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	f44080e7          	jalr	-188(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264c:	19048493          	addi	s1,s1,400
    80002650:	03248163          	beq	s1,s2,80002672 <procdump+0xa4>
    if(p->state == UNUSED)
    80002654:	8826                	mv	a6,s1
    80002656:	ec04a783          	lw	a5,-320(s1)
    8000265a:	dbed                	beqz	a5,8000264c <procdump+0x7e>
      state = "???";
    8000265c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265e:	fcfb65e3          	bltu	s6,a5,80002628 <procdump+0x5a>
    80002662:	1782                	slli	a5,a5,0x20
    80002664:	9381                	srli	a5,a5,0x20
    80002666:	078e                	slli	a5,a5,0x3
    80002668:	97de                	add	a5,a5,s7
    8000266a:	6390                	ld	a2,0(a5)
    8000266c:	fe55                	bnez	a2,80002628 <procdump+0x5a>
      state = "???";
    8000266e:	864e                	mv	a2,s3
    80002670:	bf65                	j	80002628 <procdump+0x5a>
  }
}
    80002672:	60a6                	ld	ra,72(sp)
    80002674:	6406                	ld	s0,64(sp)
    80002676:	74e2                	ld	s1,56(sp)
    80002678:	7942                	ld	s2,48(sp)
    8000267a:	79a2                	ld	s3,40(sp)
    8000267c:	7a02                	ld	s4,32(sp)
    8000267e:	6ae2                	ld	s5,24(sp)
    80002680:	6b42                	ld	s6,16(sp)
    80002682:	6ba2                	ld	s7,8(sp)
    80002684:	6161                	addi	sp,sp,80
    80002686:	8082                	ret

0000000080002688 <swtch>:
    80002688:	00153023          	sd	ra,0(a0)
    8000268c:	00253423          	sd	sp,8(a0)
    80002690:	e900                	sd	s0,16(a0)
    80002692:	ed04                	sd	s1,24(a0)
    80002694:	03253023          	sd	s2,32(a0)
    80002698:	03353423          	sd	s3,40(a0)
    8000269c:	03453823          	sd	s4,48(a0)
    800026a0:	03553c23          	sd	s5,56(a0)
    800026a4:	05653023          	sd	s6,64(a0)
    800026a8:	05753423          	sd	s7,72(a0)
    800026ac:	05853823          	sd	s8,80(a0)
    800026b0:	05953c23          	sd	s9,88(a0)
    800026b4:	07a53023          	sd	s10,96(a0)
    800026b8:	07b53423          	sd	s11,104(a0)
    800026bc:	0005b083          	ld	ra,0(a1)
    800026c0:	0085b103          	ld	sp,8(a1)
    800026c4:	6980                	ld	s0,16(a1)
    800026c6:	6d84                	ld	s1,24(a1)
    800026c8:	0205b903          	ld	s2,32(a1)
    800026cc:	0285b983          	ld	s3,40(a1)
    800026d0:	0305ba03          	ld	s4,48(a1)
    800026d4:	0385ba83          	ld	s5,56(a1)
    800026d8:	0405bb03          	ld	s6,64(a1)
    800026dc:	0485bb83          	ld	s7,72(a1)
    800026e0:	0505bc03          	ld	s8,80(a1)
    800026e4:	0585bc83          	ld	s9,88(a1)
    800026e8:	0605bd03          	ld	s10,96(a1)
    800026ec:	0685bd83          	ld	s11,104(a1)
    800026f0:	8082                	ret

00000000800026f2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f2:	1141                	addi	sp,sp,-16
    800026f4:	e406                	sd	ra,8(sp)
    800026f6:	e022                	sd	s0,0(sp)
    800026f8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fa:	00006597          	auipc	a1,0x6
    800026fe:	c0658593          	addi	a1,a1,-1018 # 80008300 <states.0+0x30>
    80002702:	00015517          	auipc	a0,0x15
    80002706:	e1e50513          	addi	a0,a0,-482 # 80017520 <tickslock>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	43c080e7          	jalr	1084(ra) # 80000b46 <initlock>
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e422                	sd	s0,8(sp)
    8000271e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	00003797          	auipc	a5,0x3
    80002724:	67078793          	addi	a5,a5,1648 # 80005d90 <kernelvec>
    80002728:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272c:	6422                	ld	s0,8(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002732:	1141                	addi	sp,sp,-16
    80002734:	e406                	sd	ra,8(sp)
    80002736:	e022                	sd	s0,0(sp)
    80002738:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	272080e7          	jalr	626(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002742:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002746:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000274c:	00005617          	auipc	a2,0x5
    80002750:	8b460613          	addi	a2,a2,-1868 # 80007000 <_trampoline>
    80002754:	00005697          	auipc	a3,0x5
    80002758:	8ac68693          	addi	a3,a3,-1876 # 80007000 <_trampoline>
    8000275c:	8e91                	sub	a3,a3,a2
    8000275e:	040007b7          	lui	a5,0x4000
    80002762:	17fd                	addi	a5,a5,-1
    80002764:	07b2                	slli	a5,a5,0xc
    80002766:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002768:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000276e:	180026f3          	csrr	a3,satp
    80002772:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002774:	6d38                	ld	a4,88(a0)
    80002776:	6134                	ld	a3,64(a0)
    80002778:	6585                	lui	a1,0x1
    8000277a:	96ae                	add	a3,a3,a1
    8000277c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000277e:	6d38                	ld	a4,88(a0)
    80002780:	00000697          	auipc	a3,0x0
    80002784:	13e68693          	addi	a3,a3,318 # 800028be <usertrap>
    80002788:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278c:	8692                	mv	a3,tp
    8000278e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002790:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002794:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002798:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a2:	6f18                	ld	a4,24(a4)
    800027a4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027a8:	6928                	ld	a0,80(a0)
    800027aa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027ac:	00005717          	auipc	a4,0x5
    800027b0:	8f070713          	addi	a4,a4,-1808 # 8000709c <userret>
    800027b4:	8f11                	sub	a4,a4,a2
    800027b6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027b8:	577d                	li	a4,-1
    800027ba:	177e                	slli	a4,a4,0x3f
    800027bc:	8d59                	or	a0,a0,a4
    800027be:	9782                	jalr	a5
}
    800027c0:	60a2                	ld	ra,8(sp)
    800027c2:	6402                	ld	s0,0(sp)
    800027c4:	0141                	addi	sp,sp,16
    800027c6:	8082                	ret

00000000800027c8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027c8:	1101                	addi	sp,sp,-32
    800027ca:	ec06                	sd	ra,24(sp)
    800027cc:	e822                	sd	s0,16(sp)
    800027ce:	e426                	sd	s1,8(sp)
    800027d0:	e04a                	sd	s2,0(sp)
    800027d2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027d4:	00015917          	auipc	s2,0x15
    800027d8:	d4c90913          	addi	s2,s2,-692 # 80017520 <tickslock>
    800027dc:	854a                	mv	a0,s2
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	3f8080e7          	jalr	1016(ra) # 80000bd6 <acquire>
  ticks++;
    800027e6:	00006497          	auipc	s1,0x6
    800027ea:	29a48493          	addi	s1,s1,666 # 80008a80 <ticks>
    800027ee:	409c                	lw	a5,0(s1)
    800027f0:	2785                	addiw	a5,a5,1
    800027f2:	c09c                	sw	a5,0(s1)
  update_time();
    800027f4:	fffff097          	auipc	ra,0xfffff
    800027f8:	6d6080e7          	jalr	1750(ra) # 80001eca <update_time>
  wakeup(&ticks);
    800027fc:	8526                	mv	a0,s1
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	974080e7          	jalr	-1676(ra) # 80002172 <wakeup>
  release(&tickslock);
    80002806:	854a                	mv	a0,s2
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	482080e7          	jalr	1154(ra) # 80000c8a <release>
}
    80002810:	60e2                	ld	ra,24(sp)
    80002812:	6442                	ld	s0,16(sp)
    80002814:	64a2                	ld	s1,8(sp)
    80002816:	6902                	ld	s2,0(sp)
    80002818:	6105                	addi	sp,sp,32
    8000281a:	8082                	ret

000000008000281c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000281c:	1101                	addi	sp,sp,-32
    8000281e:	ec06                	sd	ra,24(sp)
    80002820:	e822                	sd	s0,16(sp)
    80002822:	e426                	sd	s1,8(sp)
    80002824:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002826:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000282a:	00074d63          	bltz	a4,80002844 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282e:	57fd                	li	a5,-1
    80002830:	17fe                	slli	a5,a5,0x3f
    80002832:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002834:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002836:	06f70363          	beq	a4,a5,8000289c <devintr+0x80>
  }
}
    8000283a:	60e2                	ld	ra,24(sp)
    8000283c:	6442                	ld	s0,16(sp)
    8000283e:	64a2                	ld	s1,8(sp)
    80002840:	6105                	addi	sp,sp,32
    80002842:	8082                	ret
     (scause & 0xff) == 9){
    80002844:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002848:	46a5                	li	a3,9
    8000284a:	fed792e3          	bne	a5,a3,8000282e <devintr+0x12>
    int irq = plic_claim();
    8000284e:	00003097          	auipc	ra,0x3
    80002852:	64a080e7          	jalr	1610(ra) # 80005e98 <plic_claim>
    80002856:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002858:	47a9                	li	a5,10
    8000285a:	02f50763          	beq	a0,a5,80002888 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285e:	4785                	li	a5,1
    80002860:	02f50963          	beq	a0,a5,80002892 <devintr+0x76>
    return 1;
    80002864:	4505                	li	a0,1
    } else if(irq){
    80002866:	d8f1                	beqz	s1,8000283a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002868:	85a6                	mv	a1,s1
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	a9e50513          	addi	a0,a0,-1378 # 80008308 <states.0+0x38>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d16080e7          	jalr	-746(ra) # 80000588 <printf>
      plic_complete(irq);
    8000287a:	8526                	mv	a0,s1
    8000287c:	00003097          	auipc	ra,0x3
    80002880:	640080e7          	jalr	1600(ra) # 80005ebc <plic_complete>
    return 1;
    80002884:	4505                	li	a0,1
    80002886:	bf55                	j	8000283a <devintr+0x1e>
      uartintr();
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	112080e7          	jalr	274(ra) # 8000099a <uartintr>
    80002890:	b7ed                	j	8000287a <devintr+0x5e>
      virtio_disk_intr();
    80002892:	00004097          	auipc	ra,0x4
    80002896:	af6080e7          	jalr	-1290(ra) # 80006388 <virtio_disk_intr>
    8000289a:	b7c5                	j	8000287a <devintr+0x5e>
    if(cpuid() == 0){
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	0e4080e7          	jalr	228(ra) # 80001980 <cpuid>
    800028a4:	c901                	beqz	a0,800028b4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ac:	14479073          	csrw	sip,a5
    return 2;
    800028b0:	4509                	li	a0,2
    800028b2:	b761                	j	8000283a <devintr+0x1e>
      clockintr();
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	f14080e7          	jalr	-236(ra) # 800027c8 <clockintr>
    800028bc:	b7ed                	j	800028a6 <devintr+0x8a>

00000000800028be <usertrap>:
{
    800028be:	1101                	addi	sp,sp,-32
    800028c0:	ec06                	sd	ra,24(sp)
    800028c2:	e822                	sd	s0,16(sp)
    800028c4:	e426                	sd	s1,8(sp)
    800028c6:	e04a                	sd	s2,0(sp)
    800028c8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ce:	1007f793          	andi	a5,a5,256
    800028d2:	efb9                	bnez	a5,80002930 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d4:	00003797          	auipc	a5,0x3
    800028d8:	4bc78793          	addi	a5,a5,1212 # 80005d90 <kernelvec>
    800028dc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	0cc080e7          	jalr	204(ra) # 800019ac <myproc>
    800028e8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ea:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	14102773          	csrr	a4,sepc
    800028f0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f6:	47a1                	li	a5,8
    800028f8:	04f70463          	beq	a4,a5,80002940 <usertrap+0x82>
  } else if((which_dev = devintr()) != 0){
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	f20080e7          	jalr	-224(ra) # 8000281c <devintr>
    80002904:	892a                	mv	s2,a0
    80002906:	c16d                	beqz	a0,800029e8 <usertrap+0x12a>
    if(which_dev == 2){
    80002908:	4789                	li	a5,2
    8000290a:	06f50663          	beq	a0,a5,80002976 <usertrap+0xb8>
  if(killed(p))
    8000290e:	8526                	mv	a0,s1
    80002910:	00000097          	auipc	ra,0x0
    80002914:	ab2080e7          	jalr	-1358(ra) # 800023c2 <killed>
    80002918:	10051563          	bnez	a0,80002a22 <usertrap+0x164>
  usertrapret();
    8000291c:	00000097          	auipc	ra,0x0
    80002920:	e16080e7          	jalr	-490(ra) # 80002732 <usertrapret>
}
    80002924:	60e2                	ld	ra,24(sp)
    80002926:	6442                	ld	s0,16(sp)
    80002928:	64a2                	ld	s1,8(sp)
    8000292a:	6902                	ld	s2,0(sp)
    8000292c:	6105                	addi	sp,sp,32
    8000292e:	8082                	ret
    panic("usertrap: not from user mode");
    80002930:	00006517          	auipc	a0,0x6
    80002934:	9f850513          	addi	a0,a0,-1544 # 80008328 <states.0+0x58>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c06080e7          	jalr	-1018(ra) # 8000053e <panic>
    if(killed(p))
    80002940:	00000097          	auipc	ra,0x0
    80002944:	a82080e7          	jalr	-1406(ra) # 800023c2 <killed>
    80002948:	e10d                	bnez	a0,8000296a <usertrap+0xac>
    p->trapframe->epc += 4;
    8000294a:	6cb8                	ld	a4,88(s1)
    8000294c:	6f1c                	ld	a5,24(a4)
    8000294e:	0791                	addi	a5,a5,4
    80002950:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002952:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002956:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295a:	10079073          	csrw	sstatus,a5
    syscall();
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	328080e7          	jalr	808(ra) # 80002c86 <syscall>
  int which_dev = 0;
    80002966:	4901                	li	s2,0
    80002968:	b75d                	j	8000290e <usertrap+0x50>
      exit(-1);
    8000296a:	557d                	li	a0,-1
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	8d6080e7          	jalr	-1834(ra) # 80002242 <exit>
    80002974:	bfd9                	j	8000294a <usertrap+0x8c>
      acquire(&p->lock);
    80002976:	8526                	mv	a0,s1
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	25e080e7          	jalr	606(ra) # 80000bd6 <acquire>
      if (p->state == RUNNING)
    80002980:	4c98                	lw	a4,24(s1)
    80002982:	4791                	li	a5,4
    80002984:	02f70363          	beq	a4,a5,800029aa <usertrap+0xec>
      release(&p->lock);
    80002988:	8526                	mv	a0,s1
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	300080e7          	jalr	768(ra) # 80000c8a <release>
  if(killed(p))
    80002992:	8526                	mv	a0,s1
    80002994:	00000097          	auipc	ra,0x0
    80002998:	a2e080e7          	jalr	-1490(ra) # 800023c2 <killed>
    8000299c:	c959                	beqz	a0,80002a32 <usertrap+0x174>
    exit(-1);
    8000299e:	557d                	li	a0,-1
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	8a2080e7          	jalr	-1886(ra) # 80002242 <exit>
  if(which_dev == 2)
    800029a8:	a069                	j	80002a32 <usertrap+0x174>
        p->alarmdata.currticks++;
    800029aa:	1784a783          	lw	a5,376(s1)
    800029ae:	2785                	addiw	a5,a5,1
    800029b0:	16f4ac23          	sw	a5,376(s1)
        if (p->alarmdata.nticks != 0 && p->alarmdata.currticks % p->alarmdata.nticks == 0 && p->alarmdata.trapframe_cpy == 0)
    800029b4:	17c4a703          	lw	a4,380(s1)
    800029b8:	db61                	beqz	a4,80002988 <usertrap+0xca>
    800029ba:	02e7e7bb          	remw	a5,a5,a4
    800029be:	f7e9                	bnez	a5,80002988 <usertrap+0xca>
    800029c0:	1884b783          	ld	a5,392(s1)
    800029c4:	f3f1                	bnez	a5,80002988 <usertrap+0xca>
          p->alarmdata.trapframe_cpy = kalloc();
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	120080e7          	jalr	288(ra) # 80000ae6 <kalloc>
    800029ce:	18a4b423          	sd	a0,392(s1)
          memmove(p->alarmdata.trapframe_cpy, p->trapframe, PGSIZE);
    800029d2:	6605                	lui	a2,0x1
    800029d4:	6cac                	ld	a1,88(s1)
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	358080e7          	jalr	856(ra) # 80000d2e <memmove>
          p->trapframe->epc = p->alarmdata.handlerfn;
    800029de:	6cbc                	ld	a5,88(s1)
    800029e0:	1804b703          	ld	a4,384(s1)
    800029e4:	ef98                	sd	a4,24(a5)
    800029e6:	b74d                	j	80002988 <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ec:	5890                	lw	a2,48(s1)
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	95a50513          	addi	a0,a0,-1702 # 80008348 <states.0+0x78>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b92080e7          	jalr	-1134(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a02:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a06:	00006517          	auipc	a0,0x6
    80002a0a:	97250513          	addi	a0,a0,-1678 # 80008378 <states.0+0xa8>
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	b7a080e7          	jalr	-1158(ra) # 80000588 <printf>
    setkilled(p);
    80002a16:	8526                	mv	a0,s1
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	97e080e7          	jalr	-1666(ra) # 80002396 <setkilled>
    80002a20:	b5fd                	j	8000290e <usertrap+0x50>
    exit(-1);
    80002a22:	557d                	li	a0,-1
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	81e080e7          	jalr	-2018(ra) # 80002242 <exit>
  if(which_dev == 2)
    80002a2c:	4789                	li	a5,2
    80002a2e:	eef917e3          	bne	s2,a5,8000291c <usertrap+0x5e>
    yield();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	6a0080e7          	jalr	1696(ra) # 800020d2 <yield>
    80002a3a:	b5cd                	j	8000291c <usertrap+0x5e>

0000000080002a3c <kerneltrap>:
{
    80002a3c:	7179                	addi	sp,sp,-48
    80002a3e:	f406                	sd	ra,40(sp)
    80002a40:	f022                	sd	s0,32(sp)
    80002a42:	ec26                	sd	s1,24(sp)
    80002a44:	e84a                	sd	s2,16(sp)
    80002a46:	e44e                	sd	s3,8(sp)
    80002a48:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a52:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a56:	1004f793          	andi	a5,s1,256
    80002a5a:	cb85                	beqz	a5,80002a8a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a60:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a62:	ef85                	bnez	a5,80002a9a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	db8080e7          	jalr	-584(ra) # 8000281c <devintr>
    80002a6c:	cd1d                	beqz	a0,80002aaa <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a6e:	4789                	li	a5,2
    80002a70:	06f50a63          	beq	a0,a5,80002ae4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a74:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a78:	10049073          	csrw	sstatus,s1
}
    80002a7c:	70a2                	ld	ra,40(sp)
    80002a7e:	7402                	ld	s0,32(sp)
    80002a80:	64e2                	ld	s1,24(sp)
    80002a82:	6942                	ld	s2,16(sp)
    80002a84:	69a2                	ld	s3,8(sp)
    80002a86:	6145                	addi	sp,sp,48
    80002a88:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	90e50513          	addi	a0,a0,-1778 # 80008398 <states.0+0xc8>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	aac080e7          	jalr	-1364(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	92650513          	addi	a0,a0,-1754 # 800083c0 <states.0+0xf0>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	a9c080e7          	jalr	-1380(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002aaa:	85ce                	mv	a1,s3
    80002aac:	00006517          	auipc	a0,0x6
    80002ab0:	93450513          	addi	a0,a0,-1740 # 800083e0 <states.0+0x110>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	ad4080e7          	jalr	-1324(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002abc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	92c50513          	addi	a0,a0,-1748 # 800083f0 <states.0+0x120>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	abc080e7          	jalr	-1348(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	93450513          	addi	a0,a0,-1740 # 80008408 <states.0+0x138>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a62080e7          	jalr	-1438(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	ec8080e7          	jalr	-312(ra) # 800019ac <myproc>
    80002aec:	d541                	beqz	a0,80002a74 <kerneltrap+0x38>
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	ebe080e7          	jalr	-322(ra) # 800019ac <myproc>
    80002af6:	4d18                	lw	a4,24(a0)
    80002af8:	4791                	li	a5,4
    80002afa:	f6f71de3          	bne	a4,a5,80002a74 <kerneltrap+0x38>
    yield();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	5d4080e7          	jalr	1492(ra) # 800020d2 <yield>
    80002b06:	b7bd                	j	80002a74 <kerneltrap+0x38>

0000000080002b08 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b08:	1101                	addi	sp,sp,-32
    80002b0a:	ec06                	sd	ra,24(sp)
    80002b0c:	e822                	sd	s0,16(sp)
    80002b0e:	e426                	sd	s1,8(sp)
    80002b10:	1000                	addi	s0,sp,32
    80002b12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	e98080e7          	jalr	-360(ra) # 800019ac <myproc>
  switch (n) {
    80002b1c:	4795                	li	a5,5
    80002b1e:	0497e163          	bltu	a5,s1,80002b60 <argraw+0x58>
    80002b22:	048a                	slli	s1,s1,0x2
    80002b24:	00006717          	auipc	a4,0x6
    80002b28:	9fc70713          	addi	a4,a4,-1540 # 80008520 <states.0+0x250>
    80002b2c:	94ba                	add	s1,s1,a4
    80002b2e:	409c                	lw	a5,0(s1)
    80002b30:	97ba                	add	a5,a5,a4
    80002b32:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b34:	6d3c                	ld	a5,88(a0)
    80002b36:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b38:	60e2                	ld	ra,24(sp)
    80002b3a:	6442                	ld	s0,16(sp)
    80002b3c:	64a2                	ld	s1,8(sp)
    80002b3e:	6105                	addi	sp,sp,32
    80002b40:	8082                	ret
    return p->trapframe->a1;
    80002b42:	6d3c                	ld	a5,88(a0)
    80002b44:	7fa8                	ld	a0,120(a5)
    80002b46:	bfcd                	j	80002b38 <argraw+0x30>
    return p->trapframe->a2;
    80002b48:	6d3c                	ld	a5,88(a0)
    80002b4a:	63c8                	ld	a0,128(a5)
    80002b4c:	b7f5                	j	80002b38 <argraw+0x30>
    return p->trapframe->a3;
    80002b4e:	6d3c                	ld	a5,88(a0)
    80002b50:	67c8                	ld	a0,136(a5)
    80002b52:	b7dd                	j	80002b38 <argraw+0x30>
    return p->trapframe->a4;
    80002b54:	6d3c                	ld	a5,88(a0)
    80002b56:	6bc8                	ld	a0,144(a5)
    80002b58:	b7c5                	j	80002b38 <argraw+0x30>
    return p->trapframe->a5;
    80002b5a:	6d3c                	ld	a5,88(a0)
    80002b5c:	6fc8                	ld	a0,152(a5)
    80002b5e:	bfe9                	j	80002b38 <argraw+0x30>
  panic("argraw");
    80002b60:	00006517          	auipc	a0,0x6
    80002b64:	8b850513          	addi	a0,a0,-1864 # 80008418 <states.0+0x148>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	9d6080e7          	jalr	-1578(ra) # 8000053e <panic>

0000000080002b70 <fetchaddr>:
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	e04a                	sd	s2,0(sp)
    80002b7a:	1000                	addi	s0,sp,32
    80002b7c:	84aa                	mv	s1,a0
    80002b7e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	e2c080e7          	jalr	-468(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b88:	653c                	ld	a5,72(a0)
    80002b8a:	02f4f863          	bgeu	s1,a5,80002bba <fetchaddr+0x4a>
    80002b8e:	00848713          	addi	a4,s1,8
    80002b92:	02e7e663          	bltu	a5,a4,80002bbe <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b96:	46a1                	li	a3,8
    80002b98:	8626                	mv	a2,s1
    80002b9a:	85ca                	mv	a1,s2
    80002b9c:	6928                	ld	a0,80(a0)
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	b56080e7          	jalr	-1194(ra) # 800016f4 <copyin>
    80002ba6:	00a03533          	snez	a0,a0
    80002baa:	40a00533          	neg	a0,a0
}
    80002bae:	60e2                	ld	ra,24(sp)
    80002bb0:	6442                	ld	s0,16(sp)
    80002bb2:	64a2                	ld	s1,8(sp)
    80002bb4:	6902                	ld	s2,0(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret
    return -1;
    80002bba:	557d                	li	a0,-1
    80002bbc:	bfcd                	j	80002bae <fetchaddr+0x3e>
    80002bbe:	557d                	li	a0,-1
    80002bc0:	b7fd                	j	80002bae <fetchaddr+0x3e>

0000000080002bc2 <fetchstr>:
{
    80002bc2:	7179                	addi	sp,sp,-48
    80002bc4:	f406                	sd	ra,40(sp)
    80002bc6:	f022                	sd	s0,32(sp)
    80002bc8:	ec26                	sd	s1,24(sp)
    80002bca:	e84a                	sd	s2,16(sp)
    80002bcc:	e44e                	sd	s3,8(sp)
    80002bce:	1800                	addi	s0,sp,48
    80002bd0:	892a                	mv	s2,a0
    80002bd2:	84ae                	mv	s1,a1
    80002bd4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	dd6080e7          	jalr	-554(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bde:	86ce                	mv	a3,s3
    80002be0:	864a                	mv	a2,s2
    80002be2:	85a6                	mv	a1,s1
    80002be4:	6928                	ld	a0,80(a0)
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	b9c080e7          	jalr	-1124(ra) # 80001782 <copyinstr>
    80002bee:	00054e63          	bltz	a0,80002c0a <fetchstr+0x48>
  return strlen(buf);
    80002bf2:	8526                	mv	a0,s1
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	25a080e7          	jalr	602(ra) # 80000e4e <strlen>
}
    80002bfc:	70a2                	ld	ra,40(sp)
    80002bfe:	7402                	ld	s0,32(sp)
    80002c00:	64e2                	ld	s1,24(sp)
    80002c02:	6942                	ld	s2,16(sp)
    80002c04:	69a2                	ld	s3,8(sp)
    80002c06:	6145                	addi	sp,sp,48
    80002c08:	8082                	ret
    return -1;
    80002c0a:	557d                	li	a0,-1
    80002c0c:	bfc5                	j	80002bfc <fetchstr+0x3a>

0000000080002c0e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c0e:	1101                	addi	sp,sp,-32
    80002c10:	ec06                	sd	ra,24(sp)
    80002c12:	e822                	sd	s0,16(sp)
    80002c14:	e426                	sd	s1,8(sp)
    80002c16:	1000                	addi	s0,sp,32
    80002c18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	eee080e7          	jalr	-274(ra) # 80002b08 <argraw>
    80002c22:	c088                	sw	a0,0(s1)
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	e426                	sd	s1,8(sp)
    80002c36:	1000                	addi	s0,sp,32
    80002c38:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	ece080e7          	jalr	-306(ra) # 80002b08 <argraw>
    80002c42:	e088                	sd	a0,0(s1)
}
    80002c44:	60e2                	ld	ra,24(sp)
    80002c46:	6442                	ld	s0,16(sp)
    80002c48:	64a2                	ld	s1,8(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret

0000000080002c4e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c4e:	7179                	addi	sp,sp,-48
    80002c50:	f406                	sd	ra,40(sp)
    80002c52:	f022                	sd	s0,32(sp)
    80002c54:	ec26                	sd	s1,24(sp)
    80002c56:	e84a                	sd	s2,16(sp)
    80002c58:	1800                	addi	s0,sp,48
    80002c5a:	84ae                	mv	s1,a1
    80002c5c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c5e:	fd840593          	addi	a1,s0,-40
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	fcc080e7          	jalr	-52(ra) # 80002c2e <argaddr>
  return fetchstr(addr, buf, max);
    80002c6a:	864a                	mv	a2,s2
    80002c6c:	85a6                	mv	a1,s1
    80002c6e:	fd843503          	ld	a0,-40(s0)
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	f50080e7          	jalr	-176(ra) # 80002bc2 <fetchstr>
}
    80002c7a:	70a2                	ld	ra,40(sp)
    80002c7c:	7402                	ld	s0,32(sp)
    80002c7e:	64e2                	ld	s1,24(sp)
    80002c80:	6942                	ld	s2,16(sp)
    80002c82:	6145                	addi	sp,sp,48
    80002c84:	8082                	ret

0000000080002c86 <syscall>:
[SYS_sigreturn] "sigreturn"
};

void
syscall(void)
{
    80002c86:	7179                	addi	sp,sp,-48
    80002c88:	f406                	sd	ra,40(sp)
    80002c8a:	f022                	sd	s0,32(sp)
    80002c8c:	ec26                	sd	s1,24(sp)
    80002c8e:	e84a                	sd	s2,16(sp)
    80002c90:	e44e                	sd	s3,8(sp)
    80002c92:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	d18080e7          	jalr	-744(ra) # 800019ac <myproc>
    80002c9c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c9e:	05853903          	ld	s2,88(a0)
    80002ca2:	0a893783          	ld	a5,168(s2)
    80002ca6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002caa:	37fd                	addiw	a5,a5,-1
    80002cac:	475d                	li	a4,23
    80002cae:	04f76863          	bltu	a4,a5,80002cfe <syscall+0x78>
    80002cb2:	00399713          	slli	a4,s3,0x3
    80002cb6:	00006797          	auipc	a5,0x6
    80002cba:	88278793          	addi	a5,a5,-1918 # 80008538 <syscalls>
    80002cbe:	97ba                	add	a5,a5,a4
    80002cc0:	639c                	ld	a5,0(a5)
    80002cc2:	cf95                	beqz	a5,80002cfe <syscall+0x78>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cc4:	9782                	jalr	a5
    80002cc6:	06a93823          	sd	a0,112(s2)

    if((p->syscall_tracebits) & (1 << num)){ // is the syscall depicted by num asked to be traced.
    80002cca:	1684a783          	lw	a5,360(s1)
    80002cce:	4137d7bb          	sraw	a5,a5,s3
    80002cd2:	8b85                	andi	a5,a5,1
    80002cd4:	c7a1                	beqz	a5,80002d1c <syscall+0x96>
      printf("%d: syscall %s -> %d\n",p->pid,syscalls_names[num],p->trapframe->a0);
    80002cd6:	6cb8                	ld	a4,88(s1)
    80002cd8:	098e                	slli	s3,s3,0x3
    80002cda:	00006797          	auipc	a5,0x6
    80002cde:	cae78793          	addi	a5,a5,-850 # 80008988 <syscalls_names>
    80002ce2:	99be                	add	s3,s3,a5
    80002ce4:	7b34                	ld	a3,112(a4)
    80002ce6:	0009b603          	ld	a2,0(s3)
    80002cea:	588c                	lw	a1,48(s1)
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	73450513          	addi	a0,a0,1844 # 80008420 <states.0+0x150>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	894080e7          	jalr	-1900(ra) # 80000588 <printf>
    80002cfc:	a005                	j	80002d1c <syscall+0x96>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cfe:	86ce                	mv	a3,s3
    80002d00:	15848613          	addi	a2,s1,344
    80002d04:	588c                	lw	a1,48(s1)
    80002d06:	00005517          	auipc	a0,0x5
    80002d0a:	73250513          	addi	a0,a0,1842 # 80008438 <states.0+0x168>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	87a080e7          	jalr	-1926(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d16:	6cbc                	ld	a5,88(s1)
    80002d18:	577d                	li	a4,-1
    80002d1a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d1c:	70a2                	ld	ra,40(sp)
    80002d1e:	7402                	ld	s0,32(sp)
    80002d20:	64e2                	ld	s1,24(sp)
    80002d22:	6942                	ld	s2,16(sp)
    80002d24:	69a2                	ld	s3,8(sp)
    80002d26:	6145                	addi	sp,sp,48
    80002d28:	8082                	ret

0000000080002d2a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d2a:	1101                	addi	sp,sp,-32
    80002d2c:	ec06                	sd	ra,24(sp)
    80002d2e:	e822                	sd	s0,16(sp)
    80002d30:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d32:	fec40593          	addi	a1,s0,-20
    80002d36:	4501                	li	a0,0
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	ed6080e7          	jalr	-298(ra) # 80002c0e <argint>
  exit(n);
    80002d40:	fec42503          	lw	a0,-20(s0)
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	4fe080e7          	jalr	1278(ra) # 80002242 <exit>
  return 0;  // not reached
}
    80002d4c:	4501                	li	a0,0
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret

0000000080002d56 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d56:	1141                	addi	sp,sp,-16
    80002d58:	e406                	sd	ra,8(sp)
    80002d5a:	e022                	sd	s0,0(sp)
    80002d5c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	c4e080e7          	jalr	-946(ra) # 800019ac <myproc>
}
    80002d66:	5908                	lw	a0,48(a0)
    80002d68:	60a2                	ld	ra,8(sp)
    80002d6a:	6402                	ld	s0,0(sp)
    80002d6c:	0141                	addi	sp,sp,16
    80002d6e:	8082                	ret

0000000080002d70 <sys_fork>:

uint64
sys_fork(void)
{
    80002d70:	1141                	addi	sp,sp,-16
    80002d72:	e406                	sd	ra,8(sp)
    80002d74:	e022                	sd	s0,0(sp)
    80002d76:	0800                	addi	s0,sp,16
  return fork();
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	00a080e7          	jalr	10(ra) # 80001d82 <fork>
}
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_wait>:

uint64
sys_wait(void)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d90:	fe840593          	addi	a1,s0,-24
    80002d94:	4501                	li	a0,0
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	e98080e7          	jalr	-360(ra) # 80002c2e <argaddr>
  return wait(p);
    80002d9e:	fe843503          	ld	a0,-24(s0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	652080e7          	jalr	1618(ra) # 800023f4 <wait>
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002db2:	7179                	addi	sp,sp,-48
    80002db4:	f406                	sd	ra,40(sp)
    80002db6:	f022                	sd	s0,32(sp)
    80002db8:	ec26                	sd	s1,24(sp)
    80002dba:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dbc:	fdc40593          	addi	a1,s0,-36
    80002dc0:	4501                	li	a0,0
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	e4c080e7          	jalr	-436(ra) # 80002c0e <argint>
  addr = myproc()->sz;
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	be2080e7          	jalr	-1054(ra) # 800019ac <myproc>
    80002dd2:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dd4:	fdc42503          	lw	a0,-36(s0)
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	f4e080e7          	jalr	-178(ra) # 80001d26 <growproc>
    80002de0:	00054863          	bltz	a0,80002df0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002de4:	8526                	mv	a0,s1
    80002de6:	70a2                	ld	ra,40(sp)
    80002de8:	7402                	ld	s0,32(sp)
    80002dea:	64e2                	ld	s1,24(sp)
    80002dec:	6145                	addi	sp,sp,48
    80002dee:	8082                	ret
    return -1;
    80002df0:	54fd                	li	s1,-1
    80002df2:	bfcd                	j	80002de4 <sys_sbrk+0x32>

0000000080002df4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002df4:	7139                	addi	sp,sp,-64
    80002df6:	fc06                	sd	ra,56(sp)
    80002df8:	f822                	sd	s0,48(sp)
    80002dfa:	f426                	sd	s1,40(sp)
    80002dfc:	f04a                	sd	s2,32(sp)
    80002dfe:	ec4e                	sd	s3,24(sp)
    80002e00:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e02:	fcc40593          	addi	a1,s0,-52
    80002e06:	4501                	li	a0,0
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	e06080e7          	jalr	-506(ra) # 80002c0e <argint>
  acquire(&tickslock);
    80002e10:	00014517          	auipc	a0,0x14
    80002e14:	71050513          	addi	a0,a0,1808 # 80017520 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	dbe080e7          	jalr	-578(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e20:	00006917          	auipc	s2,0x6
    80002e24:	c6092903          	lw	s2,-928(s2) # 80008a80 <ticks>
  while(ticks - ticks0 < n){
    80002e28:	fcc42783          	lw	a5,-52(s0)
    80002e2c:	cf9d                	beqz	a5,80002e6a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e2e:	00014997          	auipc	s3,0x14
    80002e32:	6f298993          	addi	s3,s3,1778 # 80017520 <tickslock>
    80002e36:	00006497          	auipc	s1,0x6
    80002e3a:	c4a48493          	addi	s1,s1,-950 # 80008a80 <ticks>
    if(killed(myproc())){
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	b6e080e7          	jalr	-1170(ra) # 800019ac <myproc>
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	57c080e7          	jalr	1404(ra) # 800023c2 <killed>
    80002e4e:	ed15                	bnez	a0,80002e8a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e50:	85ce                	mv	a1,s3
    80002e52:	8526                	mv	a0,s1
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	2ba080e7          	jalr	698(ra) # 8000210e <sleep>
  while(ticks - ticks0 < n){
    80002e5c:	409c                	lw	a5,0(s1)
    80002e5e:	412787bb          	subw	a5,a5,s2
    80002e62:	fcc42703          	lw	a4,-52(s0)
    80002e66:	fce7ece3          	bltu	a5,a4,80002e3e <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e6a:	00014517          	auipc	a0,0x14
    80002e6e:	6b650513          	addi	a0,a0,1718 # 80017520 <tickslock>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	e18080e7          	jalr	-488(ra) # 80000c8a <release>
  return 0;
    80002e7a:	4501                	li	a0,0
}
    80002e7c:	70e2                	ld	ra,56(sp)
    80002e7e:	7442                	ld	s0,48(sp)
    80002e80:	74a2                	ld	s1,40(sp)
    80002e82:	7902                	ld	s2,32(sp)
    80002e84:	69e2                	ld	s3,24(sp)
    80002e86:	6121                	addi	sp,sp,64
    80002e88:	8082                	ret
      release(&tickslock);
    80002e8a:	00014517          	auipc	a0,0x14
    80002e8e:	69650513          	addi	a0,a0,1686 # 80017520 <tickslock>
    80002e92:	ffffe097          	auipc	ra,0xffffe
    80002e96:	df8080e7          	jalr	-520(ra) # 80000c8a <release>
      return -1;
    80002e9a:	557d                	li	a0,-1
    80002e9c:	b7c5                	j	80002e7c <sys_sleep+0x88>

0000000080002e9e <sys_kill>:

uint64
sys_kill(void)
{
    80002e9e:	1101                	addi	sp,sp,-32
    80002ea0:	ec06                	sd	ra,24(sp)
    80002ea2:	e822                	sd	s0,16(sp)
    80002ea4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ea6:	fec40593          	addi	a1,s0,-20
    80002eaa:	4501                	li	a0,0
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	d62080e7          	jalr	-670(ra) # 80002c0e <argint>
  return kill(pid);
    80002eb4:	fec42503          	lw	a0,-20(s0)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	46c080e7          	jalr	1132(ra) # 80002324 <kill>
}
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ed2:	00014517          	auipc	a0,0x14
    80002ed6:	64e50513          	addi	a0,a0,1614 # 80017520 <tickslock>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	cfc080e7          	jalr	-772(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002ee2:	00006497          	auipc	s1,0x6
    80002ee6:	b9e4a483          	lw	s1,-1122(s1) # 80008a80 <ticks>
  release(&tickslock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	63650513          	addi	a0,a0,1590 # 80017520 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	d98080e7          	jalr	-616(ra) # 80000c8a <release>
  return xticks;
}
    80002efa:	02049513          	slli	a0,s1,0x20
    80002efe:	9101                	srli	a0,a0,0x20
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret

0000000080002f0a <sys_trace>:

uint64
sys_trace(void)
{
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	e426                	sd	s1,8(sp)
    80002f12:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	a98080e7          	jalr	-1384(ra) # 800019ac <myproc>
    80002f1c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	cb8080e7          	jalr	-840(ra) # 80000bd6 <acquire>
  argint(0, &(p->syscall_tracebits));
    80002f26:	16848593          	addi	a1,s1,360
    80002f2a:	4501                	li	a0,0
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	ce2080e7          	jalr	-798(ra) # 80002c0e <argint>
  release(&p->lock);
    80002f34:	8526                	mv	a0,s1
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	d54080e7          	jalr	-684(ra) # 80000c8a <release>
  if (p->syscall_tracebits < 0)
    80002f3e:	1684a503          	lw	a0,360(s1)
    return -1;
  return 0;
}
    80002f42:	957d                	srai	a0,a0,0x3f
    80002f44:	60e2                	ld	ra,24(sp)
    80002f46:	6442                	ld	s0,16(sp)
    80002f48:	64a2                	ld	s1,8(sp)
    80002f4a:	6105                	addi	sp,sp,32
    80002f4c:	8082                	ret

0000000080002f4e <sys_sigalarm>:

uint64
sys_sigalarm()
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	e426                	sd	s1,8(sp)
    80002f56:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	a54080e7          	jalr	-1452(ra) # 800019ac <myproc>
    80002f60:	84aa                	mv	s1,a0
  acquire(&p->lock);                //aquire the lock.
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	c74080e7          	jalr	-908(ra) # 80000bd6 <acquire>
  argint(0,&(p->alarmdata.nticks)); // p->alarmdata.nticks = n 
    80002f6a:	17c48593          	addi	a1,s1,380
    80002f6e:	4501                	li	a0,0
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	c9e080e7          	jalr	-866(ra) # 80002c0e <argint>
  if(p->alarmdata.nticks < 0){      // error handling
    80002f78:	17c4a783          	lw	a5,380(s1)
    80002f7c:	0207c463          	bltz	a5,80002fa4 <sys_sigalarm+0x56>
    release(&p->lock);
    return -1;
  }
  argaddr(1,&(p->alarmdata.handlerfn));   // p->alarmdata.handlerfn = fn
    80002f80:	18048593          	addi	a1,s1,384
    80002f84:	4505                	li	a0,1
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	ca8080e7          	jalr	-856(ra) # 80002c2e <argaddr>
  if(p->alarmdata.handlerfn < 0){   // error handling
    release(&p->lock);
    return -1;
  }
  release(&p->lock);
    80002f8e:	8526                	mv	a0,s1
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	cfa080e7          	jalr	-774(ra) # 80000c8a <release>
  return 0;
    80002f98:	4501                	li	a0,0
}
    80002f9a:	60e2                	ld	ra,24(sp)
    80002f9c:	6442                	ld	s0,16(sp)
    80002f9e:	64a2                	ld	s1,8(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret
    release(&p->lock);
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	ce4080e7          	jalr	-796(ra) # 80000c8a <release>
    return -1;
    80002fae:	557d                	li	a0,-1
    80002fb0:	b7ed                	j	80002f9a <sys_sigalarm+0x4c>

0000000080002fb2 <sys_sigreturn>:

uint64
sys_sigreturn()
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	9f0080e7          	jalr	-1552(ra) # 800019ac <myproc>
    80002fc4:	84aa                	mv	s1,a0
  acquire(&p->lock);    // aquire lock
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  memmove(p->trapframe,p->alarmdata.trapframe_cpy,PGSIZE); // restore original state
    80002fce:	6605                	lui	a2,0x1
    80002fd0:	1884b583          	ld	a1,392(s1)
    80002fd4:	6ca8                	ld	a0,88(s1)
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	d58080e7          	jalr	-680(ra) # 80000d2e <memmove>

  kfree(p->alarmdata.trapframe_cpy);    // remove the copy
    80002fde:	1884b503          	ld	a0,392(s1)
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	a08080e7          	jalr	-1528(ra) # 800009ea <kfree>
  p->alarmdata.trapframe_cpy=0;
    80002fea:	1804b423          	sd	zero,392(s1)
  p->alarmdata.currticks=0;
    80002fee:	1604ac23          	sw	zero,376(s1)
  release(&p->lock);                    // release the lock
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	c96080e7          	jalr	-874(ra) # 80000c8a <release>

  // this return value was being stored in trapframe->a0 , so returned trapframe->a0 itself
  return p->trapframe->a0;  
    80002ffc:	6cbc                	ld	a5,88(s1)
    80002ffe:	7ba8                	ld	a0,112(a5)
    80003000:	60e2                	ld	ra,24(sp)
    80003002:	6442                	ld	s0,16(sp)
    80003004:	64a2                	ld	s1,8(sp)
    80003006:	6105                	addi	sp,sp,32
    80003008:	8082                	ret

000000008000300a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000300a:	7179                	addi	sp,sp,-48
    8000300c:	f406                	sd	ra,40(sp)
    8000300e:	f022                	sd	s0,32(sp)
    80003010:	ec26                	sd	s1,24(sp)
    80003012:	e84a                	sd	s2,16(sp)
    80003014:	e44e                	sd	s3,8(sp)
    80003016:	e052                	sd	s4,0(sp)
    80003018:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000301a:	00005597          	auipc	a1,0x5
    8000301e:	5e658593          	addi	a1,a1,1510 # 80008600 <syscalls+0xc8>
    80003022:	00014517          	auipc	a0,0x14
    80003026:	51650513          	addi	a0,a0,1302 # 80017538 <bcache>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	b1c080e7          	jalr	-1252(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003032:	0001c797          	auipc	a5,0x1c
    80003036:	50678793          	addi	a5,a5,1286 # 8001f538 <bcache+0x8000>
    8000303a:	0001c717          	auipc	a4,0x1c
    8000303e:	76670713          	addi	a4,a4,1894 # 8001f7a0 <bcache+0x8268>
    80003042:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003046:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000304a:	00014497          	auipc	s1,0x14
    8000304e:	50648493          	addi	s1,s1,1286 # 80017550 <bcache+0x18>
    b->next = bcache.head.next;
    80003052:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003054:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003056:	00005a17          	auipc	s4,0x5
    8000305a:	5b2a0a13          	addi	s4,s4,1458 # 80008608 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000305e:	2b893783          	ld	a5,696(s2)
    80003062:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003064:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003068:	85d2                	mv	a1,s4
    8000306a:	01048513          	addi	a0,s1,16
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	4c4080e7          	jalr	1220(ra) # 80004532 <initsleeplock>
    bcache.head.next->prev = b;
    80003076:	2b893783          	ld	a5,696(s2)
    8000307a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000307c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003080:	45848493          	addi	s1,s1,1112
    80003084:	fd349de3          	bne	s1,s3,8000305e <binit+0x54>
  }
}
    80003088:	70a2                	ld	ra,40(sp)
    8000308a:	7402                	ld	s0,32(sp)
    8000308c:	64e2                	ld	s1,24(sp)
    8000308e:	6942                	ld	s2,16(sp)
    80003090:	69a2                	ld	s3,8(sp)
    80003092:	6a02                	ld	s4,0(sp)
    80003094:	6145                	addi	sp,sp,48
    80003096:	8082                	ret

0000000080003098 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003098:	7179                	addi	sp,sp,-48
    8000309a:	f406                	sd	ra,40(sp)
    8000309c:	f022                	sd	s0,32(sp)
    8000309e:	ec26                	sd	s1,24(sp)
    800030a0:	e84a                	sd	s2,16(sp)
    800030a2:	e44e                	sd	s3,8(sp)
    800030a4:	1800                	addi	s0,sp,48
    800030a6:	892a                	mv	s2,a0
    800030a8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	48e50513          	addi	a0,a0,1166 # 80017538 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	b24080e7          	jalr	-1244(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030ba:	0001c497          	auipc	s1,0x1c
    800030be:	7364b483          	ld	s1,1846(s1) # 8001f7f0 <bcache+0x82b8>
    800030c2:	0001c797          	auipc	a5,0x1c
    800030c6:	6de78793          	addi	a5,a5,1758 # 8001f7a0 <bcache+0x8268>
    800030ca:	02f48f63          	beq	s1,a5,80003108 <bread+0x70>
    800030ce:	873e                	mv	a4,a5
    800030d0:	a021                	j	800030d8 <bread+0x40>
    800030d2:	68a4                	ld	s1,80(s1)
    800030d4:	02e48a63          	beq	s1,a4,80003108 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030d8:	449c                	lw	a5,8(s1)
    800030da:	ff279ce3          	bne	a5,s2,800030d2 <bread+0x3a>
    800030de:	44dc                	lw	a5,12(s1)
    800030e0:	ff3799e3          	bne	a5,s3,800030d2 <bread+0x3a>
      b->refcnt++;
    800030e4:	40bc                	lw	a5,64(s1)
    800030e6:	2785                	addiw	a5,a5,1
    800030e8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	44e50513          	addi	a0,a0,1102 # 80017538 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	b98080e7          	jalr	-1128(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030fa:	01048513          	addi	a0,s1,16
    800030fe:	00001097          	auipc	ra,0x1
    80003102:	46e080e7          	jalr	1134(ra) # 8000456c <acquiresleep>
      return b;
    80003106:	a8b9                	j	80003164 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003108:	0001c497          	auipc	s1,0x1c
    8000310c:	6e04b483          	ld	s1,1760(s1) # 8001f7e8 <bcache+0x82b0>
    80003110:	0001c797          	auipc	a5,0x1c
    80003114:	69078793          	addi	a5,a5,1680 # 8001f7a0 <bcache+0x8268>
    80003118:	00f48863          	beq	s1,a5,80003128 <bread+0x90>
    8000311c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000311e:	40bc                	lw	a5,64(s1)
    80003120:	cf81                	beqz	a5,80003138 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003122:	64a4                	ld	s1,72(s1)
    80003124:	fee49de3          	bne	s1,a4,8000311e <bread+0x86>
  panic("bget: no buffers");
    80003128:	00005517          	auipc	a0,0x5
    8000312c:	4e850513          	addi	a0,a0,1256 # 80008610 <syscalls+0xd8>
    80003130:	ffffd097          	auipc	ra,0xffffd
    80003134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>
      b->dev = dev;
    80003138:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000313c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003140:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003144:	4785                	li	a5,1
    80003146:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003148:	00014517          	auipc	a0,0x14
    8000314c:	3f050513          	addi	a0,a0,1008 # 80017538 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	b3a080e7          	jalr	-1222(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003158:	01048513          	addi	a0,s1,16
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	410080e7          	jalr	1040(ra) # 8000456c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003164:	409c                	lw	a5,0(s1)
    80003166:	cb89                	beqz	a5,80003178 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003168:	8526                	mv	a0,s1
    8000316a:	70a2                	ld	ra,40(sp)
    8000316c:	7402                	ld	s0,32(sp)
    8000316e:	64e2                	ld	s1,24(sp)
    80003170:	6942                	ld	s2,16(sp)
    80003172:	69a2                	ld	s3,8(sp)
    80003174:	6145                	addi	sp,sp,48
    80003176:	8082                	ret
    virtio_disk_rw(b, 0);
    80003178:	4581                	li	a1,0
    8000317a:	8526                	mv	a0,s1
    8000317c:	00003097          	auipc	ra,0x3
    80003180:	fd8080e7          	jalr	-40(ra) # 80006154 <virtio_disk_rw>
    b->valid = 1;
    80003184:	4785                	li	a5,1
    80003186:	c09c                	sw	a5,0(s1)
  return b;
    80003188:	b7c5                	j	80003168 <bread+0xd0>

000000008000318a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003196:	0541                	addi	a0,a0,16
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	46e080e7          	jalr	1134(ra) # 80004606 <holdingsleep>
    800031a0:	cd01                	beqz	a0,800031b8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031a2:	4585                	li	a1,1
    800031a4:	8526                	mv	a0,s1
    800031a6:	00003097          	auipc	ra,0x3
    800031aa:	fae080e7          	jalr	-82(ra) # 80006154 <virtio_disk_rw>
}
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret
    panic("bwrite");
    800031b8:	00005517          	auipc	a0,0x5
    800031bc:	47050513          	addi	a0,a0,1136 # 80008628 <syscalls+0xf0>
    800031c0:	ffffd097          	auipc	ra,0xffffd
    800031c4:	37e080e7          	jalr	894(ra) # 8000053e <panic>

00000000800031c8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031c8:	1101                	addi	sp,sp,-32
    800031ca:	ec06                	sd	ra,24(sp)
    800031cc:	e822                	sd	s0,16(sp)
    800031ce:	e426                	sd	s1,8(sp)
    800031d0:	e04a                	sd	s2,0(sp)
    800031d2:	1000                	addi	s0,sp,32
    800031d4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031d6:	01050913          	addi	s2,a0,16
    800031da:	854a                	mv	a0,s2
    800031dc:	00001097          	auipc	ra,0x1
    800031e0:	42a080e7          	jalr	1066(ra) # 80004606 <holdingsleep>
    800031e4:	c92d                	beqz	a0,80003256 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031e6:	854a                	mv	a0,s2
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	3da080e7          	jalr	986(ra) # 800045c2 <releasesleep>

  acquire(&bcache.lock);
    800031f0:	00014517          	auipc	a0,0x14
    800031f4:	34850513          	addi	a0,a0,840 # 80017538 <bcache>
    800031f8:	ffffe097          	auipc	ra,0xffffe
    800031fc:	9de080e7          	jalr	-1570(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003200:	40bc                	lw	a5,64(s1)
    80003202:	37fd                	addiw	a5,a5,-1
    80003204:	0007871b          	sext.w	a4,a5
    80003208:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000320a:	eb05                	bnez	a4,8000323a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000320c:	68bc                	ld	a5,80(s1)
    8000320e:	64b8                	ld	a4,72(s1)
    80003210:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003212:	64bc                	ld	a5,72(s1)
    80003214:	68b8                	ld	a4,80(s1)
    80003216:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003218:	0001c797          	auipc	a5,0x1c
    8000321c:	32078793          	addi	a5,a5,800 # 8001f538 <bcache+0x8000>
    80003220:	2b87b703          	ld	a4,696(a5)
    80003224:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003226:	0001c717          	auipc	a4,0x1c
    8000322a:	57a70713          	addi	a4,a4,1402 # 8001f7a0 <bcache+0x8268>
    8000322e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003230:	2b87b703          	ld	a4,696(a5)
    80003234:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003236:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000323a:	00014517          	auipc	a0,0x14
    8000323e:	2fe50513          	addi	a0,a0,766 # 80017538 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	a48080e7          	jalr	-1464(ra) # 80000c8a <release>
}
    8000324a:	60e2                	ld	ra,24(sp)
    8000324c:	6442                	ld	s0,16(sp)
    8000324e:	64a2                	ld	s1,8(sp)
    80003250:	6902                	ld	s2,0(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret
    panic("brelse");
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	3da50513          	addi	a0,a0,986 # 80008630 <syscalls+0xf8>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>

0000000080003266 <bpin>:

void
bpin(struct buf *b) {
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	1000                	addi	s0,sp,32
    80003270:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003272:	00014517          	auipc	a0,0x14
    80003276:	2c650513          	addi	a0,a0,710 # 80017538 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	95c080e7          	jalr	-1700(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003282:	40bc                	lw	a5,64(s1)
    80003284:	2785                	addiw	a5,a5,1
    80003286:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003288:	00014517          	auipc	a0,0x14
    8000328c:	2b050513          	addi	a0,a0,688 # 80017538 <bcache>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
}
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	64a2                	ld	s1,8(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <bunpin>:

void
bunpin(struct buf *b) {
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	e426                	sd	s1,8(sp)
    800032aa:	1000                	addi	s0,sp,32
    800032ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ae:	00014517          	auipc	a0,0x14
    800032b2:	28a50513          	addi	a0,a0,650 # 80017538 <bcache>
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	920080e7          	jalr	-1760(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032be:	40bc                	lw	a5,64(s1)
    800032c0:	37fd                	addiw	a5,a5,-1
    800032c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032c4:	00014517          	auipc	a0,0x14
    800032c8:	27450513          	addi	a0,a0,628 # 80017538 <bcache>
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	9be080e7          	jalr	-1602(ra) # 80000c8a <release>
}
    800032d4:	60e2                	ld	ra,24(sp)
    800032d6:	6442                	ld	s0,16(sp)
    800032d8:	64a2                	ld	s1,8(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret

00000000800032de <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032de:	1101                	addi	sp,sp,-32
    800032e0:	ec06                	sd	ra,24(sp)
    800032e2:	e822                	sd	s0,16(sp)
    800032e4:	e426                	sd	s1,8(sp)
    800032e6:	e04a                	sd	s2,0(sp)
    800032e8:	1000                	addi	s0,sp,32
    800032ea:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032ec:	00d5d59b          	srliw	a1,a1,0xd
    800032f0:	0001d797          	auipc	a5,0x1d
    800032f4:	9247a783          	lw	a5,-1756(a5) # 8001fc14 <sb+0x1c>
    800032f8:	9dbd                	addw	a1,a1,a5
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	d9e080e7          	jalr	-610(ra) # 80003098 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003302:	0074f713          	andi	a4,s1,7
    80003306:	4785                	li	a5,1
    80003308:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000330c:	14ce                	slli	s1,s1,0x33
    8000330e:	90d9                	srli	s1,s1,0x36
    80003310:	00950733          	add	a4,a0,s1
    80003314:	05874703          	lbu	a4,88(a4)
    80003318:	00e7f6b3          	and	a3,a5,a4
    8000331c:	c69d                	beqz	a3,8000334a <bfree+0x6c>
    8000331e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003320:	94aa                	add	s1,s1,a0
    80003322:	fff7c793          	not	a5,a5
    80003326:	8ff9                	and	a5,a5,a4
    80003328:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000332c:	00001097          	auipc	ra,0x1
    80003330:	120080e7          	jalr	288(ra) # 8000444c <log_write>
  brelse(bp);
    80003334:	854a                	mv	a0,s2
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	e92080e7          	jalr	-366(ra) # 800031c8 <brelse>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6902                	ld	s2,0(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret
    panic("freeing free block");
    8000334a:	00005517          	auipc	a0,0x5
    8000334e:	2ee50513          	addi	a0,a0,750 # 80008638 <syscalls+0x100>
    80003352:	ffffd097          	auipc	ra,0xffffd
    80003356:	1ec080e7          	jalr	492(ra) # 8000053e <panic>

000000008000335a <balloc>:
{
    8000335a:	711d                	addi	sp,sp,-96
    8000335c:	ec86                	sd	ra,88(sp)
    8000335e:	e8a2                	sd	s0,80(sp)
    80003360:	e4a6                	sd	s1,72(sp)
    80003362:	e0ca                	sd	s2,64(sp)
    80003364:	fc4e                	sd	s3,56(sp)
    80003366:	f852                	sd	s4,48(sp)
    80003368:	f456                	sd	s5,40(sp)
    8000336a:	f05a                	sd	s6,32(sp)
    8000336c:	ec5e                	sd	s7,24(sp)
    8000336e:	e862                	sd	s8,16(sp)
    80003370:	e466                	sd	s9,8(sp)
    80003372:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003374:	0001d797          	auipc	a5,0x1d
    80003378:	8887a783          	lw	a5,-1912(a5) # 8001fbfc <sb+0x4>
    8000337c:	10078163          	beqz	a5,8000347e <balloc+0x124>
    80003380:	8baa                	mv	s7,a0
    80003382:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003384:	0001db17          	auipc	s6,0x1d
    80003388:	874b0b13          	addi	s6,s6,-1932 # 8001fbf8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000338c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000338e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003390:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003392:	6c89                	lui	s9,0x2
    80003394:	a061                	j	8000341c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003396:	974a                	add	a4,a4,s2
    80003398:	8fd5                	or	a5,a5,a3
    8000339a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	0ac080e7          	jalr	172(ra) # 8000444c <log_write>
        brelse(bp);
    800033a8:	854a                	mv	a0,s2
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	e1e080e7          	jalr	-482(ra) # 800031c8 <brelse>
  bp = bread(dev, bno);
    800033b2:	85a6                	mv	a1,s1
    800033b4:	855e                	mv	a0,s7
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	ce2080e7          	jalr	-798(ra) # 80003098 <bread>
    800033be:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033c0:	40000613          	li	a2,1024
    800033c4:	4581                	li	a1,0
    800033c6:	05850513          	addi	a0,a0,88
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	908080e7          	jalr	-1784(ra) # 80000cd2 <memset>
  log_write(bp);
    800033d2:	854a                	mv	a0,s2
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	078080e7          	jalr	120(ra) # 8000444c <log_write>
  brelse(bp);
    800033dc:	854a                	mv	a0,s2
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	dea080e7          	jalr	-534(ra) # 800031c8 <brelse>
}
    800033e6:	8526                	mv	a0,s1
    800033e8:	60e6                	ld	ra,88(sp)
    800033ea:	6446                	ld	s0,80(sp)
    800033ec:	64a6                	ld	s1,72(sp)
    800033ee:	6906                	ld	s2,64(sp)
    800033f0:	79e2                	ld	s3,56(sp)
    800033f2:	7a42                	ld	s4,48(sp)
    800033f4:	7aa2                	ld	s5,40(sp)
    800033f6:	7b02                	ld	s6,32(sp)
    800033f8:	6be2                	ld	s7,24(sp)
    800033fa:	6c42                	ld	s8,16(sp)
    800033fc:	6ca2                	ld	s9,8(sp)
    800033fe:	6125                	addi	sp,sp,96
    80003400:	8082                	ret
    brelse(bp);
    80003402:	854a                	mv	a0,s2
    80003404:	00000097          	auipc	ra,0x0
    80003408:	dc4080e7          	jalr	-572(ra) # 800031c8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000340c:	015c87bb          	addw	a5,s9,s5
    80003410:	00078a9b          	sext.w	s5,a5
    80003414:	004b2703          	lw	a4,4(s6)
    80003418:	06eaf363          	bgeu	s5,a4,8000347e <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000341c:	41fad79b          	sraiw	a5,s5,0x1f
    80003420:	0137d79b          	srliw	a5,a5,0x13
    80003424:	015787bb          	addw	a5,a5,s5
    80003428:	40d7d79b          	sraiw	a5,a5,0xd
    8000342c:	01cb2583          	lw	a1,28(s6)
    80003430:	9dbd                	addw	a1,a1,a5
    80003432:	855e                	mv	a0,s7
    80003434:	00000097          	auipc	ra,0x0
    80003438:	c64080e7          	jalr	-924(ra) # 80003098 <bread>
    8000343c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343e:	004b2503          	lw	a0,4(s6)
    80003442:	000a849b          	sext.w	s1,s5
    80003446:	8662                	mv	a2,s8
    80003448:	faa4fde3          	bgeu	s1,a0,80003402 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000344c:	41f6579b          	sraiw	a5,a2,0x1f
    80003450:	01d7d69b          	srliw	a3,a5,0x1d
    80003454:	00c6873b          	addw	a4,a3,a2
    80003458:	00777793          	andi	a5,a4,7
    8000345c:	9f95                	subw	a5,a5,a3
    8000345e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003462:	4037571b          	sraiw	a4,a4,0x3
    80003466:	00e906b3          	add	a3,s2,a4
    8000346a:	0586c683          	lbu	a3,88(a3)
    8000346e:	00d7f5b3          	and	a1,a5,a3
    80003472:	d195                	beqz	a1,80003396 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003474:	2605                	addiw	a2,a2,1
    80003476:	2485                	addiw	s1,s1,1
    80003478:	fd4618e3          	bne	a2,s4,80003448 <balloc+0xee>
    8000347c:	b759                	j	80003402 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000347e:	00005517          	auipc	a0,0x5
    80003482:	1d250513          	addi	a0,a0,466 # 80008650 <syscalls+0x118>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	102080e7          	jalr	258(ra) # 80000588 <printf>
  return 0;
    8000348e:	4481                	li	s1,0
    80003490:	bf99                	j	800033e6 <balloc+0x8c>

0000000080003492 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003492:	7179                	addi	sp,sp,-48
    80003494:	f406                	sd	ra,40(sp)
    80003496:	f022                	sd	s0,32(sp)
    80003498:	ec26                	sd	s1,24(sp)
    8000349a:	e84a                	sd	s2,16(sp)
    8000349c:	e44e                	sd	s3,8(sp)
    8000349e:	e052                	sd	s4,0(sp)
    800034a0:	1800                	addi	s0,sp,48
    800034a2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034a4:	47ad                	li	a5,11
    800034a6:	02b7e763          	bltu	a5,a1,800034d4 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800034aa:	02059493          	slli	s1,a1,0x20
    800034ae:	9081                	srli	s1,s1,0x20
    800034b0:	048a                	slli	s1,s1,0x2
    800034b2:	94aa                	add	s1,s1,a0
    800034b4:	0504a903          	lw	s2,80(s1)
    800034b8:	06091e63          	bnez	s2,80003534 <bmap+0xa2>
      addr = balloc(ip->dev);
    800034bc:	4108                	lw	a0,0(a0)
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	e9c080e7          	jalr	-356(ra) # 8000335a <balloc>
    800034c6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034ca:	06090563          	beqz	s2,80003534 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800034ce:	0524a823          	sw	s2,80(s1)
    800034d2:	a08d                	j	80003534 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034d4:	ff45849b          	addiw	s1,a1,-12
    800034d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034dc:	0ff00793          	li	a5,255
    800034e0:	08e7e563          	bltu	a5,a4,8000356a <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034e4:	08052903          	lw	s2,128(a0)
    800034e8:	00091d63          	bnez	s2,80003502 <bmap+0x70>
      addr = balloc(ip->dev);
    800034ec:	4108                	lw	a0,0(a0)
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	e6c080e7          	jalr	-404(ra) # 8000335a <balloc>
    800034f6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034fa:	02090d63          	beqz	s2,80003534 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034fe:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003502:	85ca                	mv	a1,s2
    80003504:	0009a503          	lw	a0,0(s3)
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	b90080e7          	jalr	-1136(ra) # 80003098 <bread>
    80003510:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003512:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003516:	02049593          	slli	a1,s1,0x20
    8000351a:	9181                	srli	a1,a1,0x20
    8000351c:	058a                	slli	a1,a1,0x2
    8000351e:	00b784b3          	add	s1,a5,a1
    80003522:	0004a903          	lw	s2,0(s1)
    80003526:	02090063          	beqz	s2,80003546 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000352a:	8552                	mv	a0,s4
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	c9c080e7          	jalr	-868(ra) # 800031c8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003534:	854a                	mv	a0,s2
    80003536:	70a2                	ld	ra,40(sp)
    80003538:	7402                	ld	s0,32(sp)
    8000353a:	64e2                	ld	s1,24(sp)
    8000353c:	6942                	ld	s2,16(sp)
    8000353e:	69a2                	ld	s3,8(sp)
    80003540:	6a02                	ld	s4,0(sp)
    80003542:	6145                	addi	sp,sp,48
    80003544:	8082                	ret
      addr = balloc(ip->dev);
    80003546:	0009a503          	lw	a0,0(s3)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	e10080e7          	jalr	-496(ra) # 8000335a <balloc>
    80003552:	0005091b          	sext.w	s2,a0
      if(addr){
    80003556:	fc090ae3          	beqz	s2,8000352a <bmap+0x98>
        a[bn] = addr;
    8000355a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000355e:	8552                	mv	a0,s4
    80003560:	00001097          	auipc	ra,0x1
    80003564:	eec080e7          	jalr	-276(ra) # 8000444c <log_write>
    80003568:	b7c9                	j	8000352a <bmap+0x98>
  panic("bmap: out of range");
    8000356a:	00005517          	auipc	a0,0x5
    8000356e:	0fe50513          	addi	a0,a0,254 # 80008668 <syscalls+0x130>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	fcc080e7          	jalr	-52(ra) # 8000053e <panic>

000000008000357a <iget>:
{
    8000357a:	7179                	addi	sp,sp,-48
    8000357c:	f406                	sd	ra,40(sp)
    8000357e:	f022                	sd	s0,32(sp)
    80003580:	ec26                	sd	s1,24(sp)
    80003582:	e84a                	sd	s2,16(sp)
    80003584:	e44e                	sd	s3,8(sp)
    80003586:	e052                	sd	s4,0(sp)
    80003588:	1800                	addi	s0,sp,48
    8000358a:	89aa                	mv	s3,a0
    8000358c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000358e:	0001c517          	auipc	a0,0x1c
    80003592:	68a50513          	addi	a0,a0,1674 # 8001fc18 <itable>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	640080e7          	jalr	1600(ra) # 80000bd6 <acquire>
  empty = 0;
    8000359e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035a0:	0001c497          	auipc	s1,0x1c
    800035a4:	69048493          	addi	s1,s1,1680 # 8001fc30 <itable+0x18>
    800035a8:	0001e697          	auipc	a3,0x1e
    800035ac:	11868693          	addi	a3,a3,280 # 800216c0 <log>
    800035b0:	a039                	j	800035be <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b2:	02090b63          	beqz	s2,800035e8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035b6:	08848493          	addi	s1,s1,136
    800035ba:	02d48a63          	beq	s1,a3,800035ee <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035be:	449c                	lw	a5,8(s1)
    800035c0:	fef059e3          	blez	a5,800035b2 <iget+0x38>
    800035c4:	4098                	lw	a4,0(s1)
    800035c6:	ff3716e3          	bne	a4,s3,800035b2 <iget+0x38>
    800035ca:	40d8                	lw	a4,4(s1)
    800035cc:	ff4713e3          	bne	a4,s4,800035b2 <iget+0x38>
      ip->ref++;
    800035d0:	2785                	addiw	a5,a5,1
    800035d2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035d4:	0001c517          	auipc	a0,0x1c
    800035d8:	64450513          	addi	a0,a0,1604 # 8001fc18 <itable>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
      return ip;
    800035e4:	8926                	mv	s2,s1
    800035e6:	a03d                	j	80003614 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e8:	f7f9                	bnez	a5,800035b6 <iget+0x3c>
    800035ea:	8926                	mv	s2,s1
    800035ec:	b7e9                	j	800035b6 <iget+0x3c>
  if(empty == 0)
    800035ee:	02090c63          	beqz	s2,80003626 <iget+0xac>
  ip->dev = dev;
    800035f2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035f6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035fa:	4785                	li	a5,1
    800035fc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003600:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003604:	0001c517          	auipc	a0,0x1c
    80003608:	61450513          	addi	a0,a0,1556 # 8001fc18 <itable>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	67e080e7          	jalr	1662(ra) # 80000c8a <release>
}
    80003614:	854a                	mv	a0,s2
    80003616:	70a2                	ld	ra,40(sp)
    80003618:	7402                	ld	s0,32(sp)
    8000361a:	64e2                	ld	s1,24(sp)
    8000361c:	6942                	ld	s2,16(sp)
    8000361e:	69a2                	ld	s3,8(sp)
    80003620:	6a02                	ld	s4,0(sp)
    80003622:	6145                	addi	sp,sp,48
    80003624:	8082                	ret
    panic("iget: no inodes");
    80003626:	00005517          	auipc	a0,0x5
    8000362a:	05a50513          	addi	a0,a0,90 # 80008680 <syscalls+0x148>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>

0000000080003636 <fsinit>:
fsinit(int dev) {
    80003636:	7179                	addi	sp,sp,-48
    80003638:	f406                	sd	ra,40(sp)
    8000363a:	f022                	sd	s0,32(sp)
    8000363c:	ec26                	sd	s1,24(sp)
    8000363e:	e84a                	sd	s2,16(sp)
    80003640:	e44e                	sd	s3,8(sp)
    80003642:	1800                	addi	s0,sp,48
    80003644:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003646:	4585                	li	a1,1
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	a50080e7          	jalr	-1456(ra) # 80003098 <bread>
    80003650:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003652:	0001c997          	auipc	s3,0x1c
    80003656:	5a698993          	addi	s3,s3,1446 # 8001fbf8 <sb>
    8000365a:	02000613          	li	a2,32
    8000365e:	05850593          	addi	a1,a0,88
    80003662:	854e                	mv	a0,s3
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	6ca080e7          	jalr	1738(ra) # 80000d2e <memmove>
  brelse(bp);
    8000366c:	8526                	mv	a0,s1
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	b5a080e7          	jalr	-1190(ra) # 800031c8 <brelse>
  if(sb.magic != FSMAGIC)
    80003676:	0009a703          	lw	a4,0(s3)
    8000367a:	102037b7          	lui	a5,0x10203
    8000367e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003682:	02f71263          	bne	a4,a5,800036a6 <fsinit+0x70>
  initlog(dev, &sb);
    80003686:	0001c597          	auipc	a1,0x1c
    8000368a:	57258593          	addi	a1,a1,1394 # 8001fbf8 <sb>
    8000368e:	854a                	mv	a0,s2
    80003690:	00001097          	auipc	ra,0x1
    80003694:	b40080e7          	jalr	-1216(ra) # 800041d0 <initlog>
}
    80003698:	70a2                	ld	ra,40(sp)
    8000369a:	7402                	ld	s0,32(sp)
    8000369c:	64e2                	ld	s1,24(sp)
    8000369e:	6942                	ld	s2,16(sp)
    800036a0:	69a2                	ld	s3,8(sp)
    800036a2:	6145                	addi	sp,sp,48
    800036a4:	8082                	ret
    panic("invalid file system");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	fea50513          	addi	a0,a0,-22 # 80008690 <syscalls+0x158>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>

00000000800036b6 <iinit>:
{
    800036b6:	7179                	addi	sp,sp,-48
    800036b8:	f406                	sd	ra,40(sp)
    800036ba:	f022                	sd	s0,32(sp)
    800036bc:	ec26                	sd	s1,24(sp)
    800036be:	e84a                	sd	s2,16(sp)
    800036c0:	e44e                	sd	s3,8(sp)
    800036c2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036c4:	00005597          	auipc	a1,0x5
    800036c8:	fe458593          	addi	a1,a1,-28 # 800086a8 <syscalls+0x170>
    800036cc:	0001c517          	auipc	a0,0x1c
    800036d0:	54c50513          	addi	a0,a0,1356 # 8001fc18 <itable>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	472080e7          	jalr	1138(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036dc:	0001c497          	auipc	s1,0x1c
    800036e0:	56448493          	addi	s1,s1,1380 # 8001fc40 <itable+0x28>
    800036e4:	0001e997          	auipc	s3,0x1e
    800036e8:	fec98993          	addi	s3,s3,-20 # 800216d0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036ec:	00005917          	auipc	s2,0x5
    800036f0:	fc490913          	addi	s2,s2,-60 # 800086b0 <syscalls+0x178>
    800036f4:	85ca                	mv	a1,s2
    800036f6:	8526                	mv	a0,s1
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	e3a080e7          	jalr	-454(ra) # 80004532 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003700:	08848493          	addi	s1,s1,136
    80003704:	ff3498e3          	bne	s1,s3,800036f4 <iinit+0x3e>
}
    80003708:	70a2                	ld	ra,40(sp)
    8000370a:	7402                	ld	s0,32(sp)
    8000370c:	64e2                	ld	s1,24(sp)
    8000370e:	6942                	ld	s2,16(sp)
    80003710:	69a2                	ld	s3,8(sp)
    80003712:	6145                	addi	sp,sp,48
    80003714:	8082                	ret

0000000080003716 <ialloc>:
{
    80003716:	715d                	addi	sp,sp,-80
    80003718:	e486                	sd	ra,72(sp)
    8000371a:	e0a2                	sd	s0,64(sp)
    8000371c:	fc26                	sd	s1,56(sp)
    8000371e:	f84a                	sd	s2,48(sp)
    80003720:	f44e                	sd	s3,40(sp)
    80003722:	f052                	sd	s4,32(sp)
    80003724:	ec56                	sd	s5,24(sp)
    80003726:	e85a                	sd	s6,16(sp)
    80003728:	e45e                	sd	s7,8(sp)
    8000372a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000372c:	0001c717          	auipc	a4,0x1c
    80003730:	4d872703          	lw	a4,1240(a4) # 8001fc04 <sb+0xc>
    80003734:	4785                	li	a5,1
    80003736:	04e7fa63          	bgeu	a5,a4,8000378a <ialloc+0x74>
    8000373a:	8aaa                	mv	s5,a0
    8000373c:	8bae                	mv	s7,a1
    8000373e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003740:	0001ca17          	auipc	s4,0x1c
    80003744:	4b8a0a13          	addi	s4,s4,1208 # 8001fbf8 <sb>
    80003748:	00048b1b          	sext.w	s6,s1
    8000374c:	0044d793          	srli	a5,s1,0x4
    80003750:	018a2583          	lw	a1,24(s4)
    80003754:	9dbd                	addw	a1,a1,a5
    80003756:	8556                	mv	a0,s5
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	940080e7          	jalr	-1728(ra) # 80003098 <bread>
    80003760:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003762:	05850993          	addi	s3,a0,88
    80003766:	00f4f793          	andi	a5,s1,15
    8000376a:	079a                	slli	a5,a5,0x6
    8000376c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000376e:	00099783          	lh	a5,0(s3)
    80003772:	c3a1                	beqz	a5,800037b2 <ialloc+0x9c>
    brelse(bp);
    80003774:	00000097          	auipc	ra,0x0
    80003778:	a54080e7          	jalr	-1452(ra) # 800031c8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000377c:	0485                	addi	s1,s1,1
    8000377e:	00ca2703          	lw	a4,12(s4)
    80003782:	0004879b          	sext.w	a5,s1
    80003786:	fce7e1e3          	bltu	a5,a4,80003748 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000378a:	00005517          	auipc	a0,0x5
    8000378e:	f2e50513          	addi	a0,a0,-210 # 800086b8 <syscalls+0x180>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
  return 0;
    8000379a:	4501                	li	a0,0
}
    8000379c:	60a6                	ld	ra,72(sp)
    8000379e:	6406                	ld	s0,64(sp)
    800037a0:	74e2                	ld	s1,56(sp)
    800037a2:	7942                	ld	s2,48(sp)
    800037a4:	79a2                	ld	s3,40(sp)
    800037a6:	7a02                	ld	s4,32(sp)
    800037a8:	6ae2                	ld	s5,24(sp)
    800037aa:	6b42                	ld	s6,16(sp)
    800037ac:	6ba2                	ld	s7,8(sp)
    800037ae:	6161                	addi	sp,sp,80
    800037b0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037b2:	04000613          	li	a2,64
    800037b6:	4581                	li	a1,0
    800037b8:	854e                	mv	a0,s3
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	518080e7          	jalr	1304(ra) # 80000cd2 <memset>
      dip->type = type;
    800037c2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037c6:	854a                	mv	a0,s2
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	c84080e7          	jalr	-892(ra) # 8000444c <log_write>
      brelse(bp);
    800037d0:	854a                	mv	a0,s2
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	9f6080e7          	jalr	-1546(ra) # 800031c8 <brelse>
      return iget(dev, inum);
    800037da:	85da                	mv	a1,s6
    800037dc:	8556                	mv	a0,s5
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	d9c080e7          	jalr	-612(ra) # 8000357a <iget>
    800037e6:	bf5d                	j	8000379c <ialloc+0x86>

00000000800037e8 <iupdate>:
{
    800037e8:	1101                	addi	sp,sp,-32
    800037ea:	ec06                	sd	ra,24(sp)
    800037ec:	e822                	sd	s0,16(sp)
    800037ee:	e426                	sd	s1,8(sp)
    800037f0:	e04a                	sd	s2,0(sp)
    800037f2:	1000                	addi	s0,sp,32
    800037f4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f6:	415c                	lw	a5,4(a0)
    800037f8:	0047d79b          	srliw	a5,a5,0x4
    800037fc:	0001c597          	auipc	a1,0x1c
    80003800:	4145a583          	lw	a1,1044(a1) # 8001fc10 <sb+0x18>
    80003804:	9dbd                	addw	a1,a1,a5
    80003806:	4108                	lw	a0,0(a0)
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	890080e7          	jalr	-1904(ra) # 80003098 <bread>
    80003810:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003812:	05850793          	addi	a5,a0,88
    80003816:	40c8                	lw	a0,4(s1)
    80003818:	893d                	andi	a0,a0,15
    8000381a:	051a                	slli	a0,a0,0x6
    8000381c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000381e:	04449703          	lh	a4,68(s1)
    80003822:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003826:	04649703          	lh	a4,70(s1)
    8000382a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000382e:	04849703          	lh	a4,72(s1)
    80003832:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003836:	04a49703          	lh	a4,74(s1)
    8000383a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000383e:	44f8                	lw	a4,76(s1)
    80003840:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003842:	03400613          	li	a2,52
    80003846:	05048593          	addi	a1,s1,80
    8000384a:	0531                	addi	a0,a0,12
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	4e2080e7          	jalr	1250(ra) # 80000d2e <memmove>
  log_write(bp);
    80003854:	854a                	mv	a0,s2
    80003856:	00001097          	auipc	ra,0x1
    8000385a:	bf6080e7          	jalr	-1034(ra) # 8000444c <log_write>
  brelse(bp);
    8000385e:	854a                	mv	a0,s2
    80003860:	00000097          	auipc	ra,0x0
    80003864:	968080e7          	jalr	-1688(ra) # 800031c8 <brelse>
}
    80003868:	60e2                	ld	ra,24(sp)
    8000386a:	6442                	ld	s0,16(sp)
    8000386c:	64a2                	ld	s1,8(sp)
    8000386e:	6902                	ld	s2,0(sp)
    80003870:	6105                	addi	sp,sp,32
    80003872:	8082                	ret

0000000080003874 <idup>:
{
    80003874:	1101                	addi	sp,sp,-32
    80003876:	ec06                	sd	ra,24(sp)
    80003878:	e822                	sd	s0,16(sp)
    8000387a:	e426                	sd	s1,8(sp)
    8000387c:	1000                	addi	s0,sp,32
    8000387e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003880:	0001c517          	auipc	a0,0x1c
    80003884:	39850513          	addi	a0,a0,920 # 8001fc18 <itable>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	34e080e7          	jalr	846(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003890:	449c                	lw	a5,8(s1)
    80003892:	2785                	addiw	a5,a5,1
    80003894:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003896:	0001c517          	auipc	a0,0x1c
    8000389a:	38250513          	addi	a0,a0,898 # 8001fc18 <itable>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	3ec080e7          	jalr	1004(ra) # 80000c8a <release>
}
    800038a6:	8526                	mv	a0,s1
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6105                	addi	sp,sp,32
    800038b0:	8082                	ret

00000000800038b2 <ilock>:
{
    800038b2:	1101                	addi	sp,sp,-32
    800038b4:	ec06                	sd	ra,24(sp)
    800038b6:	e822                	sd	s0,16(sp)
    800038b8:	e426                	sd	s1,8(sp)
    800038ba:	e04a                	sd	s2,0(sp)
    800038bc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038be:	c115                	beqz	a0,800038e2 <ilock+0x30>
    800038c0:	84aa                	mv	s1,a0
    800038c2:	451c                	lw	a5,8(a0)
    800038c4:	00f05f63          	blez	a5,800038e2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038c8:	0541                	addi	a0,a0,16
    800038ca:	00001097          	auipc	ra,0x1
    800038ce:	ca2080e7          	jalr	-862(ra) # 8000456c <acquiresleep>
  if(ip->valid == 0){
    800038d2:	40bc                	lw	a5,64(s1)
    800038d4:	cf99                	beqz	a5,800038f2 <ilock+0x40>
}
    800038d6:	60e2                	ld	ra,24(sp)
    800038d8:	6442                	ld	s0,16(sp)
    800038da:	64a2                	ld	s1,8(sp)
    800038dc:	6902                	ld	s2,0(sp)
    800038de:	6105                	addi	sp,sp,32
    800038e0:	8082                	ret
    panic("ilock");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	dee50513          	addi	a0,a0,-530 # 800086d0 <syscalls+0x198>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f2:	40dc                	lw	a5,4(s1)
    800038f4:	0047d79b          	srliw	a5,a5,0x4
    800038f8:	0001c597          	auipc	a1,0x1c
    800038fc:	3185a583          	lw	a1,792(a1) # 8001fc10 <sb+0x18>
    80003900:	9dbd                	addw	a1,a1,a5
    80003902:	4088                	lw	a0,0(s1)
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	794080e7          	jalr	1940(ra) # 80003098 <bread>
    8000390c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000390e:	05850593          	addi	a1,a0,88
    80003912:	40dc                	lw	a5,4(s1)
    80003914:	8bbd                	andi	a5,a5,15
    80003916:	079a                	slli	a5,a5,0x6
    80003918:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000391a:	00059783          	lh	a5,0(a1)
    8000391e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003922:	00259783          	lh	a5,2(a1)
    80003926:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000392a:	00459783          	lh	a5,4(a1)
    8000392e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003932:	00659783          	lh	a5,6(a1)
    80003936:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000393a:	459c                	lw	a5,8(a1)
    8000393c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000393e:	03400613          	li	a2,52
    80003942:	05b1                	addi	a1,a1,12
    80003944:	05048513          	addi	a0,s1,80
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	3e6080e7          	jalr	998(ra) # 80000d2e <memmove>
    brelse(bp);
    80003950:	854a                	mv	a0,s2
    80003952:	00000097          	auipc	ra,0x0
    80003956:	876080e7          	jalr	-1930(ra) # 800031c8 <brelse>
    ip->valid = 1;
    8000395a:	4785                	li	a5,1
    8000395c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000395e:	04449783          	lh	a5,68(s1)
    80003962:	fbb5                	bnez	a5,800038d6 <ilock+0x24>
      panic("ilock: no type");
    80003964:	00005517          	auipc	a0,0x5
    80003968:	d7450513          	addi	a0,a0,-652 # 800086d8 <syscalls+0x1a0>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>

0000000080003974 <iunlock>:
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	e04a                	sd	s2,0(sp)
    8000397e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003980:	c905                	beqz	a0,800039b0 <iunlock+0x3c>
    80003982:	84aa                	mv	s1,a0
    80003984:	01050913          	addi	s2,a0,16
    80003988:	854a                	mv	a0,s2
    8000398a:	00001097          	auipc	ra,0x1
    8000398e:	c7c080e7          	jalr	-900(ra) # 80004606 <holdingsleep>
    80003992:	cd19                	beqz	a0,800039b0 <iunlock+0x3c>
    80003994:	449c                	lw	a5,8(s1)
    80003996:	00f05d63          	blez	a5,800039b0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000399a:	854a                	mv	a0,s2
    8000399c:	00001097          	auipc	ra,0x1
    800039a0:	c26080e7          	jalr	-986(ra) # 800045c2 <releasesleep>
}
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6902                	ld	s2,0(sp)
    800039ac:	6105                	addi	sp,sp,32
    800039ae:	8082                	ret
    panic("iunlock");
    800039b0:	00005517          	auipc	a0,0x5
    800039b4:	d3850513          	addi	a0,a0,-712 # 800086e8 <syscalls+0x1b0>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	b86080e7          	jalr	-1146(ra) # 8000053e <panic>

00000000800039c0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039c0:	7179                	addi	sp,sp,-48
    800039c2:	f406                	sd	ra,40(sp)
    800039c4:	f022                	sd	s0,32(sp)
    800039c6:	ec26                	sd	s1,24(sp)
    800039c8:	e84a                	sd	s2,16(sp)
    800039ca:	e44e                	sd	s3,8(sp)
    800039cc:	e052                	sd	s4,0(sp)
    800039ce:	1800                	addi	s0,sp,48
    800039d0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039d2:	05050493          	addi	s1,a0,80
    800039d6:	08050913          	addi	s2,a0,128
    800039da:	a021                	j	800039e2 <itrunc+0x22>
    800039dc:	0491                	addi	s1,s1,4
    800039de:	01248d63          	beq	s1,s2,800039f8 <itrunc+0x38>
    if(ip->addrs[i]){
    800039e2:	408c                	lw	a1,0(s1)
    800039e4:	dde5                	beqz	a1,800039dc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039e6:	0009a503          	lw	a0,0(s3)
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	8f4080e7          	jalr	-1804(ra) # 800032de <bfree>
      ip->addrs[i] = 0;
    800039f2:	0004a023          	sw	zero,0(s1)
    800039f6:	b7dd                	j	800039dc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039f8:	0809a583          	lw	a1,128(s3)
    800039fc:	e185                	bnez	a1,80003a1c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039fe:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a02:	854e                	mv	a0,s3
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	de4080e7          	jalr	-540(ra) # 800037e8 <iupdate>
}
    80003a0c:	70a2                	ld	ra,40(sp)
    80003a0e:	7402                	ld	s0,32(sp)
    80003a10:	64e2                	ld	s1,24(sp)
    80003a12:	6942                	ld	s2,16(sp)
    80003a14:	69a2                	ld	s3,8(sp)
    80003a16:	6a02                	ld	s4,0(sp)
    80003a18:	6145                	addi	sp,sp,48
    80003a1a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a1c:	0009a503          	lw	a0,0(s3)
    80003a20:	fffff097          	auipc	ra,0xfffff
    80003a24:	678080e7          	jalr	1656(ra) # 80003098 <bread>
    80003a28:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a2a:	05850493          	addi	s1,a0,88
    80003a2e:	45850913          	addi	s2,a0,1112
    80003a32:	a021                	j	80003a3a <itrunc+0x7a>
    80003a34:	0491                	addi	s1,s1,4
    80003a36:	01248b63          	beq	s1,s2,80003a4c <itrunc+0x8c>
      if(a[j])
    80003a3a:	408c                	lw	a1,0(s1)
    80003a3c:	dde5                	beqz	a1,80003a34 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a3e:	0009a503          	lw	a0,0(s3)
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	89c080e7          	jalr	-1892(ra) # 800032de <bfree>
    80003a4a:	b7ed                	j	80003a34 <itrunc+0x74>
    brelse(bp);
    80003a4c:	8552                	mv	a0,s4
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	77a080e7          	jalr	1914(ra) # 800031c8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a56:	0809a583          	lw	a1,128(s3)
    80003a5a:	0009a503          	lw	a0,0(s3)
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	880080e7          	jalr	-1920(ra) # 800032de <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a66:	0809a023          	sw	zero,128(s3)
    80003a6a:	bf51                	j	800039fe <itrunc+0x3e>

0000000080003a6c <iput>:
{
    80003a6c:	1101                	addi	sp,sp,-32
    80003a6e:	ec06                	sd	ra,24(sp)
    80003a70:	e822                	sd	s0,16(sp)
    80003a72:	e426                	sd	s1,8(sp)
    80003a74:	e04a                	sd	s2,0(sp)
    80003a76:	1000                	addi	s0,sp,32
    80003a78:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a7a:	0001c517          	auipc	a0,0x1c
    80003a7e:	19e50513          	addi	a0,a0,414 # 8001fc18 <itable>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	154080e7          	jalr	340(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a8a:	4498                	lw	a4,8(s1)
    80003a8c:	4785                	li	a5,1
    80003a8e:	02f70363          	beq	a4,a5,80003ab4 <iput+0x48>
  ip->ref--;
    80003a92:	449c                	lw	a5,8(s1)
    80003a94:	37fd                	addiw	a5,a5,-1
    80003a96:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a98:	0001c517          	auipc	a0,0x1c
    80003a9c:	18050513          	addi	a0,a0,384 # 8001fc18 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	1ea080e7          	jalr	490(ra) # 80000c8a <release>
}
    80003aa8:	60e2                	ld	ra,24(sp)
    80003aaa:	6442                	ld	s0,16(sp)
    80003aac:	64a2                	ld	s1,8(sp)
    80003aae:	6902                	ld	s2,0(sp)
    80003ab0:	6105                	addi	sp,sp,32
    80003ab2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab4:	40bc                	lw	a5,64(s1)
    80003ab6:	dff1                	beqz	a5,80003a92 <iput+0x26>
    80003ab8:	04a49783          	lh	a5,74(s1)
    80003abc:	fbf9                	bnez	a5,80003a92 <iput+0x26>
    acquiresleep(&ip->lock);
    80003abe:	01048913          	addi	s2,s1,16
    80003ac2:	854a                	mv	a0,s2
    80003ac4:	00001097          	auipc	ra,0x1
    80003ac8:	aa8080e7          	jalr	-1368(ra) # 8000456c <acquiresleep>
    release(&itable.lock);
    80003acc:	0001c517          	auipc	a0,0x1c
    80003ad0:	14c50513          	addi	a0,a0,332 # 8001fc18 <itable>
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	1b6080e7          	jalr	438(ra) # 80000c8a <release>
    itrunc(ip);
    80003adc:	8526                	mv	a0,s1
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	ee2080e7          	jalr	-286(ra) # 800039c0 <itrunc>
    ip->type = 0;
    80003ae6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003aea:	8526                	mv	a0,s1
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	cfc080e7          	jalr	-772(ra) # 800037e8 <iupdate>
    ip->valid = 0;
    80003af4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003af8:	854a                	mv	a0,s2
    80003afa:	00001097          	auipc	ra,0x1
    80003afe:	ac8080e7          	jalr	-1336(ra) # 800045c2 <releasesleep>
    acquire(&itable.lock);
    80003b02:	0001c517          	auipc	a0,0x1c
    80003b06:	11650513          	addi	a0,a0,278 # 8001fc18 <itable>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	0cc080e7          	jalr	204(ra) # 80000bd6 <acquire>
    80003b12:	b741                	j	80003a92 <iput+0x26>

0000000080003b14 <iunlockput>:
{
    80003b14:	1101                	addi	sp,sp,-32
    80003b16:	ec06                	sd	ra,24(sp)
    80003b18:	e822                	sd	s0,16(sp)
    80003b1a:	e426                	sd	s1,8(sp)
    80003b1c:	1000                	addi	s0,sp,32
    80003b1e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	e54080e7          	jalr	-428(ra) # 80003974 <iunlock>
  iput(ip);
    80003b28:	8526                	mv	a0,s1
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	f42080e7          	jalr	-190(ra) # 80003a6c <iput>
}
    80003b32:	60e2                	ld	ra,24(sp)
    80003b34:	6442                	ld	s0,16(sp)
    80003b36:	64a2                	ld	s1,8(sp)
    80003b38:	6105                	addi	sp,sp,32
    80003b3a:	8082                	ret

0000000080003b3c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b3c:	1141                	addi	sp,sp,-16
    80003b3e:	e422                	sd	s0,8(sp)
    80003b40:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b42:	411c                	lw	a5,0(a0)
    80003b44:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b46:	415c                	lw	a5,4(a0)
    80003b48:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b4a:	04451783          	lh	a5,68(a0)
    80003b4e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b52:	04a51783          	lh	a5,74(a0)
    80003b56:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b5a:	04c56783          	lwu	a5,76(a0)
    80003b5e:	e99c                	sd	a5,16(a1)
}
    80003b60:	6422                	ld	s0,8(sp)
    80003b62:	0141                	addi	sp,sp,16
    80003b64:	8082                	ret

0000000080003b66 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b66:	457c                	lw	a5,76(a0)
    80003b68:	0ed7e963          	bltu	a5,a3,80003c5a <readi+0xf4>
{
    80003b6c:	7159                	addi	sp,sp,-112
    80003b6e:	f486                	sd	ra,104(sp)
    80003b70:	f0a2                	sd	s0,96(sp)
    80003b72:	eca6                	sd	s1,88(sp)
    80003b74:	e8ca                	sd	s2,80(sp)
    80003b76:	e4ce                	sd	s3,72(sp)
    80003b78:	e0d2                	sd	s4,64(sp)
    80003b7a:	fc56                	sd	s5,56(sp)
    80003b7c:	f85a                	sd	s6,48(sp)
    80003b7e:	f45e                	sd	s7,40(sp)
    80003b80:	f062                	sd	s8,32(sp)
    80003b82:	ec66                	sd	s9,24(sp)
    80003b84:	e86a                	sd	s10,16(sp)
    80003b86:	e46e                	sd	s11,8(sp)
    80003b88:	1880                	addi	s0,sp,112
    80003b8a:	8b2a                	mv	s6,a0
    80003b8c:	8bae                	mv	s7,a1
    80003b8e:	8a32                	mv	s4,a2
    80003b90:	84b6                	mv	s1,a3
    80003b92:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b94:	9f35                	addw	a4,a4,a3
    return 0;
    80003b96:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b98:	0ad76063          	bltu	a4,a3,80003c38 <readi+0xd2>
  if(off + n > ip->size)
    80003b9c:	00e7f463          	bgeu	a5,a4,80003ba4 <readi+0x3e>
    n = ip->size - off;
    80003ba0:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba4:	0a0a8963          	beqz	s5,80003c56 <readi+0xf0>
    80003ba8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003baa:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bae:	5c7d                	li	s8,-1
    80003bb0:	a82d                	j	80003bea <readi+0x84>
    80003bb2:	020d1d93          	slli	s11,s10,0x20
    80003bb6:	020ddd93          	srli	s11,s11,0x20
    80003bba:	05890793          	addi	a5,s2,88
    80003bbe:	86ee                	mv	a3,s11
    80003bc0:	963e                	add	a2,a2,a5
    80003bc2:	85d2                	mv	a1,s4
    80003bc4:	855e                	mv	a0,s7
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	95c080e7          	jalr	-1700(ra) # 80002522 <either_copyout>
    80003bce:	05850d63          	beq	a0,s8,80003c28 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bd2:	854a                	mv	a0,s2
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	5f4080e7          	jalr	1524(ra) # 800031c8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bdc:	013d09bb          	addw	s3,s10,s3
    80003be0:	009d04bb          	addw	s1,s10,s1
    80003be4:	9a6e                	add	s4,s4,s11
    80003be6:	0559f763          	bgeu	s3,s5,80003c34 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bea:	00a4d59b          	srliw	a1,s1,0xa
    80003bee:	855a                	mv	a0,s6
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	8a2080e7          	jalr	-1886(ra) # 80003492 <bmap>
    80003bf8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bfc:	cd85                	beqz	a1,80003c34 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003bfe:	000b2503          	lw	a0,0(s6)
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	496080e7          	jalr	1174(ra) # 80003098 <bread>
    80003c0a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0c:	3ff4f613          	andi	a2,s1,1023
    80003c10:	40cc87bb          	subw	a5,s9,a2
    80003c14:	413a873b          	subw	a4,s5,s3
    80003c18:	8d3e                	mv	s10,a5
    80003c1a:	2781                	sext.w	a5,a5
    80003c1c:	0007069b          	sext.w	a3,a4
    80003c20:	f8f6f9e3          	bgeu	a3,a5,80003bb2 <readi+0x4c>
    80003c24:	8d3a                	mv	s10,a4
    80003c26:	b771                	j	80003bb2 <readi+0x4c>
      brelse(bp);
    80003c28:	854a                	mv	a0,s2
    80003c2a:	fffff097          	auipc	ra,0xfffff
    80003c2e:	59e080e7          	jalr	1438(ra) # 800031c8 <brelse>
      tot = -1;
    80003c32:	59fd                	li	s3,-1
  }
  return tot;
    80003c34:	0009851b          	sext.w	a0,s3
}
    80003c38:	70a6                	ld	ra,104(sp)
    80003c3a:	7406                	ld	s0,96(sp)
    80003c3c:	64e6                	ld	s1,88(sp)
    80003c3e:	6946                	ld	s2,80(sp)
    80003c40:	69a6                	ld	s3,72(sp)
    80003c42:	6a06                	ld	s4,64(sp)
    80003c44:	7ae2                	ld	s5,56(sp)
    80003c46:	7b42                	ld	s6,48(sp)
    80003c48:	7ba2                	ld	s7,40(sp)
    80003c4a:	7c02                	ld	s8,32(sp)
    80003c4c:	6ce2                	ld	s9,24(sp)
    80003c4e:	6d42                	ld	s10,16(sp)
    80003c50:	6da2                	ld	s11,8(sp)
    80003c52:	6165                	addi	sp,sp,112
    80003c54:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c56:	89d6                	mv	s3,s5
    80003c58:	bff1                	j	80003c34 <readi+0xce>
    return 0;
    80003c5a:	4501                	li	a0,0
}
    80003c5c:	8082                	ret

0000000080003c5e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c5e:	457c                	lw	a5,76(a0)
    80003c60:	10d7e863          	bltu	a5,a3,80003d70 <writei+0x112>
{
    80003c64:	7159                	addi	sp,sp,-112
    80003c66:	f486                	sd	ra,104(sp)
    80003c68:	f0a2                	sd	s0,96(sp)
    80003c6a:	eca6                	sd	s1,88(sp)
    80003c6c:	e8ca                	sd	s2,80(sp)
    80003c6e:	e4ce                	sd	s3,72(sp)
    80003c70:	e0d2                	sd	s4,64(sp)
    80003c72:	fc56                	sd	s5,56(sp)
    80003c74:	f85a                	sd	s6,48(sp)
    80003c76:	f45e                	sd	s7,40(sp)
    80003c78:	f062                	sd	s8,32(sp)
    80003c7a:	ec66                	sd	s9,24(sp)
    80003c7c:	e86a                	sd	s10,16(sp)
    80003c7e:	e46e                	sd	s11,8(sp)
    80003c80:	1880                	addi	s0,sp,112
    80003c82:	8aaa                	mv	s5,a0
    80003c84:	8bae                	mv	s7,a1
    80003c86:	8a32                	mv	s4,a2
    80003c88:	8936                	mv	s2,a3
    80003c8a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c8c:	00e687bb          	addw	a5,a3,a4
    80003c90:	0ed7e263          	bltu	a5,a3,80003d74 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c94:	00043737          	lui	a4,0x43
    80003c98:	0ef76063          	bltu	a4,a5,80003d78 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c9c:	0c0b0863          	beqz	s6,80003d6c <writei+0x10e>
    80003ca0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ca6:	5c7d                	li	s8,-1
    80003ca8:	a091                	j	80003cec <writei+0x8e>
    80003caa:	020d1d93          	slli	s11,s10,0x20
    80003cae:	020ddd93          	srli	s11,s11,0x20
    80003cb2:	05848793          	addi	a5,s1,88
    80003cb6:	86ee                	mv	a3,s11
    80003cb8:	8652                	mv	a2,s4
    80003cba:	85de                	mv	a1,s7
    80003cbc:	953e                	add	a0,a0,a5
    80003cbe:	fffff097          	auipc	ra,0xfffff
    80003cc2:	8ba080e7          	jalr	-1862(ra) # 80002578 <either_copyin>
    80003cc6:	07850263          	beq	a0,s8,80003d2a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cca:	8526                	mv	a0,s1
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	780080e7          	jalr	1920(ra) # 8000444c <log_write>
    brelse(bp);
    80003cd4:	8526                	mv	a0,s1
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	4f2080e7          	jalr	1266(ra) # 800031c8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cde:	013d09bb          	addw	s3,s10,s3
    80003ce2:	012d093b          	addw	s2,s10,s2
    80003ce6:	9a6e                	add	s4,s4,s11
    80003ce8:	0569f663          	bgeu	s3,s6,80003d34 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cec:	00a9559b          	srliw	a1,s2,0xa
    80003cf0:	8556                	mv	a0,s5
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	7a0080e7          	jalr	1952(ra) # 80003492 <bmap>
    80003cfa:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cfe:	c99d                	beqz	a1,80003d34 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d00:	000aa503          	lw	a0,0(s5)
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	394080e7          	jalr	916(ra) # 80003098 <bread>
    80003d0c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d0e:	3ff97513          	andi	a0,s2,1023
    80003d12:	40ac87bb          	subw	a5,s9,a0
    80003d16:	413b073b          	subw	a4,s6,s3
    80003d1a:	8d3e                	mv	s10,a5
    80003d1c:	2781                	sext.w	a5,a5
    80003d1e:	0007069b          	sext.w	a3,a4
    80003d22:	f8f6f4e3          	bgeu	a3,a5,80003caa <writei+0x4c>
    80003d26:	8d3a                	mv	s10,a4
    80003d28:	b749                	j	80003caa <writei+0x4c>
      brelse(bp);
    80003d2a:	8526                	mv	a0,s1
    80003d2c:	fffff097          	auipc	ra,0xfffff
    80003d30:	49c080e7          	jalr	1180(ra) # 800031c8 <brelse>
  }

  if(off > ip->size)
    80003d34:	04caa783          	lw	a5,76(s5)
    80003d38:	0127f463          	bgeu	a5,s2,80003d40 <writei+0xe2>
    ip->size = off;
    80003d3c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d40:	8556                	mv	a0,s5
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	aa6080e7          	jalr	-1370(ra) # 800037e8 <iupdate>

  return tot;
    80003d4a:	0009851b          	sext.w	a0,s3
}
    80003d4e:	70a6                	ld	ra,104(sp)
    80003d50:	7406                	ld	s0,96(sp)
    80003d52:	64e6                	ld	s1,88(sp)
    80003d54:	6946                	ld	s2,80(sp)
    80003d56:	69a6                	ld	s3,72(sp)
    80003d58:	6a06                	ld	s4,64(sp)
    80003d5a:	7ae2                	ld	s5,56(sp)
    80003d5c:	7b42                	ld	s6,48(sp)
    80003d5e:	7ba2                	ld	s7,40(sp)
    80003d60:	7c02                	ld	s8,32(sp)
    80003d62:	6ce2                	ld	s9,24(sp)
    80003d64:	6d42                	ld	s10,16(sp)
    80003d66:	6da2                	ld	s11,8(sp)
    80003d68:	6165                	addi	sp,sp,112
    80003d6a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6c:	89da                	mv	s3,s6
    80003d6e:	bfc9                	j	80003d40 <writei+0xe2>
    return -1;
    80003d70:	557d                	li	a0,-1
}
    80003d72:	8082                	ret
    return -1;
    80003d74:	557d                	li	a0,-1
    80003d76:	bfe1                	j	80003d4e <writei+0xf0>
    return -1;
    80003d78:	557d                	li	a0,-1
    80003d7a:	bfd1                	j	80003d4e <writei+0xf0>

0000000080003d7c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d7c:	1141                	addi	sp,sp,-16
    80003d7e:	e406                	sd	ra,8(sp)
    80003d80:	e022                	sd	s0,0(sp)
    80003d82:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d84:	4639                	li	a2,14
    80003d86:	ffffd097          	auipc	ra,0xffffd
    80003d8a:	01c080e7          	jalr	28(ra) # 80000da2 <strncmp>
}
    80003d8e:	60a2                	ld	ra,8(sp)
    80003d90:	6402                	ld	s0,0(sp)
    80003d92:	0141                	addi	sp,sp,16
    80003d94:	8082                	ret

0000000080003d96 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d96:	7139                	addi	sp,sp,-64
    80003d98:	fc06                	sd	ra,56(sp)
    80003d9a:	f822                	sd	s0,48(sp)
    80003d9c:	f426                	sd	s1,40(sp)
    80003d9e:	f04a                	sd	s2,32(sp)
    80003da0:	ec4e                	sd	s3,24(sp)
    80003da2:	e852                	sd	s4,16(sp)
    80003da4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003da6:	04451703          	lh	a4,68(a0)
    80003daa:	4785                	li	a5,1
    80003dac:	00f71a63          	bne	a4,a5,80003dc0 <dirlookup+0x2a>
    80003db0:	892a                	mv	s2,a0
    80003db2:	89ae                	mv	s3,a1
    80003db4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db6:	457c                	lw	a5,76(a0)
    80003db8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dba:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbc:	e79d                	bnez	a5,80003dea <dirlookup+0x54>
    80003dbe:	a8a5                	j	80003e36 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dc0:	00005517          	auipc	a0,0x5
    80003dc4:	93050513          	addi	a0,a0,-1744 # 800086f0 <syscalls+0x1b8>
    80003dc8:	ffffc097          	auipc	ra,0xffffc
    80003dcc:	776080e7          	jalr	1910(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dd0:	00005517          	auipc	a0,0x5
    80003dd4:	93850513          	addi	a0,a0,-1736 # 80008708 <syscalls+0x1d0>
    80003dd8:	ffffc097          	auipc	ra,0xffffc
    80003ddc:	766080e7          	jalr	1894(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de0:	24c1                	addiw	s1,s1,16
    80003de2:	04c92783          	lw	a5,76(s2)
    80003de6:	04f4f763          	bgeu	s1,a5,80003e34 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dea:	4741                	li	a4,16
    80003dec:	86a6                	mv	a3,s1
    80003dee:	fc040613          	addi	a2,s0,-64
    80003df2:	4581                	li	a1,0
    80003df4:	854a                	mv	a0,s2
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	d70080e7          	jalr	-656(ra) # 80003b66 <readi>
    80003dfe:	47c1                	li	a5,16
    80003e00:	fcf518e3          	bne	a0,a5,80003dd0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e04:	fc045783          	lhu	a5,-64(s0)
    80003e08:	dfe1                	beqz	a5,80003de0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e0a:	fc240593          	addi	a1,s0,-62
    80003e0e:	854e                	mv	a0,s3
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	f6c080e7          	jalr	-148(ra) # 80003d7c <namecmp>
    80003e18:	f561                	bnez	a0,80003de0 <dirlookup+0x4a>
      if(poff)
    80003e1a:	000a0463          	beqz	s4,80003e22 <dirlookup+0x8c>
        *poff = off;
    80003e1e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e22:	fc045583          	lhu	a1,-64(s0)
    80003e26:	00092503          	lw	a0,0(s2)
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	750080e7          	jalr	1872(ra) # 8000357a <iget>
    80003e32:	a011                	j	80003e36 <dirlookup+0xa0>
  return 0;
    80003e34:	4501                	li	a0,0
}
    80003e36:	70e2                	ld	ra,56(sp)
    80003e38:	7442                	ld	s0,48(sp)
    80003e3a:	74a2                	ld	s1,40(sp)
    80003e3c:	7902                	ld	s2,32(sp)
    80003e3e:	69e2                	ld	s3,24(sp)
    80003e40:	6a42                	ld	s4,16(sp)
    80003e42:	6121                	addi	sp,sp,64
    80003e44:	8082                	ret

0000000080003e46 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e46:	711d                	addi	sp,sp,-96
    80003e48:	ec86                	sd	ra,88(sp)
    80003e4a:	e8a2                	sd	s0,80(sp)
    80003e4c:	e4a6                	sd	s1,72(sp)
    80003e4e:	e0ca                	sd	s2,64(sp)
    80003e50:	fc4e                	sd	s3,56(sp)
    80003e52:	f852                	sd	s4,48(sp)
    80003e54:	f456                	sd	s5,40(sp)
    80003e56:	f05a                	sd	s6,32(sp)
    80003e58:	ec5e                	sd	s7,24(sp)
    80003e5a:	e862                	sd	s8,16(sp)
    80003e5c:	e466                	sd	s9,8(sp)
    80003e5e:	1080                	addi	s0,sp,96
    80003e60:	84aa                	mv	s1,a0
    80003e62:	8aae                	mv	s5,a1
    80003e64:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e66:	00054703          	lbu	a4,0(a0)
    80003e6a:	02f00793          	li	a5,47
    80003e6e:	02f70363          	beq	a4,a5,80003e94 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e72:	ffffe097          	auipc	ra,0xffffe
    80003e76:	b3a080e7          	jalr	-1222(ra) # 800019ac <myproc>
    80003e7a:	15053503          	ld	a0,336(a0)
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	9f6080e7          	jalr	-1546(ra) # 80003874 <idup>
    80003e86:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e88:	02f00913          	li	s2,47
  len = path - s;
    80003e8c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e8e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e90:	4b85                	li	s7,1
    80003e92:	a865                	j	80003f4a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e94:	4585                	li	a1,1
    80003e96:	4505                	li	a0,1
    80003e98:	fffff097          	auipc	ra,0xfffff
    80003e9c:	6e2080e7          	jalr	1762(ra) # 8000357a <iget>
    80003ea0:	89aa                	mv	s3,a0
    80003ea2:	b7dd                	j	80003e88 <namex+0x42>
      iunlockput(ip);
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	c6e080e7          	jalr	-914(ra) # 80003b14 <iunlockput>
      return 0;
    80003eae:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eb0:	854e                	mv	a0,s3
    80003eb2:	60e6                	ld	ra,88(sp)
    80003eb4:	6446                	ld	s0,80(sp)
    80003eb6:	64a6                	ld	s1,72(sp)
    80003eb8:	6906                	ld	s2,64(sp)
    80003eba:	79e2                	ld	s3,56(sp)
    80003ebc:	7a42                	ld	s4,48(sp)
    80003ebe:	7aa2                	ld	s5,40(sp)
    80003ec0:	7b02                	ld	s6,32(sp)
    80003ec2:	6be2                	ld	s7,24(sp)
    80003ec4:	6c42                	ld	s8,16(sp)
    80003ec6:	6ca2                	ld	s9,8(sp)
    80003ec8:	6125                	addi	sp,sp,96
    80003eca:	8082                	ret
      iunlock(ip);
    80003ecc:	854e                	mv	a0,s3
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	aa6080e7          	jalr	-1370(ra) # 80003974 <iunlock>
      return ip;
    80003ed6:	bfe9                	j	80003eb0 <namex+0x6a>
      iunlockput(ip);
    80003ed8:	854e                	mv	a0,s3
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	c3a080e7          	jalr	-966(ra) # 80003b14 <iunlockput>
      return 0;
    80003ee2:	89e6                	mv	s3,s9
    80003ee4:	b7f1                	j	80003eb0 <namex+0x6a>
  len = path - s;
    80003ee6:	40b48633          	sub	a2,s1,a1
    80003eea:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003eee:	099c5463          	bge	s8,s9,80003f76 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ef2:	4639                	li	a2,14
    80003ef4:	8552                	mv	a0,s4
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	e38080e7          	jalr	-456(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003efe:	0004c783          	lbu	a5,0(s1)
    80003f02:	01279763          	bne	a5,s2,80003f10 <namex+0xca>
    path++;
    80003f06:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f08:	0004c783          	lbu	a5,0(s1)
    80003f0c:	ff278de3          	beq	a5,s2,80003f06 <namex+0xc0>
    ilock(ip);
    80003f10:	854e                	mv	a0,s3
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	9a0080e7          	jalr	-1632(ra) # 800038b2 <ilock>
    if(ip->type != T_DIR){
    80003f1a:	04499783          	lh	a5,68(s3)
    80003f1e:	f97793e3          	bne	a5,s7,80003ea4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f22:	000a8563          	beqz	s5,80003f2c <namex+0xe6>
    80003f26:	0004c783          	lbu	a5,0(s1)
    80003f2a:	d3cd                	beqz	a5,80003ecc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f2c:	865a                	mv	a2,s6
    80003f2e:	85d2                	mv	a1,s4
    80003f30:	854e                	mv	a0,s3
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	e64080e7          	jalr	-412(ra) # 80003d96 <dirlookup>
    80003f3a:	8caa                	mv	s9,a0
    80003f3c:	dd51                	beqz	a0,80003ed8 <namex+0x92>
    iunlockput(ip);
    80003f3e:	854e                	mv	a0,s3
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	bd4080e7          	jalr	-1068(ra) # 80003b14 <iunlockput>
    ip = next;
    80003f48:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f4a:	0004c783          	lbu	a5,0(s1)
    80003f4e:	05279763          	bne	a5,s2,80003f9c <namex+0x156>
    path++;
    80003f52:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f54:	0004c783          	lbu	a5,0(s1)
    80003f58:	ff278de3          	beq	a5,s2,80003f52 <namex+0x10c>
  if(*path == 0)
    80003f5c:	c79d                	beqz	a5,80003f8a <namex+0x144>
    path++;
    80003f5e:	85a6                	mv	a1,s1
  len = path - s;
    80003f60:	8cda                	mv	s9,s6
    80003f62:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f64:	01278963          	beq	a5,s2,80003f76 <namex+0x130>
    80003f68:	dfbd                	beqz	a5,80003ee6 <namex+0xa0>
    path++;
    80003f6a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f6c:	0004c783          	lbu	a5,0(s1)
    80003f70:	ff279ce3          	bne	a5,s2,80003f68 <namex+0x122>
    80003f74:	bf8d                	j	80003ee6 <namex+0xa0>
    memmove(name, s, len);
    80003f76:	2601                	sext.w	a2,a2
    80003f78:	8552                	mv	a0,s4
    80003f7a:	ffffd097          	auipc	ra,0xffffd
    80003f7e:	db4080e7          	jalr	-588(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003f82:	9cd2                	add	s9,s9,s4
    80003f84:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f88:	bf9d                	j	80003efe <namex+0xb8>
  if(nameiparent){
    80003f8a:	f20a83e3          	beqz	s5,80003eb0 <namex+0x6a>
    iput(ip);
    80003f8e:	854e                	mv	a0,s3
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	adc080e7          	jalr	-1316(ra) # 80003a6c <iput>
    return 0;
    80003f98:	4981                	li	s3,0
    80003f9a:	bf19                	j	80003eb0 <namex+0x6a>
  if(*path == 0)
    80003f9c:	d7fd                	beqz	a5,80003f8a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f9e:	0004c783          	lbu	a5,0(s1)
    80003fa2:	85a6                	mv	a1,s1
    80003fa4:	b7d1                	j	80003f68 <namex+0x122>

0000000080003fa6 <dirlink>:
{
    80003fa6:	7139                	addi	sp,sp,-64
    80003fa8:	fc06                	sd	ra,56(sp)
    80003faa:	f822                	sd	s0,48(sp)
    80003fac:	f426                	sd	s1,40(sp)
    80003fae:	f04a                	sd	s2,32(sp)
    80003fb0:	ec4e                	sd	s3,24(sp)
    80003fb2:	e852                	sd	s4,16(sp)
    80003fb4:	0080                	addi	s0,sp,64
    80003fb6:	892a                	mv	s2,a0
    80003fb8:	8a2e                	mv	s4,a1
    80003fba:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fbc:	4601                	li	a2,0
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	dd8080e7          	jalr	-552(ra) # 80003d96 <dirlookup>
    80003fc6:	e93d                	bnez	a0,8000403c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc8:	04c92483          	lw	s1,76(s2)
    80003fcc:	c49d                	beqz	s1,80003ffa <dirlink+0x54>
    80003fce:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd0:	4741                	li	a4,16
    80003fd2:	86a6                	mv	a3,s1
    80003fd4:	fc040613          	addi	a2,s0,-64
    80003fd8:	4581                	li	a1,0
    80003fda:	854a                	mv	a0,s2
    80003fdc:	00000097          	auipc	ra,0x0
    80003fe0:	b8a080e7          	jalr	-1142(ra) # 80003b66 <readi>
    80003fe4:	47c1                	li	a5,16
    80003fe6:	06f51163          	bne	a0,a5,80004048 <dirlink+0xa2>
    if(de.inum == 0)
    80003fea:	fc045783          	lhu	a5,-64(s0)
    80003fee:	c791                	beqz	a5,80003ffa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff0:	24c1                	addiw	s1,s1,16
    80003ff2:	04c92783          	lw	a5,76(s2)
    80003ff6:	fcf4ede3          	bltu	s1,a5,80003fd0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ffa:	4639                	li	a2,14
    80003ffc:	85d2                	mv	a1,s4
    80003ffe:	fc240513          	addi	a0,s0,-62
    80004002:	ffffd097          	auipc	ra,0xffffd
    80004006:	ddc080e7          	jalr	-548(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000400a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400e:	4741                	li	a4,16
    80004010:	86a6                	mv	a3,s1
    80004012:	fc040613          	addi	a2,s0,-64
    80004016:	4581                	li	a1,0
    80004018:	854a                	mv	a0,s2
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	c44080e7          	jalr	-956(ra) # 80003c5e <writei>
    80004022:	1541                	addi	a0,a0,-16
    80004024:	00a03533          	snez	a0,a0
    80004028:	40a00533          	neg	a0,a0
}
    8000402c:	70e2                	ld	ra,56(sp)
    8000402e:	7442                	ld	s0,48(sp)
    80004030:	74a2                	ld	s1,40(sp)
    80004032:	7902                	ld	s2,32(sp)
    80004034:	69e2                	ld	s3,24(sp)
    80004036:	6a42                	ld	s4,16(sp)
    80004038:	6121                	addi	sp,sp,64
    8000403a:	8082                	ret
    iput(ip);
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	a30080e7          	jalr	-1488(ra) # 80003a6c <iput>
    return -1;
    80004044:	557d                	li	a0,-1
    80004046:	b7dd                	j	8000402c <dirlink+0x86>
      panic("dirlink read");
    80004048:	00004517          	auipc	a0,0x4
    8000404c:	6d050513          	addi	a0,a0,1744 # 80008718 <syscalls+0x1e0>
    80004050:	ffffc097          	auipc	ra,0xffffc
    80004054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>

0000000080004058 <namei>:

struct inode*
namei(char *path)
{
    80004058:	1101                	addi	sp,sp,-32
    8000405a:	ec06                	sd	ra,24(sp)
    8000405c:	e822                	sd	s0,16(sp)
    8000405e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004060:	fe040613          	addi	a2,s0,-32
    80004064:	4581                	li	a1,0
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	de0080e7          	jalr	-544(ra) # 80003e46 <namex>
}
    8000406e:	60e2                	ld	ra,24(sp)
    80004070:	6442                	ld	s0,16(sp)
    80004072:	6105                	addi	sp,sp,32
    80004074:	8082                	ret

0000000080004076 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004076:	1141                	addi	sp,sp,-16
    80004078:	e406                	sd	ra,8(sp)
    8000407a:	e022                	sd	s0,0(sp)
    8000407c:	0800                	addi	s0,sp,16
    8000407e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004080:	4585                	li	a1,1
    80004082:	00000097          	auipc	ra,0x0
    80004086:	dc4080e7          	jalr	-572(ra) # 80003e46 <namex>
}
    8000408a:	60a2                	ld	ra,8(sp)
    8000408c:	6402                	ld	s0,0(sp)
    8000408e:	0141                	addi	sp,sp,16
    80004090:	8082                	ret

0000000080004092 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004092:	1101                	addi	sp,sp,-32
    80004094:	ec06                	sd	ra,24(sp)
    80004096:	e822                	sd	s0,16(sp)
    80004098:	e426                	sd	s1,8(sp)
    8000409a:	e04a                	sd	s2,0(sp)
    8000409c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000409e:	0001d917          	auipc	s2,0x1d
    800040a2:	62290913          	addi	s2,s2,1570 # 800216c0 <log>
    800040a6:	01892583          	lw	a1,24(s2)
    800040aa:	02892503          	lw	a0,40(s2)
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	fea080e7          	jalr	-22(ra) # 80003098 <bread>
    800040b6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040b8:	02c92683          	lw	a3,44(s2)
    800040bc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040be:	02d05763          	blez	a3,800040ec <write_head+0x5a>
    800040c2:	0001d797          	auipc	a5,0x1d
    800040c6:	62e78793          	addi	a5,a5,1582 # 800216f0 <log+0x30>
    800040ca:	05c50713          	addi	a4,a0,92
    800040ce:	36fd                	addiw	a3,a3,-1
    800040d0:	1682                	slli	a3,a3,0x20
    800040d2:	9281                	srli	a3,a3,0x20
    800040d4:	068a                	slli	a3,a3,0x2
    800040d6:	0001d617          	auipc	a2,0x1d
    800040da:	61e60613          	addi	a2,a2,1566 # 800216f4 <log+0x34>
    800040de:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040e0:	4390                	lw	a2,0(a5)
    800040e2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040e4:	0791                	addi	a5,a5,4
    800040e6:	0711                	addi	a4,a4,4
    800040e8:	fed79ce3          	bne	a5,a3,800040e0 <write_head+0x4e>
  }
  bwrite(buf);
    800040ec:	8526                	mv	a0,s1
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	09c080e7          	jalr	156(ra) # 8000318a <bwrite>
  brelse(buf);
    800040f6:	8526                	mv	a0,s1
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	0d0080e7          	jalr	208(ra) # 800031c8 <brelse>
}
    80004100:	60e2                	ld	ra,24(sp)
    80004102:	6442                	ld	s0,16(sp)
    80004104:	64a2                	ld	s1,8(sp)
    80004106:	6902                	ld	s2,0(sp)
    80004108:	6105                	addi	sp,sp,32
    8000410a:	8082                	ret

000000008000410c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410c:	0001d797          	auipc	a5,0x1d
    80004110:	5e07a783          	lw	a5,1504(a5) # 800216ec <log+0x2c>
    80004114:	0af05d63          	blez	a5,800041ce <install_trans+0xc2>
{
    80004118:	7139                	addi	sp,sp,-64
    8000411a:	fc06                	sd	ra,56(sp)
    8000411c:	f822                	sd	s0,48(sp)
    8000411e:	f426                	sd	s1,40(sp)
    80004120:	f04a                	sd	s2,32(sp)
    80004122:	ec4e                	sd	s3,24(sp)
    80004124:	e852                	sd	s4,16(sp)
    80004126:	e456                	sd	s5,8(sp)
    80004128:	e05a                	sd	s6,0(sp)
    8000412a:	0080                	addi	s0,sp,64
    8000412c:	8b2a                	mv	s6,a0
    8000412e:	0001da97          	auipc	s5,0x1d
    80004132:	5c2a8a93          	addi	s5,s5,1474 # 800216f0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004136:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004138:	0001d997          	auipc	s3,0x1d
    8000413c:	58898993          	addi	s3,s3,1416 # 800216c0 <log>
    80004140:	a00d                	j	80004162 <install_trans+0x56>
    brelse(lbuf);
    80004142:	854a                	mv	a0,s2
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	084080e7          	jalr	132(ra) # 800031c8 <brelse>
    brelse(dbuf);
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	07a080e7          	jalr	122(ra) # 800031c8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004156:	2a05                	addiw	s4,s4,1
    80004158:	0a91                	addi	s5,s5,4
    8000415a:	02c9a783          	lw	a5,44(s3)
    8000415e:	04fa5e63          	bge	s4,a5,800041ba <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004162:	0189a583          	lw	a1,24(s3)
    80004166:	014585bb          	addw	a1,a1,s4
    8000416a:	2585                	addiw	a1,a1,1
    8000416c:	0289a503          	lw	a0,40(s3)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	f28080e7          	jalr	-216(ra) # 80003098 <bread>
    80004178:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000417a:	000aa583          	lw	a1,0(s5)
    8000417e:	0289a503          	lw	a0,40(s3)
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	f16080e7          	jalr	-234(ra) # 80003098 <bread>
    8000418a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000418c:	40000613          	li	a2,1024
    80004190:	05890593          	addi	a1,s2,88
    80004194:	05850513          	addi	a0,a0,88
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	b96080e7          	jalr	-1130(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800041a0:	8526                	mv	a0,s1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	fe8080e7          	jalr	-24(ra) # 8000318a <bwrite>
    if(recovering == 0)
    800041aa:	f80b1ce3          	bnez	s6,80004142 <install_trans+0x36>
      bunpin(dbuf);
    800041ae:	8526                	mv	a0,s1
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	0f2080e7          	jalr	242(ra) # 800032a2 <bunpin>
    800041b8:	b769                	j	80004142 <install_trans+0x36>
}
    800041ba:	70e2                	ld	ra,56(sp)
    800041bc:	7442                	ld	s0,48(sp)
    800041be:	74a2                	ld	s1,40(sp)
    800041c0:	7902                	ld	s2,32(sp)
    800041c2:	69e2                	ld	s3,24(sp)
    800041c4:	6a42                	ld	s4,16(sp)
    800041c6:	6aa2                	ld	s5,8(sp)
    800041c8:	6b02                	ld	s6,0(sp)
    800041ca:	6121                	addi	sp,sp,64
    800041cc:	8082                	ret
    800041ce:	8082                	ret

00000000800041d0 <initlog>:
{
    800041d0:	7179                	addi	sp,sp,-48
    800041d2:	f406                	sd	ra,40(sp)
    800041d4:	f022                	sd	s0,32(sp)
    800041d6:	ec26                	sd	s1,24(sp)
    800041d8:	e84a                	sd	s2,16(sp)
    800041da:	e44e                	sd	s3,8(sp)
    800041dc:	1800                	addi	s0,sp,48
    800041de:	892a                	mv	s2,a0
    800041e0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041e2:	0001d497          	auipc	s1,0x1d
    800041e6:	4de48493          	addi	s1,s1,1246 # 800216c0 <log>
    800041ea:	00004597          	auipc	a1,0x4
    800041ee:	53e58593          	addi	a1,a1,1342 # 80008728 <syscalls+0x1f0>
    800041f2:	8526                	mv	a0,s1
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	952080e7          	jalr	-1710(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800041fc:	0149a583          	lw	a1,20(s3)
    80004200:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004202:	0109a783          	lw	a5,16(s3)
    80004206:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004208:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000420c:	854a                	mv	a0,s2
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	e8a080e7          	jalr	-374(ra) # 80003098 <bread>
  log.lh.n = lh->n;
    80004216:	4d34                	lw	a3,88(a0)
    80004218:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000421a:	02d05563          	blez	a3,80004244 <initlog+0x74>
    8000421e:	05c50793          	addi	a5,a0,92
    80004222:	0001d717          	auipc	a4,0x1d
    80004226:	4ce70713          	addi	a4,a4,1230 # 800216f0 <log+0x30>
    8000422a:	36fd                	addiw	a3,a3,-1
    8000422c:	1682                	slli	a3,a3,0x20
    8000422e:	9281                	srli	a3,a3,0x20
    80004230:	068a                	slli	a3,a3,0x2
    80004232:	06050613          	addi	a2,a0,96
    80004236:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004238:	4390                	lw	a2,0(a5)
    8000423a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000423c:	0791                	addi	a5,a5,4
    8000423e:	0711                	addi	a4,a4,4
    80004240:	fed79ce3          	bne	a5,a3,80004238 <initlog+0x68>
  brelse(buf);
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	f84080e7          	jalr	-124(ra) # 800031c8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000424c:	4505                	li	a0,1
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	ebe080e7          	jalr	-322(ra) # 8000410c <install_trans>
  log.lh.n = 0;
    80004256:	0001d797          	auipc	a5,0x1d
    8000425a:	4807ab23          	sw	zero,1174(a5) # 800216ec <log+0x2c>
  write_head(); // clear the log
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	e34080e7          	jalr	-460(ra) # 80004092 <write_head>
}
    80004266:	70a2                	ld	ra,40(sp)
    80004268:	7402                	ld	s0,32(sp)
    8000426a:	64e2                	ld	s1,24(sp)
    8000426c:	6942                	ld	s2,16(sp)
    8000426e:	69a2                	ld	s3,8(sp)
    80004270:	6145                	addi	sp,sp,48
    80004272:	8082                	ret

0000000080004274 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004274:	1101                	addi	sp,sp,-32
    80004276:	ec06                	sd	ra,24(sp)
    80004278:	e822                	sd	s0,16(sp)
    8000427a:	e426                	sd	s1,8(sp)
    8000427c:	e04a                	sd	s2,0(sp)
    8000427e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004280:	0001d517          	auipc	a0,0x1d
    80004284:	44050513          	addi	a0,a0,1088 # 800216c0 <log>
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	94e080e7          	jalr	-1714(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004290:	0001d497          	auipc	s1,0x1d
    80004294:	43048493          	addi	s1,s1,1072 # 800216c0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004298:	4979                	li	s2,30
    8000429a:	a039                	j	800042a8 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000429c:	85a6                	mv	a1,s1
    8000429e:	8526                	mv	a0,s1
    800042a0:	ffffe097          	auipc	ra,0xffffe
    800042a4:	e6e080e7          	jalr	-402(ra) # 8000210e <sleep>
    if(log.committing){
    800042a8:	50dc                	lw	a5,36(s1)
    800042aa:	fbed                	bnez	a5,8000429c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ac:	509c                	lw	a5,32(s1)
    800042ae:	0017871b          	addiw	a4,a5,1
    800042b2:	0007069b          	sext.w	a3,a4
    800042b6:	0027179b          	slliw	a5,a4,0x2
    800042ba:	9fb9                	addw	a5,a5,a4
    800042bc:	0017979b          	slliw	a5,a5,0x1
    800042c0:	54d8                	lw	a4,44(s1)
    800042c2:	9fb9                	addw	a5,a5,a4
    800042c4:	00f95963          	bge	s2,a5,800042d6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042c8:	85a6                	mv	a1,s1
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffe097          	auipc	ra,0xffffe
    800042d0:	e42080e7          	jalr	-446(ra) # 8000210e <sleep>
    800042d4:	bfd1                	j	800042a8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042d6:	0001d517          	auipc	a0,0x1d
    800042da:	3ea50513          	addi	a0,a0,1002 # 800216c0 <log>
    800042de:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	9aa080e7          	jalr	-1622(ra) # 80000c8a <release>
      break;
    }
  }
}
    800042e8:	60e2                	ld	ra,24(sp)
    800042ea:	6442                	ld	s0,16(sp)
    800042ec:	64a2                	ld	s1,8(sp)
    800042ee:	6902                	ld	s2,0(sp)
    800042f0:	6105                	addi	sp,sp,32
    800042f2:	8082                	ret

00000000800042f4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042f4:	7139                	addi	sp,sp,-64
    800042f6:	fc06                	sd	ra,56(sp)
    800042f8:	f822                	sd	s0,48(sp)
    800042fa:	f426                	sd	s1,40(sp)
    800042fc:	f04a                	sd	s2,32(sp)
    800042fe:	ec4e                	sd	s3,24(sp)
    80004300:	e852                	sd	s4,16(sp)
    80004302:	e456                	sd	s5,8(sp)
    80004304:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004306:	0001d497          	auipc	s1,0x1d
    8000430a:	3ba48493          	addi	s1,s1,954 # 800216c0 <log>
    8000430e:	8526                	mv	a0,s1
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	8c6080e7          	jalr	-1850(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004318:	509c                	lw	a5,32(s1)
    8000431a:	37fd                	addiw	a5,a5,-1
    8000431c:	0007891b          	sext.w	s2,a5
    80004320:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004322:	50dc                	lw	a5,36(s1)
    80004324:	e7b9                	bnez	a5,80004372 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004326:	04091e63          	bnez	s2,80004382 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000432a:	0001d497          	auipc	s1,0x1d
    8000432e:	39648493          	addi	s1,s1,918 # 800216c0 <log>
    80004332:	4785                	li	a5,1
    80004334:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004336:	8526                	mv	a0,s1
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004340:	54dc                	lw	a5,44(s1)
    80004342:	06f04763          	bgtz	a5,800043b0 <end_op+0xbc>
    acquire(&log.lock);
    80004346:	0001d497          	auipc	s1,0x1d
    8000434a:	37a48493          	addi	s1,s1,890 # 800216c0 <log>
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	886080e7          	jalr	-1914(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004358:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000435c:	8526                	mv	a0,s1
    8000435e:	ffffe097          	auipc	ra,0xffffe
    80004362:	e14080e7          	jalr	-492(ra) # 80002172 <wakeup>
    release(&log.lock);
    80004366:	8526                	mv	a0,s1
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	922080e7          	jalr	-1758(ra) # 80000c8a <release>
}
    80004370:	a03d                	j	8000439e <end_op+0xaa>
    panic("log.committing");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	3be50513          	addi	a0,a0,958 # 80008730 <syscalls+0x1f8>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1c4080e7          	jalr	452(ra) # 8000053e <panic>
    wakeup(&log);
    80004382:	0001d497          	auipc	s1,0x1d
    80004386:	33e48493          	addi	s1,s1,830 # 800216c0 <log>
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffe097          	auipc	ra,0xffffe
    80004390:	de6080e7          	jalr	-538(ra) # 80002172 <wakeup>
  release(&log.lock);
    80004394:	8526                	mv	a0,s1
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
}
    8000439e:	70e2                	ld	ra,56(sp)
    800043a0:	7442                	ld	s0,48(sp)
    800043a2:	74a2                	ld	s1,40(sp)
    800043a4:	7902                	ld	s2,32(sp)
    800043a6:	69e2                	ld	s3,24(sp)
    800043a8:	6a42                	ld	s4,16(sp)
    800043aa:	6aa2                	ld	s5,8(sp)
    800043ac:	6121                	addi	sp,sp,64
    800043ae:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b0:	0001da97          	auipc	s5,0x1d
    800043b4:	340a8a93          	addi	s5,s5,832 # 800216f0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043b8:	0001da17          	auipc	s4,0x1d
    800043bc:	308a0a13          	addi	s4,s4,776 # 800216c0 <log>
    800043c0:	018a2583          	lw	a1,24(s4)
    800043c4:	012585bb          	addw	a1,a1,s2
    800043c8:	2585                	addiw	a1,a1,1
    800043ca:	028a2503          	lw	a0,40(s4)
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	cca080e7          	jalr	-822(ra) # 80003098 <bread>
    800043d6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043d8:	000aa583          	lw	a1,0(s5)
    800043dc:	028a2503          	lw	a0,40(s4)
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	cb8080e7          	jalr	-840(ra) # 80003098 <bread>
    800043e8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043ea:	40000613          	li	a2,1024
    800043ee:	05850593          	addi	a1,a0,88
    800043f2:	05848513          	addi	a0,s1,88
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	938080e7          	jalr	-1736(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800043fe:	8526                	mv	a0,s1
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	d8a080e7          	jalr	-630(ra) # 8000318a <bwrite>
    brelse(from);
    80004408:	854e                	mv	a0,s3
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	dbe080e7          	jalr	-578(ra) # 800031c8 <brelse>
    brelse(to);
    80004412:	8526                	mv	a0,s1
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	db4080e7          	jalr	-588(ra) # 800031c8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000441c:	2905                	addiw	s2,s2,1
    8000441e:	0a91                	addi	s5,s5,4
    80004420:	02ca2783          	lw	a5,44(s4)
    80004424:	f8f94ee3          	blt	s2,a5,800043c0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	c6a080e7          	jalr	-918(ra) # 80004092 <write_head>
    install_trans(0); // Now install writes to home locations
    80004430:	4501                	li	a0,0
    80004432:	00000097          	auipc	ra,0x0
    80004436:	cda080e7          	jalr	-806(ra) # 8000410c <install_trans>
    log.lh.n = 0;
    8000443a:	0001d797          	auipc	a5,0x1d
    8000443e:	2a07a923          	sw	zero,690(a5) # 800216ec <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004442:	00000097          	auipc	ra,0x0
    80004446:	c50080e7          	jalr	-944(ra) # 80004092 <write_head>
    8000444a:	bdf5                	j	80004346 <end_op+0x52>

000000008000444c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	e04a                	sd	s2,0(sp)
    80004456:	1000                	addi	s0,sp,32
    80004458:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000445a:	0001d917          	auipc	s2,0x1d
    8000445e:	26690913          	addi	s2,s2,614 # 800216c0 <log>
    80004462:	854a                	mv	a0,s2
    80004464:	ffffc097          	auipc	ra,0xffffc
    80004468:	772080e7          	jalr	1906(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000446c:	02c92603          	lw	a2,44(s2)
    80004470:	47f5                	li	a5,29
    80004472:	06c7c563          	blt	a5,a2,800044dc <log_write+0x90>
    80004476:	0001d797          	auipc	a5,0x1d
    8000447a:	2667a783          	lw	a5,614(a5) # 800216dc <log+0x1c>
    8000447e:	37fd                	addiw	a5,a5,-1
    80004480:	04f65e63          	bge	a2,a5,800044dc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004484:	0001d797          	auipc	a5,0x1d
    80004488:	25c7a783          	lw	a5,604(a5) # 800216e0 <log+0x20>
    8000448c:	06f05063          	blez	a5,800044ec <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004490:	4781                	li	a5,0
    80004492:	06c05563          	blez	a2,800044fc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004496:	44cc                	lw	a1,12(s1)
    80004498:	0001d717          	auipc	a4,0x1d
    8000449c:	25870713          	addi	a4,a4,600 # 800216f0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044a0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044a2:	4314                	lw	a3,0(a4)
    800044a4:	04b68c63          	beq	a3,a1,800044fc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044a8:	2785                	addiw	a5,a5,1
    800044aa:	0711                	addi	a4,a4,4
    800044ac:	fef61be3          	bne	a2,a5,800044a2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044b0:	0621                	addi	a2,a2,8
    800044b2:	060a                	slli	a2,a2,0x2
    800044b4:	0001d797          	auipc	a5,0x1d
    800044b8:	20c78793          	addi	a5,a5,524 # 800216c0 <log>
    800044bc:	963e                	add	a2,a2,a5
    800044be:	44dc                	lw	a5,12(s1)
    800044c0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044c2:	8526                	mv	a0,s1
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	da2080e7          	jalr	-606(ra) # 80003266 <bpin>
    log.lh.n++;
    800044cc:	0001d717          	auipc	a4,0x1d
    800044d0:	1f470713          	addi	a4,a4,500 # 800216c0 <log>
    800044d4:	575c                	lw	a5,44(a4)
    800044d6:	2785                	addiw	a5,a5,1
    800044d8:	d75c                	sw	a5,44(a4)
    800044da:	a835                	j	80004516 <log_write+0xca>
    panic("too big a transaction");
    800044dc:	00004517          	auipc	a0,0x4
    800044e0:	26450513          	addi	a0,a0,612 # 80008740 <syscalls+0x208>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044ec:	00004517          	auipc	a0,0x4
    800044f0:	26c50513          	addi	a0,a0,620 # 80008758 <syscalls+0x220>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	04a080e7          	jalr	74(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044fc:	00878713          	addi	a4,a5,8
    80004500:	00271693          	slli	a3,a4,0x2
    80004504:	0001d717          	auipc	a4,0x1d
    80004508:	1bc70713          	addi	a4,a4,444 # 800216c0 <log>
    8000450c:	9736                	add	a4,a4,a3
    8000450e:	44d4                	lw	a3,12(s1)
    80004510:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004512:	faf608e3          	beq	a2,a5,800044c2 <log_write+0x76>
  }
  release(&log.lock);
    80004516:	0001d517          	auipc	a0,0x1d
    8000451a:	1aa50513          	addi	a0,a0,426 # 800216c0 <log>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	76c080e7          	jalr	1900(ra) # 80000c8a <release>
}
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6902                	ld	s2,0(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
    8000453e:	84aa                	mv	s1,a0
    80004540:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004542:	00004597          	auipc	a1,0x4
    80004546:	23658593          	addi	a1,a1,566 # 80008778 <syscalls+0x240>
    8000454a:	0521                	addi	a0,a0,8
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	5fa080e7          	jalr	1530(ra) # 80000b46 <initlock>
  lk->name = name;
    80004554:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004558:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000455c:	0204a423          	sw	zero,40(s1)
}
    80004560:	60e2                	ld	ra,24(sp)
    80004562:	6442                	ld	s0,16(sp)
    80004564:	64a2                	ld	s1,8(sp)
    80004566:	6902                	ld	s2,0(sp)
    80004568:	6105                	addi	sp,sp,32
    8000456a:	8082                	ret

000000008000456c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000456c:	1101                	addi	sp,sp,-32
    8000456e:	ec06                	sd	ra,24(sp)
    80004570:	e822                	sd	s0,16(sp)
    80004572:	e426                	sd	s1,8(sp)
    80004574:	e04a                	sd	s2,0(sp)
    80004576:	1000                	addi	s0,sp,32
    80004578:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000457a:	00850913          	addi	s2,a0,8
    8000457e:	854a                	mv	a0,s2
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	656080e7          	jalr	1622(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004588:	409c                	lw	a5,0(s1)
    8000458a:	cb89                	beqz	a5,8000459c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000458c:	85ca                	mv	a1,s2
    8000458e:	8526                	mv	a0,s1
    80004590:	ffffe097          	auipc	ra,0xffffe
    80004594:	b7e080e7          	jalr	-1154(ra) # 8000210e <sleep>
  while (lk->locked) {
    80004598:	409c                	lw	a5,0(s1)
    8000459a:	fbed                	bnez	a5,8000458c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000459c:	4785                	li	a5,1
    8000459e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045a0:	ffffd097          	auipc	ra,0xffffd
    800045a4:	40c080e7          	jalr	1036(ra) # 800019ac <myproc>
    800045a8:	591c                	lw	a5,48(a0)
    800045aa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045ac:	854a                	mv	a0,s2
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6dc080e7          	jalr	1756(ra) # 80000c8a <release>
}
    800045b6:	60e2                	ld	ra,24(sp)
    800045b8:	6442                	ld	s0,16(sp)
    800045ba:	64a2                	ld	s1,8(sp)
    800045bc:	6902                	ld	s2,0(sp)
    800045be:	6105                	addi	sp,sp,32
    800045c0:	8082                	ret

00000000800045c2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045c2:	1101                	addi	sp,sp,-32
    800045c4:	ec06                	sd	ra,24(sp)
    800045c6:	e822                	sd	s0,16(sp)
    800045c8:	e426                	sd	s1,8(sp)
    800045ca:	e04a                	sd	s2,0(sp)
    800045cc:	1000                	addi	s0,sp,32
    800045ce:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d0:	00850913          	addi	s2,a0,8
    800045d4:	854a                	mv	a0,s2
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	600080e7          	jalr	1536(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800045de:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045e6:	8526                	mv	a0,s1
    800045e8:	ffffe097          	auipc	ra,0xffffe
    800045ec:	b8a080e7          	jalr	-1142(ra) # 80002172 <wakeup>
  release(&lk->lk);
    800045f0:	854a                	mv	a0,s2
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	698080e7          	jalr	1688(ra) # 80000c8a <release>
}
    800045fa:	60e2                	ld	ra,24(sp)
    800045fc:	6442                	ld	s0,16(sp)
    800045fe:	64a2                	ld	s1,8(sp)
    80004600:	6902                	ld	s2,0(sp)
    80004602:	6105                	addi	sp,sp,32
    80004604:	8082                	ret

0000000080004606 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004606:	7179                	addi	sp,sp,-48
    80004608:	f406                	sd	ra,40(sp)
    8000460a:	f022                	sd	s0,32(sp)
    8000460c:	ec26                	sd	s1,24(sp)
    8000460e:	e84a                	sd	s2,16(sp)
    80004610:	e44e                	sd	s3,8(sp)
    80004612:	1800                	addi	s0,sp,48
    80004614:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004616:	00850913          	addi	s2,a0,8
    8000461a:	854a                	mv	a0,s2
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	5ba080e7          	jalr	1466(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004624:	409c                	lw	a5,0(s1)
    80004626:	ef99                	bnez	a5,80004644 <holdingsleep+0x3e>
    80004628:	4481                	li	s1,0
  release(&lk->lk);
    8000462a:	854a                	mv	a0,s2
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	65e080e7          	jalr	1630(ra) # 80000c8a <release>
  return r;
}
    80004634:	8526                	mv	a0,s1
    80004636:	70a2                	ld	ra,40(sp)
    80004638:	7402                	ld	s0,32(sp)
    8000463a:	64e2                	ld	s1,24(sp)
    8000463c:	6942                	ld	s2,16(sp)
    8000463e:	69a2                	ld	s3,8(sp)
    80004640:	6145                	addi	sp,sp,48
    80004642:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004644:	0284a983          	lw	s3,40(s1)
    80004648:	ffffd097          	auipc	ra,0xffffd
    8000464c:	364080e7          	jalr	868(ra) # 800019ac <myproc>
    80004650:	5904                	lw	s1,48(a0)
    80004652:	413484b3          	sub	s1,s1,s3
    80004656:	0014b493          	seqz	s1,s1
    8000465a:	bfc1                	j	8000462a <holdingsleep+0x24>

000000008000465c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000465c:	1141                	addi	sp,sp,-16
    8000465e:	e406                	sd	ra,8(sp)
    80004660:	e022                	sd	s0,0(sp)
    80004662:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004664:	00004597          	auipc	a1,0x4
    80004668:	12458593          	addi	a1,a1,292 # 80008788 <syscalls+0x250>
    8000466c:	0001d517          	auipc	a0,0x1d
    80004670:	19c50513          	addi	a0,a0,412 # 80021808 <ftable>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	4d2080e7          	jalr	1234(ra) # 80000b46 <initlock>
}
    8000467c:	60a2                	ld	ra,8(sp)
    8000467e:	6402                	ld	s0,0(sp)
    80004680:	0141                	addi	sp,sp,16
    80004682:	8082                	ret

0000000080004684 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004684:	1101                	addi	sp,sp,-32
    80004686:	ec06                	sd	ra,24(sp)
    80004688:	e822                	sd	s0,16(sp)
    8000468a:	e426                	sd	s1,8(sp)
    8000468c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000468e:	0001d517          	auipc	a0,0x1d
    80004692:	17a50513          	addi	a0,a0,378 # 80021808 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	540080e7          	jalr	1344(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000469e:	0001d497          	auipc	s1,0x1d
    800046a2:	18248493          	addi	s1,s1,386 # 80021820 <ftable+0x18>
    800046a6:	0001e717          	auipc	a4,0x1e
    800046aa:	11a70713          	addi	a4,a4,282 # 800227c0 <disk>
    if(f->ref == 0){
    800046ae:	40dc                	lw	a5,4(s1)
    800046b0:	cf99                	beqz	a5,800046ce <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b2:	02848493          	addi	s1,s1,40
    800046b6:	fee49ce3          	bne	s1,a4,800046ae <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046ba:	0001d517          	auipc	a0,0x1d
    800046be:	14e50513          	addi	a0,a0,334 # 80021808 <ftable>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5c8080e7          	jalr	1480(ra) # 80000c8a <release>
  return 0;
    800046ca:	4481                	li	s1,0
    800046cc:	a819                	j	800046e2 <filealloc+0x5e>
      f->ref = 1;
    800046ce:	4785                	li	a5,1
    800046d0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046d2:	0001d517          	auipc	a0,0x1d
    800046d6:	13650513          	addi	a0,a0,310 # 80021808 <ftable>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	5b0080e7          	jalr	1456(ra) # 80000c8a <release>
}
    800046e2:	8526                	mv	a0,s1
    800046e4:	60e2                	ld	ra,24(sp)
    800046e6:	6442                	ld	s0,16(sp)
    800046e8:	64a2                	ld	s1,8(sp)
    800046ea:	6105                	addi	sp,sp,32
    800046ec:	8082                	ret

00000000800046ee <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046ee:	1101                	addi	sp,sp,-32
    800046f0:	ec06                	sd	ra,24(sp)
    800046f2:	e822                	sd	s0,16(sp)
    800046f4:	e426                	sd	s1,8(sp)
    800046f6:	1000                	addi	s0,sp,32
    800046f8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046fa:	0001d517          	auipc	a0,0x1d
    800046fe:	10e50513          	addi	a0,a0,270 # 80021808 <ftable>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4d4080e7          	jalr	1236(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000470a:	40dc                	lw	a5,4(s1)
    8000470c:	02f05263          	blez	a5,80004730 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004710:	2785                	addiw	a5,a5,1
    80004712:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004714:	0001d517          	auipc	a0,0x1d
    80004718:	0f450513          	addi	a0,a0,244 # 80021808 <ftable>
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	56e080e7          	jalr	1390(ra) # 80000c8a <release>
  return f;
}
    80004724:	8526                	mv	a0,s1
    80004726:	60e2                	ld	ra,24(sp)
    80004728:	6442                	ld	s0,16(sp)
    8000472a:	64a2                	ld	s1,8(sp)
    8000472c:	6105                	addi	sp,sp,32
    8000472e:	8082                	ret
    panic("filedup");
    80004730:	00004517          	auipc	a0,0x4
    80004734:	06050513          	addi	a0,a0,96 # 80008790 <syscalls+0x258>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	e06080e7          	jalr	-506(ra) # 8000053e <panic>

0000000080004740 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004740:	7139                	addi	sp,sp,-64
    80004742:	fc06                	sd	ra,56(sp)
    80004744:	f822                	sd	s0,48(sp)
    80004746:	f426                	sd	s1,40(sp)
    80004748:	f04a                	sd	s2,32(sp)
    8000474a:	ec4e                	sd	s3,24(sp)
    8000474c:	e852                	sd	s4,16(sp)
    8000474e:	e456                	sd	s5,8(sp)
    80004750:	0080                	addi	s0,sp,64
    80004752:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004754:	0001d517          	auipc	a0,0x1d
    80004758:	0b450513          	addi	a0,a0,180 # 80021808 <ftable>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	47a080e7          	jalr	1146(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004764:	40dc                	lw	a5,4(s1)
    80004766:	06f05163          	blez	a5,800047c8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000476a:	37fd                	addiw	a5,a5,-1
    8000476c:	0007871b          	sext.w	a4,a5
    80004770:	c0dc                	sw	a5,4(s1)
    80004772:	06e04363          	bgtz	a4,800047d8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004776:	0004a903          	lw	s2,0(s1)
    8000477a:	0094ca83          	lbu	s5,9(s1)
    8000477e:	0104ba03          	ld	s4,16(s1)
    80004782:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004786:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000478a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000478e:	0001d517          	auipc	a0,0x1d
    80004792:	07a50513          	addi	a0,a0,122 # 80021808 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	4f4080e7          	jalr	1268(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000479e:	4785                	li	a5,1
    800047a0:	04f90d63          	beq	s2,a5,800047fa <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047a4:	3979                	addiw	s2,s2,-2
    800047a6:	4785                	li	a5,1
    800047a8:	0527e063          	bltu	a5,s2,800047e8 <fileclose+0xa8>
    begin_op();
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	ac8080e7          	jalr	-1336(ra) # 80004274 <begin_op>
    iput(ff.ip);
    800047b4:	854e                	mv	a0,s3
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	2b6080e7          	jalr	694(ra) # 80003a6c <iput>
    end_op();
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	b36080e7          	jalr	-1226(ra) # 800042f4 <end_op>
    800047c6:	a00d                	j	800047e8 <fileclose+0xa8>
    panic("fileclose");
    800047c8:	00004517          	auipc	a0,0x4
    800047cc:	fd050513          	addi	a0,a0,-48 # 80008798 <syscalls+0x260>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	d6e080e7          	jalr	-658(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047d8:	0001d517          	auipc	a0,0x1d
    800047dc:	03050513          	addi	a0,a0,48 # 80021808 <ftable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	4aa080e7          	jalr	1194(ra) # 80000c8a <release>
  }
}
    800047e8:	70e2                	ld	ra,56(sp)
    800047ea:	7442                	ld	s0,48(sp)
    800047ec:	74a2                	ld	s1,40(sp)
    800047ee:	7902                	ld	s2,32(sp)
    800047f0:	69e2                	ld	s3,24(sp)
    800047f2:	6a42                	ld	s4,16(sp)
    800047f4:	6aa2                	ld	s5,8(sp)
    800047f6:	6121                	addi	sp,sp,64
    800047f8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047fa:	85d6                	mv	a1,s5
    800047fc:	8552                	mv	a0,s4
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	34c080e7          	jalr	844(ra) # 80004b4a <pipeclose>
    80004806:	b7cd                	j	800047e8 <fileclose+0xa8>

0000000080004808 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004808:	715d                	addi	sp,sp,-80
    8000480a:	e486                	sd	ra,72(sp)
    8000480c:	e0a2                	sd	s0,64(sp)
    8000480e:	fc26                	sd	s1,56(sp)
    80004810:	f84a                	sd	s2,48(sp)
    80004812:	f44e                	sd	s3,40(sp)
    80004814:	0880                	addi	s0,sp,80
    80004816:	84aa                	mv	s1,a0
    80004818:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000481a:	ffffd097          	auipc	ra,0xffffd
    8000481e:	192080e7          	jalr	402(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004822:	409c                	lw	a5,0(s1)
    80004824:	37f9                	addiw	a5,a5,-2
    80004826:	4705                	li	a4,1
    80004828:	04f76763          	bltu	a4,a5,80004876 <filestat+0x6e>
    8000482c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000482e:	6c88                	ld	a0,24(s1)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	082080e7          	jalr	130(ra) # 800038b2 <ilock>
    stati(f->ip, &st);
    80004838:	fb840593          	addi	a1,s0,-72
    8000483c:	6c88                	ld	a0,24(s1)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	2fe080e7          	jalr	766(ra) # 80003b3c <stati>
    iunlock(f->ip);
    80004846:	6c88                	ld	a0,24(s1)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	12c080e7          	jalr	300(ra) # 80003974 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004850:	46e1                	li	a3,24
    80004852:	fb840613          	addi	a2,s0,-72
    80004856:	85ce                	mv	a1,s3
    80004858:	05093503          	ld	a0,80(s2)
    8000485c:	ffffd097          	auipc	ra,0xffffd
    80004860:	e0c080e7          	jalr	-500(ra) # 80001668 <copyout>
    80004864:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004868:	60a6                	ld	ra,72(sp)
    8000486a:	6406                	ld	s0,64(sp)
    8000486c:	74e2                	ld	s1,56(sp)
    8000486e:	7942                	ld	s2,48(sp)
    80004870:	79a2                	ld	s3,40(sp)
    80004872:	6161                	addi	sp,sp,80
    80004874:	8082                	ret
  return -1;
    80004876:	557d                	li	a0,-1
    80004878:	bfc5                	j	80004868 <filestat+0x60>

000000008000487a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000487a:	7179                	addi	sp,sp,-48
    8000487c:	f406                	sd	ra,40(sp)
    8000487e:	f022                	sd	s0,32(sp)
    80004880:	ec26                	sd	s1,24(sp)
    80004882:	e84a                	sd	s2,16(sp)
    80004884:	e44e                	sd	s3,8(sp)
    80004886:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004888:	00854783          	lbu	a5,8(a0)
    8000488c:	c3d5                	beqz	a5,80004930 <fileread+0xb6>
    8000488e:	84aa                	mv	s1,a0
    80004890:	89ae                	mv	s3,a1
    80004892:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004894:	411c                	lw	a5,0(a0)
    80004896:	4705                	li	a4,1
    80004898:	04e78963          	beq	a5,a4,800048ea <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000489c:	470d                	li	a4,3
    8000489e:	04e78d63          	beq	a5,a4,800048f8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a2:	4709                	li	a4,2
    800048a4:	06e79e63          	bne	a5,a4,80004920 <fileread+0xa6>
    ilock(f->ip);
    800048a8:	6d08                	ld	a0,24(a0)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	008080e7          	jalr	8(ra) # 800038b2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048b2:	874a                	mv	a4,s2
    800048b4:	5094                	lw	a3,32(s1)
    800048b6:	864e                	mv	a2,s3
    800048b8:	4585                	li	a1,1
    800048ba:	6c88                	ld	a0,24(s1)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	2aa080e7          	jalr	682(ra) # 80003b66 <readi>
    800048c4:	892a                	mv	s2,a0
    800048c6:	00a05563          	blez	a0,800048d0 <fileread+0x56>
      f->off += r;
    800048ca:	509c                	lw	a5,32(s1)
    800048cc:	9fa9                	addw	a5,a5,a0
    800048ce:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048d0:	6c88                	ld	a0,24(s1)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	0a2080e7          	jalr	162(ra) # 80003974 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048da:	854a                	mv	a0,s2
    800048dc:	70a2                	ld	ra,40(sp)
    800048de:	7402                	ld	s0,32(sp)
    800048e0:	64e2                	ld	s1,24(sp)
    800048e2:	6942                	ld	s2,16(sp)
    800048e4:	69a2                	ld	s3,8(sp)
    800048e6:	6145                	addi	sp,sp,48
    800048e8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048ea:	6908                	ld	a0,16(a0)
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	3c6080e7          	jalr	966(ra) # 80004cb2 <piperead>
    800048f4:	892a                	mv	s2,a0
    800048f6:	b7d5                	j	800048da <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048f8:	02451783          	lh	a5,36(a0)
    800048fc:	03079693          	slli	a3,a5,0x30
    80004900:	92c1                	srli	a3,a3,0x30
    80004902:	4725                	li	a4,9
    80004904:	02d76863          	bltu	a4,a3,80004934 <fileread+0xba>
    80004908:	0792                	slli	a5,a5,0x4
    8000490a:	0001d717          	auipc	a4,0x1d
    8000490e:	e5e70713          	addi	a4,a4,-418 # 80021768 <devsw>
    80004912:	97ba                	add	a5,a5,a4
    80004914:	639c                	ld	a5,0(a5)
    80004916:	c38d                	beqz	a5,80004938 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004918:	4505                	li	a0,1
    8000491a:	9782                	jalr	a5
    8000491c:	892a                	mv	s2,a0
    8000491e:	bf75                	j	800048da <fileread+0x60>
    panic("fileread");
    80004920:	00004517          	auipc	a0,0x4
    80004924:	e8850513          	addi	a0,a0,-376 # 800087a8 <syscalls+0x270>
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	c16080e7          	jalr	-1002(ra) # 8000053e <panic>
    return -1;
    80004930:	597d                	li	s2,-1
    80004932:	b765                	j	800048da <fileread+0x60>
      return -1;
    80004934:	597d                	li	s2,-1
    80004936:	b755                	j	800048da <fileread+0x60>
    80004938:	597d                	li	s2,-1
    8000493a:	b745                	j	800048da <fileread+0x60>

000000008000493c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000493c:	715d                	addi	sp,sp,-80
    8000493e:	e486                	sd	ra,72(sp)
    80004940:	e0a2                	sd	s0,64(sp)
    80004942:	fc26                	sd	s1,56(sp)
    80004944:	f84a                	sd	s2,48(sp)
    80004946:	f44e                	sd	s3,40(sp)
    80004948:	f052                	sd	s4,32(sp)
    8000494a:	ec56                	sd	s5,24(sp)
    8000494c:	e85a                	sd	s6,16(sp)
    8000494e:	e45e                	sd	s7,8(sp)
    80004950:	e062                	sd	s8,0(sp)
    80004952:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004954:	00954783          	lbu	a5,9(a0)
    80004958:	10078663          	beqz	a5,80004a64 <filewrite+0x128>
    8000495c:	892a                	mv	s2,a0
    8000495e:	8aae                	mv	s5,a1
    80004960:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004962:	411c                	lw	a5,0(a0)
    80004964:	4705                	li	a4,1
    80004966:	02e78263          	beq	a5,a4,8000498a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000496a:	470d                	li	a4,3
    8000496c:	02e78663          	beq	a5,a4,80004998 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004970:	4709                	li	a4,2
    80004972:	0ee79163          	bne	a5,a4,80004a54 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004976:	0ac05d63          	blez	a2,80004a30 <filewrite+0xf4>
    int i = 0;
    8000497a:	4981                	li	s3,0
    8000497c:	6b05                	lui	s6,0x1
    8000497e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004982:	6b85                	lui	s7,0x1
    80004984:	c00b8b9b          	addiw	s7,s7,-1024
    80004988:	a861                	j	80004a20 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000498a:	6908                	ld	a0,16(a0)
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	22e080e7          	jalr	558(ra) # 80004bba <pipewrite>
    80004994:	8a2a                	mv	s4,a0
    80004996:	a045                	j	80004a36 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004998:	02451783          	lh	a5,36(a0)
    8000499c:	03079693          	slli	a3,a5,0x30
    800049a0:	92c1                	srli	a3,a3,0x30
    800049a2:	4725                	li	a4,9
    800049a4:	0cd76263          	bltu	a4,a3,80004a68 <filewrite+0x12c>
    800049a8:	0792                	slli	a5,a5,0x4
    800049aa:	0001d717          	auipc	a4,0x1d
    800049ae:	dbe70713          	addi	a4,a4,-578 # 80021768 <devsw>
    800049b2:	97ba                	add	a5,a5,a4
    800049b4:	679c                	ld	a5,8(a5)
    800049b6:	cbdd                	beqz	a5,80004a6c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049b8:	4505                	li	a0,1
    800049ba:	9782                	jalr	a5
    800049bc:	8a2a                	mv	s4,a0
    800049be:	a8a5                	j	80004a36 <filewrite+0xfa>
    800049c0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	8b0080e7          	jalr	-1872(ra) # 80004274 <begin_op>
      ilock(f->ip);
    800049cc:	01893503          	ld	a0,24(s2)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	ee2080e7          	jalr	-286(ra) # 800038b2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049d8:	8762                	mv	a4,s8
    800049da:	02092683          	lw	a3,32(s2)
    800049de:	01598633          	add	a2,s3,s5
    800049e2:	4585                	li	a1,1
    800049e4:	01893503          	ld	a0,24(s2)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	276080e7          	jalr	630(ra) # 80003c5e <writei>
    800049f0:	84aa                	mv	s1,a0
    800049f2:	00a05763          	blez	a0,80004a00 <filewrite+0xc4>
        f->off += r;
    800049f6:	02092783          	lw	a5,32(s2)
    800049fa:	9fa9                	addw	a5,a5,a0
    800049fc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a00:	01893503          	ld	a0,24(s2)
    80004a04:	fffff097          	auipc	ra,0xfffff
    80004a08:	f70080e7          	jalr	-144(ra) # 80003974 <iunlock>
      end_op();
    80004a0c:	00000097          	auipc	ra,0x0
    80004a10:	8e8080e7          	jalr	-1816(ra) # 800042f4 <end_op>

      if(r != n1){
    80004a14:	009c1f63          	bne	s8,s1,80004a32 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a18:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a1c:	0149db63          	bge	s3,s4,80004a32 <filewrite+0xf6>
      int n1 = n - i;
    80004a20:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a24:	84be                	mv	s1,a5
    80004a26:	2781                	sext.w	a5,a5
    80004a28:	f8fb5ce3          	bge	s6,a5,800049c0 <filewrite+0x84>
    80004a2c:	84de                	mv	s1,s7
    80004a2e:	bf49                	j	800049c0 <filewrite+0x84>
    int i = 0;
    80004a30:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a32:	013a1f63          	bne	s4,s3,80004a50 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a36:	8552                	mv	a0,s4
    80004a38:	60a6                	ld	ra,72(sp)
    80004a3a:	6406                	ld	s0,64(sp)
    80004a3c:	74e2                	ld	s1,56(sp)
    80004a3e:	7942                	ld	s2,48(sp)
    80004a40:	79a2                	ld	s3,40(sp)
    80004a42:	7a02                	ld	s4,32(sp)
    80004a44:	6ae2                	ld	s5,24(sp)
    80004a46:	6b42                	ld	s6,16(sp)
    80004a48:	6ba2                	ld	s7,8(sp)
    80004a4a:	6c02                	ld	s8,0(sp)
    80004a4c:	6161                	addi	sp,sp,80
    80004a4e:	8082                	ret
    ret = (i == n ? n : -1);
    80004a50:	5a7d                	li	s4,-1
    80004a52:	b7d5                	j	80004a36 <filewrite+0xfa>
    panic("filewrite");
    80004a54:	00004517          	auipc	a0,0x4
    80004a58:	d6450513          	addi	a0,a0,-668 # 800087b8 <syscalls+0x280>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
    return -1;
    80004a64:	5a7d                	li	s4,-1
    80004a66:	bfc1                	j	80004a36 <filewrite+0xfa>
      return -1;
    80004a68:	5a7d                	li	s4,-1
    80004a6a:	b7f1                	j	80004a36 <filewrite+0xfa>
    80004a6c:	5a7d                	li	s4,-1
    80004a6e:	b7e1                	j	80004a36 <filewrite+0xfa>

0000000080004a70 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a70:	7179                	addi	sp,sp,-48
    80004a72:	f406                	sd	ra,40(sp)
    80004a74:	f022                	sd	s0,32(sp)
    80004a76:	ec26                	sd	s1,24(sp)
    80004a78:	e84a                	sd	s2,16(sp)
    80004a7a:	e44e                	sd	s3,8(sp)
    80004a7c:	e052                	sd	s4,0(sp)
    80004a7e:	1800                	addi	s0,sp,48
    80004a80:	84aa                	mv	s1,a0
    80004a82:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a84:	0005b023          	sd	zero,0(a1)
    80004a88:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	bf8080e7          	jalr	-1032(ra) # 80004684 <filealloc>
    80004a94:	e088                	sd	a0,0(s1)
    80004a96:	c551                	beqz	a0,80004b22 <pipealloc+0xb2>
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	bec080e7          	jalr	-1044(ra) # 80004684 <filealloc>
    80004aa0:	00aa3023          	sd	a0,0(s4)
    80004aa4:	c92d                	beqz	a0,80004b16 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	040080e7          	jalr	64(ra) # 80000ae6 <kalloc>
    80004aae:	892a                	mv	s2,a0
    80004ab0:	c125                	beqz	a0,80004b10 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ab2:	4985                	li	s3,1
    80004ab4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ab8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004abc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ac0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ac4:	00004597          	auipc	a1,0x4
    80004ac8:	9ac58593          	addi	a1,a1,-1620 # 80008470 <states.0+0x1a0>
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	07a080e7          	jalr	122(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004ad4:	609c                	ld	a5,0(s1)
    80004ad6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ada:	609c                	ld	a5,0(s1)
    80004adc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ae0:	609c                	ld	a5,0(s1)
    80004ae2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ae6:	609c                	ld	a5,0(s1)
    80004ae8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aec:	000a3783          	ld	a5,0(s4)
    80004af0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004af4:	000a3783          	ld	a5,0(s4)
    80004af8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004afc:	000a3783          	ld	a5,0(s4)
    80004b00:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b04:	000a3783          	ld	a5,0(s4)
    80004b08:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b0c:	4501                	li	a0,0
    80004b0e:	a025                	j	80004b36 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b10:	6088                	ld	a0,0(s1)
    80004b12:	e501                	bnez	a0,80004b1a <pipealloc+0xaa>
    80004b14:	a039                	j	80004b22 <pipealloc+0xb2>
    80004b16:	6088                	ld	a0,0(s1)
    80004b18:	c51d                	beqz	a0,80004b46 <pipealloc+0xd6>
    fileclose(*f0);
    80004b1a:	00000097          	auipc	ra,0x0
    80004b1e:	c26080e7          	jalr	-986(ra) # 80004740 <fileclose>
  if(*f1)
    80004b22:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b26:	557d                	li	a0,-1
  if(*f1)
    80004b28:	c799                	beqz	a5,80004b36 <pipealloc+0xc6>
    fileclose(*f1);
    80004b2a:	853e                	mv	a0,a5
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	c14080e7          	jalr	-1004(ra) # 80004740 <fileclose>
  return -1;
    80004b34:	557d                	li	a0,-1
}
    80004b36:	70a2                	ld	ra,40(sp)
    80004b38:	7402                	ld	s0,32(sp)
    80004b3a:	64e2                	ld	s1,24(sp)
    80004b3c:	6942                	ld	s2,16(sp)
    80004b3e:	69a2                	ld	s3,8(sp)
    80004b40:	6a02                	ld	s4,0(sp)
    80004b42:	6145                	addi	sp,sp,48
    80004b44:	8082                	ret
  return -1;
    80004b46:	557d                	li	a0,-1
    80004b48:	b7fd                	j	80004b36 <pipealloc+0xc6>

0000000080004b4a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b4a:	1101                	addi	sp,sp,-32
    80004b4c:	ec06                	sd	ra,24(sp)
    80004b4e:	e822                	sd	s0,16(sp)
    80004b50:	e426                	sd	s1,8(sp)
    80004b52:	e04a                	sd	s2,0(sp)
    80004b54:	1000                	addi	s0,sp,32
    80004b56:	84aa                	mv	s1,a0
    80004b58:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	07c080e7          	jalr	124(ra) # 80000bd6 <acquire>
  if(writable){
    80004b62:	02090d63          	beqz	s2,80004b9c <pipeclose+0x52>
    pi->writeopen = 0;
    80004b66:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b6a:	21848513          	addi	a0,s1,536
    80004b6e:	ffffd097          	auipc	ra,0xffffd
    80004b72:	604080e7          	jalr	1540(ra) # 80002172 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b76:	2204b783          	ld	a5,544(s1)
    80004b7a:	eb95                	bnez	a5,80004bae <pipeclose+0x64>
    release(&pi->lock);
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	10c080e7          	jalr	268(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	e62080e7          	jalr	-414(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004b90:	60e2                	ld	ra,24(sp)
    80004b92:	6442                	ld	s0,16(sp)
    80004b94:	64a2                	ld	s1,8(sp)
    80004b96:	6902                	ld	s2,0(sp)
    80004b98:	6105                	addi	sp,sp,32
    80004b9a:	8082                	ret
    pi->readopen = 0;
    80004b9c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ba0:	21c48513          	addi	a0,s1,540
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	5ce080e7          	jalr	1486(ra) # 80002172 <wakeup>
    80004bac:	b7e9                	j	80004b76 <pipeclose+0x2c>
    release(&pi->lock);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	0da080e7          	jalr	218(ra) # 80000c8a <release>
}
    80004bb8:	bfe1                	j	80004b90 <pipeclose+0x46>

0000000080004bba <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bba:	711d                	addi	sp,sp,-96
    80004bbc:	ec86                	sd	ra,88(sp)
    80004bbe:	e8a2                	sd	s0,80(sp)
    80004bc0:	e4a6                	sd	s1,72(sp)
    80004bc2:	e0ca                	sd	s2,64(sp)
    80004bc4:	fc4e                	sd	s3,56(sp)
    80004bc6:	f852                	sd	s4,48(sp)
    80004bc8:	f456                	sd	s5,40(sp)
    80004bca:	f05a                	sd	s6,32(sp)
    80004bcc:	ec5e                	sd	s7,24(sp)
    80004bce:	e862                	sd	s8,16(sp)
    80004bd0:	1080                	addi	s0,sp,96
    80004bd2:	84aa                	mv	s1,a0
    80004bd4:	8aae                	mv	s5,a1
    80004bd6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	dd4080e7          	jalr	-556(ra) # 800019ac <myproc>
    80004be0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	ff2080e7          	jalr	-14(ra) # 80000bd6 <acquire>
  while(i < n){
    80004bec:	0b405663          	blez	s4,80004c98 <pipewrite+0xde>
  int i = 0;
    80004bf0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bf4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bf8:	21c48b93          	addi	s7,s1,540
    80004bfc:	a089                	j	80004c3e <pipewrite+0x84>
      release(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	08a080e7          	jalr	138(ra) # 80000c8a <release>
      return -1;
    80004c08:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c0a:	854a                	mv	a0,s2
    80004c0c:	60e6                	ld	ra,88(sp)
    80004c0e:	6446                	ld	s0,80(sp)
    80004c10:	64a6                	ld	s1,72(sp)
    80004c12:	6906                	ld	s2,64(sp)
    80004c14:	79e2                	ld	s3,56(sp)
    80004c16:	7a42                	ld	s4,48(sp)
    80004c18:	7aa2                	ld	s5,40(sp)
    80004c1a:	7b02                	ld	s6,32(sp)
    80004c1c:	6be2                	ld	s7,24(sp)
    80004c1e:	6c42                	ld	s8,16(sp)
    80004c20:	6125                	addi	sp,sp,96
    80004c22:	8082                	ret
      wakeup(&pi->nread);
    80004c24:	8562                	mv	a0,s8
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	54c080e7          	jalr	1356(ra) # 80002172 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c2e:	85a6                	mv	a1,s1
    80004c30:	855e                	mv	a0,s7
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	4dc080e7          	jalr	1244(ra) # 8000210e <sleep>
  while(i < n){
    80004c3a:	07495063          	bge	s2,s4,80004c9a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c3e:	2204a783          	lw	a5,544(s1)
    80004c42:	dfd5                	beqz	a5,80004bfe <pipewrite+0x44>
    80004c44:	854e                	mv	a0,s3
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	77c080e7          	jalr	1916(ra) # 800023c2 <killed>
    80004c4e:	f945                	bnez	a0,80004bfe <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c50:	2184a783          	lw	a5,536(s1)
    80004c54:	21c4a703          	lw	a4,540(s1)
    80004c58:	2007879b          	addiw	a5,a5,512
    80004c5c:	fcf704e3          	beq	a4,a5,80004c24 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c60:	4685                	li	a3,1
    80004c62:	01590633          	add	a2,s2,s5
    80004c66:	faf40593          	addi	a1,s0,-81
    80004c6a:	0509b503          	ld	a0,80(s3)
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	a86080e7          	jalr	-1402(ra) # 800016f4 <copyin>
    80004c76:	03650263          	beq	a0,s6,80004c9a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c7a:	21c4a783          	lw	a5,540(s1)
    80004c7e:	0017871b          	addiw	a4,a5,1
    80004c82:	20e4ae23          	sw	a4,540(s1)
    80004c86:	1ff7f793          	andi	a5,a5,511
    80004c8a:	97a6                	add	a5,a5,s1
    80004c8c:	faf44703          	lbu	a4,-81(s0)
    80004c90:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c94:	2905                	addiw	s2,s2,1
    80004c96:	b755                	j	80004c3a <pipewrite+0x80>
  int i = 0;
    80004c98:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c9a:	21848513          	addi	a0,s1,536
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	4d4080e7          	jalr	1236(ra) # 80002172 <wakeup>
  release(&pi->lock);
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	fe2080e7          	jalr	-30(ra) # 80000c8a <release>
  return i;
    80004cb0:	bfa9                	j	80004c0a <pipewrite+0x50>

0000000080004cb2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cb2:	715d                	addi	sp,sp,-80
    80004cb4:	e486                	sd	ra,72(sp)
    80004cb6:	e0a2                	sd	s0,64(sp)
    80004cb8:	fc26                	sd	s1,56(sp)
    80004cba:	f84a                	sd	s2,48(sp)
    80004cbc:	f44e                	sd	s3,40(sp)
    80004cbe:	f052                	sd	s4,32(sp)
    80004cc0:	ec56                	sd	s5,24(sp)
    80004cc2:	e85a                	sd	s6,16(sp)
    80004cc4:	0880                	addi	s0,sp,80
    80004cc6:	84aa                	mv	s1,a0
    80004cc8:	892e                	mv	s2,a1
    80004cca:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ccc:	ffffd097          	auipc	ra,0xffffd
    80004cd0:	ce0080e7          	jalr	-800(ra) # 800019ac <myproc>
    80004cd4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	efe080e7          	jalr	-258(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce0:	2184a703          	lw	a4,536(s1)
    80004ce4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cec:	02f71763          	bne	a4,a5,80004d1a <piperead+0x68>
    80004cf0:	2244a783          	lw	a5,548(s1)
    80004cf4:	c39d                	beqz	a5,80004d1a <piperead+0x68>
    if(killed(pr)){
    80004cf6:	8552                	mv	a0,s4
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	6ca080e7          	jalr	1738(ra) # 800023c2 <killed>
    80004d00:	e941                	bnez	a0,80004d90 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d02:	85a6                	mv	a1,s1
    80004d04:	854e                	mv	a0,s3
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	408080e7          	jalr	1032(ra) # 8000210e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d0e:	2184a703          	lw	a4,536(s1)
    80004d12:	21c4a783          	lw	a5,540(s1)
    80004d16:	fcf70de3          	beq	a4,a5,80004cf0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d1a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d1c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d1e:	05505363          	blez	s5,80004d64 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d22:	2184a783          	lw	a5,536(s1)
    80004d26:	21c4a703          	lw	a4,540(s1)
    80004d2a:	02f70d63          	beq	a4,a5,80004d64 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d2e:	0017871b          	addiw	a4,a5,1
    80004d32:	20e4ac23          	sw	a4,536(s1)
    80004d36:	1ff7f793          	andi	a5,a5,511
    80004d3a:	97a6                	add	a5,a5,s1
    80004d3c:	0187c783          	lbu	a5,24(a5)
    80004d40:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d44:	4685                	li	a3,1
    80004d46:	fbf40613          	addi	a2,s0,-65
    80004d4a:	85ca                	mv	a1,s2
    80004d4c:	050a3503          	ld	a0,80(s4)
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	918080e7          	jalr	-1768(ra) # 80001668 <copyout>
    80004d58:	01650663          	beq	a0,s6,80004d64 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d5c:	2985                	addiw	s3,s3,1
    80004d5e:	0905                	addi	s2,s2,1
    80004d60:	fd3a91e3          	bne	s5,s3,80004d22 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d64:	21c48513          	addi	a0,s1,540
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	40a080e7          	jalr	1034(ra) # 80002172 <wakeup>
  release(&pi->lock);
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	f18080e7          	jalr	-232(ra) # 80000c8a <release>
  return i;
}
    80004d7a:	854e                	mv	a0,s3
    80004d7c:	60a6                	ld	ra,72(sp)
    80004d7e:	6406                	ld	s0,64(sp)
    80004d80:	74e2                	ld	s1,56(sp)
    80004d82:	7942                	ld	s2,48(sp)
    80004d84:	79a2                	ld	s3,40(sp)
    80004d86:	7a02                	ld	s4,32(sp)
    80004d88:	6ae2                	ld	s5,24(sp)
    80004d8a:	6b42                	ld	s6,16(sp)
    80004d8c:	6161                	addi	sp,sp,80
    80004d8e:	8082                	ret
      release(&pi->lock);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	ef8080e7          	jalr	-264(ra) # 80000c8a <release>
      return -1;
    80004d9a:	59fd                	li	s3,-1
    80004d9c:	bff9                	j	80004d7a <piperead+0xc8>

0000000080004d9e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d9e:	1141                	addi	sp,sp,-16
    80004da0:	e422                	sd	s0,8(sp)
    80004da2:	0800                	addi	s0,sp,16
    80004da4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004da6:	8905                	andi	a0,a0,1
    80004da8:	c111                	beqz	a0,80004dac <flags2perm+0xe>
      perm = PTE_X;
    80004daa:	4521                	li	a0,8
    if(flags & 0x2)
    80004dac:	8b89                	andi	a5,a5,2
    80004dae:	c399                	beqz	a5,80004db4 <flags2perm+0x16>
      perm |= PTE_W;
    80004db0:	00456513          	ori	a0,a0,4
    return perm;
}
    80004db4:	6422                	ld	s0,8(sp)
    80004db6:	0141                	addi	sp,sp,16
    80004db8:	8082                	ret

0000000080004dba <exec>:

int
exec(char *path, char **argv)
{
    80004dba:	de010113          	addi	sp,sp,-544
    80004dbe:	20113c23          	sd	ra,536(sp)
    80004dc2:	20813823          	sd	s0,528(sp)
    80004dc6:	20913423          	sd	s1,520(sp)
    80004dca:	21213023          	sd	s2,512(sp)
    80004dce:	ffce                	sd	s3,504(sp)
    80004dd0:	fbd2                	sd	s4,496(sp)
    80004dd2:	f7d6                	sd	s5,488(sp)
    80004dd4:	f3da                	sd	s6,480(sp)
    80004dd6:	efde                	sd	s7,472(sp)
    80004dd8:	ebe2                	sd	s8,464(sp)
    80004dda:	e7e6                	sd	s9,456(sp)
    80004ddc:	e3ea                	sd	s10,448(sp)
    80004dde:	ff6e                	sd	s11,440(sp)
    80004de0:	1400                	addi	s0,sp,544
    80004de2:	892a                	mv	s2,a0
    80004de4:	dea43423          	sd	a0,-536(s0)
    80004de8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	bc0080e7          	jalr	-1088(ra) # 800019ac <myproc>
    80004df4:	84aa                	mv	s1,a0

  begin_op();
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	47e080e7          	jalr	1150(ra) # 80004274 <begin_op>

  if((ip = namei(path)) == 0){
    80004dfe:	854a                	mv	a0,s2
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	258080e7          	jalr	600(ra) # 80004058 <namei>
    80004e08:	c93d                	beqz	a0,80004e7e <exec+0xc4>
    80004e0a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	aa6080e7          	jalr	-1370(ra) # 800038b2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e14:	04000713          	li	a4,64
    80004e18:	4681                	li	a3,0
    80004e1a:	e5040613          	addi	a2,s0,-432
    80004e1e:	4581                	li	a1,0
    80004e20:	8556                	mv	a0,s5
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	d44080e7          	jalr	-700(ra) # 80003b66 <readi>
    80004e2a:	04000793          	li	a5,64
    80004e2e:	00f51a63          	bne	a0,a5,80004e42 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e32:	e5042703          	lw	a4,-432(s0)
    80004e36:	464c47b7          	lui	a5,0x464c4
    80004e3a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e3e:	04f70663          	beq	a4,a5,80004e8a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e42:	8556                	mv	a0,s5
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	cd0080e7          	jalr	-816(ra) # 80003b14 <iunlockput>
    end_op();
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	4a8080e7          	jalr	1192(ra) # 800042f4 <end_op>
  }
  return -1;
    80004e54:	557d                	li	a0,-1
}
    80004e56:	21813083          	ld	ra,536(sp)
    80004e5a:	21013403          	ld	s0,528(sp)
    80004e5e:	20813483          	ld	s1,520(sp)
    80004e62:	20013903          	ld	s2,512(sp)
    80004e66:	79fe                	ld	s3,504(sp)
    80004e68:	7a5e                	ld	s4,496(sp)
    80004e6a:	7abe                	ld	s5,488(sp)
    80004e6c:	7b1e                	ld	s6,480(sp)
    80004e6e:	6bfe                	ld	s7,472(sp)
    80004e70:	6c5e                	ld	s8,464(sp)
    80004e72:	6cbe                	ld	s9,456(sp)
    80004e74:	6d1e                	ld	s10,448(sp)
    80004e76:	7dfa                	ld	s11,440(sp)
    80004e78:	22010113          	addi	sp,sp,544
    80004e7c:	8082                	ret
    end_op();
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	476080e7          	jalr	1142(ra) # 800042f4 <end_op>
    return -1;
    80004e86:	557d                	li	a0,-1
    80004e88:	b7f9                	j	80004e56 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	ffffd097          	auipc	ra,0xffffd
    80004e90:	be4080e7          	jalr	-1052(ra) # 80001a70 <proc_pagetable>
    80004e94:	8b2a                	mv	s6,a0
    80004e96:	d555                	beqz	a0,80004e42 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e98:	e7042783          	lw	a5,-400(s0)
    80004e9c:	e8845703          	lhu	a4,-376(s0)
    80004ea0:	c735                	beqz	a4,80004f0c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ea2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ea8:	6a05                	lui	s4,0x1
    80004eaa:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004eae:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004eb2:	6d85                	lui	s11,0x1
    80004eb4:	7d7d                	lui	s10,0xfffff
    80004eb6:	a481                	j	800050f6 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eb8:	00004517          	auipc	a0,0x4
    80004ebc:	91050513          	addi	a0,a0,-1776 # 800087c8 <syscalls+0x290>
    80004ec0:	ffffb097          	auipc	ra,0xffffb
    80004ec4:	67e080e7          	jalr	1662(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ec8:	874a                	mv	a4,s2
    80004eca:	009c86bb          	addw	a3,s9,s1
    80004ece:	4581                	li	a1,0
    80004ed0:	8556                	mv	a0,s5
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	c94080e7          	jalr	-876(ra) # 80003b66 <readi>
    80004eda:	2501                	sext.w	a0,a0
    80004edc:	1aa91a63          	bne	s2,a0,80005090 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee0:	009d84bb          	addw	s1,s11,s1
    80004ee4:	013d09bb          	addw	s3,s10,s3
    80004ee8:	1f74f763          	bgeu	s1,s7,800050d6 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004eec:	02049593          	slli	a1,s1,0x20
    80004ef0:	9181                	srli	a1,a1,0x20
    80004ef2:	95e2                	add	a1,a1,s8
    80004ef4:	855a                	mv	a0,s6
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	166080e7          	jalr	358(ra) # 8000105c <walkaddr>
    80004efe:	862a                	mv	a2,a0
    if(pa == 0)
    80004f00:	dd45                	beqz	a0,80004eb8 <exec+0xfe>
      n = PGSIZE;
    80004f02:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f04:	fd49f2e3          	bgeu	s3,s4,80004ec8 <exec+0x10e>
      n = sz - i;
    80004f08:	894e                	mv	s2,s3
    80004f0a:	bf7d                	j	80004ec8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f0c:	4901                	li	s2,0
  iunlockput(ip);
    80004f0e:	8556                	mv	a0,s5
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	c04080e7          	jalr	-1020(ra) # 80003b14 <iunlockput>
  end_op();
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	3dc080e7          	jalr	988(ra) # 800042f4 <end_op>
  p = myproc();
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	a8c080e7          	jalr	-1396(ra) # 800019ac <myproc>
    80004f28:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f2a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f2e:	6785                	lui	a5,0x1
    80004f30:	17fd                	addi	a5,a5,-1
    80004f32:	993e                	add	s2,s2,a5
    80004f34:	77fd                	lui	a5,0xfffff
    80004f36:	00f977b3          	and	a5,s2,a5
    80004f3a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f3e:	4691                	li	a3,4
    80004f40:	6609                	lui	a2,0x2
    80004f42:	963e                	add	a2,a2,a5
    80004f44:	85be                	mv	a1,a5
    80004f46:	855a                	mv	a0,s6
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	4c8080e7          	jalr	1224(ra) # 80001410 <uvmalloc>
    80004f50:	8c2a                	mv	s8,a0
  ip = 0;
    80004f52:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f54:	12050e63          	beqz	a0,80005090 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f58:	75f9                	lui	a1,0xffffe
    80004f5a:	95aa                	add	a1,a1,a0
    80004f5c:	855a                	mv	a0,s6
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	6d8080e7          	jalr	1752(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f66:	7afd                	lui	s5,0xfffff
    80004f68:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f6a:	df043783          	ld	a5,-528(s0)
    80004f6e:	6388                	ld	a0,0(a5)
    80004f70:	c925                	beqz	a0,80004fe0 <exec+0x226>
    80004f72:	e9040993          	addi	s3,s0,-368
    80004f76:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f7a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f7c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	ed0080e7          	jalr	-304(ra) # 80000e4e <strlen>
    80004f86:	0015079b          	addiw	a5,a0,1
    80004f8a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f8e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f92:	13596663          	bltu	s2,s5,800050be <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f96:	df043d83          	ld	s11,-528(s0)
    80004f9a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f9e:	8552                	mv	a0,s4
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	eae080e7          	jalr	-338(ra) # 80000e4e <strlen>
    80004fa8:	0015069b          	addiw	a3,a0,1
    80004fac:	8652                	mv	a2,s4
    80004fae:	85ca                	mv	a1,s2
    80004fb0:	855a                	mv	a0,s6
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	6b6080e7          	jalr	1718(ra) # 80001668 <copyout>
    80004fba:	10054663          	bltz	a0,800050c6 <exec+0x30c>
    ustack[argc] = sp;
    80004fbe:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc2:	0485                	addi	s1,s1,1
    80004fc4:	008d8793          	addi	a5,s11,8
    80004fc8:	def43823          	sd	a5,-528(s0)
    80004fcc:	008db503          	ld	a0,8(s11)
    80004fd0:	c911                	beqz	a0,80004fe4 <exec+0x22a>
    if(argc >= MAXARG)
    80004fd2:	09a1                	addi	s3,s3,8
    80004fd4:	fb3c95e3          	bne	s9,s3,80004f7e <exec+0x1c4>
  sz = sz1;
    80004fd8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fdc:	4a81                	li	s5,0
    80004fde:	a84d                	j	80005090 <exec+0x2d6>
  sp = sz;
    80004fe0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fe2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fe4:	00349793          	slli	a5,s1,0x3
    80004fe8:	f9040713          	addi	a4,s0,-112
    80004fec:	97ba                	add	a5,a5,a4
    80004fee:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc600>
  sp -= (argc+1) * sizeof(uint64);
    80004ff2:	00148693          	addi	a3,s1,1
    80004ff6:	068e                	slli	a3,a3,0x3
    80004ff8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ffc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005000:	01597663          	bgeu	s2,s5,8000500c <exec+0x252>
  sz = sz1;
    80005004:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005008:	4a81                	li	s5,0
    8000500a:	a059                	j	80005090 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000500c:	e9040613          	addi	a2,s0,-368
    80005010:	85ca                	mv	a1,s2
    80005012:	855a                	mv	a0,s6
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	654080e7          	jalr	1620(ra) # 80001668 <copyout>
    8000501c:	0a054963          	bltz	a0,800050ce <exec+0x314>
  p->trapframe->a1 = sp;
    80005020:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005024:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005028:	de843783          	ld	a5,-536(s0)
    8000502c:	0007c703          	lbu	a4,0(a5)
    80005030:	cf11                	beqz	a4,8000504c <exec+0x292>
    80005032:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005034:	02f00693          	li	a3,47
    80005038:	a039                	j	80005046 <exec+0x28c>
      last = s+1;
    8000503a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000503e:	0785                	addi	a5,a5,1
    80005040:	fff7c703          	lbu	a4,-1(a5)
    80005044:	c701                	beqz	a4,8000504c <exec+0x292>
    if(*s == '/')
    80005046:	fed71ce3          	bne	a4,a3,8000503e <exec+0x284>
    8000504a:	bfc5                	j	8000503a <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000504c:	4641                	li	a2,16
    8000504e:	de843583          	ld	a1,-536(s0)
    80005052:	158b8513          	addi	a0,s7,344
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	dc6080e7          	jalr	-570(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000505e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005062:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005066:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000506a:	058bb783          	ld	a5,88(s7)
    8000506e:	e6843703          	ld	a4,-408(s0)
    80005072:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005074:	058bb783          	ld	a5,88(s7)
    80005078:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000507c:	85ea                	mv	a1,s10
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	a8e080e7          	jalr	-1394(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005086:	0004851b          	sext.w	a0,s1
    8000508a:	b3f1                	j	80004e56 <exec+0x9c>
    8000508c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005090:	df843583          	ld	a1,-520(s0)
    80005094:	855a                	mv	a0,s6
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	a76080e7          	jalr	-1418(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000509e:	da0a92e3          	bnez	s5,80004e42 <exec+0x88>
  return -1;
    800050a2:	557d                	li	a0,-1
    800050a4:	bb4d                	j	80004e56 <exec+0x9c>
    800050a6:	df243c23          	sd	s2,-520(s0)
    800050aa:	b7dd                	j	80005090 <exec+0x2d6>
    800050ac:	df243c23          	sd	s2,-520(s0)
    800050b0:	b7c5                	j	80005090 <exec+0x2d6>
    800050b2:	df243c23          	sd	s2,-520(s0)
    800050b6:	bfe9                	j	80005090 <exec+0x2d6>
    800050b8:	df243c23          	sd	s2,-520(s0)
    800050bc:	bfd1                	j	80005090 <exec+0x2d6>
  sz = sz1;
    800050be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c2:	4a81                	li	s5,0
    800050c4:	b7f1                	j	80005090 <exec+0x2d6>
  sz = sz1;
    800050c6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ca:	4a81                	li	s5,0
    800050cc:	b7d1                	j	80005090 <exec+0x2d6>
  sz = sz1;
    800050ce:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050d2:	4a81                	li	s5,0
    800050d4:	bf75                	j	80005090 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050d6:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050da:	e0843783          	ld	a5,-504(s0)
    800050de:	0017869b          	addiw	a3,a5,1
    800050e2:	e0d43423          	sd	a3,-504(s0)
    800050e6:	e0043783          	ld	a5,-512(s0)
    800050ea:	0387879b          	addiw	a5,a5,56
    800050ee:	e8845703          	lhu	a4,-376(s0)
    800050f2:	e0e6dee3          	bge	a3,a4,80004f0e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050f6:	2781                	sext.w	a5,a5
    800050f8:	e0f43023          	sd	a5,-512(s0)
    800050fc:	03800713          	li	a4,56
    80005100:	86be                	mv	a3,a5
    80005102:	e1840613          	addi	a2,s0,-488
    80005106:	4581                	li	a1,0
    80005108:	8556                	mv	a0,s5
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	a5c080e7          	jalr	-1444(ra) # 80003b66 <readi>
    80005112:	03800793          	li	a5,56
    80005116:	f6f51be3          	bne	a0,a5,8000508c <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000511a:	e1842783          	lw	a5,-488(s0)
    8000511e:	4705                	li	a4,1
    80005120:	fae79de3          	bne	a5,a4,800050da <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005124:	e4043483          	ld	s1,-448(s0)
    80005128:	e3843783          	ld	a5,-456(s0)
    8000512c:	f6f4ede3          	bltu	s1,a5,800050a6 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005130:	e2843783          	ld	a5,-472(s0)
    80005134:	94be                	add	s1,s1,a5
    80005136:	f6f4ebe3          	bltu	s1,a5,800050ac <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000513a:	de043703          	ld	a4,-544(s0)
    8000513e:	8ff9                	and	a5,a5,a4
    80005140:	fbad                	bnez	a5,800050b2 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005142:	e1c42503          	lw	a0,-484(s0)
    80005146:	00000097          	auipc	ra,0x0
    8000514a:	c58080e7          	jalr	-936(ra) # 80004d9e <flags2perm>
    8000514e:	86aa                	mv	a3,a0
    80005150:	8626                	mv	a2,s1
    80005152:	85ca                	mv	a1,s2
    80005154:	855a                	mv	a0,s6
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	2ba080e7          	jalr	698(ra) # 80001410 <uvmalloc>
    8000515e:	dea43c23          	sd	a0,-520(s0)
    80005162:	d939                	beqz	a0,800050b8 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005164:	e2843c03          	ld	s8,-472(s0)
    80005168:	e2042c83          	lw	s9,-480(s0)
    8000516c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005170:	f60b83e3          	beqz	s7,800050d6 <exec+0x31c>
    80005174:	89de                	mv	s3,s7
    80005176:	4481                	li	s1,0
    80005178:	bb95                	j	80004eec <exec+0x132>

000000008000517a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000517a:	7179                	addi	sp,sp,-48
    8000517c:	f406                	sd	ra,40(sp)
    8000517e:	f022                	sd	s0,32(sp)
    80005180:	ec26                	sd	s1,24(sp)
    80005182:	e84a                	sd	s2,16(sp)
    80005184:	1800                	addi	s0,sp,48
    80005186:	892e                	mv	s2,a1
    80005188:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000518a:	fdc40593          	addi	a1,s0,-36
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	a80080e7          	jalr	-1408(ra) # 80002c0e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005196:	fdc42703          	lw	a4,-36(s0)
    8000519a:	47bd                	li	a5,15
    8000519c:	02e7eb63          	bltu	a5,a4,800051d2 <argfd+0x58>
    800051a0:	ffffd097          	auipc	ra,0xffffd
    800051a4:	80c080e7          	jalr	-2036(ra) # 800019ac <myproc>
    800051a8:	fdc42703          	lw	a4,-36(s0)
    800051ac:	01a70793          	addi	a5,a4,26
    800051b0:	078e                	slli	a5,a5,0x3
    800051b2:	953e                	add	a0,a0,a5
    800051b4:	611c                	ld	a5,0(a0)
    800051b6:	c385                	beqz	a5,800051d6 <argfd+0x5c>
    return -1;
  if(pfd)
    800051b8:	00090463          	beqz	s2,800051c0 <argfd+0x46>
    *pfd = fd;
    800051bc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051c0:	4501                	li	a0,0
  if(pf)
    800051c2:	c091                	beqz	s1,800051c6 <argfd+0x4c>
    *pf = f;
    800051c4:	e09c                	sd	a5,0(s1)
}
    800051c6:	70a2                	ld	ra,40(sp)
    800051c8:	7402                	ld	s0,32(sp)
    800051ca:	64e2                	ld	s1,24(sp)
    800051cc:	6942                	ld	s2,16(sp)
    800051ce:	6145                	addi	sp,sp,48
    800051d0:	8082                	ret
    return -1;
    800051d2:	557d                	li	a0,-1
    800051d4:	bfcd                	j	800051c6 <argfd+0x4c>
    800051d6:	557d                	li	a0,-1
    800051d8:	b7fd                	j	800051c6 <argfd+0x4c>

00000000800051da <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051da:	1101                	addi	sp,sp,-32
    800051dc:	ec06                	sd	ra,24(sp)
    800051de:	e822                	sd	s0,16(sp)
    800051e0:	e426                	sd	s1,8(sp)
    800051e2:	1000                	addi	s0,sp,32
    800051e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	7c6080e7          	jalr	1990(ra) # 800019ac <myproc>
    800051ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051f0:	0d050793          	addi	a5,a0,208
    800051f4:	4501                	li	a0,0
    800051f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051f8:	6398                	ld	a4,0(a5)
    800051fa:	cb19                	beqz	a4,80005210 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051fc:	2505                	addiw	a0,a0,1
    800051fe:	07a1                	addi	a5,a5,8
    80005200:	fed51ce3          	bne	a0,a3,800051f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005204:	557d                	li	a0,-1
}
    80005206:	60e2                	ld	ra,24(sp)
    80005208:	6442                	ld	s0,16(sp)
    8000520a:	64a2                	ld	s1,8(sp)
    8000520c:	6105                	addi	sp,sp,32
    8000520e:	8082                	ret
      p->ofile[fd] = f;
    80005210:	01a50793          	addi	a5,a0,26
    80005214:	078e                	slli	a5,a5,0x3
    80005216:	963e                	add	a2,a2,a5
    80005218:	e204                	sd	s1,0(a2)
      return fd;
    8000521a:	b7f5                	j	80005206 <fdalloc+0x2c>

000000008000521c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000521c:	715d                	addi	sp,sp,-80
    8000521e:	e486                	sd	ra,72(sp)
    80005220:	e0a2                	sd	s0,64(sp)
    80005222:	fc26                	sd	s1,56(sp)
    80005224:	f84a                	sd	s2,48(sp)
    80005226:	f44e                	sd	s3,40(sp)
    80005228:	f052                	sd	s4,32(sp)
    8000522a:	ec56                	sd	s5,24(sp)
    8000522c:	e85a                	sd	s6,16(sp)
    8000522e:	0880                	addi	s0,sp,80
    80005230:	8b2e                	mv	s6,a1
    80005232:	89b2                	mv	s3,a2
    80005234:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005236:	fb040593          	addi	a1,s0,-80
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	e3c080e7          	jalr	-452(ra) # 80004076 <nameiparent>
    80005242:	84aa                	mv	s1,a0
    80005244:	14050f63          	beqz	a0,800053a2 <create+0x186>
    return 0;

  ilock(dp);
    80005248:	ffffe097          	auipc	ra,0xffffe
    8000524c:	66a080e7          	jalr	1642(ra) # 800038b2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005250:	4601                	li	a2,0
    80005252:	fb040593          	addi	a1,s0,-80
    80005256:	8526                	mv	a0,s1
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	b3e080e7          	jalr	-1218(ra) # 80003d96 <dirlookup>
    80005260:	8aaa                	mv	s5,a0
    80005262:	c931                	beqz	a0,800052b6 <create+0x9a>
    iunlockput(dp);
    80005264:	8526                	mv	a0,s1
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	8ae080e7          	jalr	-1874(ra) # 80003b14 <iunlockput>
    ilock(ip);
    8000526e:	8556                	mv	a0,s5
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	642080e7          	jalr	1602(ra) # 800038b2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005278:	000b059b          	sext.w	a1,s6
    8000527c:	4789                	li	a5,2
    8000527e:	02f59563          	bne	a1,a5,800052a8 <create+0x8c>
    80005282:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc744>
    80005286:	37f9                	addiw	a5,a5,-2
    80005288:	17c2                	slli	a5,a5,0x30
    8000528a:	93c1                	srli	a5,a5,0x30
    8000528c:	4705                	li	a4,1
    8000528e:	00f76d63          	bltu	a4,a5,800052a8 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005292:	8556                	mv	a0,s5
    80005294:	60a6                	ld	ra,72(sp)
    80005296:	6406                	ld	s0,64(sp)
    80005298:	74e2                	ld	s1,56(sp)
    8000529a:	7942                	ld	s2,48(sp)
    8000529c:	79a2                	ld	s3,40(sp)
    8000529e:	7a02                	ld	s4,32(sp)
    800052a0:	6ae2                	ld	s5,24(sp)
    800052a2:	6b42                	ld	s6,16(sp)
    800052a4:	6161                	addi	sp,sp,80
    800052a6:	8082                	ret
    iunlockput(ip);
    800052a8:	8556                	mv	a0,s5
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	86a080e7          	jalr	-1942(ra) # 80003b14 <iunlockput>
    return 0;
    800052b2:	4a81                	li	s5,0
    800052b4:	bff9                	j	80005292 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052b6:	85da                	mv	a1,s6
    800052b8:	4088                	lw	a0,0(s1)
    800052ba:	ffffe097          	auipc	ra,0xffffe
    800052be:	45c080e7          	jalr	1116(ra) # 80003716 <ialloc>
    800052c2:	8a2a                	mv	s4,a0
    800052c4:	c539                	beqz	a0,80005312 <create+0xf6>
  ilock(ip);
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	5ec080e7          	jalr	1516(ra) # 800038b2 <ilock>
  ip->major = major;
    800052ce:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052d2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052d6:	4905                	li	s2,1
    800052d8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800052dc:	8552                	mv	a0,s4
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	50a080e7          	jalr	1290(ra) # 800037e8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052e6:	000b059b          	sext.w	a1,s6
    800052ea:	03258b63          	beq	a1,s2,80005320 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800052ee:	004a2603          	lw	a2,4(s4)
    800052f2:	fb040593          	addi	a1,s0,-80
    800052f6:	8526                	mv	a0,s1
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	cae080e7          	jalr	-850(ra) # 80003fa6 <dirlink>
    80005300:	06054f63          	bltz	a0,8000537e <create+0x162>
  iunlockput(dp);
    80005304:	8526                	mv	a0,s1
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	80e080e7          	jalr	-2034(ra) # 80003b14 <iunlockput>
  return ip;
    8000530e:	8ad2                	mv	s5,s4
    80005310:	b749                	j	80005292 <create+0x76>
    iunlockput(dp);
    80005312:	8526                	mv	a0,s1
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	800080e7          	jalr	-2048(ra) # 80003b14 <iunlockput>
    return 0;
    8000531c:	8ad2                	mv	s5,s4
    8000531e:	bf95                	j	80005292 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005320:	004a2603          	lw	a2,4(s4)
    80005324:	00003597          	auipc	a1,0x3
    80005328:	4c458593          	addi	a1,a1,1220 # 800087e8 <syscalls+0x2b0>
    8000532c:	8552                	mv	a0,s4
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	c78080e7          	jalr	-904(ra) # 80003fa6 <dirlink>
    80005336:	04054463          	bltz	a0,8000537e <create+0x162>
    8000533a:	40d0                	lw	a2,4(s1)
    8000533c:	00003597          	auipc	a1,0x3
    80005340:	4b458593          	addi	a1,a1,1204 # 800087f0 <syscalls+0x2b8>
    80005344:	8552                	mv	a0,s4
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	c60080e7          	jalr	-928(ra) # 80003fa6 <dirlink>
    8000534e:	02054863          	bltz	a0,8000537e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005352:	004a2603          	lw	a2,4(s4)
    80005356:	fb040593          	addi	a1,s0,-80
    8000535a:	8526                	mv	a0,s1
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	c4a080e7          	jalr	-950(ra) # 80003fa6 <dirlink>
    80005364:	00054d63          	bltz	a0,8000537e <create+0x162>
    dp->nlink++;  // for ".."
    80005368:	04a4d783          	lhu	a5,74(s1)
    8000536c:	2785                	addiw	a5,a5,1
    8000536e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005372:	8526                	mv	a0,s1
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	474080e7          	jalr	1140(ra) # 800037e8 <iupdate>
    8000537c:	b761                	j	80005304 <create+0xe8>
  ip->nlink = 0;
    8000537e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005382:	8552                	mv	a0,s4
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	464080e7          	jalr	1124(ra) # 800037e8 <iupdate>
  iunlockput(ip);
    8000538c:	8552                	mv	a0,s4
    8000538e:	ffffe097          	auipc	ra,0xffffe
    80005392:	786080e7          	jalr	1926(ra) # 80003b14 <iunlockput>
  iunlockput(dp);
    80005396:	8526                	mv	a0,s1
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	77c080e7          	jalr	1916(ra) # 80003b14 <iunlockput>
  return 0;
    800053a0:	bdcd                	j	80005292 <create+0x76>
    return 0;
    800053a2:	8aaa                	mv	s5,a0
    800053a4:	b5fd                	j	80005292 <create+0x76>

00000000800053a6 <sys_dup>:
{
    800053a6:	7179                	addi	sp,sp,-48
    800053a8:	f406                	sd	ra,40(sp)
    800053aa:	f022                	sd	s0,32(sp)
    800053ac:	ec26                	sd	s1,24(sp)
    800053ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053b0:	fd840613          	addi	a2,s0,-40
    800053b4:	4581                	li	a1,0
    800053b6:	4501                	li	a0,0
    800053b8:	00000097          	auipc	ra,0x0
    800053bc:	dc2080e7          	jalr	-574(ra) # 8000517a <argfd>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053c2:	02054363          	bltz	a0,800053e8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053c6:	fd843503          	ld	a0,-40(s0)
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	e10080e7          	jalr	-496(ra) # 800051da <fdalloc>
    800053d2:	84aa                	mv	s1,a0
    return -1;
    800053d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053d6:	00054963          	bltz	a0,800053e8 <sys_dup+0x42>
  filedup(f);
    800053da:	fd843503          	ld	a0,-40(s0)
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	310080e7          	jalr	784(ra) # 800046ee <filedup>
  return fd;
    800053e6:	87a6                	mv	a5,s1
}
    800053e8:	853e                	mv	a0,a5
    800053ea:	70a2                	ld	ra,40(sp)
    800053ec:	7402                	ld	s0,32(sp)
    800053ee:	64e2                	ld	s1,24(sp)
    800053f0:	6145                	addi	sp,sp,48
    800053f2:	8082                	ret

00000000800053f4 <sys_read>:
{
    800053f4:	7179                	addi	sp,sp,-48
    800053f6:	f406                	sd	ra,40(sp)
    800053f8:	f022                	sd	s0,32(sp)
    800053fa:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053fc:	fd840593          	addi	a1,s0,-40
    80005400:	4505                	li	a0,1
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	82c080e7          	jalr	-2004(ra) # 80002c2e <argaddr>
  argint(2, &n);
    8000540a:	fe440593          	addi	a1,s0,-28
    8000540e:	4509                	li	a0,2
    80005410:	ffffd097          	auipc	ra,0xffffd
    80005414:	7fe080e7          	jalr	2046(ra) # 80002c0e <argint>
  if(argfd(0, 0, &f) < 0)
    80005418:	fe840613          	addi	a2,s0,-24
    8000541c:	4581                	li	a1,0
    8000541e:	4501                	li	a0,0
    80005420:	00000097          	auipc	ra,0x0
    80005424:	d5a080e7          	jalr	-678(ra) # 8000517a <argfd>
    80005428:	87aa                	mv	a5,a0
    return -1;
    8000542a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000542c:	0007cc63          	bltz	a5,80005444 <sys_read+0x50>
  return fileread(f, p, n);
    80005430:	fe442603          	lw	a2,-28(s0)
    80005434:	fd843583          	ld	a1,-40(s0)
    80005438:	fe843503          	ld	a0,-24(s0)
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	43e080e7          	jalr	1086(ra) # 8000487a <fileread>
}
    80005444:	70a2                	ld	ra,40(sp)
    80005446:	7402                	ld	s0,32(sp)
    80005448:	6145                	addi	sp,sp,48
    8000544a:	8082                	ret

000000008000544c <sys_write>:
{
    8000544c:	7179                	addi	sp,sp,-48
    8000544e:	f406                	sd	ra,40(sp)
    80005450:	f022                	sd	s0,32(sp)
    80005452:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005454:	fd840593          	addi	a1,s0,-40
    80005458:	4505                	li	a0,1
    8000545a:	ffffd097          	auipc	ra,0xffffd
    8000545e:	7d4080e7          	jalr	2004(ra) # 80002c2e <argaddr>
  argint(2, &n);
    80005462:	fe440593          	addi	a1,s0,-28
    80005466:	4509                	li	a0,2
    80005468:	ffffd097          	auipc	ra,0xffffd
    8000546c:	7a6080e7          	jalr	1958(ra) # 80002c0e <argint>
  if(argfd(0, 0, &f) < 0)
    80005470:	fe840613          	addi	a2,s0,-24
    80005474:	4581                	li	a1,0
    80005476:	4501                	li	a0,0
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	d02080e7          	jalr	-766(ra) # 8000517a <argfd>
    80005480:	87aa                	mv	a5,a0
    return -1;
    80005482:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005484:	0007cc63          	bltz	a5,8000549c <sys_write+0x50>
  return filewrite(f, p, n);
    80005488:	fe442603          	lw	a2,-28(s0)
    8000548c:	fd843583          	ld	a1,-40(s0)
    80005490:	fe843503          	ld	a0,-24(s0)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	4a8080e7          	jalr	1192(ra) # 8000493c <filewrite>
}
    8000549c:	70a2                	ld	ra,40(sp)
    8000549e:	7402                	ld	s0,32(sp)
    800054a0:	6145                	addi	sp,sp,48
    800054a2:	8082                	ret

00000000800054a4 <sys_close>:
{
    800054a4:	1101                	addi	sp,sp,-32
    800054a6:	ec06                	sd	ra,24(sp)
    800054a8:	e822                	sd	s0,16(sp)
    800054aa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054ac:	fe040613          	addi	a2,s0,-32
    800054b0:	fec40593          	addi	a1,s0,-20
    800054b4:	4501                	li	a0,0
    800054b6:	00000097          	auipc	ra,0x0
    800054ba:	cc4080e7          	jalr	-828(ra) # 8000517a <argfd>
    return -1;
    800054be:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054c0:	02054463          	bltz	a0,800054e8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054c4:	ffffc097          	auipc	ra,0xffffc
    800054c8:	4e8080e7          	jalr	1256(ra) # 800019ac <myproc>
    800054cc:	fec42783          	lw	a5,-20(s0)
    800054d0:	07e9                	addi	a5,a5,26
    800054d2:	078e                	slli	a5,a5,0x3
    800054d4:	97aa                	add	a5,a5,a0
    800054d6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054da:	fe043503          	ld	a0,-32(s0)
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	262080e7          	jalr	610(ra) # 80004740 <fileclose>
  return 0;
    800054e6:	4781                	li	a5,0
}
    800054e8:	853e                	mv	a0,a5
    800054ea:	60e2                	ld	ra,24(sp)
    800054ec:	6442                	ld	s0,16(sp)
    800054ee:	6105                	addi	sp,sp,32
    800054f0:	8082                	ret

00000000800054f2 <sys_fstat>:
{
    800054f2:	1101                	addi	sp,sp,-32
    800054f4:	ec06                	sd	ra,24(sp)
    800054f6:	e822                	sd	s0,16(sp)
    800054f8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800054fa:	fe040593          	addi	a1,s0,-32
    800054fe:	4505                	li	a0,1
    80005500:	ffffd097          	auipc	ra,0xffffd
    80005504:	72e080e7          	jalr	1838(ra) # 80002c2e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005508:	fe840613          	addi	a2,s0,-24
    8000550c:	4581                	li	a1,0
    8000550e:	4501                	li	a0,0
    80005510:	00000097          	auipc	ra,0x0
    80005514:	c6a080e7          	jalr	-918(ra) # 8000517a <argfd>
    80005518:	87aa                	mv	a5,a0
    return -1;
    8000551a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000551c:	0007ca63          	bltz	a5,80005530 <sys_fstat+0x3e>
  return filestat(f, st);
    80005520:	fe043583          	ld	a1,-32(s0)
    80005524:	fe843503          	ld	a0,-24(s0)
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	2e0080e7          	jalr	736(ra) # 80004808 <filestat>
}
    80005530:	60e2                	ld	ra,24(sp)
    80005532:	6442                	ld	s0,16(sp)
    80005534:	6105                	addi	sp,sp,32
    80005536:	8082                	ret

0000000080005538 <sys_link>:
{
    80005538:	7169                	addi	sp,sp,-304
    8000553a:	f606                	sd	ra,296(sp)
    8000553c:	f222                	sd	s0,288(sp)
    8000553e:	ee26                	sd	s1,280(sp)
    80005540:	ea4a                	sd	s2,272(sp)
    80005542:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005544:	08000613          	li	a2,128
    80005548:	ed040593          	addi	a1,s0,-304
    8000554c:	4501                	li	a0,0
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	700080e7          	jalr	1792(ra) # 80002c4e <argstr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005558:	10054e63          	bltz	a0,80005674 <sys_link+0x13c>
    8000555c:	08000613          	li	a2,128
    80005560:	f5040593          	addi	a1,s0,-176
    80005564:	4505                	li	a0,1
    80005566:	ffffd097          	auipc	ra,0xffffd
    8000556a:	6e8080e7          	jalr	1768(ra) # 80002c4e <argstr>
    return -1;
    8000556e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005570:	10054263          	bltz	a0,80005674 <sys_link+0x13c>
  begin_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	d00080e7          	jalr	-768(ra) # 80004274 <begin_op>
  if((ip = namei(old)) == 0){
    8000557c:	ed040513          	addi	a0,s0,-304
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	ad8080e7          	jalr	-1320(ra) # 80004058 <namei>
    80005588:	84aa                	mv	s1,a0
    8000558a:	c551                	beqz	a0,80005616 <sys_link+0xde>
  ilock(ip);
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	326080e7          	jalr	806(ra) # 800038b2 <ilock>
  if(ip->type == T_DIR){
    80005594:	04449703          	lh	a4,68(s1)
    80005598:	4785                	li	a5,1
    8000559a:	08f70463          	beq	a4,a5,80005622 <sys_link+0xea>
  ip->nlink++;
    8000559e:	04a4d783          	lhu	a5,74(s1)
    800055a2:	2785                	addiw	a5,a5,1
    800055a4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	23e080e7          	jalr	574(ra) # 800037e8 <iupdate>
  iunlock(ip);
    800055b2:	8526                	mv	a0,s1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	3c0080e7          	jalr	960(ra) # 80003974 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055bc:	fd040593          	addi	a1,s0,-48
    800055c0:	f5040513          	addi	a0,s0,-176
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	ab2080e7          	jalr	-1358(ra) # 80004076 <nameiparent>
    800055cc:	892a                	mv	s2,a0
    800055ce:	c935                	beqz	a0,80005642 <sys_link+0x10a>
  ilock(dp);
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	2e2080e7          	jalr	738(ra) # 800038b2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055d8:	00092703          	lw	a4,0(s2)
    800055dc:	409c                	lw	a5,0(s1)
    800055de:	04f71d63          	bne	a4,a5,80005638 <sys_link+0x100>
    800055e2:	40d0                	lw	a2,4(s1)
    800055e4:	fd040593          	addi	a1,s0,-48
    800055e8:	854a                	mv	a0,s2
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	9bc080e7          	jalr	-1604(ra) # 80003fa6 <dirlink>
    800055f2:	04054363          	bltz	a0,80005638 <sys_link+0x100>
  iunlockput(dp);
    800055f6:	854a                	mv	a0,s2
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	51c080e7          	jalr	1308(ra) # 80003b14 <iunlockput>
  iput(ip);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	46a080e7          	jalr	1130(ra) # 80003a6c <iput>
  end_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	cea080e7          	jalr	-790(ra) # 800042f4 <end_op>
  return 0;
    80005612:	4781                	li	a5,0
    80005614:	a085                	j	80005674 <sys_link+0x13c>
    end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	cde080e7          	jalr	-802(ra) # 800042f4 <end_op>
    return -1;
    8000561e:	57fd                	li	a5,-1
    80005620:	a891                	j	80005674 <sys_link+0x13c>
    iunlockput(ip);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	4f0080e7          	jalr	1264(ra) # 80003b14 <iunlockput>
    end_op();
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	cc8080e7          	jalr	-824(ra) # 800042f4 <end_op>
    return -1;
    80005634:	57fd                	li	a5,-1
    80005636:	a83d                	j	80005674 <sys_link+0x13c>
    iunlockput(dp);
    80005638:	854a                	mv	a0,s2
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	4da080e7          	jalr	1242(ra) # 80003b14 <iunlockput>
  ilock(ip);
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	26e080e7          	jalr	622(ra) # 800038b2 <ilock>
  ip->nlink--;
    8000564c:	04a4d783          	lhu	a5,74(s1)
    80005650:	37fd                	addiw	a5,a5,-1
    80005652:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	190080e7          	jalr	400(ra) # 800037e8 <iupdate>
  iunlockput(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	4b2080e7          	jalr	1202(ra) # 80003b14 <iunlockput>
  end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	c8a080e7          	jalr	-886(ra) # 800042f4 <end_op>
  return -1;
    80005672:	57fd                	li	a5,-1
}
    80005674:	853e                	mv	a0,a5
    80005676:	70b2                	ld	ra,296(sp)
    80005678:	7412                	ld	s0,288(sp)
    8000567a:	64f2                	ld	s1,280(sp)
    8000567c:	6952                	ld	s2,272(sp)
    8000567e:	6155                	addi	sp,sp,304
    80005680:	8082                	ret

0000000080005682 <sys_unlink>:
{
    80005682:	7151                	addi	sp,sp,-240
    80005684:	f586                	sd	ra,232(sp)
    80005686:	f1a2                	sd	s0,224(sp)
    80005688:	eda6                	sd	s1,216(sp)
    8000568a:	e9ca                	sd	s2,208(sp)
    8000568c:	e5ce                	sd	s3,200(sp)
    8000568e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005690:	08000613          	li	a2,128
    80005694:	f3040593          	addi	a1,s0,-208
    80005698:	4501                	li	a0,0
    8000569a:	ffffd097          	auipc	ra,0xffffd
    8000569e:	5b4080e7          	jalr	1460(ra) # 80002c4e <argstr>
    800056a2:	18054163          	bltz	a0,80005824 <sys_unlink+0x1a2>
  begin_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	bce080e7          	jalr	-1074(ra) # 80004274 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ae:	fb040593          	addi	a1,s0,-80
    800056b2:	f3040513          	addi	a0,s0,-208
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	9c0080e7          	jalr	-1600(ra) # 80004076 <nameiparent>
    800056be:	84aa                	mv	s1,a0
    800056c0:	c979                	beqz	a0,80005796 <sys_unlink+0x114>
  ilock(dp);
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	1f0080e7          	jalr	496(ra) # 800038b2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056ca:	00003597          	auipc	a1,0x3
    800056ce:	11e58593          	addi	a1,a1,286 # 800087e8 <syscalls+0x2b0>
    800056d2:	fb040513          	addi	a0,s0,-80
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	6a6080e7          	jalr	1702(ra) # 80003d7c <namecmp>
    800056de:	14050a63          	beqz	a0,80005832 <sys_unlink+0x1b0>
    800056e2:	00003597          	auipc	a1,0x3
    800056e6:	10e58593          	addi	a1,a1,270 # 800087f0 <syscalls+0x2b8>
    800056ea:	fb040513          	addi	a0,s0,-80
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	68e080e7          	jalr	1678(ra) # 80003d7c <namecmp>
    800056f6:	12050e63          	beqz	a0,80005832 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056fa:	f2c40613          	addi	a2,s0,-212
    800056fe:	fb040593          	addi	a1,s0,-80
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	692080e7          	jalr	1682(ra) # 80003d96 <dirlookup>
    8000570c:	892a                	mv	s2,a0
    8000570e:	12050263          	beqz	a0,80005832 <sys_unlink+0x1b0>
  ilock(ip);
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	1a0080e7          	jalr	416(ra) # 800038b2 <ilock>
  if(ip->nlink < 1)
    8000571a:	04a91783          	lh	a5,74(s2)
    8000571e:	08f05263          	blez	a5,800057a2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005722:	04491703          	lh	a4,68(s2)
    80005726:	4785                	li	a5,1
    80005728:	08f70563          	beq	a4,a5,800057b2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000572c:	4641                	li	a2,16
    8000572e:	4581                	li	a1,0
    80005730:	fc040513          	addi	a0,s0,-64
    80005734:	ffffb097          	auipc	ra,0xffffb
    80005738:	59e080e7          	jalr	1438(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000573c:	4741                	li	a4,16
    8000573e:	f2c42683          	lw	a3,-212(s0)
    80005742:	fc040613          	addi	a2,s0,-64
    80005746:	4581                	li	a1,0
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	514080e7          	jalr	1300(ra) # 80003c5e <writei>
    80005752:	47c1                	li	a5,16
    80005754:	0af51563          	bne	a0,a5,800057fe <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005758:	04491703          	lh	a4,68(s2)
    8000575c:	4785                	li	a5,1
    8000575e:	0af70863          	beq	a4,a5,8000580e <sys_unlink+0x18c>
  iunlockput(dp);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	3b0080e7          	jalr	944(ra) # 80003b14 <iunlockput>
  ip->nlink--;
    8000576c:	04a95783          	lhu	a5,74(s2)
    80005770:	37fd                	addiw	a5,a5,-1
    80005772:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005776:	854a                	mv	a0,s2
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	070080e7          	jalr	112(ra) # 800037e8 <iupdate>
  iunlockput(ip);
    80005780:	854a                	mv	a0,s2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	392080e7          	jalr	914(ra) # 80003b14 <iunlockput>
  end_op();
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	b6a080e7          	jalr	-1174(ra) # 800042f4 <end_op>
  return 0;
    80005792:	4501                	li	a0,0
    80005794:	a84d                	j	80005846 <sys_unlink+0x1c4>
    end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	b5e080e7          	jalr	-1186(ra) # 800042f4 <end_op>
    return -1;
    8000579e:	557d                	li	a0,-1
    800057a0:	a05d                	j	80005846 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057a2:	00003517          	auipc	a0,0x3
    800057a6:	05650513          	addi	a0,a0,86 # 800087f8 <syscalls+0x2c0>
    800057aa:	ffffb097          	auipc	ra,0xffffb
    800057ae:	d94080e7          	jalr	-620(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057b2:	04c92703          	lw	a4,76(s2)
    800057b6:	02000793          	li	a5,32
    800057ba:	f6e7f9e3          	bgeu	a5,a4,8000572c <sys_unlink+0xaa>
    800057be:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057c2:	4741                	li	a4,16
    800057c4:	86ce                	mv	a3,s3
    800057c6:	f1840613          	addi	a2,s0,-232
    800057ca:	4581                	li	a1,0
    800057cc:	854a                	mv	a0,s2
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	398080e7          	jalr	920(ra) # 80003b66 <readi>
    800057d6:	47c1                	li	a5,16
    800057d8:	00f51b63          	bne	a0,a5,800057ee <sys_unlink+0x16c>
    if(de.inum != 0)
    800057dc:	f1845783          	lhu	a5,-232(s0)
    800057e0:	e7a1                	bnez	a5,80005828 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057e2:	29c1                	addiw	s3,s3,16
    800057e4:	04c92783          	lw	a5,76(s2)
    800057e8:	fcf9ede3          	bltu	s3,a5,800057c2 <sys_unlink+0x140>
    800057ec:	b781                	j	8000572c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057ee:	00003517          	auipc	a0,0x3
    800057f2:	02250513          	addi	a0,a0,34 # 80008810 <syscalls+0x2d8>
    800057f6:	ffffb097          	auipc	ra,0xffffb
    800057fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057fe:	00003517          	auipc	a0,0x3
    80005802:	02a50513          	addi	a0,a0,42 # 80008828 <syscalls+0x2f0>
    80005806:	ffffb097          	auipc	ra,0xffffb
    8000580a:	d38080e7          	jalr	-712(ra) # 8000053e <panic>
    dp->nlink--;
    8000580e:	04a4d783          	lhu	a5,74(s1)
    80005812:	37fd                	addiw	a5,a5,-1
    80005814:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	fce080e7          	jalr	-50(ra) # 800037e8 <iupdate>
    80005822:	b781                	j	80005762 <sys_unlink+0xe0>
    return -1;
    80005824:	557d                	li	a0,-1
    80005826:	a005                	j	80005846 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	2ea080e7          	jalr	746(ra) # 80003b14 <iunlockput>
  iunlockput(dp);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	2e0080e7          	jalr	736(ra) # 80003b14 <iunlockput>
  end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	ab8080e7          	jalr	-1352(ra) # 800042f4 <end_op>
  return -1;
    80005844:	557d                	li	a0,-1
}
    80005846:	70ae                	ld	ra,232(sp)
    80005848:	740e                	ld	s0,224(sp)
    8000584a:	64ee                	ld	s1,216(sp)
    8000584c:	694e                	ld	s2,208(sp)
    8000584e:	69ae                	ld	s3,200(sp)
    80005850:	616d                	addi	sp,sp,240
    80005852:	8082                	ret

0000000080005854 <sys_open>:

uint64
sys_open(void)
{
    80005854:	7131                	addi	sp,sp,-192
    80005856:	fd06                	sd	ra,184(sp)
    80005858:	f922                	sd	s0,176(sp)
    8000585a:	f526                	sd	s1,168(sp)
    8000585c:	f14a                	sd	s2,160(sp)
    8000585e:	ed4e                	sd	s3,152(sp)
    80005860:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005862:	f4c40593          	addi	a1,s0,-180
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	3a6080e7          	jalr	934(ra) # 80002c0e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005870:	08000613          	li	a2,128
    80005874:	f5040593          	addi	a1,s0,-176
    80005878:	4501                	li	a0,0
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	3d4080e7          	jalr	980(ra) # 80002c4e <argstr>
    80005882:	87aa                	mv	a5,a0
    return -1;
    80005884:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005886:	0a07c963          	bltz	a5,80005938 <sys_open+0xe4>

  begin_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	9ea080e7          	jalr	-1558(ra) # 80004274 <begin_op>

  if(omode & O_CREATE){
    80005892:	f4c42783          	lw	a5,-180(s0)
    80005896:	2007f793          	andi	a5,a5,512
    8000589a:	cfc5                	beqz	a5,80005952 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000589c:	4681                	li	a3,0
    8000589e:	4601                	li	a2,0
    800058a0:	4589                	li	a1,2
    800058a2:	f5040513          	addi	a0,s0,-176
    800058a6:	00000097          	auipc	ra,0x0
    800058aa:	976080e7          	jalr	-1674(ra) # 8000521c <create>
    800058ae:	84aa                	mv	s1,a0
    if(ip == 0){
    800058b0:	c959                	beqz	a0,80005946 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058b2:	04449703          	lh	a4,68(s1)
    800058b6:	478d                	li	a5,3
    800058b8:	00f71763          	bne	a4,a5,800058c6 <sys_open+0x72>
    800058bc:	0464d703          	lhu	a4,70(s1)
    800058c0:	47a5                	li	a5,9
    800058c2:	0ce7ed63          	bltu	a5,a4,8000599c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	dbe080e7          	jalr	-578(ra) # 80004684 <filealloc>
    800058ce:	89aa                	mv	s3,a0
    800058d0:	10050363          	beqz	a0,800059d6 <sys_open+0x182>
    800058d4:	00000097          	auipc	ra,0x0
    800058d8:	906080e7          	jalr	-1786(ra) # 800051da <fdalloc>
    800058dc:	892a                	mv	s2,a0
    800058de:	0e054763          	bltz	a0,800059cc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058e2:	04449703          	lh	a4,68(s1)
    800058e6:	478d                	li	a5,3
    800058e8:	0cf70563          	beq	a4,a5,800059b2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058ec:	4789                	li	a5,2
    800058ee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058f2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058f6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058fa:	f4c42783          	lw	a5,-180(s0)
    800058fe:	0017c713          	xori	a4,a5,1
    80005902:	8b05                	andi	a4,a4,1
    80005904:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005908:	0037f713          	andi	a4,a5,3
    8000590c:	00e03733          	snez	a4,a4
    80005910:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005914:	4007f793          	andi	a5,a5,1024
    80005918:	c791                	beqz	a5,80005924 <sys_open+0xd0>
    8000591a:	04449703          	lh	a4,68(s1)
    8000591e:	4789                	li	a5,2
    80005920:	0af70063          	beq	a4,a5,800059c0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	04e080e7          	jalr	78(ra) # 80003974 <iunlock>
  end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	9c6080e7          	jalr	-1594(ra) # 800042f4 <end_op>

  return fd;
    80005936:	854a                	mv	a0,s2
}
    80005938:	70ea                	ld	ra,184(sp)
    8000593a:	744a                	ld	s0,176(sp)
    8000593c:	74aa                	ld	s1,168(sp)
    8000593e:	790a                	ld	s2,160(sp)
    80005940:	69ea                	ld	s3,152(sp)
    80005942:	6129                	addi	sp,sp,192
    80005944:	8082                	ret
      end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	9ae080e7          	jalr	-1618(ra) # 800042f4 <end_op>
      return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	b7e5                	j	80005938 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005952:	f5040513          	addi	a0,s0,-176
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	702080e7          	jalr	1794(ra) # 80004058 <namei>
    8000595e:	84aa                	mv	s1,a0
    80005960:	c905                	beqz	a0,80005990 <sys_open+0x13c>
    ilock(ip);
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	f50080e7          	jalr	-176(ra) # 800038b2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000596a:	04449703          	lh	a4,68(s1)
    8000596e:	4785                	li	a5,1
    80005970:	f4f711e3          	bne	a4,a5,800058b2 <sys_open+0x5e>
    80005974:	f4c42783          	lw	a5,-180(s0)
    80005978:	d7b9                	beqz	a5,800058c6 <sys_open+0x72>
      iunlockput(ip);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	198080e7          	jalr	408(ra) # 80003b14 <iunlockput>
      end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	970080e7          	jalr	-1680(ra) # 800042f4 <end_op>
      return -1;
    8000598c:	557d                	li	a0,-1
    8000598e:	b76d                	j	80005938 <sys_open+0xe4>
      end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	964080e7          	jalr	-1692(ra) # 800042f4 <end_op>
      return -1;
    80005998:	557d                	li	a0,-1
    8000599a:	bf79                	j	80005938 <sys_open+0xe4>
    iunlockput(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	176080e7          	jalr	374(ra) # 80003b14 <iunlockput>
    end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	94e080e7          	jalr	-1714(ra) # 800042f4 <end_op>
    return -1;
    800059ae:	557d                	li	a0,-1
    800059b0:	b761                	j	80005938 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059b2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059b6:	04649783          	lh	a5,70(s1)
    800059ba:	02f99223          	sh	a5,36(s3)
    800059be:	bf25                	j	800058f6 <sys_open+0xa2>
    itrunc(ip);
    800059c0:	8526                	mv	a0,s1
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	ffe080e7          	jalr	-2(ra) # 800039c0 <itrunc>
    800059ca:	bfa9                	j	80005924 <sys_open+0xd0>
      fileclose(f);
    800059cc:	854e                	mv	a0,s3
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	d72080e7          	jalr	-654(ra) # 80004740 <fileclose>
    iunlockput(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	13c080e7          	jalr	316(ra) # 80003b14 <iunlockput>
    end_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	914080e7          	jalr	-1772(ra) # 800042f4 <end_op>
    return -1;
    800059e8:	557d                	li	a0,-1
    800059ea:	b7b9                	j	80005938 <sys_open+0xe4>

00000000800059ec <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059ec:	7175                	addi	sp,sp,-144
    800059ee:	e506                	sd	ra,136(sp)
    800059f0:	e122                	sd	s0,128(sp)
    800059f2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	880080e7          	jalr	-1920(ra) # 80004274 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059fc:	08000613          	li	a2,128
    80005a00:	f7040593          	addi	a1,s0,-144
    80005a04:	4501                	li	a0,0
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	248080e7          	jalr	584(ra) # 80002c4e <argstr>
    80005a0e:	02054963          	bltz	a0,80005a40 <sys_mkdir+0x54>
    80005a12:	4681                	li	a3,0
    80005a14:	4601                	li	a2,0
    80005a16:	4585                	li	a1,1
    80005a18:	f7040513          	addi	a0,s0,-144
    80005a1c:	00000097          	auipc	ra,0x0
    80005a20:	800080e7          	jalr	-2048(ra) # 8000521c <create>
    80005a24:	cd11                	beqz	a0,80005a40 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	0ee080e7          	jalr	238(ra) # 80003b14 <iunlockput>
  end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	8c6080e7          	jalr	-1850(ra) # 800042f4 <end_op>
  return 0;
    80005a36:	4501                	li	a0,0
}
    80005a38:	60aa                	ld	ra,136(sp)
    80005a3a:	640a                	ld	s0,128(sp)
    80005a3c:	6149                	addi	sp,sp,144
    80005a3e:	8082                	ret
    end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	8b4080e7          	jalr	-1868(ra) # 800042f4 <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	b7fd                	j	80005a38 <sys_mkdir+0x4c>

0000000080005a4c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a4c:	7135                	addi	sp,sp,-160
    80005a4e:	ed06                	sd	ra,152(sp)
    80005a50:	e922                	sd	s0,144(sp)
    80005a52:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	820080e7          	jalr	-2016(ra) # 80004274 <begin_op>
  argint(1, &major);
    80005a5c:	f6c40593          	addi	a1,s0,-148
    80005a60:	4505                	li	a0,1
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	1ac080e7          	jalr	428(ra) # 80002c0e <argint>
  argint(2, &minor);
    80005a6a:	f6840593          	addi	a1,s0,-152
    80005a6e:	4509                	li	a0,2
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	19e080e7          	jalr	414(ra) # 80002c0e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a78:	08000613          	li	a2,128
    80005a7c:	f7040593          	addi	a1,s0,-144
    80005a80:	4501                	li	a0,0
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	1cc080e7          	jalr	460(ra) # 80002c4e <argstr>
    80005a8a:	02054b63          	bltz	a0,80005ac0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a8e:	f6841683          	lh	a3,-152(s0)
    80005a92:	f6c41603          	lh	a2,-148(s0)
    80005a96:	458d                	li	a1,3
    80005a98:	f7040513          	addi	a0,s0,-144
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	780080e7          	jalr	1920(ra) # 8000521c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa4:	cd11                	beqz	a0,80005ac0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	06e080e7          	jalr	110(ra) # 80003b14 <iunlockput>
  end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	846080e7          	jalr	-1978(ra) # 800042f4 <end_op>
  return 0;
    80005ab6:	4501                	li	a0,0
}
    80005ab8:	60ea                	ld	ra,152(sp)
    80005aba:	644a                	ld	s0,144(sp)
    80005abc:	610d                	addi	sp,sp,160
    80005abe:	8082                	ret
    end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	834080e7          	jalr	-1996(ra) # 800042f4 <end_op>
    return -1;
    80005ac8:	557d                	li	a0,-1
    80005aca:	b7fd                	j	80005ab8 <sys_mknod+0x6c>

0000000080005acc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005acc:	7135                	addi	sp,sp,-160
    80005ace:	ed06                	sd	ra,152(sp)
    80005ad0:	e922                	sd	s0,144(sp)
    80005ad2:	e526                	sd	s1,136(sp)
    80005ad4:	e14a                	sd	s2,128(sp)
    80005ad6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ad8:	ffffc097          	auipc	ra,0xffffc
    80005adc:	ed4080e7          	jalr	-300(ra) # 800019ac <myproc>
    80005ae0:	892a                	mv	s2,a0
  
  begin_op();
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	792080e7          	jalr	1938(ra) # 80004274 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005aea:	08000613          	li	a2,128
    80005aee:	f6040593          	addi	a1,s0,-160
    80005af2:	4501                	li	a0,0
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	15a080e7          	jalr	346(ra) # 80002c4e <argstr>
    80005afc:	04054b63          	bltz	a0,80005b52 <sys_chdir+0x86>
    80005b00:	f6040513          	addi	a0,s0,-160
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	554080e7          	jalr	1364(ra) # 80004058 <namei>
    80005b0c:	84aa                	mv	s1,a0
    80005b0e:	c131                	beqz	a0,80005b52 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	da2080e7          	jalr	-606(ra) # 800038b2 <ilock>
  if(ip->type != T_DIR){
    80005b18:	04449703          	lh	a4,68(s1)
    80005b1c:	4785                	li	a5,1
    80005b1e:	04f71063          	bne	a4,a5,80005b5e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	e50080e7          	jalr	-432(ra) # 80003974 <iunlock>
  iput(p->cwd);
    80005b2c:	15093503          	ld	a0,336(s2)
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	f3c080e7          	jalr	-196(ra) # 80003a6c <iput>
  end_op();
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	7bc080e7          	jalr	1980(ra) # 800042f4 <end_op>
  p->cwd = ip;
    80005b40:	14993823          	sd	s1,336(s2)
  return 0;
    80005b44:	4501                	li	a0,0
}
    80005b46:	60ea                	ld	ra,152(sp)
    80005b48:	644a                	ld	s0,144(sp)
    80005b4a:	64aa                	ld	s1,136(sp)
    80005b4c:	690a                	ld	s2,128(sp)
    80005b4e:	610d                	addi	sp,sp,160
    80005b50:	8082                	ret
    end_op();
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	7a2080e7          	jalr	1954(ra) # 800042f4 <end_op>
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	b7ed                	j	80005b46 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	fb4080e7          	jalr	-76(ra) # 80003b14 <iunlockput>
    end_op();
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	78c080e7          	jalr	1932(ra) # 800042f4 <end_op>
    return -1;
    80005b70:	557d                	li	a0,-1
    80005b72:	bfd1                	j	80005b46 <sys_chdir+0x7a>

0000000080005b74 <sys_exec>:

uint64
sys_exec(void)
{
    80005b74:	7145                	addi	sp,sp,-464
    80005b76:	e786                	sd	ra,456(sp)
    80005b78:	e3a2                	sd	s0,448(sp)
    80005b7a:	ff26                	sd	s1,440(sp)
    80005b7c:	fb4a                	sd	s2,432(sp)
    80005b7e:	f74e                	sd	s3,424(sp)
    80005b80:	f352                	sd	s4,416(sp)
    80005b82:	ef56                	sd	s5,408(sp)
    80005b84:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b86:	e3840593          	addi	a1,s0,-456
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	0a2080e7          	jalr	162(ra) # 80002c2e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b94:	08000613          	li	a2,128
    80005b98:	f4040593          	addi	a1,s0,-192
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	0b0080e7          	jalr	176(ra) # 80002c4e <argstr>
    80005ba6:	87aa                	mv	a5,a0
    return -1;
    80005ba8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005baa:	0c07c263          	bltz	a5,80005c6e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bae:	10000613          	li	a2,256
    80005bb2:	4581                	li	a1,0
    80005bb4:	e4040513          	addi	a0,s0,-448
    80005bb8:	ffffb097          	auipc	ra,0xffffb
    80005bbc:	11a080e7          	jalr	282(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bc0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bc4:	89a6                	mv	s3,s1
    80005bc6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bc8:	02000a13          	li	s4,32
    80005bcc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bd0:	00391793          	slli	a5,s2,0x3
    80005bd4:	e3040593          	addi	a1,s0,-464
    80005bd8:	e3843503          	ld	a0,-456(s0)
    80005bdc:	953e                	add	a0,a0,a5
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	f92080e7          	jalr	-110(ra) # 80002b70 <fetchaddr>
    80005be6:	02054a63          	bltz	a0,80005c1a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bea:	e3043783          	ld	a5,-464(s0)
    80005bee:	c3b9                	beqz	a5,80005c34 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	ef6080e7          	jalr	-266(ra) # 80000ae6 <kalloc>
    80005bf8:	85aa                	mv	a1,a0
    80005bfa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bfe:	cd11                	beqz	a0,80005c1a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c00:	6605                	lui	a2,0x1
    80005c02:	e3043503          	ld	a0,-464(s0)
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	fbc080e7          	jalr	-68(ra) # 80002bc2 <fetchstr>
    80005c0e:	00054663          	bltz	a0,80005c1a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c12:	0905                	addi	s2,s2,1
    80005c14:	09a1                	addi	s3,s3,8
    80005c16:	fb491be3          	bne	s2,s4,80005bcc <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	10048913          	addi	s2,s1,256
    80005c1e:	6088                	ld	a0,0(s1)
    80005c20:	c531                	beqz	a0,80005c6c <sys_exec+0xf8>
    kfree(argv[i]);
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	dc8080e7          	jalr	-568(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2a:	04a1                	addi	s1,s1,8
    80005c2c:	ff2499e3          	bne	s1,s2,80005c1e <sys_exec+0xaa>
  return -1;
    80005c30:	557d                	li	a0,-1
    80005c32:	a835                	j	80005c6e <sys_exec+0xfa>
      argv[i] = 0;
    80005c34:	0a8e                	slli	s5,s5,0x3
    80005c36:	fc040793          	addi	a5,s0,-64
    80005c3a:	9abe                	add	s5,s5,a5
    80005c3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c40:	e4040593          	addi	a1,s0,-448
    80005c44:	f4040513          	addi	a0,s0,-192
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	172080e7          	jalr	370(ra) # 80004dba <exec>
    80005c50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c52:	10048993          	addi	s3,s1,256
    80005c56:	6088                	ld	a0,0(s1)
    80005c58:	c901                	beqz	a0,80005c68 <sys_exec+0xf4>
    kfree(argv[i]);
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	d90080e7          	jalr	-624(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c62:	04a1                	addi	s1,s1,8
    80005c64:	ff3499e3          	bne	s1,s3,80005c56 <sys_exec+0xe2>
  return ret;
    80005c68:	854a                	mv	a0,s2
    80005c6a:	a011                	j	80005c6e <sys_exec+0xfa>
  return -1;
    80005c6c:	557d                	li	a0,-1
}
    80005c6e:	60be                	ld	ra,456(sp)
    80005c70:	641e                	ld	s0,448(sp)
    80005c72:	74fa                	ld	s1,440(sp)
    80005c74:	795a                	ld	s2,432(sp)
    80005c76:	79ba                	ld	s3,424(sp)
    80005c78:	7a1a                	ld	s4,416(sp)
    80005c7a:	6afa                	ld	s5,408(sp)
    80005c7c:	6179                	addi	sp,sp,464
    80005c7e:	8082                	ret

0000000080005c80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c80:	7139                	addi	sp,sp,-64
    80005c82:	fc06                	sd	ra,56(sp)
    80005c84:	f822                	sd	s0,48(sp)
    80005c86:	f426                	sd	s1,40(sp)
    80005c88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	d22080e7          	jalr	-734(ra) # 800019ac <myproc>
    80005c92:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c94:	fd840593          	addi	a1,s0,-40
    80005c98:	4501                	li	a0,0
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	f94080e7          	jalr	-108(ra) # 80002c2e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ca2:	fc840593          	addi	a1,s0,-56
    80005ca6:	fd040513          	addi	a0,s0,-48
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	dc6080e7          	jalr	-570(ra) # 80004a70 <pipealloc>
    return -1;
    80005cb2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cb4:	0c054463          	bltz	a0,80005d7c <sys_pipe+0xfc>
  fd0 = -1;
    80005cb8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cbc:	fd043503          	ld	a0,-48(s0)
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	51a080e7          	jalr	1306(ra) # 800051da <fdalloc>
    80005cc8:	fca42223          	sw	a0,-60(s0)
    80005ccc:	08054b63          	bltz	a0,80005d62 <sys_pipe+0xe2>
    80005cd0:	fc843503          	ld	a0,-56(s0)
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	506080e7          	jalr	1286(ra) # 800051da <fdalloc>
    80005cdc:	fca42023          	sw	a0,-64(s0)
    80005ce0:	06054863          	bltz	a0,80005d50 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ce4:	4691                	li	a3,4
    80005ce6:	fc440613          	addi	a2,s0,-60
    80005cea:	fd843583          	ld	a1,-40(s0)
    80005cee:	68a8                	ld	a0,80(s1)
    80005cf0:	ffffc097          	auipc	ra,0xffffc
    80005cf4:	978080e7          	jalr	-1672(ra) # 80001668 <copyout>
    80005cf8:	02054063          	bltz	a0,80005d18 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cfc:	4691                	li	a3,4
    80005cfe:	fc040613          	addi	a2,s0,-64
    80005d02:	fd843583          	ld	a1,-40(s0)
    80005d06:	0591                	addi	a1,a1,4
    80005d08:	68a8                	ld	a0,80(s1)
    80005d0a:	ffffc097          	auipc	ra,0xffffc
    80005d0e:	95e080e7          	jalr	-1698(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d12:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d14:	06055463          	bgez	a0,80005d7c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d18:	fc442783          	lw	a5,-60(s0)
    80005d1c:	07e9                	addi	a5,a5,26
    80005d1e:	078e                	slli	a5,a5,0x3
    80005d20:	97a6                	add	a5,a5,s1
    80005d22:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d26:	fc042503          	lw	a0,-64(s0)
    80005d2a:	0569                	addi	a0,a0,26
    80005d2c:	050e                	slli	a0,a0,0x3
    80005d2e:	94aa                	add	s1,s1,a0
    80005d30:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d34:	fd043503          	ld	a0,-48(s0)
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	a08080e7          	jalr	-1528(ra) # 80004740 <fileclose>
    fileclose(wf);
    80005d40:	fc843503          	ld	a0,-56(s0)
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	9fc080e7          	jalr	-1540(ra) # 80004740 <fileclose>
    return -1;
    80005d4c:	57fd                	li	a5,-1
    80005d4e:	a03d                	j	80005d7c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d50:	fc442783          	lw	a5,-60(s0)
    80005d54:	0007c763          	bltz	a5,80005d62 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d58:	07e9                	addi	a5,a5,26
    80005d5a:	078e                	slli	a5,a5,0x3
    80005d5c:	94be                	add	s1,s1,a5
    80005d5e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d62:	fd043503          	ld	a0,-48(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	9da080e7          	jalr	-1574(ra) # 80004740 <fileclose>
    fileclose(wf);
    80005d6e:	fc843503          	ld	a0,-56(s0)
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	9ce080e7          	jalr	-1586(ra) # 80004740 <fileclose>
    return -1;
    80005d7a:	57fd                	li	a5,-1
}
    80005d7c:	853e                	mv	a0,a5
    80005d7e:	70e2                	ld	ra,56(sp)
    80005d80:	7442                	ld	s0,48(sp)
    80005d82:	74a2                	ld	s1,40(sp)
    80005d84:	6121                	addi	sp,sp,64
    80005d86:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	c6dfc0ef          	jal	ra,80002a3c <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b18080e7          	jalr	-1256(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	ae0080e7          	jalr	-1312(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	ab8080e7          	jalr	-1352(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	04a7cc63          	blt	a5,a0,80005f48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	8cc78793          	addi	a5,a5,-1844 # 800227c0 <disk>
    80005efc:	97aa                	add	a5,a5,a0
    80005efe:	0187c783          	lbu	a5,24(a5)
    80005f02:	ebb9                	bnez	a5,80005f58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f04:	00451613          	slli	a2,a0,0x4
    80005f08:	0001d797          	auipc	a5,0x1d
    80005f0c:	8b878793          	addi	a5,a5,-1864 # 800227c0 <disk>
    80005f10:	6394                	ld	a3,0(a5)
    80005f12:	96b2                	add	a3,a3,a2
    80005f14:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f18:	6398                	ld	a4,0(a5)
    80005f1a:	9732                	add	a4,a4,a2
    80005f1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f28:	953e                	add	a0,a0,a5
    80005f2a:	4785                	li	a5,1
    80005f2c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f30:	0001d517          	auipc	a0,0x1d
    80005f34:	8a850513          	addi	a0,a0,-1880 # 800227d8 <disk+0x18>
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	23a080e7          	jalr	570(ra) # 80002172 <wakeup>
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret
    panic("free_desc 1");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	8f050513          	addi	a0,a0,-1808 # 80008838 <syscalls+0x300>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5ee080e7          	jalr	1518(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f58:	00003517          	auipc	a0,0x3
    80005f5c:	8f050513          	addi	a0,a0,-1808 # 80008848 <syscalls+0x310>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>

0000000080005f68 <virtio_disk_init>:
{
    80005f68:	1101                	addi	sp,sp,-32
    80005f6a:	ec06                	sd	ra,24(sp)
    80005f6c:	e822                	sd	s0,16(sp)
    80005f6e:	e426                	sd	s1,8(sp)
    80005f70:	e04a                	sd	s2,0(sp)
    80005f72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f74:	00003597          	auipc	a1,0x3
    80005f78:	8e458593          	addi	a1,a1,-1820 # 80008858 <syscalls+0x320>
    80005f7c:	0001d517          	auipc	a0,0x1d
    80005f80:	96c50513          	addi	a0,a0,-1684 # 800228e8 <disk+0x128>
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	bc2080e7          	jalr	-1086(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f8c:	100017b7          	lui	a5,0x10001
    80005f90:	4398                	lw	a4,0(a5)
    80005f92:	2701                	sext.w	a4,a4
    80005f94:	747277b7          	lui	a5,0x74727
    80005f98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f9c:	14f71c63          	bne	a4,a5,800060f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fa0:	100017b7          	lui	a5,0x10001
    80005fa4:	43dc                	lw	a5,4(a5)
    80005fa6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa8:	4709                	li	a4,2
    80005faa:	14e79563          	bne	a5,a4,800060f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fae:	100017b7          	lui	a5,0x10001
    80005fb2:	479c                	lw	a5,8(a5)
    80005fb4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fb6:	12e79f63          	bne	a5,a4,800060f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	47d8                	lw	a4,12(a5)
    80005fc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc2:	554d47b7          	lui	a5,0x554d4
    80005fc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fca:	12f71563          	bne	a4,a5,800060f4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd6:	4705                	li	a4,1
    80005fd8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fda:	470d                	li	a4,3
    80005fdc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fde:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fe0:	c7ffe737          	lui	a4,0xc7ffe
    80005fe4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbe5f>
    80005fe8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fea:	2701                	sext.w	a4,a4
    80005fec:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	472d                	li	a4,11
    80005ff0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ff2:	5bbc                	lw	a5,112(a5)
    80005ff4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ff8:	8ba1                	andi	a5,a5,8
    80005ffa:	10078563          	beqz	a5,80006104 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006006:	43fc                	lw	a5,68(a5)
    80006008:	2781                	sext.w	a5,a5
    8000600a:	10079563          	bnez	a5,80006114 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000600e:	100017b7          	lui	a5,0x10001
    80006012:	5bdc                	lw	a5,52(a5)
    80006014:	2781                	sext.w	a5,a5
  if(max == 0)
    80006016:	10078763          	beqz	a5,80006124 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	10f77c63          	bgeu	a4,a5,80006134 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	ac6080e7          	jalr	-1338(ra) # 80000ae6 <kalloc>
    80006028:	0001c497          	auipc	s1,0x1c
    8000602c:	79848493          	addi	s1,s1,1944 # 800227c0 <disk>
    80006030:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	ab4080e7          	jalr	-1356(ra) # 80000ae6 <kalloc>
    8000603a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000603c:	ffffb097          	auipc	ra,0xffffb
    80006040:	aaa080e7          	jalr	-1366(ra) # 80000ae6 <kalloc>
    80006044:	87aa                	mv	a5,a0
    80006046:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006048:	6088                	ld	a0,0(s1)
    8000604a:	cd6d                	beqz	a0,80006144 <virtio_disk_init+0x1dc>
    8000604c:	0001c717          	auipc	a4,0x1c
    80006050:	77c73703          	ld	a4,1916(a4) # 800227c8 <disk+0x8>
    80006054:	cb65                	beqz	a4,80006144 <virtio_disk_init+0x1dc>
    80006056:	c7fd                	beqz	a5,80006144 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006058:	6605                	lui	a2,0x1
    8000605a:	4581                	li	a1,0
    8000605c:	ffffb097          	auipc	ra,0xffffb
    80006060:	c76080e7          	jalr	-906(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006064:	0001c497          	auipc	s1,0x1c
    80006068:	75c48493          	addi	s1,s1,1884 # 800227c0 <disk>
    8000606c:	6605                	lui	a2,0x1
    8000606e:	4581                	li	a1,0
    80006070:	6488                	ld	a0,8(s1)
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	c60080e7          	jalr	-928(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000607a:	6605                	lui	a2,0x1
    8000607c:	4581                	li	a1,0
    8000607e:	6888                	ld	a0,16(s1)
    80006080:	ffffb097          	auipc	ra,0xffffb
    80006084:	c52080e7          	jalr	-942(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	4721                	li	a4,8
    8000608e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006090:	4098                	lw	a4,0(s1)
    80006092:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006096:	40d8                	lw	a4,4(s1)
    80006098:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000609c:	6498                	ld	a4,8(s1)
    8000609e:	0007069b          	sext.w	a3,a4
    800060a2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060a6:	9701                	srai	a4,a4,0x20
    800060a8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060ac:	6898                	ld	a4,16(s1)
    800060ae:	0007069b          	sext.w	a3,a4
    800060b2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060b6:	9701                	srai	a4,a4,0x20
    800060b8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060bc:	4705                	li	a4,1
    800060be:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060c0:	00e48c23          	sb	a4,24(s1)
    800060c4:	00e48ca3          	sb	a4,25(s1)
    800060c8:	00e48d23          	sb	a4,26(s1)
    800060cc:	00e48da3          	sb	a4,27(s1)
    800060d0:	00e48e23          	sb	a4,28(s1)
    800060d4:	00e48ea3          	sb	a4,29(s1)
    800060d8:	00e48f23          	sb	a4,30(s1)
    800060dc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060e0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e4:	0727a823          	sw	s2,112(a5)
}
    800060e8:	60e2                	ld	ra,24(sp)
    800060ea:	6442                	ld	s0,16(sp)
    800060ec:	64a2                	ld	s1,8(sp)
    800060ee:	6902                	ld	s2,0(sp)
    800060f0:	6105                	addi	sp,sp,32
    800060f2:	8082                	ret
    panic("could not find virtio disk");
    800060f4:	00002517          	auipc	a0,0x2
    800060f8:	77450513          	addi	a0,a0,1908 # 80008868 <syscalls+0x330>
    800060fc:	ffffa097          	auipc	ra,0xffffa
    80006100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006104:	00002517          	auipc	a0,0x2
    80006108:	78450513          	addi	a0,a0,1924 # 80008888 <syscalls+0x350>
    8000610c:	ffffa097          	auipc	ra,0xffffa
    80006110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006114:	00002517          	auipc	a0,0x2
    80006118:	79450513          	addi	a0,a0,1940 # 800088a8 <syscalls+0x370>
    8000611c:	ffffa097          	auipc	ra,0xffffa
    80006120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	7a450513          	addi	a0,a0,1956 # 800088c8 <syscalls+0x390>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	7b450513          	addi	a0,a0,1972 # 800088e8 <syscalls+0x3b0>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	7c450513          	addi	a0,a0,1988 # 80008908 <syscalls+0x3d0>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>

0000000080006154 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006154:	7119                	addi	sp,sp,-128
    80006156:	fc86                	sd	ra,120(sp)
    80006158:	f8a2                	sd	s0,112(sp)
    8000615a:	f4a6                	sd	s1,104(sp)
    8000615c:	f0ca                	sd	s2,96(sp)
    8000615e:	ecce                	sd	s3,88(sp)
    80006160:	e8d2                	sd	s4,80(sp)
    80006162:	e4d6                	sd	s5,72(sp)
    80006164:	e0da                	sd	s6,64(sp)
    80006166:	fc5e                	sd	s7,56(sp)
    80006168:	f862                	sd	s8,48(sp)
    8000616a:	f466                	sd	s9,40(sp)
    8000616c:	f06a                	sd	s10,32(sp)
    8000616e:	ec6e                	sd	s11,24(sp)
    80006170:	0100                	addi	s0,sp,128
    80006172:	8aaa                	mv	s5,a0
    80006174:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006176:	00c52d03          	lw	s10,12(a0)
    8000617a:	001d1d1b          	slliw	s10,s10,0x1
    8000617e:	1d02                	slli	s10,s10,0x20
    80006180:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006184:	0001c517          	auipc	a0,0x1c
    80006188:	76450513          	addi	a0,a0,1892 # 800228e8 <disk+0x128>
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006194:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006196:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006198:	0001cb97          	auipc	s7,0x1c
    8000619c:	628b8b93          	addi	s7,s7,1576 # 800227c0 <disk>
  for(int i = 0; i < 3; i++){
    800061a0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061a2:	0001cc97          	auipc	s9,0x1c
    800061a6:	746c8c93          	addi	s9,s9,1862 # 800228e8 <disk+0x128>
    800061aa:	a08d                	j	8000620c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061ac:	00fb8733          	add	a4,s7,a5
    800061b0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061b4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061b6:	0207c563          	bltz	a5,800061e0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061ba:	2905                	addiw	s2,s2,1
    800061bc:	0611                	addi	a2,a2,4
    800061be:	05690c63          	beq	s2,s6,80006216 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061c2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061c4:	0001c717          	auipc	a4,0x1c
    800061c8:	5fc70713          	addi	a4,a4,1532 # 800227c0 <disk>
    800061cc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061ce:	01874683          	lbu	a3,24(a4)
    800061d2:	fee9                	bnez	a3,800061ac <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061d4:	2785                	addiw	a5,a5,1
    800061d6:	0705                	addi	a4,a4,1
    800061d8:	fe979be3          	bne	a5,s1,800061ce <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061dc:	57fd                	li	a5,-1
    800061de:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061e0:	01205d63          	blez	s2,800061fa <virtio_disk_rw+0xa6>
    800061e4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061e6:	000a2503          	lw	a0,0(s4)
    800061ea:	00000097          	auipc	ra,0x0
    800061ee:	cfc080e7          	jalr	-772(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    800061f2:	2d85                	addiw	s11,s11,1
    800061f4:	0a11                	addi	s4,s4,4
    800061f6:	ffb918e3          	bne	s2,s11,800061e6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061fa:	85e6                	mv	a1,s9
    800061fc:	0001c517          	auipc	a0,0x1c
    80006200:	5dc50513          	addi	a0,a0,1500 # 800227d8 <disk+0x18>
    80006204:	ffffc097          	auipc	ra,0xffffc
    80006208:	f0a080e7          	jalr	-246(ra) # 8000210e <sleep>
  for(int i = 0; i < 3; i++){
    8000620c:	f8040a13          	addi	s4,s0,-128
{
    80006210:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006212:	894e                	mv	s2,s3
    80006214:	b77d                	j	800061c2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006216:	f8042583          	lw	a1,-128(s0)
    8000621a:	00a58793          	addi	a5,a1,10
    8000621e:	0792                	slli	a5,a5,0x4

  if(write)
    80006220:	0001c617          	auipc	a2,0x1c
    80006224:	5a060613          	addi	a2,a2,1440 # 800227c0 <disk>
    80006228:	00f60733          	add	a4,a2,a5
    8000622c:	018036b3          	snez	a3,s8
    80006230:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006232:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006236:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000623a:	f6078693          	addi	a3,a5,-160
    8000623e:	6218                	ld	a4,0(a2)
    80006240:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006242:	00878513          	addi	a0,a5,8
    80006246:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006248:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000624a:	6208                	ld	a0,0(a2)
    8000624c:	96aa                	add	a3,a3,a0
    8000624e:	4741                	li	a4,16
    80006250:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006252:	4705                	li	a4,1
    80006254:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006258:	f8442703          	lw	a4,-124(s0)
    8000625c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006260:	0712                	slli	a4,a4,0x4
    80006262:	953a                	add	a0,a0,a4
    80006264:	058a8693          	addi	a3,s5,88
    80006268:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000626a:	6208                	ld	a0,0(a2)
    8000626c:	972a                	add	a4,a4,a0
    8000626e:	40000693          	li	a3,1024
    80006272:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006274:	001c3c13          	seqz	s8,s8
    80006278:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000627a:	001c6c13          	ori	s8,s8,1
    8000627e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006282:	f8842603          	lw	a2,-120(s0)
    80006286:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000628a:	0001c697          	auipc	a3,0x1c
    8000628e:	53668693          	addi	a3,a3,1334 # 800227c0 <disk>
    80006292:	00258713          	addi	a4,a1,2
    80006296:	0712                	slli	a4,a4,0x4
    80006298:	9736                	add	a4,a4,a3
    8000629a:	587d                	li	a6,-1
    8000629c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062a0:	0612                	slli	a2,a2,0x4
    800062a2:	9532                	add	a0,a0,a2
    800062a4:	f9078793          	addi	a5,a5,-112
    800062a8:	97b6                	add	a5,a5,a3
    800062aa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800062ac:	629c                	ld	a5,0(a3)
    800062ae:	97b2                	add	a5,a5,a2
    800062b0:	4605                	li	a2,1
    800062b2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062b4:	4509                	li	a0,2
    800062b6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800062ba:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062be:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062c2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062c6:	6698                	ld	a4,8(a3)
    800062c8:	00275783          	lhu	a5,2(a4)
    800062cc:	8b9d                	andi	a5,a5,7
    800062ce:	0786                	slli	a5,a5,0x1
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062d6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062da:	6698                	ld	a4,8(a3)
    800062dc:	00275783          	lhu	a5,2(a4)
    800062e0:	2785                	addiw	a5,a5,1
    800062e2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062e6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ea:	100017b7          	lui	a5,0x10001
    800062ee:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062f2:	004aa783          	lw	a5,4(s5)
    800062f6:	02c79163          	bne	a5,a2,80006318 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062fa:	0001c917          	auipc	s2,0x1c
    800062fe:	5ee90913          	addi	s2,s2,1518 # 800228e8 <disk+0x128>
  while(b->disk == 1) {
    80006302:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006304:	85ca                	mv	a1,s2
    80006306:	8556                	mv	a0,s5
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	e06080e7          	jalr	-506(ra) # 8000210e <sleep>
  while(b->disk == 1) {
    80006310:	004aa783          	lw	a5,4(s5)
    80006314:	fe9788e3          	beq	a5,s1,80006304 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006318:	f8042903          	lw	s2,-128(s0)
    8000631c:	00290793          	addi	a5,s2,2
    80006320:	00479713          	slli	a4,a5,0x4
    80006324:	0001c797          	auipc	a5,0x1c
    80006328:	49c78793          	addi	a5,a5,1180 # 800227c0 <disk>
    8000632c:	97ba                	add	a5,a5,a4
    8000632e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006332:	0001c997          	auipc	s3,0x1c
    80006336:	48e98993          	addi	s3,s3,1166 # 800227c0 <disk>
    8000633a:	00491713          	slli	a4,s2,0x4
    8000633e:	0009b783          	ld	a5,0(s3)
    80006342:	97ba                	add	a5,a5,a4
    80006344:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006348:	854a                	mv	a0,s2
    8000634a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000634e:	00000097          	auipc	ra,0x0
    80006352:	b98080e7          	jalr	-1128(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006356:	8885                	andi	s1,s1,1
    80006358:	f0ed                	bnez	s1,8000633a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000635a:	0001c517          	auipc	a0,0x1c
    8000635e:	58e50513          	addi	a0,a0,1422 # 800228e8 <disk+0x128>
    80006362:	ffffb097          	auipc	ra,0xffffb
    80006366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
}
    8000636a:	70e6                	ld	ra,120(sp)
    8000636c:	7446                	ld	s0,112(sp)
    8000636e:	74a6                	ld	s1,104(sp)
    80006370:	7906                	ld	s2,96(sp)
    80006372:	69e6                	ld	s3,88(sp)
    80006374:	6a46                	ld	s4,80(sp)
    80006376:	6aa6                	ld	s5,72(sp)
    80006378:	6b06                	ld	s6,64(sp)
    8000637a:	7be2                	ld	s7,56(sp)
    8000637c:	7c42                	ld	s8,48(sp)
    8000637e:	7ca2                	ld	s9,40(sp)
    80006380:	7d02                	ld	s10,32(sp)
    80006382:	6de2                	ld	s11,24(sp)
    80006384:	6109                	addi	sp,sp,128
    80006386:	8082                	ret

0000000080006388 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006388:	1101                	addi	sp,sp,-32
    8000638a:	ec06                	sd	ra,24(sp)
    8000638c:	e822                	sd	s0,16(sp)
    8000638e:	e426                	sd	s1,8(sp)
    80006390:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006392:	0001c497          	auipc	s1,0x1c
    80006396:	42e48493          	addi	s1,s1,1070 # 800227c0 <disk>
    8000639a:	0001c517          	auipc	a0,0x1c
    8000639e:	54e50513          	addi	a0,a0,1358 # 800228e8 <disk+0x128>
    800063a2:	ffffb097          	auipc	ra,0xffffb
    800063a6:	834080e7          	jalr	-1996(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063aa:	10001737          	lui	a4,0x10001
    800063ae:	533c                	lw	a5,96(a4)
    800063b0:	8b8d                	andi	a5,a5,3
    800063b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063b8:	689c                	ld	a5,16(s1)
    800063ba:	0204d703          	lhu	a4,32(s1)
    800063be:	0027d783          	lhu	a5,2(a5)
    800063c2:	04f70863          	beq	a4,a5,80006412 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063c6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ca:	6898                	ld	a4,16(s1)
    800063cc:	0204d783          	lhu	a5,32(s1)
    800063d0:	8b9d                	andi	a5,a5,7
    800063d2:	078e                	slli	a5,a5,0x3
    800063d4:	97ba                	add	a5,a5,a4
    800063d6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063d8:	00278713          	addi	a4,a5,2
    800063dc:	0712                	slli	a4,a4,0x4
    800063de:	9726                	add	a4,a4,s1
    800063e0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063e4:	e721                	bnez	a4,8000642c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063e6:	0789                	addi	a5,a5,2
    800063e8:	0792                	slli	a5,a5,0x4
    800063ea:	97a6                	add	a5,a5,s1
    800063ec:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063ee:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063f2:	ffffc097          	auipc	ra,0xffffc
    800063f6:	d80080e7          	jalr	-640(ra) # 80002172 <wakeup>

    disk.used_idx += 1;
    800063fa:	0204d783          	lhu	a5,32(s1)
    800063fe:	2785                	addiw	a5,a5,1
    80006400:	17c2                	slli	a5,a5,0x30
    80006402:	93c1                	srli	a5,a5,0x30
    80006404:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006408:	6898                	ld	a4,16(s1)
    8000640a:	00275703          	lhu	a4,2(a4)
    8000640e:	faf71ce3          	bne	a4,a5,800063c6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006412:	0001c517          	auipc	a0,0x1c
    80006416:	4d650513          	addi	a0,a0,1238 # 800228e8 <disk+0x128>
    8000641a:	ffffb097          	auipc	ra,0xffffb
    8000641e:	870080e7          	jalr	-1936(ra) # 80000c8a <release>
}
    80006422:	60e2                	ld	ra,24(sp)
    80006424:	6442                	ld	s0,16(sp)
    80006426:	64a2                	ld	s1,8(sp)
    80006428:	6105                	addi	sp,sp,32
    8000642a:	8082                	ret
      panic("virtio_disk_intr status");
    8000642c:	00002517          	auipc	a0,0x2
    80006430:	4f450513          	addi	a0,a0,1268 # 80008920 <syscalls+0x3e8>
    80006434:	ffffa097          	auipc	ra,0xffffa
    80006438:	10a080e7          	jalr	266(ra) # 8000053e <panic>
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
