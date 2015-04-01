# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/wxGTK/wxGTK-3.0.2.0-r1.ebuild,v 1.1 2015/02/02 16:26:17 sping Exp $

EAPI="5"

inherit eutils flag-o-matic multibuild multilib-minimal

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="http://wxwidgets.org/"

# we use the wxPython tarballs because they include the full wxGTK sources and
# docs, and are released more frequently than wxGTK.
SRC_URI="mirror://sourceforge/wxpython/wxPython-src-${PV}.tar.bz2
	doc? ( mirror://sourceforge/wxpython/wxPython-docs-${PV}.tar.bz2 )"

KEYWORDS=""
IUSE="+X aqua doc debug gstreamer gtk libnotify opengl sdl tiff webkit"

SLOT="3.0"

RDEPEND="
	dev-libs/expat[${MULTILIB_USEDEP}]
	sdl?    ( media-libs/libsdl[${MULTILIB_USEDEP}] )
	X?  (
		>=dev-libs/glib-2.22:2[${MULTILIB_USEDEP}]
		media-libs/libpng:0=[${MULTILIB_USEDEP}]
		sys-libs/zlib[${MULTILIB_USEDEP}]
		virtual/jpeg[${MULTILIB_USEDEP}]
		gtk? ( >=x11-libs/gtk+-2.18:2[${MULTILIB_USEDEP}] )
		x11-libs/gtk+:3[${MULTILIB_USEDEP}]
		x11-libs/gdk-pixbuf[${MULTILIB_USEDEP}]
		x11-libs/libSM[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
		x11-libs/pango[X,${MULTILIB_USEDEP}]
		gstreamer? (
			media-libs/gstreamer:0.10[${MULTILIB_USEDEP}]
			media-libs/gst-plugins-base:0.10[${MULTILIB_USEDEP}] )
		libnotify? ( x11-libs/libnotify[${MULTILIB_USEDEP}] )
		opengl? ( virtual/opengl[${MULTILIB_USEDEP}] )
		tiff?   ( media-libs/tiff:0[${MULTILIB_USEDEP}] )
		webkit? ( net-libs/webkit-gtk:2 )
		)
	aqua? (
		gtk? ( >=x11-libs/gtk+-2.4[aqua=,${MULTILIB_USEDEP}] )
		x11-libs/gtk+:3[aqua=,${MULTILIB_USEDEP}]
		virtual/jpeg[${MULTILIB_USEDEP}]
		tiff?   ( media-libs/tiff:0[${MULTILIB_USEDEP}] )
		)"

DEPEND="${RDEPEND}
	virtual/glu[${MULTILIB_USEDEP}]
	virtual/pkgconfig[${MULTILIB_USEDEP}]
	X?  (
		x11-proto/xproto[${MULTILIB_USEDEP}]
		x11-proto/xineramaproto[${MULTILIB_USEDEP}]
		x11-proto/xf86vidmodeproto[${MULTILIB_USEDEP}]
	)"

PDEPEND=">=app-eselect/eselect-wxwidgets-20131230"

LICENSE="wxWinLL-3
		GPL-2
		doc?	( wxWinFDL-3 )"

S="${WORKDIR}/wxPython-src-${PV}"

wxgtk_setup() {
	local MULTIBUILD_ID="wxgtk"
	local MULTIBUILD_VARIANTS=( $(usex gtk gtk2) gtk3 )

	"${@}"
}

pkg_setup() {
	MULTIBUILD_ID="multilib"
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.0.0.0-collision.patch
	epatch_user

	multilib_prepare() {
		# https://bugs.gentoo.org/421851
		# https://bugs.gentoo.org/499984
		# https://bugs.gentoo.org/536004
		sed \
			-e "/wx_cv_std_libpath=/s:=.*:=$(get_libdir):" \
			-e 's:3\.0\.1:3.0.2:g' \
			-e 's:^wx_release_number=1$:wx_release_number=2:' \
			-i "${BUILD_DIR}"/configure || die
	}
	multilib_copy_sources
	multilib_foreach_abi multilib_prepare
}

multilib_src_configure() {
	multibuild_src_configure() {
		mkdir -p "${BUILD_DIR}" || die
                pushd "${BUILD_DIR}" >/dev/null || die

		local myconf

		# X independent options
		myconf="
				--with-zlib=sys
				--with-expat=sys
				--enable-compat28
				$(use_with sdl)"

		# debug in >=2.9
		# there is no longer separate debug libraries (gtk2ud)
		# wxDEBUG_LEVEL=1 is the default and we will leave it enabled
		# wxDEBUG_LEVEL=2 enables assertions that have expensive runtime costs.
		# apps can disable these features by building w/ -NDEBUG or wxDEBUG_LEVEL_0.
		# http://docs.wxwidgets.org/3.0/overview_debugging.html
		# http://groups.google.com/group/wx-dev/browse_thread/thread/c3c7e78d63d7777f/05dee25410052d9c
		use debug \
			&& myconf="${myconf} --enable-debug=max"

		# wxGTK options
		#   --enable-graphics_ctx - needed for webkit, editra
		#   --without-gnomevfs - bug #203389
		use X && \
			myconf="${myconf}
				--enable-graphics_ctx
				--with-gtkprint
				--enable-gui
				--with-libpng=sys
				--with-libxpm=sys
				--with-libjpeg=sys
				--without-gnomevfs
				$(use_enable gstreamer mediactrl)
				$(multilib_native_use_enable webkit webview)
				$(use_with libnotify)
				$(use_with opengl)
				$(use_with tiff libtiff sys)"

		use aqua && \
			myconf="${myconf}
				--enable-graphics_ctx
				--enable-gui
				--with-libpng=sys
				--with-libxpm=sys
				--with-libjpeg=sys
				--with-mac
				--with-opengl"
				# cocoa toolkit seems to be broken

		# wxBase options
		if use !X && use !aqua ; then
			myconf="${myconf}
				--disable-gui"
		fi

		myconf="${myconf}
			--with-gtk=${MULTIBUILD_VARIANT: -1}"

		ECONF_SOURCE="${S}" econf ${myconf}

		popd >/dev/null || die
	}

	wxgtk_setup multibuild_foreach_variant multibuild_src_configure
}

multilib_src_compile() {
	multibuild_src_compile() {
		pushd "${BUILD_DIR}" >/dev/null || die
		emake
		popd >/dev/null || die
	}

	wxgtk_setup multibuild_foreach_variant multibuild_src_compile
}

multilib_src_install() {
	multibuild_src_install() {
		pushd "${BUILD_DIR}" >/dev/null || die
		emake DESTDIR="${D}" install
		popd >/dev/null || die
	}

	wxgtk_setup multibuild_foreach_variant multibuild_src_install
}

multilib_src_install_all() {
	cd "${S}"/docs
	dodoc changes.txt readme.txt
	newdoc base/readme.txt base_readme.txt
	newdoc gtk/readme.txt gtk_readme.txt

	if use doc; then
		dohtml -r "${S}"/docs/doxygen/out/html/*
	fi

	# Stray windows locale file, causes collisions
	local wxmsw="${ED}usr/share/locale/it/LC_MESSAGES/wxmsw.mo"
	[[ -e ${wxmsw} ]] && rm "${wxmsw}"
}

pkg_postinst() {
	has_version app-eselect/eselect-wxwidgets \
		&& eselect wxwidgets update
}

pkg_postrm() {
	has_version app-eselect/eselect-wxwidgets \
		&& eselect wxwidgets update
}
