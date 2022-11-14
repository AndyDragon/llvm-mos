//===-- MOSCopyOpt.cpp - MOS Copy Optimization ---------------------------===//
//
// Part of LLVM-MOS, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the MOS pass to fully optimize COPY operations before
// lowering.
//
//===----------------------------------------------------------------------===//

#include "MOSCopyOpt.h"

#include "MCTargetDesc/MOSMCTargetDesc.h"
#include "MOS.h"
#include "MOSRegisterInfo.h"
#include "MOSSubtarget.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/LivePhysRegs.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"

#define DEBUG_TYPE "mos-copy-opt"

using namespace llvm;

namespace {

class MOSCopyOpt : public MachineFunctionPass {
public:
  static char ID;

  MOSCopyOpt() : MachineFunctionPass(ID) {
    llvm::initializeMOSCopyOptPass(*PassRegistry::getPassRegistry());
  }

  bool runOnMachineFunction(MachineFunction &MF) override;
};

} // namespace

// Scan backwards along possible traces from a given Machine Instruction and
// check that a condition holds along all of them. If the entry is reached, the
// default value is used for that trace.
template <typename CondT>
static bool allPrevTraces(MachineInstr &MI, const CondT &Cond, bool Default) {
  struct Entry {
    MachineBasicBlock &MBB;
    MachineBasicBlock::reverse_iterator I;
  };

  SmallVector<Entry> WorkList = {
      {*MI.getParent(), MachineBasicBlock::reverse_iterator(MI.getIterator())}};
  DenseSet<const MachineBasicBlock *> Seen;
  while (!WorkList.empty()) {
    Entry E = WorkList.back();
    WorkList.pop_back();
    if (Seen.contains(&E.MBB))
      continue;

    // Don't count the start MBB as seen until it's been seen as a predecessor.
    if (E.I == E.MBB.rbegin())
      Seen.insert(&E.MBB);

    bool Found = false;
    for (MachineInstr &MI : make_range(E.I, E.MBB.rend())) {
      Optional<bool> C = Cond(MI);
      if (!C)
        continue;
      if (!*C)
        return false;
      Found = true;
      break;
    }
    if (!Found) {
      if (E.MBB.isEntryBlock() && !Default)
        return false;
      for (MachineBasicBlock *MBB : E.MBB.predecessors())
        WorkList.push_back({*MBB, MBB->rbegin()});
    }
  }
  return true;
}

static Register findForwardedCopy(MachineInstr &MI,
                                  SmallVectorImpl<MachineInstr *> &NewSrcMIs) {
  assert(MI.isCopy());
  const TargetRegisterInfo &TRI = *MI.getMF()->getSubtarget().getRegisterInfo();
  Register Src = MI.getOperand(1).getReg();
  Register NewSrc = 0;
  if (!allPrevTraces(
          MI,
          [&](MachineInstr &MI) -> Optional<bool> {
            if (!MI.modifiesRegister(Src, &TRI))
              return llvm::None;
            if (!MI.isCopy())
              return false;
            Register Dst = MI.getOperand(0).getReg();
            if (Dst != Src)
              return false;
            Register NewSrcCand = MI.getOperand(1).getReg();
            if (NewSrc && NewSrc != NewSrcCand)
              return false;
            NewSrc = NewSrcCand;
            NewSrcMIs.push_back(&MI);
            return true;
          },
          /*Default=*/false)) {
    return 0;
  }
  return NewSrc;
}

static bool findLdImm(MachineInstr &MI,
                      SmallVectorImpl<MachineInstr *> &LdImms) {
  const TargetRegisterInfo &TRI = *MI.getMF()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII = *MI.getMF()->getSubtarget().getInstrInfo();
  Register Dst = MI.getOperand(0).getReg();
  Register Src = MI.getOperand(1).getReg();
  return allPrevTraces(
      MI,
      [&](MachineInstr &MI) -> Optional<bool> {
        if (!MI.modifiesRegister(Src, &TRI))
          return llvm::None;
        if (!MI.isMoveImmediate())
          return false;
        if (MI.getOperand(0).getReg() != Src)
          return false;
        const TargetRegisterClass *RC =
            TII.getRegClass(MI.getDesc(), 0, &TRI, *MI.getMF());
        if (!RC->contains(Dst))
          return false;
        if (!LdImms.empty() && !LdImms.front()->isIdenticalTo(MI))
          return false;
        LdImms.push_back(&MI);
        return true;
      },
      /*Default=*/false);
}

