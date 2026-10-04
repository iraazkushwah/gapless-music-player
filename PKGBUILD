pkgname=g4music-custom
pkgver=1.0
pkgrel=1
pkgdesc="A beautiful, fast and fluent music player written in GTK4 (Customized)"
arch=('x86_64')
license=('GPL3')
depends=('gtk4' 'libadwaita' 'gstreamer' 'gst-plugins-base' 'gst-plugins-good' 'gst-plugins-bad')
makedepends=('meson' 'ninja' 'vala')

build() {
  cd "$startdir"
  rm -rf build-pkg
  meson setup build-pkg --prefix=/usr
  meson compile -C build-pkg
}

package() {
  cd "$startdir"
  DESTDIR="$pkgdir" meson install -C build-pkg
}
