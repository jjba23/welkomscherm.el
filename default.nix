# welkomscherm.el

# Copyright © Josep Bigorra <jjbigorra@gmail.com>

# welkomscherm.el is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# welkomscherm.el is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with welkomscherm.el.  If not, see <https://www.gnu.org/licenses/>.

# The package of this checkout, built with `melpaBuild' -- the builder MELPA
# itself uses, which reads the headers, writes the -pkg.el and the autoloads,
# and byte-compiles, so that `(require 'welkomscherm)' and the autoloaded
# commands work for whoever installs it.
#
# The arguments have defaults so that `nix-build' works here; a flake that
# pins nixpkgs passes `lib' and `melpaBuild' from its own Emacs package scope
# instead, since `melpaBuild' belongs to that scope and not to `pkgs'.

{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
, melpaBuild ? pkgs.emacsPackages.melpaBuild
}:

let
  # The version is written once, in the package's own header, which is where
  # Emacs reads it.  Reading it here instead of repeating the literal is what
  # keeps a release to one edit: the derivation cannot fall behind the file.
  headerLines = builtins.filter
    (line: lib.hasPrefix ";; Version:" line)
    (lib.splitString "\n" (builtins.readFile ./welkomscherm.el));
in
melpaBuild {
  pname = "welkomscherm";
  version =
    if headerLines == [ ] then
      throw ''
        welkomscherm.el has no `;; Version:' header, which is where default.nix
        reads the version from.  Put it back, or set the version by hand here.
      ''
    else
      lib.trim (lib.removePrefix ";; Version:" (builtins.head headerLines));

  # `cleanSource' because the name `melpaBuild' gives this path must not end in
  # `.el': its unpack hook reads that suffix as "a single .el file", and a
  # directory by that name would then not be found.  It also keeps .git and
  # editor backups out of the store.
  src = lib.cleanSource ./.;

  # The repository carries its tests, its NEWS and its COPYING next to the
  # package; the package is the .el files at the top level and nothing else.
  files = ''("*.el")'';

  meta = {
    description = "Simple welcome screen / dashboard";
    homepage = "https://codeberg.org/jjba23/welkomscherm.el";
    license = lib.licenses.gpl3Plus;
    maintainers = [ lib.maintainers.jjba23 ];
  };
}
