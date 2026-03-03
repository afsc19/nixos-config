# TODO temporarily fix for nixcord
{ ... }:
final: prev: {
  equicord = prev.equicord.overrideAttrs (old: {
    pnpmDeps = final.pnpm.fetchDeps {
      inherit (old) pname version src;
      fetcherVersion = 3; 
      hash = "sha256-L4qy3zMM6ksYcBT7gB6qCzfZIELVe+KZZxTSnfI3Rkk=";
    };
  });
}