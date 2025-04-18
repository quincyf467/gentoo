# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV=${PV/_p/+}
MY_P=${PN}-${MY_PV}

inherit edo

DESCRIPTION="System for writing extensible parsers for programming languages"
HOMEPAGE="https://github.com/camlp4/camlp4"
SRC_URI="https://github.com/camlp4/camlp4/archive/${MY_PV}.tar.gz
	-> ${P}.tar.gz"
S="${WORKDIR}"/${P/_p/-}

LICENSE="LGPL-2-with-linking-exception"
SLOT="0/${PV}"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux"
IUSE="+ocamlopt"

RDEPEND="
	=dev-lang/ocaml-5.3*:=[ocamlopt?]
	dev-ml/camlp-streams:=[ocamlopt?]
"
DEPEND="
	${RDEPEND}
	dev-ml/ocamlbuild[ocamlopt?]
	dev-ml/findlib:=
"

QA_FLAGS_IGNORED='.*'

PATCHES=( "${FILESDIR}/reload.patch" )

src_configure() {
	edo ./configure                             \
		--bindir="${EPREFIX}/usr/bin"           \
		--libdir="$(ocamlc -where)"             \
		--pkgdir="$(ocamlc -where)"
}

src_compile() {
	# Increase stack limit to 11GiB to avoid stack overflow error.
	ulimit -s 11530000

	emake byte
	use ocamlopt && emake native
}

src_install() {
	# OCaml generates textrels on 32-bit arches
	if use arm || use ppc || use x86 ; then
		export QA_TEXTRELS='.*'
	fi
	emake DESTDIR="${D}" install install-META
	dodoc CHANGES.md README.md
}
