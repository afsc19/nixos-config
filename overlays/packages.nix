# Import packages from ../packages directory
let
  packagesDir = ../packages;
in
{ lib, inputs, ... }:
_final: prev:
let
  scope = lib.makeScope prev.newScope (_self: {
    inherit lib inputs;
  });
in
{
  my = lib.packagesFromDirectoryRecursive {
    inherit (scope) newScope callPackage;
    directory = packagesDir;
  };
}
