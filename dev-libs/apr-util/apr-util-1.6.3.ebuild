# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Usually apr-util has the same PV as apr, but in case of security fixes, this may change.
# APR_PV="${PV}"
APR_PV="1.7.2"

inherit autotools db-use multilib toolchain-funcs

DESCRIPTION="Apache Portable Runtime Utility Library"
HOMEPAGE="https://apr.apache.org/"
SRC_URI="mirror://apache/apr/${P}.tar.bz2"

LICENSE="Apache-2.0"
SLOT="1"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="berkdb doc gdbm ldap mysql nss odbc openssl postgres sqlite static-libs"

RDEPEND="
	>=dev-libs/apr-${APR_PV}:1=
	dev-libs/expat
	virtual/libcrypt:=
	berkdb? ( >=sys-libs/db-4:= )
	gdbm? ( sys-libs/gdbm:= )
	ldap? ( net-nds/openldap:= )
	mysql? (
		|| (
			dev-db/mariadb-connector-c
			>=dev-db/mysql-connector-c-8
		)
	)
	nss? ( dev-libs/nss )
	odbc? ( dev-db/unixODBC )
	openssl? ( dev-libs/openssl:= )
	postgres? ( dev-db/postgresql:= )
	sqlite? ( dev-db/sqlite:3 )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-build/libtool-2.4.2
	doc? ( app-text/doxygen )
"

DOCS=( CHANGES NOTICE README )

PATCHES=(
	"${FILESDIR}"/${PN}-1.5.3-sysroot.patch # bug #385775
	"${FILESDIR}"/${PN}-1.6.1-libtool.patch # bug #779487
	"${FILESDIR}"/${PN}-1.6.1-my_bool.patch
	"${FILESDIR}"/${PN}-1.6.1-drop-my_init.patch
	"${FILESDIR}"/${PN}-1.6.3-fix-pkgconfig-libs.patch
	"${FILESDIR}"/${PN}-1.6.3-configure-int.patch
)

QA_CONFIG_IMPL_DECL_SKIP=(
	memset_s # bug #898566
)

src_prepare() {
	default

	# Fix usage of libmysqlclient (bug #620230)
	grep -lrF "libmysqlclient_r" "${S}" \
		| xargs sed 's@libmysqlclient_r@libmysqlclient@g' -i \
		|| die

	mv configure.{in,ac} || die
	eautoreconf
}

src_configure() {
	local myconf=(
		--datadir="${EPREFIX}"/usr/share/apr-util-1
		--with-apr="${ESYSROOT}"/usr
		--with-expat="${EPREFIX}"/usr
		--without-sqlite2
		$(use_with gdbm)
		$(use_with ldap)
		$(use_with mysql)
		$(use_with nss)
		$(use_with odbc)
		$(use_with openssl)
		$(use_with postgres pgsql)
		$(use_with sqlite sqlite3)
	)

	tc-is-static-only && myconf+=( --disable-util-dso )

	if use berkdb; then
		local db_version
		db_version="$(db_findver sys-libs/db)" || die "Unable to find Berkeley DB version"
		db_version="$(db_ver_to_slot "${db_version}")"
		db_version="${db_version/\./}"
		myconf+=(
			--with-dbm=db${db_version}
			# We use ${T} for the libdir because otherwise it'd simply be the normal
			# system libdir. That's pointless as the compiler will search it for
			# us already. This makes cross-compiling and such easier.
			--with-berkeley-db="$(db_includedir 2>/dev/null):${T}"
		)
	else
		myconf+=( --without-berkeley-db )
	fi

	if use nss || use openssl ; then
		# bug #518708
		myconf+=( --with-crypto )
	fi

	econf "${myconf[@]}"

	# Use the current env build settings rather than whatever apr was built with.
	sed -i -r \
		-e "/^(apr_builddir|apr_builders|top_builddir)=/s:=:=${SYSROOT}:" \
		-e "/^CC=/s:=.*:=$(tc-getCC):" \
		-e '/^LTFLAGS/s:--silent::' \
		build/rules.mk || die
}

src_compile() {
	emake all $(usev doc dox)
}

src_test() {
	# Building tests in parallel is broken
	emake -j1 check
}

src_install() {
	default

	find "${ED}" -name "*.la" -delete || die
	if [[ -d "${ED}/usr/$(get_libdir)/apr-util-${SLOT}" ]] ; then
		find "${ED}/usr/$(get_libdir)/apr-util-${SLOT}" -name "*.a" -delete || die
	fi

	if ! use static-libs ; then
		find "${ED}" -name "*.a" -not -name "*$(get_libname)" -delete || die
	fi

	if use doc ; then
		docinto html
		dodoc -r docs/dox/html/*
	fi

	# This file is only used on AIX systems, which Gentoo is not,
	# and causes collisions between the SLOTs, so remove it.
	rm "${ED}/usr/$(get_libdir)/aprutil.exp" || die
}
