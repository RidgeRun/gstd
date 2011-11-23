ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = gstd gst-client

gstd_SOURCES = main.vala gstd-factory.vala gstd-pipeline.vala gstd-watchdog.vala gstd-signals.vala
gstd_VALAFLAGS = --thread --vapidir=@VAPIDIR@ --vapidir=. --pkg gstd-config \
    --pkg gstreamer-0.10 --pkg gstreamer-interfaces-0.10 --pkg posix --pkg dbus-glib-1 \
    @GSTREAMER_SUPPORT_QOS_SIGNAL@ @GSTREAMER_SUPPORT_STEP@ @GSTD_SUPPORT_WATCHDOG@ @GSTD_SUPPORT_SIGNALS@
gstd_CFLAGS = @GSTREAMER_CFLAGS@ @GSTREAMER_INTERFACES_CFLAGS@ @DBUS_GLIB_CFLAGS@
gstd_LDADD = @GSTREAMER_LIBS@ @GSTREAMER_INTERFACES_LIBS@ @DBUS_GLIB_LIBS@

gst_client_SOURCES = gst-client.vala
gst_client_VALAFLAGS = --vapidir=@VAPIDIR@ --vapidir=. --pkg gstd-config \
    --pkg gstreamer-0.10 --pkg gstreamer-interfaces-0.10 --pkg posix --pkg dbus-glib-1 \
    @READLINE_SUPPORT@
gst_client_CFLAGS = @GSTREAMER_CFLAGS@ @DBUS_GLIB_CFLAGS@
gst_client_LDADD = @GSTREAMER_LIBS@ @GSTREAMER_INTERFACES_LIBS@ @DBUS_GLIB_LIBS@ @READLINE_LIBS@

install-data-hook:
	cd $(bindir) ; rm -f gst-client-interpreter ; $(LN_S) gst-client gst-client-interpreter

interfaces_xml := com.ridgerun.gstreamer.gstd.FactoryInterface.xml \
 com.ridgerun.gstreamer.gstd.PipelineInterface.xml

EXTRA_DIST= $(interfaces_xml)

interfacedir=$(datadir)/dbus-1/interfaces/
interface_DATA= $(interfaces_xml)
