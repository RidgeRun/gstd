AC_INIT([gstd],[1.0],[gstd-devel@lists.sourceforge.net])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_MACRO_DIR([m4])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AC_PROG_CC
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile src/Makefile])
AC_CONFIG_FILES(gstd-1.0.pc:gstd-1.0.pc.in)
AC_CONFIG_FILES(com.ridgerun.gstreamer.gstd.service:com.ridgerun.gstreamer.gstd.service.in)

AM_PROG_VALAC([0.7.6])

dnl Check for pkgconfig first
AC_CHECK_PROG(HAVE_PKGCONFIG, pkg-config, yes, no)

dnl Give error and exit if we don't have pkgconfig
if test "x$HAVE_PKGCONFIG" = "xno"; then
  AC_MSG_ERROR(you need to have pkgconfig installed !)
fi

dnl Now we're ready to ask for gstreamer
PKG_CHECK_MODULES(GSTREAMER, gstreamer-0.10 >= 0.10.22 , HAVE_GSTREAMER=yes, HAVE_GSTREAMER=no)

dnl Give error and exit if we don't have gstreamer
if test "x$HAVE_GSTREAMER" = "xno"; then
  AC_MSG_ERROR([you need gstreamer development packages installed >= 0.10.22 !])
fi

dnl append GSTREAMER_ERROR cflags to GSTREAMER_CFLAGS
GSTREAMER_CFLAGS="$GSTREAMER_CFLAGS $GSTREAMER_ERROR"

dnl make GSTREAMER_CFLAGS and GSTREAMER_LIBS available
AC_SUBST(GSTREAMER_CFLAGS)
AC_SUBST(GSTREAMER_LIBS)

dnl Now we're ready to ask for gstreamer-interfaces
PKG_CHECK_MODULES(GSTREAMER_INTERFACES, gstreamer-interfaces-0.10 >= 0.10.22 , HAVE_GSTREAMER_INTERFACES=yes, HAVE_GSTREAMER_INTERFACES=no)

dnl Give error and exit if we don't have gstreamer
if test "x$HAVE_GSTREAMER_INTERFACES" = "xno"; then
  AC_MSG_ERROR([you need gstreamer-interfaces development packages installed !])
fi

dnl make GSTREAMER_INTERFACES_CFLAGS and GSTREAMER_INTERFACES_LIBS available
AC_SUBST(GSTREAMER_INTERFACES_CFLAGS)
AC_SUBST(GSTREAMER_INTERFACES_LIBS)

dnl Now we're ready to ask for dbus-glib
PKG_CHECK_MODULES(DBUS_GLIB, dbus-glib-1 >= 0.80 , HAVE_DBUS_GLIB=yes, HAVE_DBUS_GLIB=no)

dnl Give error and exit if we don't have dbus-glib
if test "x$HAVE_DBUS_GLIB" = "xno"; then
  AC_MSG_ERROR([you need dbus-glib-1 development packages installed >= 0.80 !])
fi

dnl append DBUS_GLIB_ERROR cflags to DBUS_GLIB_CFLAGS
DBUS_GLIB_CFLAGS="$DBUS_GLIB_CFLAGS $DBUS_GLIB_ERROR"

dnl make DBUS_GLIB_CFLAGS and DBUS_GLIB_LIBS available
AC_SUBST(DBUS_GLIB_CFLAGS)
AC_SUBST(DBUS_GLIB_LIBS)

#AC_PROG_INTLTOOL([0.17])

#GETTEXT_PACKAGE= gst-client
#AC_SUBST(GETTEXT_PACKAGE)

AC_OUTPUT



