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

LIBRPITX_VERSION = 0aec0363e26867e7be75f52b9d0e22e8518a4eb0
PATCH_DIRS = $(TOP)/patches/librpitx
LDFLAGS += -lbcm_host

TOP := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SRC_TOP = $(TOP)/src
LIBRPITX_SRC = $(SRC_TOP)/librpitx-$(LIBRPITX_VERSION)

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj
DL = $(TOP)/dl

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

install: $(PREFIX)/sendiq

$(BUILD)/sendiq.o: $(SRC_TOP)/sendiq.cpp
	$(CXX) -c $(CXXFLAGS) $(LDFLAGS) -I$(BUILD)/include -o $@ $<

$(PREFIX)/sendiq: $(PREFIX) $(BUILD)/lib/librpitx.a $(BUILD)/sendiq.o
	$(CXX) $(BUILD)/sendiq.o $(CXXFLAGS) $(LDFLAGS) -L$(BUILD)/lib -lrpitx -o $(PREFIX)/sendiq

$(BUILD)/lib/librpitx.a: $(BUILD) $(SRC_TOP)/.patched
	$(MAKE_ENV) $(MAKE) $(MAKE_OPTS) -C $(LIBRPITX_SRC)/src
	# Install - this is a little lame...
	mkdir -p $(BUILD)/lib
	cp $(LIBRPITX_SRC)/src/librpitx.a $(BUILD)/lib
	mkdir -p $(BUILD)/include/librpitx/src
	cp $(LIBRPITX_SRC)/src/*.h $(BUILD)/include/librpitx/src

fake_install: $(PREFIX)
	printf "#!/bin/sh\nexit 0\n" > $(PREFIX)/sendiq

$(SRC_TOP)/sendiq.cpp: $(DL)/sendiq.cpp
	# Consider committing sendiq.cpp to this repo rather than downloading it...
	cp $(DL)/sendiq.cpp $(SRC_TOP)/sendiq.cpp

$(SRC_TOP)/.extracted: $(DL)/librpitx-$(LIBRPITX_VERSION).tar.gz $(DL)/sendiq.cpp
	# sha256sum -c librpitx.hash
	tar x -C $(SRC_TOP) -f $(DL)/librpitx-$(LIBRPITX_VERSION).tar.gz
	touch $(SRC_TOP)/.extracted

$(SRC_TOP)/.patched: $(SRC_TOP)/.extracted
	cd $(LIBRPITX_SRC); \
	for patchdir in $(PATCH_DIRS); do \
	    for patch in $$(ls $$patchdir); do \
		patch -p1 < "$$patchdir/$$patch"; \
	    done; \
	done
	touch $(SRC_TOP)/.patched

$(DL)/librpitx-$(LIBRPITX_VERSION).tar.gz: $(DL)
	curl -L https://github.com/F5OEO/librpitx/archive/$(LIBRPITX_VERSION).tar.gz > $@
$(DL)/sendiq.cpp: $(DL)
	curl -L https://raw.githubusercontent.com/F5OEO/rpitx/master/src/sendiq.cpp > $@

$(PREFIX) $(BUILD) $(DL):
	mkdir -p $@

clean:
	if [ -n "$(MIX_COMPILE_PATH)" ]; then $(RM) -r $(BUILD); fi
	$(MAKE_ENV) $(MAKE) $(MAKE_OPTS) -C $(LIBRPITX_SRC)/src clean

.PHONY: all clean calling_from_make fake_install install
