// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vjedro_1_addi_tb__pch.h"

//============================================================
// Constructors

Vjedro_1_addi_tb::Vjedro_1_addi_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vjedro_1_addi_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vjedro_1_addi_tb::Vjedro_1_addi_tb(const char* _vcname__)
    : Vjedro_1_addi_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vjedro_1_addi_tb::~Vjedro_1_addi_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vjedro_1_addi_tb___024root___eval_debug_assertions(Vjedro_1_addi_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Vjedro_1_addi_tb___024root___eval_static(Vjedro_1_addi_tb___024root* vlSelf);
void Vjedro_1_addi_tb___024root___eval_initial(Vjedro_1_addi_tb___024root* vlSelf);
void Vjedro_1_addi_tb___024root___eval_settle(Vjedro_1_addi_tb___024root* vlSelf);
void Vjedro_1_addi_tb___024root___eval(Vjedro_1_addi_tb___024root* vlSelf);

void Vjedro_1_addi_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vjedro_1_addi_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vjedro_1_addi_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vjedro_1_addi_tb___024root___eval_static(&(vlSymsp->TOP));
        Vjedro_1_addi_tb___024root___eval_initial(&(vlSymsp->TOP));
        Vjedro_1_addi_tb___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vjedro_1_addi_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vjedro_1_addi_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vjedro_1_addi_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vjedro_1_addi_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vjedro_1_addi_tb___024root___eval_final(Vjedro_1_addi_tb___024root* vlSelf);

VL_ATTR_COLD void Vjedro_1_addi_tb::final() {
    Vjedro_1_addi_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vjedro_1_addi_tb::hierName() const { return vlSymsp->name(); }
const char* Vjedro_1_addi_tb::modelName() const { return "Vjedro_1_addi_tb"; }
unsigned Vjedro_1_addi_tb::threads() const { return 1; }
void Vjedro_1_addi_tb::prepareClone() const { contextp()->prepareClone(); }
void Vjedro_1_addi_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
