#
# spec file for package emacs-welkomscherm
#
# Copyright (c) 2026 SUSE LLC and contributors
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           emacs-welkomscherm
Version:        1.5.2
Release:        0
Summary:        Simple welcome screen and dashboard for Emacs
License:        MIT
URL:            https://github.com/jjba23/welkomscherm.el
Source0:        welkomscherm.el-%{version}.tar.gz
BuildRequires:  emacs
Requires:       emacs

%description
Welkomscherm is a clean, extensible splash page for Emacs: a sectioned list
of links and commands, with no external library needed.

%prep
%autosetup -n welkomscherm.el-%{version}

%build
emacs -Q --batch -f batch-byte-compile welkomscherm.el

%install
install -d %{buildroot}%{_datadir}/emacs/site-lisp
install -m 0644 welkomscherm.el welkomscherm.elc %{buildroot}%{_datadir}/emacs/site-lisp/

%check
emacs -Q --batch -L . -L test -l test/welkomscherm-test.el -f ert-run-tests-batch-and-exit

%files
%license LICENSE
%doc README.org NEWS.org
%{_datadir}/emacs/site-lisp/welkomscherm.el
%{_datadir}/emacs/site-lisp/welkomscherm.elc

%changelog
* Thu Nov 12 2026 Josep Bigorra <jjbigorra@gmail.com> - 1.5.2
- Turn the banner off by default; enable it with `welkomscherm/show-banner'.

* Thu Nov 12 2026 Josep Bigorra <jjbigorra@gmail.com> - 1.5.1
- Try Emacs's PNG splash logo when the build cannot draw the SVG one, and
  make the ASCII banner opt-in (no banner in terminals by default).

* Thu Nov 12 2026 Josep Bigorra <jjbigorra@gmail.com> - 1.5.0
- Draw the GNU Emacs splash logo as a banner, with an ASCII fallback in
  terminals, and add opt-in plain-text icons for links.

* Thu Nov 12 2026 Josep Bigorra <jjbigorra@gmail.com> - 1.4.1
- Keep Org's `org-agenda-buffer' to the agenda collection so a killed
  buffer cannot break the next render on Emacs 28.

* Thu Nov 12 2026 Josep Bigorra <jjbigorra@gmail.com> - 1.4.0
- Add an opt-in Org agenda section and list recent files one per line.
- Split the manual into short pages under docs/.

