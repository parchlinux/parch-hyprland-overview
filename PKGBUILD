# Maintainer: Parch Linux Developers <info@parchlinux.com>
pkgname=parch-hyprland-overview
pkgver=2.0
pkgrel=1
pkgdesc="Parch Linux Hyprland workspace overview powered by Quickshell"
arch=('any')
url="https://github.com/parchlinux/parch-hyprland-overview"
license=('GPL-3.0-or-later')
depends=('quickshell' 'hyprland')
optdepends=('ttf-google-sans: default font for overview UI')

package() {
    install -dm755 "$pkgdir/usr/share/$pkgname"
    install -Dm644 "$startdir/shell.qml" "$pkgdir/usr/share/$pkgname/shell.qml"
    install -Dm644 "$startdir/Theme.qml" "$pkgdir/usr/share/$pkgname/Theme.qml"
    cp -dr --no-preserve=ownership "$startdir/overview" "$pkgdir/usr/share/$pkgname/"
    find "$pkgdir/usr/share/$pkgname" -type d -exec chmod 755 {} +
    find "$pkgdir/usr/share/$pkgname" -type f -exec chmod 644 {} +

    install -Dm755 "$startdir/parch-hyprland-overview" "$pkgdir/usr/bin/parch-hyprland-overview"
}
