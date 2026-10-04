Name:           g4music-custom
Version:        1.0
Release:        1%{?dist}
Summary:        A beautiful, fast and fluent music player written in GTK4

License:        GPL-3.0-only
URL:            https://github.com/neithern/g4music

BuildRequires:  meson
BuildRequires:  gcc
BuildRequires:  vala
BuildRequires:  pkgconfig(gtk4)
BuildRequires:  pkgconfig(libadwaita-1)
BuildRequires:  pkgconfig(gstreamer-1.0)
BuildRequires:  desktop-file-utils

Requires:       gtk4
Requires:       libadwaita
Requires:       gstreamer1
Requires:       gstreamer1-plugins-base
Requires:       gstreamer1-plugins-good
Requires:       gstreamer1-plugins-bad-free

%description
A beautiful, fast and fluent music player written in GTK4 (Customized version).

%prep
# Setup macro is typically used here with Source0, but for local builds:
# We assume the user is building from the source tree directly using rpmbuild -ba

%build
%meson
%meson_build

%install
%meson_install
%find_lang g4music

%files -f g4music.lang
%{_bindir}/g4music
%{_datadir}/applications/com.github.neithern.g4music.desktop
%{_datadir}/glib-2.0/schemas/com.github.neithern.g4music.gschema.xml
%{_datadir}/icons/hicolor/*/apps/com.github.neithern.g4music*
%{_datadir}/metainfo/com.github.neithern.g4music.metainfo.xml

%changelog
* Sun Oct 04 2026 Custom Build <custom@build.local> - 1.0-1
- Initial custom package for Fedora
