{ role ? "ci", host, port, hostname }:

let
  sources = import ../nix/sources.nix;
  pkgs = import (sources.nixpkgs) {};
  #inherit (sources) nix-darwin;
  nix-darwin = sources.nix-darwin-hercules;
  system = (import nix-darwin {
    nixpkgs = sources.nixpkgs;
    configuration = "${guestConfDir}/darwin-configuration.nix";
    system = "x86_64-darwin";
  }).system;
  lib = pkgs.lib;

  # this ensures that nix-darwin can find everything it needs, but wont see things it doesnt need
  # that prevents the guest from being rebooted when things it doesnt read get modified
  guestConfDir = pkgs.runCommand "guest-config-dir" {
    inherit host port hostname;
    nixDarwinUrl = nix-darwin.url;
    #nixDarwinUrl = "https://github.com/LnL7/nix-darwin/archive/1d09aa2681bb3fbebb6cf9a40c21c6c871117146.tar.gz";
    #nixDarwinUrl = "https://github.com/hercules-ci/nix-darwin/archive/e2277706f08d7d1a77e86e5628352e4a1ef66eab.tar.gz";
  } ''
    mkdir -pv $out
    cd $out
    mkdir -pv ci-ops/nix-darwin
    cd ci-ops
    cp -r --no-preserve=mode ${./roles} nix-darwin/roles
    cp -r --no-preserve=mode ${./modules} nix-darwin/modules
    cp -r --no-preserve=mode ${./services} nix-darwin/services
    cp -r --no-preserve=mode ${../nix} nix
    cp ${./test.nix} nix-darwin/test.nix
    mkdir lib
    cp ${sources.ops-lib + "/overlays/ssh-keys.nix"} lib/ssh-keys.nix
    cd ..
    cp -r ${../modules/macs/guest}/* .
    substituteAll apply.sh apply.sh
    cd ci-ops/nix-darwin/roles
    ln -sv ${role}.nix active-role.nix
  '';
in {
  inherit nix-darwin system guestConfDir;
}
