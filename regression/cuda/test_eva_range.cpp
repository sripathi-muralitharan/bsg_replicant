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

/*******************************************************************/
/* This kernel is designed to overload the memory system.          */
/* It forces cache evictions by striding to the line in the        */
/* same set of the same cache and doing a single store.            */
/* It then stores a word to an address maping to the evicted line. */
/*******************************************************************/

#include "test_eva_range.hpp"
#include <sys/stat.h>
#include <assert.h>

#define ALLOC_NAME "default_allocator"

#define CUDA_CALL(expr)                                                 \
        {                                                               \
                int __r;                                                \
                __r = expr;                                             \
                if (__r != HB_MC_SUCCESS) {                             \
                        bsg_pr_err("'%s' failed: %s\n", #expr, hb_mc_strerror(__r)); \
                        return __r;                                     \
                }                                                       \
        }

#define array_size(x)                           \
        (sizeof(x)/sizeof(x[0]))

////////////////////
// test addresses //
////////////////////
typedef struct test {
    hb_mc_eva_t address;
    hb_mc_eva_t value;
} test_t;

static
const test_t TESTS [] = {
    {0x83000000, 0xdeadbeef},
    {0x83fffffc, 0x0abcedef},
    {0x87000000, 0xcafebabe},
    {0x87fffffc, 0x12345678},
    {0x88000000, 0xb001ea00},
    {0x97000000, 0xfeed3e3e},
};

/////////////////
// test driver //
/////////////////
int test_loader (int argc, char **argv) {
        int rc;
        char *bin_path, *test_name;
        struct arguments_path args = {NULL, NULL};

        argp_parse (&argp_path, argc, argv, 0, 0, &args);
        bin_path = args.path;
        test_name = args.name;

        bsg_pr_test_info("Running %s "
                         "on a grid of 2x2 tile groups\n\n", test_name);

        // kernel name
        const char kernel_name [] = "kernel_eva_range";

        // init
        hb_mc_device_t device;
        CUDA_CALL(hb_mc_device_init_custom_dimensions(&device, test_name, 0, hb_mc_dimension(1,1)));
        CUDA_CALL(hb_mc_device_program_init(&device, bin_path, ALLOC_NAME, 0));

        // config tg
        hb_mc_dimension_t tg_dim = { .x = 1, .y = 1 };
        hb_mc_dimension_t grid_dim = { .x = 1, .y = 1 };

        //////////
        // Args //
        //////////

        // value read
        hb_mc_eva_t value_read_ptr;
        hb_mc_eva_t value_read = 0;
        CUDA_CALL(hb_mc_device_malloc(&device, sizeof(hb_mc_eva_t), &value_read_ptr));

        ///////////////
        // Run tests //
        ///////////////
        for (int t = 0; t < array_size(TESTS); t++) {
            // ptr
            hb_mc_eva_t ptr = TESTS[t].address;

            // value written
            hb_mc_eva_t value_written = TESTS[t].value;

            // write value
            CUDA_CALL(hb_mc_device_memcpy(&device, (void*)ptr, &value_written,
                                          sizeof(value_written),
                                          HB_MC_MEMCPY_TO_DEVICE));

            uint32_t kernel_argv[] = {ptr, value_read_ptr};

            // call kernel
            CUDA_CALL(hb_mc_kernel_enqueue (&device, grid_dim, tg_dim, kernel_name,
                                            array_size(kernel_argv), kernel_argv));

            CUDA_CALL(hb_mc_device_tile_groups_execute(&device));

            // read back
            CUDA_CALL(hb_mc_device_memcpy(&device, &value_read, (void*)value_read_ptr,
                                          sizeof(value_read),
                                          HB_MC_MEMCPY_TO_HOST));

            if (value_read != value_written) {
                bsg_pr_err("Test %d: address 0x%08" PRIx32 ": "
                           "host wrote 0x%08" PRIx32 ","
                           "vcore read 0x%08" PRIx32 "\n",
                           t, ptr, value_written, value_read);
                return HB_MC_FAIL;
            }
        }

        //////////
        // Exit //
        //////////
        CUDA_CALL(hb_mc_device_finish(&device));

        return HB_MC_SUCCESS;
}

#ifdef COSIM
void cosim_main(uint32_t *exit_code, char * args) {
        // We aren't passed command line arguments directly so we parse them
        // from *args. args is a string from VCS - to pass a string of arguments
        // to args, pass c_args to VCS as follows: +c_args="<space separated
        // list of args>"
        int argc = get_argc(args);
        char *argv[argc];
        get_argv(args, argc, argv);

#ifdef VCS
        svScope scope;
        scope = svGetScopeFromName("tb");
        svSetScope(scope);
#endif
        bsg_pr_test_info("Unified Main Regression Test (COSIMULATION)\n");
        int rc = test_loader(argc, argv);
        *exit_code = rc;
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return;
}
#else
int main(int argc, char ** argv) {
        bsg_pr_test_info("Unified Main CUDA Regression Test (F1)\n");
        int rc = test_loader(argc, argv);
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return rc;
}
#endif

