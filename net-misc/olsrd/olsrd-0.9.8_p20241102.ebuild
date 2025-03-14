# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

# Snapshot to fix bug #927456 (and before that, bug #735572)
MY_COMMIT="3653c47b88653be6c5dcf9e8ce3a5efbb69684a4"
DESCRIPTION="An implementation of the Optimized Link State Routing protocol"
HOMEPAGE="http://www.olsr.org/"
SRC_URI="https://github.com/OLSR/olsrd/archive/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"
#SRC_URI="https://github.com/OLSR/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_COMMIT}"

LICENSE="BSD LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="gui pud"

RDEPEND="
	gui? (
		dev-libs/glib:2
		x11-libs/gdk-pixbuf:2
		x11-libs/gtk+:2
	)
	pud? ( sci-geosciences/gpsd )
"
DEPEND="
	${RDEPEND}
	x11-base/xorg-proto
"
BDEPEND="
	app-alternatives/yacc
	app-alternatives/lex
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-0.9.0.2-gtk.patch
)

src_prepare() {
	default

	# fix parallel make
	# respect AR
	# verbose build
	# fix default prefix, bug #453440
	sed -i \
		-e '/@echo "\[/d' \
		-e 's|$(MAKECMD)|$(MAKE)|g' \
		-e 's|@$(CC)|$(CC)|g' \
		-e 's|@ar |$(AR) |g' \
		-e '/^prefix/s:/usr/local:/usr:' \
		$( find -name 'Makefile*' ) || die

	# respect LDFLAGS
	sed -i \
		-e 's|$(CC)|& $(OLSRD_LDFLAGS)|g' \
		lib/pud/nmealib/Makefile lib/pud/wireformat/Makefile || die
}

src_configure() {
	if ! use pud; then
		sed -i -e '/^SUBDIRS/ s|pud||g' Makefile || die
	fi
}

src_compile() {
	tc-export PKG_CONFIG

	emake \
		CC="$(tc-getCC) -std=gnu17" \
		LIBDIR="/usr/$(get_libdir)/${PN}" \
		OLSRD_LDFLAGS="${LDFLAGS}" \
		OS=linux \
		VERBOSE=1 \
		build_all

	if use gui; then
		emake -C gui/linux-gtk LIBDIR="/usr/$(get_libdir)/${PN}" CC="$(tc-getCC) -std=gnu17"
	fi
}

src_install() {
	# See bug #715392 re LDCONFIG
	emake \
		DESTDIR="${D}" \
		DOCDIR_OLSRD="${D}/usr/share/doc/${PF}" \
		LIBDIR="${D}/usr/$(get_libdir)/${PN}" \
		OS=linux \
		STRIP=true \
		LDCONFIG=true \
		install_all

	if use gui; then
		emake -C gui/linux-gtk \
			DESTDIR="${D}" \
			LIBDIR="${D}/usr/$(get_libdir)/${PN}" \
			install
	fi

	doinitd "${FILESDIR}"/${PN}

	gzip -d \
		"${ED}"/usr/share/man/man5/olsrd.conf.5.gz \
		"${ED}"/usr/share/man/man8/olsrd.8.gz \
		|| die

	dodoc CHANGELOG \
		valgrind-howto.txt files/olsrd.conf.default.rfc \
		files/olsrd.conf.default.lq \
		lib/arprefresh/README_ARPREFRESH \
		lib/bmf/README_BMF \
		lib/dot_draw/README_DOT_DRAW \
		lib/dyn_gw/README_DYN_GW \
		lib/dyn_gw_plain/README_DYN_GW_PLAIN \
		lib/httpinfo/README_HTTPINFO \
		lib/mini/README_MINI \
		lib/nameservice/README_NAMESERVICE \
		lib/pgraph/README_PGRAPH \
		lib/quagga/README_QUAGGA \
		lib/secure/README_SECURE \
		lib/txtinfo/README_TXTINFO \
		lib/watchdog/README_WATCHDOG
}
