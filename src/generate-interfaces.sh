#! /bin/sh

die()
{
	echo "${1}"
	exit 1
}

readonly INTERFACES=gstd-interfaces.vala

rm -f gstd.vala || die "failed to rm gstd.vala"
./vala-dbus-binding-tool --api-path=. --gdbus --strip-namespace=com --strip-namespace=ridgerun --strip-namespace=gstreamer || die "failed to generate vala interfaces"
rm -f ${INTERFACES} || die "failed to rm ${INTERFACES}"
mv gstd.vala ${INTERFACES} || die "failed to rename to ${INTERFACES}"

