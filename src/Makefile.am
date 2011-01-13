ACLOCAL_AMFLAGS = -I m4
SUBDIRS = src 

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = gstd-1.0.pc

dbusdir=$(datadir)/dbus-1/system-services/
dbus_DATA=com.ridgerun.gstreamer.gstd.service

dbusconfdir=/etc/dbus-1/system.d/
dbusconf_DATA=gstd.conf

EXTRA_DIST = gstd-1.0.pc.in com.ridgerun.gstreamer.gstd.service.in gstd.conf
