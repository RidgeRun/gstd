AC_INIT([gstd],[1.4],[gstd-devel@lists.sourceforge.net])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_MACRO_DIR([m4])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AC_PROG_CC
AC_PROG_LN_S

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile src/Makefile])
AC_CONFIG_FILES(gstd-1.4.pc:gstd-1.4.pc.in)
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

dnl give error and exit if we don't have pkgconfig
AC_CHECK_PROG(HAVE_PKGCONFIG,
	pkg-config,
	[],
	[
		AC_MSG_ERROR([You need to have pkg-config installed!])
	]
)

dnl obtain the gstreamer version desired by the user
AC_ARG_WITH(
	gstreamer-version,
	AS_HELP_STRING(
		[--with-gstreamer-version=VERSION],
		[gstreamer version to use. E.g. --with-gstreamer-version=1.0 or --with-gstreamer-version=0.10]
    	),
    	[
    		case "${withval}" in
    			1.0)
				GST_REQUIRED=1.4.3
				GSTPB_REQUIRED=1.4.3
				checkqosstep=no
    				;;
    			0.10)
				GST_REQUIRED=0.10.22
				GSTPB_REQUIRED=0.10.22
				checkqosstep=yes
    				;;
    			*)
    				AC_MSG_ERROR([bad value ${withval} for --with-gstreamer-version, use 0.10 or 1.0])
    				;;
    		esac
    		AC_MSG_NOTICE([using seelcted version: $withval])
    		gstversion=$withval
    		usedefault=no
    	],
  	[
  		AC_MSG_NOTICE([gstreamer version not specified, try to use latest version: 1.0])
  		gstversion=1.0
		GST_REQUIRED=1.4.3
		GSTPB_REQUIRED=1.4.3
		usedefault=yes
		checkqosstep=no
  	]
)

dnl checking gstreamer
PKG_CHECK_MODULES(GST,
	[
		gstreamer-$gstversion >= $GST_REQUIRED
		gstreamer-base-$gstversion >= $GSTPB_REQUIRED
		gstreamer-controller-$gstversion >= $GST_REQUIRED
	],
	[
		dnl append GST_ERROR cflags to GST_CFLAGS
		GST_CFLAGS="$GST_CFLAGS $GST_ERROR"
	],
	[
		case "${usedefault}" in
			yes)
				AC_MSG_NOTICE([default gstreamer version 1.0 not found, checking for 0.10])
				gstversion=0.10
				GST_REQUIRED=0.10.22
				GSTPB_REQUIRED=0.10.22
				checkqosstep=yes
				PKG_CHECK_MODULES(GST,
					[
						gstreamer-$gstversion >= $GST_REQUIRED
						gstreamer-base-$gstversion >= $GSTPB_REQUIRED
						gstreamer-controller-$gstversion >= $GST_REQUIRED
					],
					[
						dnl append GST_ERROR cflags to GST_CFLAGS
						GST_CFLAGS="$GST_CFLAGS $GST_ERROR"
					],
					[AC_MSG_ERROR(gstreamer version 0.10 not found. You need to install or upgrade the Gstreamer development packages on you system.)]
				)
				;;
			no|*)
				AC_MSG_ERROR([The requested gstreamer version $gstversion was not found])
				;;
		esac

	]
)

dnl checking for qos and step support -> this is only for gstreamer 0.10, since in gstreamer 1.0 it will be present
if test "x$checkqosstep" = "xyes"; then
	dnl obtain the gstreamer complete version and extract the micro version
	_PKG_CONFIG([GST_VERSION], [modversion], [gstreamer-$gstversion])
	GST_RELEASE=`echo $pkg_cv_GST_VERSION | sed "s/\(.*\)\.\(.*\)\.\(.*\)/\3/"`

	dnl check step support
	AC_MSG_CHECKING(Checking if gstreamer version has support for step)
	if test $GST_RELEASE -ge 24 ; then
    		GST_SUPPORT_STEP="-D GST_SUPPORT_STEP"
    		AC_MSG_RESULT(yes)
	else
    		GST_SUPPORT_STEP=
    		AC_MSG_RESULT(no)
	fi

	dnl check qos support
	AC_MSG_CHECKING(Checking if gstreamer version has support for QOS signals)
	if test $GST_RELEASE -ge 29 ; then
   		GST_SUPPORT_QOS_SIGNAL="-D GST_SUPPORT_QOS_SIGNAL"
    		AC_MSG_RESULT(yes)
	else
    		GST_SUPPORT_QOS_SIGNAL=
    		AC_MSG_RESULT(no)
	fi

	AC_SUBST(GST_SUPPORT_QOS_SIGNAL)
	AC_SUBST(GST_SUPPORT_STEP)
fi

dnl Check for modules depending on the gstreamer version and assign HAVE_GSTREAMER_1 conditional
case "${gstversion}" in
	1.0)
		have_gstreamer_1=yes
		PKG_CHECK_MODULES(GST_EXTRA_MODULES,
			[
				gstreamer-video-$gstversion >= $GST_REQUIRED
			],
			[
				GST_CFLAGS="$GST_CFLAGS $GST_EXTRA_MODULES_CFLAGS"
				GST_LIBS="$GST_LIBS $GST_EXTRA_MODULES_LIBS"
			],
			[
				AC_MSG_ERROR([you need gstreamer-video installed !])
			]
		)
		;;
	0.10)
		have_gstreamer_1=no
		PKG_CHECK_MODULES(GST_EXTRA_MODULES,
			[
				gstreamer-interfaces-$gstversion >= $GST_REQUIRED
			],
			[
				GST_CFLAGS="$GST_CFLAGS $GST_EXTRA_MODULES_CFLAGS"
				GST_LIBS="$GST_LIBS $GST_EXTRA_MODULES_LIBS"
			],
			[
				AC_MSG_ERROR([you need gstreamer-interfaces installed !])
			]
		)
		;;
	*)
		AC_MSG_ERROR([Gstreamer version not found !])
		;;
esac

dnl make gstreamer version available
AC_SUBST(gstversion)

dnl create conditional variable HAVE_GSTREAMER_1
AM_CONDITIONAL([HAVE_GSTREAMER_1], [test x$have_gstreamer_1 = xyes])

dnl make cflags and libs available
AC_SUBST(GST_CFLAGS)
AC_SUBST(GST_LIBS)


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
