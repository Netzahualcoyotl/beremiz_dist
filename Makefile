#! gmake

# This is top level Makefile for beremiz_public_dist

# see also: 
#   build_in_docker.sh : use case example
#   provision_*.sh : prerequisites

all: main_target

DIST ?= windows

src := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

SOURCES_DIR := $(src)/sources

include $(src)/sources.revisions

CPUS := `cat /proc/cpuinfo | grep -e 'processor\W*:\W*[[:digit:]]*' | nl -n ln | tail -n1 | cut -f1`

distfiles = $(src)/distfiles
sfmirror = downloads
ifndef tmp
tmp := $(shell mktemp -d -t beremiz_dist_build_tmp.XXXXXXXXXX)
endif

define get_src_http
	dld=$(distfiles)/`echo $(2) | tr ' ()' '___'`;( ( [ -f $$dld ] || wget $(1)/$(2) -O $$dld ) && ( [ ! -f $$dld.md5 ] && (cd $(distfiles);md5sum `basename $$dld`) > $$dld.md5 || (cd $(distfiles);md5sum -c `basename $$dld.md5`) ) ) &&
endef

ifneq ("$(DIST)","")
include $(src)/$(DIST).mk
endif

FROM_SOURCE_PROJECTS=beremiz matiec $(DIST_FROM_SOURCE_PROJECTS)

tar_opts=--absolute-names --exclude=.* --exclude=.*.pyc --exclude=.*.swp --exclude=__pycache__

PREPARE_PROJECTS = beremiz matiec canfestival Modbus open62541 BACnet paho.mqtt.c frozen ethercat

VERSIONPY=$(SOURCES_DIR)/beremiz/version.py

SOURCE_STAMPS = $(foreach project,$(PREPARE_PROJECTS),$(SOURCES_DIR)/$(project)_src)

.PHONY: prepare_sources

prepare_sources:
	test "$(SOURCES_DIR)" = "$(src)/sources"
	rm -rf -- "$(SOURCES_DIR)"
	mkdir -p "$(SOURCES_DIR)"
	$(MAKE) --no-print-directory $(SOURCE_STAMPS)

define make_source_rule
$(SOURCES_DIR)/$(1)_src:
	@set -eu; \
	dest="$(SOURCES_DIR)/$(1)"; \
	rm -rf "$$$$dest"; \
	mkdir -p "$(SOURCES_DIR)"; \
	echo "Cloning $(1) from GitHub"; \
	git clone --no-checkout "https://github.com/$(2).git" "$$$$dest"; \
	git -C "$$$$dest" checkout --detach "$(3)"; \
	touch "$$@"

endef

$(eval $(call make_source_rule,beremiz,Netzahualcoyotl/beremiz,$(beremiz_revisionid)))
$(eval $(call make_source_rule,matiec,Netzahualcoyotl/matiec,$(matiec_revisionid)))
$(eval $(call make_source_rule,canfestival,Netzahualcoyotl/canfestival,$(canfestival_revisionid)))
$(eval $(call make_source_rule,Modbus,Netzahualcoyotl/Modbus,$(Modbus_revisionid)))
$(eval $(call make_source_rule,open62541,Netzahualcoyotl/open62541,$(open62541_revisionid)))
$(eval $(call make_source_rule,BACnet,Netzahualcoyotl/BACnet,$(BACnet_revisionid)))
$(eval $(call make_source_rule,paho.mqtt.c,Netzahualcoyotl/paho-mqtt-c,$(paho_mqtt_c_revisionid)))
$(eval $(call make_source_rule,frozen,Netzahualcoyotl/frozen,$(frozen_revisionid)))
$(eval $(call make_source_rule,ethercat,Netzahualcoyotl/ethercat,$(ethercat_revisionid)))

own_sources: $(foreach project,$(FROM_SOURCE_PROJECTS),$(SOURCES_DIR)/$(project)_src)
	touch $@

all_sources: $(SOURCE_STAMPS)
	touch $@

define show_revision_details
	echo "$(1) revision is: $($(2))"
endef

revisions.txt: all_sources
	echo "Generate revisions.txt"
	echo "\n******* PACKAGE REVISIONS ********\n" > revisions.txt
	echo -n "beremiz_public_dist revision is: " >> revisions.txt
	git -C $(src) rev-parse HEAD >> revisions.txt
	( \
	$(call show_revision_details,beremiz,beremiz_revisionid); \
	$(call show_revision_details,matiec,matiec_revisionid); \
	$(call show_revision_details,canfestival,canfestival_revisionid); \
	$(call show_revision_details,Modbus,Modbus_revisionid); \
	$(call show_revision_details,open62541,open62541_revisionid); \
	$(call show_revision_details,BACnet,BACnet_revisionid); \
	$(call show_revision_details,paho.mqtt.c,paho_mqtt_c_revisionid); \
	$(call show_revision_details,frozen,frozen_revisionid); \
	$(call show_revision_details,ethercat,ethercat_revisionid)) >> revisions.txt

