//go:build arm64 && !purego
// +build arm64,!purego

#include "textflag.h"

DATA bit_reverse_table_l<>+0x00(SB)/8, $0x0e060a020c040800
DATA bit_reverse_table_l<>+0x08(SB)/8, $0x0f070b030d050901
GLOBL bit_reverse_table_l<>(SB), RODATA, $16

DATA bit_reverse_table_h<>+0x00(SB)/8, $0xe060a020c0408000
DATA bit_reverse_table_h<>+0x08(SB)/8, $0xf070b030d0509010
GLOBL bit_reverse_table_h<>(SB), RODATA, $16

DATA bit_reverse_and_table<>+0x00(SB)/8, $0x0f0f0f0f0f0f0f0f
DATA bit_reverse_and_table<>+0x08(SB)/8, $0x0f0f0f0f0f0f0f0f
GLOBL bit_reverse_and_table<>(SB), RODATA, $16

DATA shuf_mask_dw0_0_dw1_0<>+0x00(SB)/8, $0xffffffff03020100
DATA shuf_mask_dw0_0_dw1_0<>+0x08(SB)/8, $0xffffffff07060504
GLOBL shuf_mask_dw0_0_dw1_0<>(SB), RODATA, $16

DATA shuf_mask_dw2_0_dw3_0<>+0x00(SB)/8, $0xffffffff0b0a0908
DATA shuf_mask_dw2_0_dw3_0<>+0x08(SB)/8, $0xffffffff0f0e0d0c
GLOBL shuf_mask_dw2_0_dw3_0<>(SB), RODATA, $16

#define AX R2
#define BX R3
#define CX R4
#define DX R5

#define XTMP1 V1
#define XTMP2 V2
#define XTMP3 V3
#define XTMP4 V4
#define XTMP5 V5
#define XTMP6 V6
#define XDATA V7
#define XDIGEST V8
#define KS_L V9
#define KS_M1 V10
#define KS_M2 V11
#define KS_H V12
#define BIT_REV_TAB_L V20
#define BIT_REV_TAB_H V21
#define BIT_REV_AND_TAB V22
#define SHUF_MASK_DW0_DW1 V23
#define SHUF_MASK_DW2_DW3 V24

#define LOAD_GLOBAL_DATA() \
	LDP bit_reverse_table_l<>(SB), (R0, R1)                   \
	VMOV R0, BIT_REV_TAB_L.D[0]                               \
	VMOV R1, BIT_REV_TAB_L.D[1]                               \
	LDP bit_reverse_table_h<>(SB), (R0, R1)                   \
	VMOV R0, BIT_REV_TAB_H.D[0]                               \
	VMOV R1, BIT_REV_TAB_H.D[1]                               \	
	LDP bit_reverse_and_table<>(SB), (R0, R1)                 \
	VMOV R0, BIT_REV_AND_TAB.D[0]                             \
	VMOV R1, BIT_REV_AND_TAB.D[1]                             \
	LDP shuf_mask_dw0_0_dw1_0<>(SB), (R0, R1)                 \
	VMOV R0, SHUF_MASK_DW0_DW1.D[0]                           \
	VMOV R1, SHUF_MASK_DW0_DW1.D[1]                           \
	LDP shuf_mask_dw2_0_dw3_0<>(SB), (R0, R1)                 \
	VMOV R0, SHUF_MASK_DW2_DW3.D[0]                           \
	VMOV R1, SHUF_MASK_DW2_DW3.D[1]

// func eia3Round16B(t *uint32, keyStream *uint32, p *byte, tagSize int)
TEXT ·eia3Round16B(SB),NOSPLIT,$0
	MOVD t+0(FP), AX
	MOVD ks+8(FP), BX
	MOVD p+16(FP), CX
	MOVD tagSize+24(FP), DX

	LOAD_GLOBAL_DATA()

	// Reverse data bytes
	VLD1 (CX), [XDATA.B16]
	VAND BIT_REV_AND_TAB.B16, XDATA.B16, XTMP3.B16
	VUSHR $4, XDATA.S4, XTMP1.S4
	VAND BIT_REV_AND_TAB.B16, XTMP1.B16, XTMP1.B16

	VTBL XTMP3.B16, [BIT_REV_TAB_H.B16], XTMP3.B16
	VTBL XTMP1.B16, [BIT_REV_TAB_L.B16], XTMP1.B16
	VEOR XTMP1.B16, XTMP3.B16, XTMP3.B16 // XTMP3 - bit reverse data bytes

	// ZUC authentication part, 4x32 data bits
	// setup KS
	VLD1 (BX), [XTMP1.B16, XTMP2.B16]
	VST1 [XTMP2.B16], (BX) // Copy last 16 bytes of KS to the front
	// TODO: Any better solution???
	VMOV XTMP1.S[1], KS_L.S[0]
	VMOV XTMP1.S[0], KS_L.S[1]
	VMOV XTMP1.S[2], KS_L.S[2]
	VMOV XTMP1.S[1], KS_L.S[3]	// KS bits [63:32 31:0 95:64 63:32]
	VMOV XTMP1.S[3], KS_M1.S[0]
	VMOV XTMP1.S[2], KS_M1.S[1]
	VMOV XTMP2.S[0], KS_M1.S[2]
	VMOV XTMP1.S[3], KS_M1.S[3]	// KS bits [127:96 95:64 159:128 127:96]

	// setup DATA
	VTBL SHUF_MASK_DW0_DW1.B16, [XTMP3.B16], XTMP1.B16 // XTMP1 - Data bits [31:0 0s 63:32 0s]
	VTBL SHUF_MASK_DW2_DW3.B16, [XTMP3.B16], XTMP2.B16 // XTMP2 - Data bits [95:64 0s 127:96 0s]

	// clmul
	// xor the results from 4 32-bit words together
	// Calculate lower 32 bits of tag
	VPMULL KS_L.D1, XTMP1.D1, XTMP3.Q1
	VPMULL2 KS_L.D2, XTMP1.D2, XTMP4.Q1
	VPMULL KS_M1.D1, XTMP2.D1, XTMP5.Q1
	VPMULL2 KS_M1.D2, XTMP2.D2, XTMP6.Q1

	VEOR XTMP3.B16, XTMP4.B16, XTMP3.B16
	VEOR XTMP5.B16, XTMP6.B16, XTMP5.B16
	VEOR XTMP3.B16, XTMP5.B16, XDIGEST.B16

	VMOV XDIGEST.S[1], R10
	MOVW (AX), R11
	EORW R10, R11
	MOVW R11, (AX)

	RET
