#! gmake

# This is top level Makefile for beremiz_public_dist

# see also: 
#   build_in_docker.sh : use case example
#   provision_*.sh : prerequisites

all: main_target

DIST ?= windows

src := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_ROOT ?= $(HOME)/build
CPUS := `cat /proc/cpuinfo | grep -e 'processor\W*:\W*[[:digit:]]*' | nl -n ln | tail -n1 | cut -f1`

distfiles = $(src)/distfiles
sfmirror = downloads
ifndef tmp
tmp := $(shell mktemp -d -t beremiz_dist_build_tmp.XXXXXXXXXX)
endif

define get_src_http
	dld=$(distfiles)/`echo $(2) | tr ' ()' '___'`;( ( [ -f $$dld ] || wget $(1)/$(2) -O $$dld ) && ( [ ! -f $$dld.md5 ] && (cd $(distfiles);md5sum `basename $$dld`) > $$dld.md5 || (cd $(distfiles);md5sum -c `basename $$dld.md5`) ) ) &&
endef

VERSIONPY=sources/beremiz/version.py

ifneq ("$(DIST)","")
include $(src)/$(DIST).mk
endif

FROM_SOURCE_PROJECTS=beremiz matiec $(DIST_FROM_SOURCE_PROJECTS)

tar_opts=--absolute-names --exclude=.* --exclude=.*.pyc --exclude=.*.swp --exclude=__pycache__

PREPARE_PROJECTS = beremiz matiec canfestival Modbus open62541 BACnet paho.mqtt.c frozen ethercat

# Fixed source revisions
BEREMIZ_REVISION = 96c1189fe88020ef44b8433437671886d5b21a26
MATIEC_REVISION = 3a41303bcb4e50403417bc39c63f88981d7d961e
CANFESTIVAL_REVISION = c41b9cc7224398cc8f5a3b853f3743b395d02222
MODBUS_REVISION = 74a5f6a2c3f9b61308a62fc58bbe10572d79a003
OPEN62541_REVISION = fb3e17c448ca1a8dbed83ca776401b059b92da7d
BACNET_REVISION = 7c87c95f6270492a369631f5b58d6e1ac20ea6d3
PAHO_MQTT_C_REVISION = 4a939ddb01eea581a32fd6f0adcfee51b91d2601
FROZEN_REVISION = cfff12e9d3f20e9ea670ced1beb27be141fa3254
ETHERCAT_REVISION = f4cbbea0ecfc4fb2d356e7911acad3914d4ac621

SOURCES_DIR := $(abspath $(BUILD_ROOT))/sources

SOURCE_STAMPS = $(foreach project,$(PREPARE_PROJECTS),$(SOURCES_DIR)/$(project)_src)

.PHONY: prepare_sources

prepare_sources:
	rm -rf "$(SOURCES_DIR)"
	mkdir -p "$(SOURCES_DIR)"
	$(MAKE) --no-print-directory $(SOURCE_STAMPS)

define make_source_rule
$(SOURCES_DIR)/$(1)_src:
	@set -eu; \
	local_repo="$(src)/../$(1)"; \
	dest="$(SOURCES_DIR)/$(1)"; \
	rm -rf "$$$$dest"; \
	mkdir -p "$$$$dest"; \
	if [ -d "$$$$local_repo" ] && \
	   git -C "$$$$local_repo" cat-file -e "$(3)^{commit}" 2>/dev/null; then \
		echo "Preparing $(1) from local repository"; \
		git -C "$$$$local_repo" archive --format=tar "$(3)" > "$$$$dest.tar"; \
		tar -xf "$$$$dest.tar" -C "$$$$dest"; \
		rm -f "$$$$dest.tar"; \
	else \
		echo "Preparing $(1) from GitHub"; \
		archive="$(distfiles)/$(1)-$(3).tar.gz"; \
		mkdir -p "$(distfiles)"; \
		if [ ! -s "$$$$archive" ]; then \
			wget -O "$$$$archive.tmp" "https://github.com/$(2)/archive/$(3).tar.gz"; \
			mv "$$$$archive.tmp" "$$$$archive"; \
		fi; \
		tar -xzf "$$$$archive" --strip-components=1 -C "$$$$dest"; \
	fi; \
	touch "$$@"

sources/$(1)_src: $(SOURCES_DIR)/$(1)_src
endef

$(eval $(call make_source_rule,beremiz,Netzahualcoyotl/beremiz,$(BEREMIZ_REVISION)))
$(eval $(call make_source_rule,matiec,Netzahualcoyotl/matiec,$(MATIEC_REVISION)))
$(eval $(call make_source_rule,canfestival,Netzahualcoyotl/canfestival,$(CANFESTIVAL_REVISION)))
$(eval $(call make_source_rule,Modbus,Netzahualcoyotl/Modbus,$(MODBUS_REVISION)))
$(eval $(call make_source_rule,open62541,Netzahualcoyotl/open62541,$(OPEN62541_REVISION)))
$(eval $(call make_source_rule,BACnet,Netzahualcoyotl/BACnet,$(BACNET_REVISION)))
$(eval $(call make_source_rule,paho.mqtt.c,Netzahualcoyotl/paho-mqtt-c,$(PAHO_MQTT_C_REVISION)))
$(eval $(call make_source_rule,frozen,Netzahualcoyotl/frozen,$(FROZEN_REVISION)))
$(eval $(call make_source_rule,ethercat,Netzahualcoyotl/ethercat,$(ETHERCAT_REVISION)))

own_sources: $(foreach project,$(FROM_SOURCE_PROJECTS),sources/$(project)_src)
	touch $@

all_sources: $(foreach project,$(PREPARE_PROJECTS),sources/$(project)_src)
	touch $@

define show_revision_details
	echo "$(1) revision is: $($(2))"
endef

revisions.txt: all_sources
	echo "Generate revisions.txt"
	echo "\n******* PACKAGE REVISIONS ********\n" > revisions.txt
	echo -n "beremiz_public_dist revision is: " >> revisions.txt
	git -C $(src) rev-parse HEAD >> revisions.txt
	($(call show_revision_details,beremiz,BEREMIZ_REVISION); \
	$(call show_revision_details,matiec,MATIEC_REVISION); \
	$(call show_revision_details,canfestival,CANFESTIVAL_REVISION); \
	$(call show_revision_details,Modbus,MODBUS_REVISION); \
	$(call show_revision_details,open62541,OPEN62541_REVISION); \
	$(call show_revision_details,BACnet,BACNET_REVISION); \
	$(call show_revision_details,paho.mqtt.c,PAHO_MQTT_C_REVISION); \
	$(call show_revision_details,frozen,FROZEN_REVISION); \
	$(call show_revision_details,ethercat,ETHERCAT_REVISION)) >> revisions.txt

