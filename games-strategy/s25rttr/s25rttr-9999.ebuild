# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-strategy/s25rttr/s25rttr-0.8.1.ebuild,v 1.1 2013/12/23 13:45:08 hasufell Exp $

EAPI=5
inherit eutils cmake-utils gnome2-utils games versionator

DESCRIPTION="Open Source remake of The Settlers II game (needs original game files)"
HOMEPAGE="http://www.siedler25.org/"

if [[ ${PV} == 9999 ]]; then
    inherit bzr
    SRC_URI=""
    EBZR_REPO_URI="lp:s25rttr"
else
    # no upstream source tarball yet
    # https://bugs.launchpad.net/s25rttr/+bug/1069546
    inherit bzr
    SRC_URI=""
    EBZR_REPO_URI="lp:s25rttr"
    EBZR_REVISION="$(get_version_component_range 4 ${PV})"
fi

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="debug glfw"

RDEPEND="app-arch/bzip2
	dev-lang/lua:5.2
	media-libs/libsamplerate
	media-libs/libsdl[X,sound,opengl,video]
	media-libs/libsndfile
	media-libs/sdl-mixer[vorbis]
	net-libs/miniupnpc
	virtual/libiconv
	virtual/opengl
	glfw? ( <media-libs/glfw-3 )"
DEPEND="${RDEPEND}
	sys-devel/gettext"

src_prepare() {
	epatch "${FILESDIR}"/${P}-cmake.patch \
		"${FILESDIR}"/${P}-soundconverter.patch \
		"${FILESDIR}"/s25rttr-lua.patch
}

src_configure() {
	local arch
	case ${ARCH} in
		amd64)
			arch="x86_64" ;;
		x86)
			arch="i386" ;;
		*) die "Architecture ${ARCH} not yet supported" ;;
	esac

	local mycmakeargs=(
		-DCOMPILEFOR="linux"
		-DCOMPILEARCH="${arch}"
		-DCMAKE_SKIP_RPATH=YES
		-DPREFIX="${GAMES_PREFIX}"
		-DBINDIR="${GAMES_BINDIR}"
		-DDATADIR="${GAMES_DATADIR}"
		-DLIBDIR="$(games_get_libdir)/${PN}"
		-DDRIVERDIR="$(games_get_libdir)/${PN}"
		-DGAMEDIR="~/.${PN}/S2"
		$(cmake-utils_use_build glfw GLFW_DRIVER)
	)

	cmake-utils_src_configure
}

src_compile() {
	# work around some relative paths (CMAKE_IN_SOURCE_BUILD not supported)
	ln -s "${CMAKE_USE_DIR}"/RTTR "${CMAKE_BUILD_DIR}"/RTTR || die

	cmake-utils_src_compile

	mv "${CMAKE_USE_DIR}"/RTTR/{sound-convert,s-c_resample} "${T}"/ || die
}

src_install() {
	cd "${CMAKE_BUILD_DIR}" || die

	exeinto "$(games_get_libdir)"/${PN}
	doexe "${T}"/{sound-convert,s-c_resample}
	exeinto "$(games_get_libdir)"/${PN}/video
	doexe driver/video/SDL/src/libvideoSDL.so
	use glfw && doexe driver/video/GLFW/src/libvideoGLFW.so
	exeinto "$(games_get_libdir)"/${PN}/audio
	doexe driver/audio/SDL/src/libaudioSDL.so

	insinto "${GAMES_DATADIR}"
	doins -r "${CMAKE_USE_DIR}"/RTTR

	doicon -s 64 "${CMAKE_USE_DIR}"/debian/${PN}.png
	dogamesbin src/s25client
	make_desktop_entry "s25client" "Settlers RTTR" "${PN}"
	dodoc RTTR/texte/{keyboardlayout.txt,readme.txt}

	prepgamesdirs
}

pkg_preinst() {
	games_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	games_pkg_postinst
	elog "Copy your Settlers2 game files into ~/.${PN}/S2"

	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
