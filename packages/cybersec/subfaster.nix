# subfaster - speed-focused fork of subfinder for passive subdomain enumeration
# https://github.com/melvinsh/subfaster
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "subfaster";
  version = "2.21.0";

  src = fetchFromGitHub {
    owner = "melvinsh";
    repo = "subfaster";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TKN4AXIKy8IkVdJ5spYXt3P8UJRtvai2oBSi8TpzmHs=";
  };

  vendorHash = "sha256-/nVcu12++1oRLDixTsMn7KKirOUWKHuTedRC7nqZDew=";

  subPackages = [ "cmd/subfaster" ];

  ldflags = [
    "-s"
    "-w"
  ];

  # Tests query live passive sources over the network
  doCheck = false;

  meta = {
    description = "Fast passive subdomain enumeration tool, a speed-focused fork of subfinder";
    homepage = "https://github.com/melvinsh/subfaster";
    changelog = "https://github.com/melvinsh/subfaster/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "subfaster";
  };
})
