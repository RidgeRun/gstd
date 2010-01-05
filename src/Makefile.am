ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = gstd gst-client

gstd_SOURCES = main.vala gstd-factory.vala gstd-pipeline.vala
gstd_VALAFLAGS = --pkg gstreamer-0.10 --pkg posix --pkg dbus-glib-1
gstd_CFLAGS = @GSTREAMER_CFLAGS@ @DBUS_GLIB_CFLAGS@
gstd_LDADD = @GSTREAMER_LIBS@ @DBUS_GLIB_LIBS@

gst_client_SOURCES = gst-client.vala
gst_client_VALAFLAGS = --pkg posix --pkg dbus-glib-1
gst_client_CFLAGS = @DBUS_GLIB_CFLAGS@ -DGETTEXT_PACKAGE=\"gst-client\"
gst_client_LDADD = @DBUS_GLIB_LIBS@


interface_xml := factory-iface.xml pipeline-iface.xml
gstddir = $(includedir)/gstd

EXTRA_DIST= $(interface_xml)
gstd_DATA = $(interface_xml)
