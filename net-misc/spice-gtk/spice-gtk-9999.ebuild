# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VALA_USE_DEPEND="vapigen"
PYTHON_COMPAT=( python3_{10..13} )

inherit desktop meson optfeature python-any-r1 readme.gentoo-r1 vala xdg

DESCRIPTION="Set of GObject and Gtk objects for connecting to Spice servers and a client GUI"
HOMEPAGE="https://www.spice-space.org https://gitlab.freedesktop.org/spice/spice-gtk"
if [[ ${PV} == *9999* ]] ; then
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/spice/spice-gtk.git"
	inherit git-r3

	SPICE_PROTOCOL_VER=9999
else
	SRC_URI="https://www.spice-space.org/download/gtk/${P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~ppc ~ppc64 ~riscv ~sparc ~x86"

	SPICE_PROTOCOL_VER=0.14.3
fi

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="gtk-doc +gtk3 +introspection lz4 mjpeg policykit sasl smartcard usbredir vala valgrind wayland webdav"

# TODO:
# * check if sys-freebsd/freebsd-lib (from virtual/acl) provides acl/libacl.h
# * use external pnp.ids as soon as that means not pulling in gnome-desktop
RDEPEND="
	>=dev-libs/glib-2.46:2
	dev-libs/json-glib:0=
	media-libs/gst-plugins-base:1.0
	media-libs/gst-plugins-good:1.0
	media-libs/gstreamer:1.0[introspection?]
	media-libs/opus
	media-libs/libjpeg-turbo:=
	sys-libs/zlib
	>=x11-libs/cairo-1.2
	>=x11-libs/pixman-0.17.7
	x11-libs/libX11
	gtk3? ( x11-libs/gtk+:3[introspection?] )
	introspection? ( dev-libs/gobject-introspection )
	dev-libs/openssl:=
	lz4? ( app-arch/lz4 )
	policykit? (
		>=sys-auth/polkit-0.110-r1
	)
	sasl? ( dev-libs/cyrus-sasl )
	smartcard? ( app-emulation/qemu[smartcard] )
	usbredir? (
		sys-apps/hwdata
		>=sys-apps/usbredir-0.4.2
		virtual/acl
		virtual/libusb:1
	)
	webdav? (
		net-libs/phodav:3.0
		net-libs/libsoup:3.0
	)
"
# TODO: spice-gtk has an automagic dependency on media-libs/libva without a
# configure knob. The package is relatively lightweight so we just depend
# on it unconditionally for now. It would be cleaner to transform this into
# a USE="vaapi" conditional and patch the buildsystem...
RDEPEND="
	${RDEPEND}
	amd64? ( media-libs/libva:= )
	arm64? ( media-libs/libva:= )
	x86? ( media-libs/libva:= )
"
DEPEND="
	${RDEPEND}
	>=app-emulation/spice-protocol-${SPICE_PROTOCOL_VER}
	valgrind? ( dev-debug/valgrind )
"
BDEPEND="
	$(python_gen_any_dep '
		dev-python/pyparsing[${PYTHON_USEDEP}]
		dev-python/six[${PYTHON_USEDEP}]
	')
	dev-perl/Text-CSV
	dev-util/glib-utils
	>=sys-devel/gettext-0.17
	virtual/pkgconfig
	gtk-doc? (  dev-util/gtk-doc )
	vala? ( $(vala_depend) )
"

python_check_deps() {
	python_has_version "dev-python/six[${PYTHON_USEDEP}]" &&
	python_has_version "dev-python/pyparsing[${PYTHON_USEDEP}]"
}

src_prepare() {
	default

	python_fix_shebang subprojects/keycodemapdb/tools/keymap-gen

	use vala && vala_setup
}

src_configure() {
	local emesonargs=(
		$(meson_feature gtk-doc gtk_doc)
		$(meson_feature gtk3 gtk)
		$(meson_feature introspection)
		$(meson_use mjpeg builtin-mjpeg)
		$(meson_feature policykit polkit)
		$(meson_feature lz4)
		$(meson_feature sasl)
		$(meson_feature smartcard)
		$(meson_feature usbredir)
		$(meson_feature vala vapi)
		$(meson_use valgrind)
		$(meson_feature webdav)
		$(meson_feature wayland wayland-protocols)
	)

	if use elibc_musl; then
		emesonargs+=(
			-Dcoroutine=gthread
		)
	fi

	if use usbredir; then
		emesonargs+=(
			-Dusb-acl-helper-dir=/usr/libexec
			-Dusb-ids-path="${EPREFIX}"/usr/share/hwdata/usb.ids
		)
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	if use usbredir && use policykit; then
		# bug #775554 (and bug #851657)
		fowners root:root /usr/libexec/spice-client-glib-usb-acl-helper
		fperms 4755 /usr/libexec/spice-client-glib-usb-acl-helper
	fi

	make_desktop_entry spicy Spicy "utilities-terminal" "Network;RemoteAccess;"
	readme.gentoo_create_doc
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "Sound support (via pulseaudio)" media-plugins/gst-plugins-pulse
}
