// Copyright (c) 2020, University of Washington All rights reserved.
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
#include <bsg_nonsynth_dpi_gpio.hpp>
#include <bsg_manycore_printing.h>
#include <bsg_manycore_coordinate.h>
#include <bsg_manycore_tracer.hpp>
#include <string>
#include <sstream>
#include <vector>
using namespace bsg_nonsynth_dpi;
using namespace std;

// There are TWO GPIO pins:
// -- One to control the TRACER (vanilla_operation_trace.csv)
// -- One to control the LOGGGER (vanilla.log)
// These correspond to the methods below
#define HB_MC_TRACER_TRACE_IDX 0
#define HB_MC_TRACER_LOG_IDX 1
#define HB_MC_TRACER_PINS 2
/**
 * Initialize an hb_mc_tracer_t instance
 * @param[in] p    A pointer to the hb_mc_tracer_t instance to initialize
 * @param[in] hier An implementation-dependent string. See the implementation for more details.
 * @return HB_MC_SUCCESS on success. Otherwise an error code defined in bsg_manycore_errno.h.
 *
 * NOTE: In this implementation, the argument hier indicates the path
 * to the top level module in simulation.
 */
int hb_mc_tracer_init(hb_mc_tracer_t *p, string &hier){
        dpi_gpio<HB_MC_TRACER_PINS> *tracer = new dpi_gpio<HB_MC_TRACER_PINS>(hier + ".trace_control");

        // Save the 2D vector
        *p = reinterpret_cast<hb_mc_tracer_t>(tracer);
        return HB_MC_SUCCESS;
}

/**
 * Clean up an hb_mc_tracer_t instance
 * @return HB_MC_SUCCESS on success. Otherwise an error code defined in bsg_manycore_errno.h.
 */
int hb_mc_tracer_cleanup(hb_mc_tracer_t *p){
        dpi_gpio<HB_MC_TRACER_PINS> *tracer = reinterpret_cast<dpi_gpio<HB_MC_TRACER_PINS> *>(*p);

        delete tracer;
        return HB_MC_SUCCESS;
}

/**
 * Enable trace file generation (vanilla_operation_trace.csv)
 * @param[in] p    A tracer instance initialized with hb_mc_tracer_init()
 * @return HB_MC_SUCCESS on success. Otherwise an error code defined in bsg_manycore_errno.h.
 */
int hb_mc_tracer_trace_enable(hb_mc_tracer_t p){
        dpi_gpio<HB_MC_TRACER_PINS> *tracer = reinterpret_cast<dpi_gpio<HB_MC_TRACER_PINS> *>(p);

        tracer->set(HB_MC_TRACER_TRACE_IDX, true);
        return HB_MC_SUCCESS;
}

/**
 * Disable trace file generation (vanilla_operation_trace.csv)
 * @param[in] p    A tracer instance initialized with hb_mc_tracer_init()
 * @return HB_MC_SUCCESS on success. Otherwise an error code defined in bsg_manycore_errno.h.
 */
int hb_mc_tracer_trace_disable(hb_mc_tracer_t p){
        dpi_gpio<HB_MC_TRACER_PINS> *tracer = reinterpret_cast<dpi_gpio<HB_MC_TRACER_PINS> *>(p);

        tracer->set(HB_MC_TRACER_TRACE_IDX, false);
        return HB_MC_SUCCESS;
}

/**
 * Enable log file generation (vanilla.log)
 * @param[in] p    A tracer instance initialized with hb_mc_tracer_init()
 * @return HB_MC_SUCCESS on success. Otherwise an error code defined in bsg_manycore_errno.h.
 */
int hb_mc_tracer_log_enable(hb_mc_tracer_t p){
        dpi_gpio<HB_MC_TRACER_PINS> *tracer = reinterpret_cast<dpi_gpio<HB_MC_TRACER_PINS> *>(p);

        tracer->set(HB_MC_TRACER_LOG_IDX, true);
        return HB_MC_SUCCESS;
}

/**
 * Disable log file generation (vanilla.log)
 * @param[in] p    A tracer instance initialized with hb_mc_tracer_init()
 * @return HB_MC_SUCCESS on success. Otherwise an error code defined in bsg_manycore_errno.h.
 */
int hb_mc_tracer_log_disable(hb_mc_tracer_t p){
        dpi_gpio<HB_MC_TRACER_PINS> *tracer = reinterpret_cast<dpi_gpio<HB_MC_TRACER_PINS> *>(p);

        tracer->set(HB_MC_TRACER_LOG_IDX, false);
        return HB_MC_SUCCESS;
}
