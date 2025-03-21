# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Console MOD-Player based on libmikmod"
HOMEPAGE="https://mikmod.sourceforge.net/"
SRC_URI="https://downloads.sourceforge.net/mikmod/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ppc ~ppc64 ~sparc x86"

DEPEND="
	>=media-libs/libmikmod-3.3
	>=sys-libs/ncurses-5.7-r7:=
"
RDEPEND="${DEPEND}"

DOCS=( AUTHORS NEWS README )
