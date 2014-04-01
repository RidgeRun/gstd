AC_INIT([gstd],[1.3],[gstd-devel@lists.sourceforge.net])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_MACRO_DIR([m4])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AC_PROG_CC
AC_PROG_LN_S

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile src/Makefile])
AC_CONFIG_FILES(gstd-1.3.pc:gstd-1.3.pc.in)
AC_CONFIG_FILES(com.ridgerun.gstreamer.gstd.service:com.ridgerun.gstreamer.gstd.service.in)

AM_PROG_VALAC([0.12])

dnl Check for readline library
AC_TRY_CPP([#include <readline/readline.h>],have_readline=yes, have_readline=no)
AC_MSG_CHECKING([if readline is available])
AM_CONDITIONAL([HAVE_READLINE], [test x$have_readline = xyes])
AM_COND_IF([HAVE_READLINE],
    AC_MSG_RESULT(yes);READLINE_SUPPORT="--pkg readline -D HAVE_READLINE";READLINE_LIBS="-lreadline -lncurses",
    AC_MSG_RESULT(no))
AC_SUBST([READLINE_SUPPORT])
AC_SUBST([READLINE_LIBS])

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

_PKG_CONFIG([GSTREAMER_VERSION], [modversion], [gstreamer-0.10])
GSTREAMER_MAJOR=`echo $pkg_cv_GSTREAMER_VERSION | sed "s/\(.*\)\.\(.*\)\.\(.*\)/\1/"`
GSTREAMER_MINOR=`echo $pkg_cv_GSTREAMER_VERSION | sed "s/\(.*\)\.\(.*\)\.\(.*\)/\2/"`
GSTREAMER_RELEASE=`echo $pkg_cv_GSTREAMER_VERSION | sed "s/\(.*\)\.\(.*\)\.\(.*\)/\3/"`
AC_MSG_CHECKING(Checking if gstreamer version has support for QOS signals)
if test $GSTREAMER_RELEASE -ge 29 ; then
    GSTREAMER_SUPPORT_QOS_SIGNAL="-D GSTREAMER_SUPPORT_QOS_SIGNAL"
    AC_MSG_RESULT(yes)
else
    GSTREAMER_SUPPORT_QOS_SIGNAL=
    AC_MSG_RESULT(no)
fi
AC_SUBST(GSTREAMER_SUPPORT_QOS_SIGNAL)

AC_MSG_CHECKING(Checking if gstreamer version has support for step)
if test $GSTREAMER_RELEASE -ge 24 ; then
    GSTREAMER_SUPPORT_STEP="-D GSTREAMER_SUPPORT_STEP"
    AC_MSG_RESULT(yes)
else
    GSTREAMER_SUPPORT_STEP=
    AC_MSG_RESULT(no)
fi
AC_SUBST(GSTREAMER_SUPPORT_STEP)


dnl Now we're ready to ask for gstreamer-interfaces
PKG_CHECK_MODULES(GSTREAMER_INTERFACES, gstreamer-interfaces-0.10 >= 0.10.22 , HAVE_GSTREAMER_INTERFACES=yes, HAVE_GSTREAMER_INTERFACES=no)

dnl Give error and exit if we don't have gstreamer
if test "x$HAVE_GSTREAMER_INTERFACES" = "xno"; then
  AC_MSG_ERROR([you need gst-plugins-base development packages installed !])
fi

dnl make GSTREAMER_INTERFACES_CFLAGS and GSTREAMER_INTERFACES_LIBS available
AC_SUBST(GSTREAMER_INTERFACES_CFLAGS)
AC_SUBST(GSTREAMER_INTERFACES_LIBS)

dnl Now we're ready to ask for gio-2.0
PKG_CHECK_MODULES(GIO, gio-2.0 >= 2.0 , HAVE_GIO=yes, HAVE_GIO=no)

dnl Give error and exit if we don't have gio-2.0
if test "x$HAVE_GIO" = "xno"; then
  AC_MSG_ERROR([you need gio-2.0 development packages installed >= 2.0 !])
fi

dnl make GIO_CFLAGS and GIO_LIBS available
AC_SUBST(GIO_CFLAGS)
AC_SUBST(GIO_LIBS)

if test -z "$VAPIDIR"; then
  VAPIDIR=/usr/share/vala-0.12/vapi
fi
AC_ARG_VAR([VAPIDIR], [path for the vala bindings])
AC_ARG_WITH(vapidir,
  [AS_HELP_STRING([--with-vapidir=<path>],
    [Set the path for the vapidir])],
  [AC_MSG_NOTICE([Setting the vapidir "$withval"])
   AC_SUBST([VAPIDIR],[$withval])
  ]
)

AC_OUTPUT
