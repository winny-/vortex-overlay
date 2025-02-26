# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit vcs-snapshot

LIBRETRO_REPO_NAME="libretro/${PN}"
LIBRETRO_COMMIT_SHA="8d114dd55b0a357efec12d34d02dfe190a6ccc3a"

DESCRIPTION="Assets needed for RetroArch. Also contains the official branding."
HOMEPAGE="https://github.com/libretro/retroarch-assets"
SRC_URI="https://github.com/${LIBRETRO_REPO_NAME}/archive/${LIBRETRO_COMMIT_SHA}.tar.gz -> ${P}.tar.gz"

LICENSE="CC-BY-4.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="materialui ozone rgui xmb"

src_prepare() {
	default

	sed -i -e "s/libretro/retroarch/g" Makefile || die

	declare -A FLAGS=( [materialui]=glui [ozone]= [rgui]= [xmb]= )
	for flag in "${!FLAGS[@]}"; do
		if ! use "${flag}"; then
			local folder="${FLAGS[$flag]:-$flag}"
			rm -r "${folder}" || die
		fi
	done
}
