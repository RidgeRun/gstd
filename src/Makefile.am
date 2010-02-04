ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = gstd gst-client

gstd_SOURCES = main.vala gstd-factory.vala gstd-pipeline.vala
gstd_VALAFLAGS = --pkg gstreamer-0.10 --pkg posix --pkg dbus-glib-1
gstd_CFLAGS = @GSTREAMER_CFLAGS@ @DBUS_GLIB_CFLAGS@
gstd_LDADD = @GSTREAMER_LIBS@ @DBUS_GLIB_LIBS@

gst_client_SOURCES = gst-client.vala
gst_client_VALAFLAGS = --pkg posix --pkg dbus-glib-1 --pkg readline -X -lreadline
gst_client_CFLAGS = @DBUS_GLIB_CFLAGS@ -DGETTEXT_PACKAGE=\"gst-client\"
gst_client_LDADD = @DBUS_GLIB_LIBS@ -lreadline -lncurses

interfaces_xml := com.ridgerun.gstreamer.gstd.FactoryInterface.xml \
 com.ridgerun.gstreamer.gstd.PipelineInterface.xml

EXTRA_DIST= $(interfaces_xml)

interfacedir=$(datadir)/dbus-1/interfaces/
interface_DATA= $(interfaces_xml)
