ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = harrierd harrier

harrierd_SOURCES = main.vala harrier.vala harrier_common_defs.h
harrierd_VALAFLAGS = --pkg gstreamer-0.10 --pkg posix --pkg dbus-glib-1
harrierd_CFLAGS = @GSTREAMER_CFLAGS@ @DBUS_GLIB_CFLAGS@
harrierd_LDADD = @GSTREAMER_LIBS@ @DBUS_GLIB_LIBS@

harrier_SOURCES = harrierCli.vala
harrier_VALAFLAGS = --pkg posix --pkg dbus-glib-1
harrier_CFLAGS = @DBUS_GLIB_CFLAGS@
harrier_LDADD = @DBUS_GLIB_LIBS@

interface_xml := harrier_dbus_interface.xml
harrierdir = $(includedir)/harrier

EXTRA_DIST= $(interface_xml)
harrier_DATA = $(interface_xml)

checkxml: $(interface_xml)
	@xmllint --valid --noout $<
	@echo $< checks out ok
