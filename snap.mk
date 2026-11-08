# Snap distribution

main_target: snap_amd64 snap_arm64

DIST_FROM_SOURCE_PROJECTS=canfestival Modbus BACnet paho.mqtt.c frozen ethercat

snap_sources: all_sources $(src)/snap/snapcraft.yaml | revisions.txt
	rm -rf $(SOURCES_DIR)/snap
	tar -C $(src) $(tar_opts) -c snap | tar -C $(SOURCES_DIR) -x
	cp revisions.txt $(SOURCES_DIR)
	touch $@

# Assume building on intel/amd architecture
snap_amd64: snap_sources
	cd $(SOURCES_DIR); snapcraft clean ; snapcraft pack
	mv $(SOURCES_DIR)/beremiz_`python3 $(VERSIONPY)`_amd64.snap .
	touch $@

# Assume snapcraft is allowed to remote-build
snap_arm64: snap_sources
	cd $(SOURCES_DIR); git init . ; snapcraft remote-build --launchpad-accept-public-upload --build-for arm64
	mv $(SOURCES_DIR)/beremiz_`python3 $(VERSIONPY)`_arm64.snap .
	touch $@
