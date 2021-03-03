# Copyright (c) 2019, University of Washington All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may
# be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This Makefile fragment defines rules/flags for compiling C/C++ files

include $(LIBRARIES_PATH)/platforms/dpi-vcs/compilation.mk

# RISC-V toolchain
RV64_CC = $(BLACKPARROT_DIR)/external/bin/riscv64-unknown-linux-gnu-gcc
RV64_CXX = $(BLACKPARROT_DIR)/external/bin/riscv64-unknown-linux-gnu-g++
RV64_OBJDUMP = $(BLACKPARROT_DIR)/external/bin/riscv64-unknown-linux-gnu-objdump
RV64_OBJCOPY = $(BLACKPARROT_DIR)/external/bin/riscv64-unknown-linux-gnu-objcopy

# BlackParrot NBF loader
# Usage: python /path/to/nbf/nbf.py --config --ncpus=1 --mem=prog.mem > <output>.nbf
BP_NBF = $(BLACKPARROT_DIR)/bp_common/software/py/nbf.py
PYTHON = python

# each regression target needs to build its .o from a .c and .h of the
# same name
%.o: %.c %.h
	# x86 target to satisfy VCS during compile time
	# TODO: Remove dummy test later
	$(CC) -c -o $@ test_bsg_scalar_print.c $(INCLUDES) $(CFLAGS) $(CDEFINES) -DBSG_TEST_NAME=$(patsubst %.c,%,$<)
	$(RV64_CC) -o $*.rv64o $< $(INCLUDES) $(CFLAGS) $(CDEFINES) -DBSG_TEST_NAME=$(patsubst %.c,%,$<) \
			-march=rv64ima -mabi=lp64 -mcmodel=medany \
			-static -nostartfiles -L$(BLACKPARROT_DIR)/bp_common/test/lib/ -lperch -Triscv.ld -UVCS -fPIC
	$(RV64_OBJDUMP) -d -t $*.rv64o > prog.dump
	$(RV64_OBJCOPY) -O verilog $*.rv64o prog.mem
	# Fixme: NBF commands hardcoded in manycore NBF
	# $(PYTHON) $(BP_NBF) --config --ncpus=1 --mem=prog.mem > prog.nbf

# ... or a .cpp and .hpp of the same name
%.o: %.cpp %.hpp
	# x86 target to satisfy VCS during compile time
	$(CXX) -c -o $@ $< $(INCLUDES) $(CXXFLAGS) $(CXXDEFINES) -DBSG_TEST_NAME=$(patsubst %.cpp,%,$<)
	$(RV64_CXX) -c -o $*.rv64o $< $(INCLUDES) $(CXXFLAGS) $(CXXDEFINES) -DBSG_TEST_NAME=$(patsubst %.cpp,%,$<) 
	$(RV64_OBJDUMP) -d -t $*.rv64o > prog.dump
	$(RV64_OBJCOPY) -O verilog $*.rv64o prog.mem
	# Fixme: NBF commands hardcoded in manycore NBF
	# $(PYTHON) $(BP_NBF) --config --ncpus=1 --mem=prog.mem > prog.nbf

.PHONY: platform.compilation.clean
platform.compilation.clean:
	rm -rf *.o
	rm -f prog.* *.rv64o