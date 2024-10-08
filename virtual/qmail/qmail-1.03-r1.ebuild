# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for qmail"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~mips ppc64 ~s390 sparc x86"

RDEPEND="|| (
	mail-mta/netqmail
	mail-mta/notqmail
)"
