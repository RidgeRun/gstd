bin_PROGRAMS = harrier

harrier_SOURCES = harrier.c harrier_common_defs.h harrier_config_common_defs.h harrier_server_stub.h harrier_config_client_stub.h
harrier_CFLAGS = $(shell pkg-config --cflags dbus-1 dbus-glib-1 gstreamer-0.10) \
		-DPROGNAME=\"harrier\" -g -Wall -DNO_DAEMON -DG_DISABLE_DEPRECATED
harrier_LDFLAGS = $(shell pkg-config --libs dbus-1 dbus-glib-1 gstreamer-0.10)


BUILT_SOURCES= harrier_server_stub.h harrier_client_stub.h
CLEANFILES= harrier_server_stub.h 
EXTRA_DIST= harrier_dbus_interface.xml harrier_common_defs.h harrier_config_common_defs.h

interface_vr_xml := harrier_dbus_interface.xml


harrier_server_stub.h: $(interface_vr_xml)

	dbus-binding-tool --prefix=harrier_object --mode=glib-server \
	$< > $@

harrier_client_stub.h: $(interface_vr_xml)
	dbus-binding-tool --prefix=harrier_object --mode=glib-client \
	$< > ../include/$@

checkxml: $(interface_vr_xml)
	@xmllint --valid --noout $<
	@echo $< checks out ok

