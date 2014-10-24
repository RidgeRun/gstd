ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = gstd gst-client

# gstd
gstd_SOURCES = gstd-interfaces.vala gstd-main.vala gstd-factory.vala gstd-pipeline.vala
gstd_VALAFLAGS = --thread --vapidir=@VAPIDIR@ --vapidir=. --pkg gstd-config \
    --pkg gstreamer-@gstversion@ --pkg gstreamer-base-@gstversion@ --pkg gstreamer-controller-@gstversion@ \
    --pkg gio-2.0 --pkg posix @GST_SUPPORT_QOS_SIGNAL@ @GST_SUPPORT_STEP@ -D VERSION_MAJOR

gstd_CFLAGS = @GST_CFLAGS@ @GIO_CFLAGS@
gstd_LDADD = @GST_LIBS@ @GIO_LIBS@

# gst_client
gst_client_SOURCES = gstd-interfaces.vala gst-client.vala
gst_client_VALAFLAGS = --vapidir=@VAPIDIR@ --vapidir=. --pkg gstd-config \
    --pkg gio-2.0 --pkg posix \
    @READLINE_SUPPORT@
gst_client_CFLAGS = @GST_CFLAGS@
gst_client_LDADD = @GST_LIBS@ @GIO_LIBS@ @READLINE_LIBS@

# add extra flags depending on gstreamer version
if HAVE_GSTREAMER_1
    gstd_VALAFLAGS += --pkg gstreamer-video-@gstversion@ -D GSTREAMER_1_X
    gst_client_VALAFLAGS += --pkg gstreamer-video-@gstversion@ -D GSTREAMER_1_X
else
    gstd_VALAFLAGS += --pkg gstreamer-interfaces-@gstversion@
    gst_client_VALAFLAGS += --pkg gstreamer-interfaces-@gstversion@
endif

install-data-hook:
	cd $(bindir) ; rm -f gst-client-interpreter ; $(LN_S) gst-client gst-client-interpreter

interfaces_xml = com.ridgerun.gstreamer.gstd.FactoryInterface.xml \
 com.ridgerun.gstreamer.gstd.PipelineInterface.xml

EXTRA_DIST= $(interfaces_xml)

interfacedir=$(datadir)/dbus-1/interfaces/
interface_DATA= $(interfaces_xml)
