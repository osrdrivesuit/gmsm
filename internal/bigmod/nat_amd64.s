//go:build amd64 && gc && !purego
// +build amd64,gc,!purego

// func montgomeryLoop(d []uint, a []uint, b []uint, m []uint, m0inv uint) uint
TEXT ·montgomeryLoop(SB), $8-112
	MOVQ d_len+8(FP), CX
	MOVQ d_base+0(FP), BX
	MOVQ b_base+48(FP), SI
	MOVQ m_base+72(FP), DI
	MOVQ m0inv+96(FP), R8
	XORQ R9, R9
	XORQ R10, R10

outerLoop:
	MOVQ  a_base+24(FP), R11
	MOVQ  (R11)(R10*8), R11
	MOVQ  (SI), AX
	MULQ  R11
	MOVQ  AX, R13
	MOVQ  DX, R12
	ADDQ  (BX), R13
	ADCQ  $0x00, R12
	MOVQ  R8, R14
	IMULQ R13, R14
	BTRQ  $0x3f, R14
	MOVQ  (DI), AX
	MULQ  R14
	ADDQ  AX, R13
	ADCQ  DX, R12
	SHRQ  $0x3f, R12, R13
	XORQ  R12, R12
	INCQ  R12
	JMP   innerLoopCondition

innerLoop:
	MOVQ (SI)(R12*8), AX
	MULQ R11
	MOVQ AX, BP
	MOVQ DX, R15
	MOVQ (DI)(R12*8), AX
	MULQ R14
	ADDQ AX, BP
	ADCQ DX, R15
	ADDQ (BX)(R12*8), BP
	ADCQ $0x00, R15
	ADDQ R13, BP
	ADCQ $0x00, R15
	MOVQ BP, AX
	BTRQ $0x3f, AX
	MOVQ AX, -8(BX)(R12*8)
	SHRQ $0x3f, R15, BP
	MOVQ BP, R13
	INCQ R12

innerLoopCondition:
	CMPQ CX, R12
	JGT  innerLoop
	ADDQ R13, R9
	MOVQ R9, AX
	BTRQ $0x3f, AX
	MOVQ AX, -8(BX)(CX*8)
	SHRQ $0x3f, R9
	INCQ R10
	CMPQ CX, R10
	JGT  outerLoop
	MOVQ R9, ret+104(FP)
	RET
