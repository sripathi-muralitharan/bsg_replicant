// Copyright (c) 2019, University of Washington All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// 
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
// 
// Neither the name of the copyright holder nor the names of its contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// This file implements the SimulationWrapper object. 

#ifndef __BSG_MANYCORE_SIMULATOR_HPP
#define __BSG_MANYCORE_SIMULATOR_HPP
#include <string>

class SimulationWrapper{
        // This is the generic pointer for implementation-specific
        // simulator details. In Verilator, this is
        // Vmanycore_tb_top. In VCS this is the scope
        // for DPI.
        void *top = nullptr;

public:
        SimulationWrapper(std::string &hierarchy);
        ~SimulationWrapper();

        // Change the assertion state. 

        // When Verilator simulation starts, we want to disable
        // assertion because it is a two-state simulator and the lack
        // of z/x may cause erroneous assertions.
        //
        // This does not need to be implemented in 4-state simulators
        // like VCS
        void assertOn(bool val);

        // Cause time to proceed. 
        // eval() wraps the Vmanycore_tb_top->eval() function.
        void eval();
};
#endif // __BSG_MANYCORE_SIMULATOR_HPP
