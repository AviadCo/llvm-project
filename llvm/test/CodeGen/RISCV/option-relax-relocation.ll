;; With +relax, J below needs a relocation to ensure the target is correct
;; after linker relaxation. See https://github.com/ClangBuiltLinux/linux/issues/1965

; RUN: llc -mtriple=riscv64 -mattr=-relax -filetype=obj < %s \
; RUN:     | llvm-objdump -d -r - | FileCheck %s --check-prefixes=CHECK,NORELAX
; RUN: llc -mtriple=riscv64 -mattr=+relax -filetype=obj < %s \
; RUN:     | llvm-objdump -d -r - | FileCheck %s --check-prefixes=CHECK,RELAX

; CHECK:        j       {{.*}}
; RELAX-NEXT:           R_RISCV_JAL  {{.*}}
; CHECK-NEXT:   auipc   ra, 0x0
; CHECK-NEXT:           R_RISCV_CALL_PLT     f
; RELAX-NEXT:           R_RISCV_RELAX        *ABS*
; CHECK-NEXT:   jalr    ra
; CHECK-NEXT:   j       {{.*}}
; CHECK-NEXT:   j       {{.*}}
; RELAX-NEXT:           R_RISCV_JAL  .L0
; NORELAX-NEXT: li      a0, 0x0
; RELAX-EMPTY:

define dso_local noundef signext i32 @main() local_unnamed_addr #0 {
entry:
  callbr void asm sideeffect ".option push\0A.option norelax\0Aj $0\0A.option pop\0A", "!i"()
          to label %asm.fallthrough [label %label]

asm.fallthrough:                                  ; preds = %entry
  tail call void @f()
  callbr void asm sideeffect ".option push\0A.option norelax\0Aj $0\0A.option pop\0A", "!i"()
          to label %asm.fallthrough [label %label]
  br label %label

label:                                            ; preds = %asm.fallthrough, %entry
  ret i32 0
}

declare void @f()

attributes #0 = { nounwind "target-features"="-c,+relax" }