static bool isClobbered(MachineInstr &MI, Register NewSrc,
                        const SmallVectorImpl<MachineInstr *> &NewSrcMIs) {
  const TargetRegisterInfo &TRI = *MI.getMF()->getSubtarget().getRegisterInfo();
  return !allPrevTraces(
      MI,
      [&](MachineInstr &MI) -> Optional<bool> {
        if (is_contained(NewSrcMIs, &MI))
          return true;
        if (MI.modifiesRegister(NewSrc, &TRI))
          return false;
        return llvm::None;
      },
      /*Default=*/true);
}

bool MOSCopyOpt::runOnMachineFunction(MachineFunction &MF) {
  const MOSSubtarget &STI = MF.getSubtarget<MOSSubtarget>();
  const MOSRegisterInfo &TRI = *STI.getRegisterInfo();
  const TargetInstrInfo &TII = *STI.getInstrInfo();

  LLVM_DEBUG(dbgs() << MF.getName() << "\n");

  for (MachineBasicBlock &MBB : MF) {
    for (MachineInstr &MI : make_early_inc_range(MBB)) {
      if (!MI.isCopy())
        continue;

      Register Dst = MI.getOperand(0).getReg();
      Register Src = MI.getOperand(1).getReg();
      SmallVector<MachineInstr *> NewSrcMIs;
      Register NewSrc = findForwardedCopy(MI, NewSrcMIs);
      if (!NewSrc)
        continue;

      LLVM_DEBUG(dbgs() << MI);
      LLVM_DEBUG(dbgs() << "Found candidate: " << printReg(NewSrc, &TRI)
                        << '\n');

      if (TRI.copyCost(Dst, NewSrc, STI) > TRI.copyCost(Dst, Src, STI)) {
        LLVM_DEBUG(dbgs() << "New copy is more expensive.\n");
        continue;
      }

      if (isClobbered(MI, NewSrc, NewSrcMIs)) {
        LLVM_DEBUG(dbgs() << "Clobbered.\n");
        continue;
      }

      LLVM_DEBUG(dbgs() << "Rewriting copy: " << MI);
      for (MachineInstr *NewSrcMI : NewSrcMIs)
        NewSrcMI->clearRegisterKills(NewSrc, &TRI);
      if (Dst == NewSrc) {
        LLVM_DEBUG(dbgs() << "Erased.\n");
        MI.eraseFromParent();
      } else {
        MI.getOperand(1).setReg(NewSrc);
        MI.getOperand(1).setIsKill(false);
        LLVM_DEBUG(dbgs() << "Rewrote to: " << MI);
      }
    }

    for (MachineInstr &MI : make_early_inc_range(MBB)) {
      if (!MI.isCopy())
        continue;

      Register Dst = MI.getOperand(0).getReg();
      Register Src = MI.getOperand(1).getReg();

      if (!MOS::Imag16RegClass.contains(Dst) && Dst != MOS::C &&
          Dst != MOS::V && TRI.copyCost(Dst, Src, STI) <= 4)
        continue;

      SmallVector<MachineInstr *> LdImms;
      if (!findLdImm(MI, LdImms))
        continue;

      LLVM_DEBUG(dbgs() << MI);
      LLVM_DEBUG(dbgs() << "Found remat candidate: " << *LdImms.front());

      if (isClobbered(MI, LdImms.front()->getOperand(0).getReg(), LdImms)) {
        LLVM_DEBUG(dbgs() << "Clobbered.\n");
        continue;
      }

      for (MachineInstr *LdImm : LdImms)
        LdImm->clearRegisterKills(Src, &TRI);
      LdImms.front()->clearRegisterKills(Src, &TRI);
      TII.reMaterialize(MBB, MI, Dst, 0, *LdImms.front(), TRI);
      MI.eraseFromParent();
    }
  }

  for (MachineBasicBlock *MBB : post_order(&MF)) {
    LivePhysRegs LPR(TRI);

    recomputeLivenessFlags(*MBB);
    for (MachineInstr &MI : make_early_inc_range(*MBB)) {
      if (MI.isCopy() && MI.getOperand(0).isDead()) {
        LLVM_DEBUG(dbgs() << "Erasing dead copy: " << MI);
        MI.eraseFromParent();
      }
    }

    if (!MBB->isEntryBlock()) {
      recomputeLivenessFlags(*MBB);
      MBB->clearLiveIns();
      computeAndAddLiveIns(LPR, *MBB);
    }
  }
  return true;
}

char MOSCopyOpt::ID = 0;

INITIALIZE_PASS(MOSCopyOpt, DEBUG_TYPE, "Optimize copies for MOS", false, false)

MachineFunctionPass *llvm::createMOSCopyOptPass() { return new MOSCopyOpt(); }
