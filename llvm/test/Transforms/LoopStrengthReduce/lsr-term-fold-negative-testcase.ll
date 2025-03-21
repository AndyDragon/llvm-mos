; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 2
; REQUIRES: asserts
; RUN: opt < %s -passes=loop-reduce,loop-term-fold -S -debug 2>&1 | FileCheck %s

target datalayout = "e-p:64:64:64-n64"

define i32 @loop_variant(ptr %ar, i32 %n, i32 %m) {
; CHECK-LABEL: define i32 @loop_variant
; CHECK-SAME: (ptr [[AR:%.*]], i32 [[N:%.*]], i32 [[M:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[FOR_COND:%.*]]
; CHECK:       for.cond:
; CHECK-NEXT:    [[N_ADDR_0:%.*]] = phi i32 [ [[N]], [[ENTRY:%.*]] ], [ [[MUL:%.*]], [[FOR_COND]] ]
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[N_ADDR_0]], [[M]]
; CHECK-NEXT:    [[MUL]] = shl nsw i32 [[N_ADDR_0]], 1
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_COND]], label [[FOR_END:%.*]]
; CHECK:       for.end:
; CHECK-NEXT:    [[N_ADDR_0_LCSSA:%.*]] = phi i32 [ [[N_ADDR_0]], [[FOR_COND]] ]
; CHECK-NEXT:    ret i32 [[N_ADDR_0_LCSSA]]
;
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.cond, %entry
  %n.addr.0 = phi i32 [ %n, %entry ], [ %mul, %for.cond ]
  %cmp = icmp slt i32 %n.addr.0, %m
  %mul = shl nsw i32 %n.addr.0, 1
  br i1 %cmp, label %for.cond, label %for.end

for.end:                                          ; preds = %for.cond
  ret i32 %n.addr.0
}

define i32 @nested_loop(ptr %ar, i32 %n, i32 %m, i32 %o) {
; CHECK-LABEL: define i32 @nested_loop
; CHECK-SAME: (ptr [[AR:%.*]], i32 [[N:%.*]], i32 [[M:%.*]], i32 [[O:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP15:%.*]] = icmp sgt i32 [[O]], 0
; CHECK-NEXT:    br i1 [[CMP15]], label [[FOR_BODY_PREHEADER:%.*]], label [[FOR_COND_CLEANUP:%.*]]
; CHECK:       for.body.preheader:
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.cond.cleanup.loopexit:
; CHECK-NEXT:    [[CNT_1_LCSSA_LCSSA:%.*]] = phi i32 [ [[CNT_1_LCSSA:%.*]], [[FOR_COND_CLEANUP3:%.*]] ]
; CHECK-NEXT:    br label [[FOR_COND_CLEANUP]]
; CHECK:       for.cond.cleanup:
; CHECK-NEXT:    [[CNT_0_LCSSA:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[CNT_1_LCSSA_LCSSA]], [[FOR_COND_CLEANUP_LOOPEXIT:%.*]] ]
; CHECK-NEXT:    ret i32 [[CNT_0_LCSSA]]
; CHECK:       for.body:
; CHECK-NEXT:    [[I_017:%.*]] = phi i32 [ [[INC6:%.*]], [[FOR_COND_CLEANUP3]] ], [ 0, [[FOR_BODY_PREHEADER]] ]
; CHECK-NEXT:    [[CNT_016:%.*]] = phi i32 [ [[CNT_1_LCSSA]], [[FOR_COND_CLEANUP3]] ], [ 0, [[FOR_BODY_PREHEADER]] ]
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 [[N]], [[I_017]]
; CHECK-NEXT:    [[CMP212:%.*]] = icmp slt i32 [[SUB]], [[M]]
; CHECK-NEXT:    br i1 [[CMP212]], label [[FOR_BODY4_PREHEADER:%.*]], label [[FOR_COND_CLEANUP3]]
; CHECK:       for.body4.preheader:
; CHECK-NEXT:    br label [[FOR_BODY4:%.*]]
; CHECK:       for.cond.cleanup3.loopexit:
; CHECK-NEXT:    [[INC_LCSSA:%.*]] = phi i32 [ [[INC:%.*]], [[FOR_BODY4]] ]
; CHECK-NEXT:    br label [[FOR_COND_CLEANUP3]]
; CHECK:       for.cond.cleanup3:
; CHECK-NEXT:    [[CNT_1_LCSSA]] = phi i32 [ [[CNT_016]], [[FOR_BODY]] ], [ [[INC_LCSSA]], [[FOR_COND_CLEANUP3_LOOPEXIT:%.*]] ]
; CHECK-NEXT:    [[INC6]] = add nuw nsw i32 [[I_017]], 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[INC6]], [[O]]
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_BODY]], label [[FOR_COND_CLEANUP_LOOPEXIT]]
; CHECK:       for.body4:
; CHECK-NEXT:    [[J_014:%.*]] = phi i32 [ [[MUL:%.*]], [[FOR_BODY4]] ], [ [[SUB]], [[FOR_BODY4_PREHEADER]] ]
; CHECK-NEXT:    [[CNT_113:%.*]] = phi i32 [ [[INC]], [[FOR_BODY4]] ], [ [[CNT_016]], [[FOR_BODY4_PREHEADER]] ]
; CHECK-NEXT:    [[INC]] = add i32 [[CNT_113]], 1
; CHECK-NEXT:    [[MUL]] = shl nsw i32 [[J_014]], 1
; CHECK-NEXT:    [[CMP2:%.*]] = icmp slt i32 [[MUL]], [[M]]
; CHECK-NEXT:    br i1 [[CMP2]], label [[FOR_BODY4]], label [[FOR_COND_CLEANUP3_LOOPEXIT]]
;
entry:
  %cmp15 = icmp sgt i32 %o, 0
  br i1 %cmp15, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3, %entry
  %cnt.0.lcssa = phi i32 [ 0, %entry ], [ %cnt.1.lcssa, %for.cond.cleanup3 ]
  ret i32 %cnt.0.lcssa

