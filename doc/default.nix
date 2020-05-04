{
  pkgs ? import ./pkgs.nix
}:

let
  inherit (pkgs) stdenv mobile-nixos-process-doc rsync;

  # Styles, built from a preprocessor.
  styles = pkgs.callPackage ./_support/styles { };

  # Asciidoc source for the devices section.
  devices = pkgs.callPackage ./_support/devices { };

  # Asciidoc source for the options section.
  options = pkgs.callPackage ./_support/options { };
in

stdenv.mkDerivation {
  name = "mobile-nixos-docs";
  src = ./.;

  buildInputs = [
    mobile-nixos-process-doc
    rsync
  ];

  buildPhase = ''
    export LANG=C.UTF-8

    # Removes the internal notes.
    rm -f README.md

    # Replace it in-place with the repo README.
    cat >> README.adoc <<EOF
    = README.adoc
    include::_support/common.inc[]

    EOF
    tail -n +4 ${../README.adoc} >> README.adoc

    # The title needs to be first
    head -n1 ${../CONTRIBUTING.adoc} > contributing.adoc

    # Then we're adding our common stuff
    cat >> contributing.adoc <<EOF
    include::_support/common.inc[]
    EOF

    # Then continuing with the file.
    tail -n +2 ${../CONTRIBUTING.adoc} >> contributing.adoc

    if [ ! -e index.adoc ]; then
    cat >> index.adoc <<EOF
    = Main Page
    include::_support/common.inc[]

    This is a local build of the Mobile NixOS documentation.

    The full site is at https://mobile.nixos.org/.

    EOF
    fi

    # Copies the generated asciidoc source for the devices.
    cp -prf ${devices}/devices devices

    # Copies the generated asciidoc source for the options.
    cp -prf ${options}/options options

    # Use our pipeline to process the docs.
    process-doc "**/*.adoc" "**/*.md" \
      --styles-dir="${styles}" \
      --output-dir="$out"

    rsync --prune-empty-dirs --verbose --archive \
      --include="*.jpeg" \
      --include="*.png" \
      --include="*/" --exclude="*" . $out/
  '';

  dontInstall = true;
}
