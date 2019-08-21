# Makefile targets:
#
# all/install   build and install the package
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_COMPILE_PATH path to the build's ebin directory
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

TOP := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SRC_TOP = $(TOP)/src

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj

GNU_TARGET_NAME = $(notdir $(CROSSCOMPILE))
GNU_HOST_NAME =

MAKE_ENV = KCONFIG_NOTIMESTAMP=1

ifneq ($(CROSSCOMPILE),)
MAKE_OPTS += CROSS_COMPILE="$(CROSSCOMPILE)-"
endif

ifeq ($(shell uname -s),Darwin)
# Fixes to build on OSX
MAKE = $(shell which gmake)
ifeq ($(MAKE),)
    $(error gmake required to build. Install by running "brew install homebrew/core/make")
endif

SED = $(shell which gsed)
ifeq ($(SED),)
    $(error gsed required to build. Install by running "brew install gnu-sed")
endif

MAKE_OPTS += SED=$(SED)

ifeq ($(CROSSCOMPILE),)
$(warning Native OS compilation is not supported on OSX. Skipping compilation.)

# Do a fake install for host
TARGETS = fake_install
endif
endif
TARGETS ?= install

calling_from_make:
	mix compile

all: $(TARGETS)

install: librpitx_cxx
	$(MAKE_ENV) $(MAKE) $(MAKE_OPTS) -C $(SRC_TOP)/librpitx/src
	# compile sendiq.cpp here

fake_install: librpitx_cxx
	@echo $(value TARGETS)
	printf "#!/bin/sh\nexit 0\n" > $(PREFIX)/sendiq

fetch_libs:
	if [ ! -d "$(SRC_TOP)/librpitx" ]; then git submodule update; fi
	if [ ! -f "$(SRC_TOP)/sendiq.cpp" ]; then \
		curl -L https://raw.githubusercontent.com/F5OEO/rpitx/master/src/sendiq.cpp > $(SRC_TOP)/sendiq.cpp; \
	fi
	
librpitx_cxx:
	sed -i 's/CCP/CXX/g' $(SRC_TOP)/librpitx/src/Makefile 

$(PREFIX):
	mkdir -p $@

clean:
	if [ -n "$(MIX_COMPILE_PATH)" ]; then $(RM) -r $(BUILD); fi
	$(MAKE_ENV) $(MAKE) $(MAKE_OPTS) -C $(SRC_TOP)/librpitx/src clean
	git -C $(SRC_TOP)/librpitx reset --hard HEAD

.PHONY: all clean calling_from_make fake_install install