//===-- MOSFrameLowering.cpp - MOS Frame Information ----------------------===//
//
// Part of LLVM-MOS, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the MOS implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "MOSFrameLowering.h"

#include "MCTargetDesc/MOSMCTargetDesc.h"
#include "MOSRegisterInfo.h"

#include "llvm/CodeGen/GlobalISel/CallLowering.h"
#include "llvm/CodeGen/GlobalISel/MachineIRBuilder.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/CodeGen/PseudoSourceValue.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/ErrorHandling.h"

#define DEBUG_TYPE "mos-framelowering"

using namespace llvm;

MOSFrameLowering::MOSFrameLowering()
    : TargetFrameLowering(StackGrowsDown, /*StackAlignment=*/Align(1),
                          /*LocalAreaOffset=*/0) {}

bool MOSFrameLowering::assignCalleeSavedSpillSlots(
    MachineFunction &MF, const TargetRegisterInfo *TRI,
    std::vector<CalleeSavedInfo> &CSI) const {
  // The static stack is cheap, so just use that. CSR use may still occur, e.g.,
  // if a long lived pointer is needed that will be indirected against many
  // times.
  if (MF.getFunction().doesNotRecurse())
    return false;

  // Place the CSI on the hard stack, which we don't explicitly model.
  // Accordingly, this does nothing, but says everything is fine.
  // spillCalleeSavedRegisters will emit the spills and reloads sequentially to
  // and from the hard stack.
  return true;
}

bool MOSFrameLowering::spillCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    ArrayRef<CalleeSavedInfo> CSI, const TargetRegisterInfo *TRI) const {
  // The static stack is cheap, so just use that.
  if (MBB.getParent()->getFunction().doesNotRecurse())
    return false;

  MachineIRBuilder Builder(MBB, MI);
  bool AMaybeLive = MBB.computeRegisterLiveness(TRI, MOS::A, MI) !=
                    MachineBasicBlock::LQR_Dead;
  if (AMaybeLive)
    Builder.buildInstr(MOS::STabs).addUse(MOS::A).addExternalSymbol("_SaveA");
  // There are intentionally very few CSRs, few enough to place on the hard
  // stack without much risk of overflow. This is the only non-temporary way the
  // compiler uses the hard stack, since the free CSRs can then be used with
  // impunity. This is slightly more expensive than saving/resting values
  // directly on the hard stack, but it's significantly simpler.
  for (const CalleeSavedInfo &CI : CSI) {
    Builder.buildInstr(MOS::LDimag8).addDef(MOS::A).addUse(CI.getReg());
    Builder.buildInstr(MOS::PHA);
  }
  if (AMaybeLive)
    Builder.buildInstr(MOS::LDabs).addDef(MOS::A).addExternalSymbol("_SaveA");
  return true;
}

bool MOSFrameLowering::restoreCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    MutableArrayRef<CalleeSavedInfo> CSI, const TargetRegisterInfo *TRI) const {
  // The static stack is cheap, so just use that.
  if (MBB.getParent()->getFunction().doesNotRecurse())
    return false;

  // Reverse the process of spillCalleeSavedRegisters.
  bool AMaybeLive = MBB.computeRegisterLiveness(TRI, MOS::A, MI) !=
                    MachineBasicBlock::LQR_Dead;
  MachineIRBuilder Builder(MBB, MI);
  if (AMaybeLive)
    Builder.buildInstr(MOS::STabs).addUse(MOS::A).addExternalSymbol("_SaveA");
  for (const CalleeSavedInfo &CI : reverse(CSI)) {
    Builder.buildInstr(MOS::PLA);
    Builder.buildInstr(MOS::STimag8).addDef(CI.getReg()).addUse(MOS::A);
  }
  if (AMaybeLive)
    Builder.buildInstr(MOS::LDabs).addDef(MOS::A).addExternalSymbol("_SaveA");
  return true;
}

void MOSFrameLowering::processFunctionBeforeFrameFinalized(
    MachineFunction &MF, RegScavenger *RS) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();

  // Assign all locals to static stack in non-recursive functions.
  if (MF.getFunction().doesNotRecurse()) {
    int64_t Offset = 0;
    for (int Idx = 0, End = MFI.getObjectIndexEnd(); Idx < End; ++Idx) {
      if (MFI.isDeadObjectIndex(Idx) || MFI.isVariableSizedObjectIndex(Idx))
        continue;

      MFI.setStackID(Idx, TargetStackID::NoAlloc);
      MFI.setObjectOffset(Idx, Offset);
      Offset += MFI.getObjectSize(Idx); // Static stack grows up.
    }
    return;
  }
}

MachineBasicBlock::iterator MOSFrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator MI) const {
  int64_t Offset = MI->getOperand(0).getImm();
  if (hasReservedCallFrame(MF) || !Offset)
    return MBB.erase(MI);

  const auto &TII = *MF.getSubtarget().getInstrInfo();
  if (MI->getOpcode() == TII.getCallFrameSetupOpcode())
    MI->getOperand(0).setImm(-Offset);
  MI->setDesc(TII.get(MOS::IncSP));
  MI->RemoveOperand(1);
  return MI;
}

void MOSFrameLowering::emitPrologue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();

  // If soft stack is used, decrease the soft stack pointer SP.
  if (MFI.getStackSize()) {
    MachineIRBuilder Builder(MBB, MBB.begin());
    Builder.buildInstr(MOS::IncSP).addImm(-MFI.getStackSize());
    if (hasFP(MF))
      Builder.buildCopy(MOS::RS1, Register(MOS::RS0));
  }
}

void MOSFrameLowering::emitEpilogue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();

  // If soft stack is used, increase the soft stack pointer SP.
  if (MFI.getStackSize()) {
    MachineIRBuilder Builder(MBB, MBB.getFirstTerminator());
    if (hasFP(MF))
      Builder.buildCopy(MOS::RS0, Register(MOS::RS1));
    Builder.buildInstr(MOS::IncSP).addImm(MFI.getStackSize());
  }
}

bool MOSFrameLowering::hasFP(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  return MFI.isFrameAddressTaken() || MFI.hasVarSizedObjects();
}

bool MOSFrameLowering::isSupportedStackID(TargetStackID::Value ID) const {
  switch (ID) {
  default:
    return false;
  case TargetStackID::Default:
  case TargetStackID::NoAlloc:
    return true;
  }
}

uint64_t MOSFrameLowering::staticSize(const MachineFrameInfo &MFI) const {
  uint64_t Size = 0;
  for (int i = 0, e = MFI.getObjectIndexEnd(); i < e; ++i)
    if (MFI.getStackID(i) == TargetStackID::NoAlloc)
      Size += MFI.getObjectSize(i);
  return Size;
}