for.body:                                         ; preds = %entry, %for.cond.cleanup3
  %i.017 = phi i32 [ %inc6, %for.cond.cleanup3 ], [ 0, %entry ]
  %cnt.016 = phi i32 [ %cnt.1.lcssa, %for.cond.cleanup3 ], [ 0, %entry ]
  %sub = sub nsw i32 %n, %i.017
  %cmp212 = icmp slt i32 %sub, %m
  br i1 %cmp212, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.body4, %for.body
  %cnt.1.lcssa = phi i32 [ %cnt.016, %for.body ], [ %inc, %for.body4 ]
  %inc6 = add nuw nsw i32 %i.017, 1
  %cmp = icmp slt i32 %inc6, %o
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.body4:                                        ; preds = %for.body, %for.body4
  %j.014 = phi i32 [ %mul, %for.body4 ], [ %sub, %for.body ]
  %cnt.113 = phi i32 [ %inc, %for.body4 ], [ %cnt.016, %for.body ]
  %inc = add nsw i32 %cnt.113, 1
  %mul = shl nsw i32 %j.014, 1
  %cmp2 = icmp slt i32 %mul, %m
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3
}

declare void @foo(ptr)

define void @NonAddRecIV(ptr %a) {
; CHECK-LABEL: define void @NonAddRecIV
; CHECK-SAME: (ptr [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[UGLYGEP:%.*]] = getelementptr i8, ptr [[A]], i32 84
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[A]], i64 148
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[LSR_IV1:%.*]] = phi ptr [ [[UGLYGEP2:%.*]], [[FOR_BODY]] ], [ [[UGLYGEP]], [[ENTRY:%.*]] ]
; CHECK-NEXT:    store i32 1, ptr [[LSR_IV1]], align 4
; CHECK-NEXT:    [[UGLYGEP2]] = getelementptr i8, ptr [[LSR_IV1]], i64 4
; CHECK-NEXT:    [[LSR_FOLD_TERM_COND_REPLACED_TERM_COND:%.*]] = icmp eq ptr [[UGLYGEP2]], [[SCEVGEP]]
; CHECK-NEXT:    br i1 [[LSR_FOLD_TERM_COND_REPLACED_TERM_COND]], label [[FOR_END:%.*]], label [[FOR_BODY]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  %uglygep = getelementptr i8, ptr %a, i32 84
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %lsr.iv1 = phi ptr [ %uglygep2, %for.body ], [ %uglygep, %entry ]
  %lsr.iv = phi i32 [ %lsr.iv.next, %for.body ], [ 1, %entry ]
  store i32 1, ptr %lsr.iv1, align 4
  %lsr.iv.next = mul nsw i32 %lsr.iv, 2
  %uglygep2 = getelementptr i8, ptr %lsr.iv1, i64 4
  %exitcond.not = icmp eq i32 %lsr.iv.next, 65536
  br i1 %exitcond.not, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

@fp_inc = common global float 0.000000e+00, align 4

define void @NonSCEVableIV(float %init, ptr %A, i32 %N) {
; CHECK-LABEL: define void @NonSCEVableIV
; CHECK-SAME: (float [[INIT:%.*]], ptr [[A:%.*]], i32 [[N:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = load float, ptr @fp_inc, align 4
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[LSR_IV1:%.*]] = phi ptr [ [[SCEVGEP:%.*]], [[FOR_BODY]] ], [ [[A]], [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[LSR_IV:%.*]] = phi i64 [ [[LSR_IV_NEXT:%.*]], [[FOR_BODY]] ], [ 1, [[ENTRY]] ]
; CHECK-NEXT:    [[X_05:%.*]] = phi float [ [[INIT]], [[ENTRY]] ], [ [[ADD:%.*]], [[FOR_BODY]] ]
; CHECK-NEXT:    store float [[X_05]], ptr [[LSR_IV1]], align 4
; CHECK-NEXT:    [[ADD]] = fsub float [[X_05]], [[TMP0]]
; CHECK-NEXT:    [[LFTR_WIDEIV:%.*]] = trunc i64 [[LSR_IV]] to i32
; CHECK-NEXT:    [[EXITCOND:%.*]] = icmp eq i32 [[LFTR_WIDEIV]], [[N]]
; CHECK-NEXT:    [[LSR_IV_NEXT]] = add nuw nsw i64 [[LSR_IV]], 1
; CHECK-NEXT:    [[SCEVGEP]] = getelementptr i8, ptr [[LSR_IV1]], i64 4
; CHECK-NEXT:    br i1 [[EXITCOND]], label [[FOR_END:%.*]], label [[FOR_BODY]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  %0 = load float, ptr @fp_inc, align 4
  br label %for.body

for.body:                                         ; preds = %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %x.05 = phi float [ %init, %entry ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %A, i64 %indvars.iv
  store float %x.05, ptr %arrayidx, align 4
  %add = fsub float %x.05, %0
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %lftr.wideiv = trunc i64 %indvars.iv.next to i32
  %exitcond = icmp eq i32 %lftr.wideiv, %N
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.end
  ret void
}

define void @NonIcmp(ptr %a) {
; CHECK-LABEL: define void @NonIcmp
; CHECK-SAME: (ptr [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[UGLYGEP:%.*]] = getelementptr i8, ptr [[A]], i64 84
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[LSR_IV2:%.*]] = phi i64 [ [[LSR_IV_NEXT3:%.*]], [[FOR_BODY]] ], [ 378, [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[LSR_IV1:%.*]] = phi ptr [ [[UGLYGEP2:%.*]], [[FOR_BODY]] ], [ [[UGLYGEP]], [[ENTRY]] ]
; CHECK-NEXT:    store i32 1, ptr [[LSR_IV1]], align 4
; CHECK-NEXT:    [[UGLYGEP2]] = getelementptr i8, ptr [[LSR_IV1]], i64 4
; CHECK-NEXT:    [[EXITCOND_NOT:%.*]] = icmp sle i64 [[LSR_IV2]], 0
; CHECK-NEXT:    [[FIND_COND:%.*]] = and i1 [[EXITCOND_NOT]], true
; CHECK-NEXT:    [[LSR_IV_NEXT3]] = add nsw i64 [[LSR_IV2]], -1
; CHECK-NEXT:    br i1 [[FIND_COND]], label [[FOR_END:%.*]], label [[FOR_BODY]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  %uglygep = getelementptr i8, ptr %a, i64 84
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %lsr.iv1 = phi ptr [ %uglygep2, %for.body ], [ %uglygep, %entry ]
  %lsr.iv = phi i64 [ %lsr.iv.next, %for.body ], [ 379, %entry ]
  store i32 1, ptr %lsr.iv1, align 4
  %lsr.iv.next = add nsw i64 %lsr.iv, -1
  %uglygep2 = getelementptr i8, ptr %lsr.iv1, i64 4
  %exitcond.not = icmp sle i64 %lsr.iv.next, 0
  %find.cond = and i1 %exitcond.not, 1
  br i1 %find.cond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

; After LSR, there are three IVs in this loop.  As a result, we have two
; alternate IVs to chose from.  At the moment, we chose the last, but this
; is somewhat arbitrary.
define void @TermCondMoreThanOneUse(ptr %a) {
; CHECK-LABEL: define void @TermCondMoreThanOneUse
; CHECK-SAME: (ptr [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[UGLYGEP:%.*]] = getelementptr i8, ptr [[A]], i64 84
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[A]], i64 1600
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[LSR_IV2:%.*]] = phi i64 [ [[LSR_IV_NEXT3:%.*]], [[FOR_BODY]] ], [ -378, [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[LSR_IV1:%.*]] = phi ptr [ [[UGLYGEP2:%.*]], [[FOR_BODY]] ], [ [[UGLYGEP]], [[ENTRY]] ]
; CHECK-NEXT:    store i32 1, ptr [[LSR_IV1]], align 4
; CHECK-NEXT:    [[UGLYGEP2]] = getelementptr i8, ptr [[LSR_IV1]], i64 4
; CHECK-NEXT:    [[EXITCOND_NOT:%.*]] = icmp eq i64 [[LSR_IV2]], 0
; CHECK-NEXT:    [[DUMMY:%.*]] = select i1 [[EXITCOND_NOT]], i8 0, i8 1
; CHECK-NEXT:    [[LSR_IV_NEXT3]] = add nsw i64 [[LSR_IV2]], 1
; CHECK-NEXT:    [[LSR_FOLD_TERM_COND_REPLACED_TERM_COND:%.*]] = icmp eq ptr [[UGLYGEP2]], [[SCEVGEP]]
; CHECK-NEXT:    br i1 [[LSR_FOLD_TERM_COND_REPLACED_TERM_COND]], label [[FOR_END:%.*]], label [[FOR_BODY]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  %uglygep = getelementptr i8, ptr %a, i64 84
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %lsr.iv1 = phi ptr [ %uglygep2, %for.body ], [ %uglygep, %entry ]
  %lsr.iv = phi i64 [ %lsr.iv.next, %for.body ], [ 379, %entry ]
  store i32 1, ptr %lsr.iv1, align 4
  %lsr.iv.next = add nsw i64 %lsr.iv, -1
  %uglygep2 = getelementptr i8, ptr %lsr.iv1, i64 4
  %exitcond.not = icmp eq i64 %lsr.iv.next, 0
  %dummy = select i1 %exitcond.not, i8 0, i8 1
  br i1 %exitcond.not, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

; The test case is reduced from FFmpeg/libavfilter/ebur128.c
; Testing check if terminating value is safe to expand
%struct.FFEBUR128State = type { i32, ptr, i64, i64 }

@histogram_energy_boundaries = global [1001 x double] zeroinitializer, align 8

define void @ebur128_calc_gating_block(ptr %st, ptr %optional_output) {
; CHECK-LABEL: define void @ebur128_calc_gating_block
; CHECK-SAME: (ptr [[ST:%.*]], ptr [[OPTIONAL_OUTPUT:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = load i32, ptr [[ST]], align 8
; CHECK-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
; CHECK-NEXT:    [[CMP28_NOT:%.*]] = icmp eq i32 [[TMP0]], 0
; CHECK-NEXT:    br i1 [[CMP28_NOT]], label [[FOR_END13:%.*]], label [[FOR_COND2_PREHEADER_LR_PH:%.*]]
; CHECK:       for.cond2.preheader.lr.ph:
; CHECK-NEXT:    [[AUDIO_DATA_INDEX:%.*]] = getelementptr inbounds [[STRUCT_FFEBUR128STATE:%.*]], ptr [[ST]], i64 0, i32 3
; CHECK-NEXT:    [[TMP1:%.*]] = load i64, ptr [[AUDIO_DATA_INDEX]], align 8
; CHECK-NEXT:    [[DIV:%.*]] = udiv i64 [[TMP1]], [[CONV]]
; CHECK-NEXT:    [[CMP525_NOT:%.*]] = icmp ult i64 [[TMP1]], [[CONV]]
; CHECK-NEXT:    [[AUDIO_DATA:%.*]] = getelementptr inbounds [[STRUCT_FFEBUR128STATE]], ptr [[ST]], i64 0, i32 1
; CHECK-NEXT:    [[UMAX:%.*]] = tail call i64 @llvm.umax.i64(i64 [[DIV]], i64 1)
; CHECK-NEXT:    [[TMP2:%.*]] = shl nuw nsw i64 [[CONV]], 3
; CHECK-NEXT:    br label [[FOR_COND2_PREHEADER:%.*]]
; CHECK:       for.cond2.preheader:
; CHECK-NEXT:    [[LSR_IV1:%.*]] = phi i64 [ [[LSR_IV_NEXT2:%.*]], [[FOR_INC11:%.*]] ], [ 0, [[FOR_COND2_PREHEADER_LR_PH]] ]
; CHECK-NEXT:    [[CHANNEL_SUM_030:%.*]] = phi double [ 0.000000e+00, [[FOR_COND2_PREHEADER_LR_PH]] ], [ [[CHANNEL_SUM_1_LCSSA:%.*]], [[FOR_INC11]] ]
; CHECK-NEXT:    [[C_029:%.*]] = phi i64 [ 0, [[FOR_COND2_PREHEADER_LR_PH]] ], [ [[INC12:%.*]], [[FOR_INC11]] ]
; CHECK-NEXT:    br i1 [[CMP525_NOT]], label [[FOR_INC11]], label [[FOR_BODY7_LR_PH:%.*]]
; CHECK:       for.body7.lr.ph:
; CHECK-NEXT:    [[TMP3:%.*]] = load ptr, ptr [[AUDIO_DATA]], align 8
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[TMP3]], i64 [[LSR_IV1]]
; CHECK-NEXT:    br label [[FOR_BODY7:%.*]]
; CHECK:       for.body7:
; CHECK-NEXT:    [[LSR_IV3:%.*]] = phi ptr [ [[SCEVGEP4:%.*]], [[FOR_BODY7]] ], [ [[SCEVGEP]], [[FOR_BODY7_LR_PH]] ]
; CHECK-NEXT:    [[LSR_IV:%.*]] = phi i64 [ [[LSR_IV_NEXT:%.*]], [[FOR_BODY7]] ], [ [[UMAX]], [[FOR_BODY7_LR_PH]] ]
; CHECK-NEXT:    [[CHANNEL_SUM_127:%.*]] = phi double [ [[CHANNEL_SUM_030]], [[FOR_BODY7_LR_PH]] ], [ [[ADD10:%.*]], [[FOR_BODY7]] ]
; CHECK-NEXT:    [[TMP4:%.*]] = load double, ptr [[LSR_IV3]], align 8
; CHECK-NEXT:    [[ADD10]] = fadd double [[CHANNEL_SUM_127]], [[TMP4]]
; CHECK-NEXT:    [[LSR_IV_NEXT]] = add i64 [[LSR_IV]], -1
; CHECK-NEXT:    [[SCEVGEP4]] = getelementptr i8, ptr [[LSR_IV3]], i64 [[TMP2]]
; CHECK-NEXT:    [[EXITCOND_NOT:%.*]] = icmp eq i64 [[LSR_IV_NEXT]], 0
; CHECK-NEXT:    br i1 [[EXITCOND_NOT]], label [[FOR_INC11_LOOPEXIT:%.*]], label [[FOR_BODY7]]
; CHECK:       for.inc11.loopexit:
; CHECK-NEXT:    [[ADD10_LCSSA:%.*]] = phi double [ [[ADD10]], [[FOR_BODY7]] ]
; CHECK-NEXT:    br label [[FOR_INC11]]
; CHECK:       for.inc11:
; CHECK-NEXT:    [[CHANNEL_SUM_1_LCSSA]] = phi double [ [[CHANNEL_SUM_030]], [[FOR_COND2_PREHEADER]] ], [ [[ADD10_LCSSA]], [[FOR_INC11_LOOPEXIT]] ]
; CHECK-NEXT:    [[INC12]] = add nuw nsw i64 [[C_029]], 1
; CHECK-NEXT:    [[LSR_IV_NEXT2]] = add nuw nsw i64 [[LSR_IV1]], 8
; CHECK-NEXT:    [[EXITCOND32_NOT:%.*]] = icmp eq i64 [[INC12]], [[CONV]]
; CHECK-NEXT:    br i1 [[EXITCOND32_NOT]], label [[FOR_END13_LOOPEXIT:%.*]], label [[FOR_COND2_PREHEADER]]
; CHECK:       for.end13.loopexit:
; CHECK-NEXT:    [[CHANNEL_SUM_1_LCSSA_LCSSA:%.*]] = phi double [ [[CHANNEL_SUM_1_LCSSA]], [[FOR_INC11]] ]
; CHECK-NEXT:    br label [[FOR_END13]]
; CHECK:       for.end13:
; CHECK-NEXT:    [[CHANNEL_SUM_0_LCSSA:%.*]] = phi double [ 0.000000e+00, [[ENTRY:%.*]] ], [ [[CHANNEL_SUM_1_LCSSA_LCSSA]], [[FOR_END13_LOOPEXIT]] ]
; CHECK-NEXT:    [[ADD14:%.*]] = fadd double [[CHANNEL_SUM_0_LCSSA]], 0.000000e+00
; CHECK-NEXT:    store double [[ADD14]], ptr [[OPTIONAL_OUTPUT]], align 8
; CHECK-NEXT:    ret void
;
entry:
  %0 = load i32, ptr %st, align 8
  %conv = zext i32 %0 to i64
  %cmp28.not = icmp eq i32 %0, 0
  br i1 %cmp28.not, label %for.end13, label %for.cond2.preheader.lr.ph

for.cond2.preheader.lr.ph:                        ; preds = %entry
  %audio_data_index = getelementptr inbounds %struct.FFEBUR128State, ptr %st, i64 0, i32 3
  %1 = load i64, ptr %audio_data_index, align 8
  %div = udiv i64 %1, %conv
  %cmp525.not = icmp ult i64 %1, %conv
  %audio_data = getelementptr inbounds %struct.FFEBUR128State, ptr %st, i64 0, i32 1
  %umax = tail call i64 @llvm.umax.i64(i64 %div, i64 1)
  br label %for.cond2.preheader

for.cond2.preheader:                              ; preds = %for.cond2.preheader.lr.ph, %for.inc11
  %channel_sum.030 = phi double [ 0.000000e+00, %for.cond2.preheader.lr.ph ], [ %channel_sum.1.lcssa, %for.inc11 ]
  %c.029 = phi i64 [ 0, %for.cond2.preheader.lr.ph ], [ %inc12, %for.inc11 ]
  br i1 %cmp525.not, label %for.inc11, label %for.body7.lr.ph

for.body7.lr.ph:                                  ; preds = %for.cond2.preheader
  %2 = load ptr, ptr %audio_data, align 8
  br label %for.body7

for.body7:                                        ; preds = %for.body7.lr.ph, %for.body7
  %channel_sum.127 = phi double [ %channel_sum.030, %for.body7.lr.ph ], [ %add10, %for.body7 ]
  %i.026 = phi i64 [ 0, %for.body7.lr.ph ], [ %inc, %for.body7 ]
  %mul = mul i64 %i.026, %conv
  %add = add i64 %mul, %c.029
  %arrayidx = getelementptr inbounds double, ptr %2, i64 %add
  %3 = load double, ptr %arrayidx, align 8
  %add10 = fadd double %channel_sum.127, %3
  %inc = add nuw i64 %i.026, 1
  %exitcond.not = icmp eq i64 %inc, %umax
  br i1 %exitcond.not, label %for.inc11, label %for.body7

for.inc11:                                        ; preds = %for.body7, %for.cond2.preheader
  %channel_sum.1.lcssa = phi double [ %channel_sum.030, %for.cond2.preheader ], [ %add10, %for.body7 ]
  %inc12 = add nuw nsw i64 %c.029, 1
  %exitcond32.not = icmp eq i64 %inc12, %conv
  br i1 %exitcond32.not, label %for.end13, label %for.cond2.preheader

for.end13:                                        ; preds = %for.inc11, %entry
  %channel_sum.0.lcssa = phi double [ 0.000000e+00, %entry ], [ %channel_sum.1.lcssa, %for.inc11 ]
  %add14 = fadd double %channel_sum.0.lcssa, 0.000000e+00
  store double %add14, ptr %optional_output, align 8
  ret void
}

declare i64 @llvm.umax.i64(i64, i64)

%struct.PAKT_INFO = type { i32, i32, i32, [0 x i32] }

define i64 @alac_seek(ptr %0) {
; CHECK-LABEL: define i64 @alac_seek
; CHECK-SAME: (ptr [[TMP0:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[DIV:%.*]] = udiv i64 1, 0
; CHECK-NEXT:    [[TMP1:%.*]] = add nuw nsw i64 [[DIV]], 1
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[TMP0]], i64 12
; CHECK-NEXT:    br label [[FOR_BODY_I:%.*]]
; CHECK:       for.body.i:
; CHECK-NEXT:    [[LSR_IV1:%.*]] = phi ptr [ [[SCEVGEP2:%.*]], [[FOR_BODY_I]] ], [ [[SCEVGEP]], [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[LSR_IV:%.*]] = phi i64 [ [[LSR_IV_NEXT:%.*]], [[FOR_BODY_I]] ], [ [[TMP1]], [[ENTRY]] ]
; CHECK-NEXT:    [[TMP2:%.*]] = load i32, ptr [[LSR_IV1]], align 4
; CHECK-NEXT:    [[LSR_IV_NEXT]] = add i64 [[LSR_IV]], -1
; CHECK-NEXT:    [[SCEVGEP2]] = getelementptr i8, ptr [[LSR_IV1]], i64 4
; CHECK-NEXT:    [[EXITCOND_NOT_I:%.*]] = icmp eq i64 [[LSR_IV_NEXT]], 0
; CHECK-NEXT:    br i1 [[EXITCOND_NOT_I]], label [[ALAC_PAKT_BLOCK_OFFSET_EXIT:%.*]], label [[FOR_BODY_I]]
; CHECK:       alac_pakt_block_offset.exit:
; CHECK-NEXT:    ret i64 0
;
entry:
  %div = udiv i64 1, 0
  br label %for.body.i

for.body.i:                                       ; preds = %for.body.i, %entry
  %indvars.iv.i = phi i64 [ 0, %entry ], [ %indvars.iv.next.i, %for.body.i ]
  %arrayidx.i = getelementptr %struct.PAKT_INFO, ptr %0, i64 0, i32 3, i64 %indvars.iv.i
  %1 = load i32, ptr %arrayidx.i, align 4
  %indvars.iv.next.i = add i64 %indvars.iv.i, 1
  %exitcond.not.i = icmp eq i64 %indvars.iv.i, %div
  br i1 %exitcond.not.i, label %alac_pakt_block_offset.exit, label %for.body.i

alac_pakt_block_offset.exit:                      ; preds = %for.body.i
  ret i64 0
}
