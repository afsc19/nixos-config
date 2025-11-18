# Agenix secrets, heavily inspired on Diogotcorreia's dotfiles.
let
  zenSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHh9INLI4sUow/VZaBoZGwdlr3ZoYa8/j58ahzSK1LPE";
  thetis = "age1fido2-hmac1qqpgqkdh6zc0q6cw5zwm9neeke0wgpj5pz7xrj8ewrl6hkav86ht50sp43tlvlvtwnjzesmwp7uyrf4f03auc9sq3psghzxem3yjplld4mmn6mj3klccuyaduqrgwvekfakam89f5qwsgag2utsa3vf32exe0vv756t4l9ym3078e257gju9eev4s4g9av4q5x5tvrc5r6l97aggn94cqnh40kgyn72fcrwg0p535wrx7898084tau2tq8stxg3g9c9wsvrlzwd";

  personalSystems = [
    zenSystem
    thetis
  ];
  serverSystems = [
    # TODO add oracle1
    # TODO propagate to others
  ];
  thirdPartySystems = [
    # ?
  ];
  allSystems = personalSystems ++ serverSystems ++ thirdPartySystems;

  mkSystem =
    dir: publicKeys: files:
    builtins.foldl' (
      acc: file:
      let
        filePrefix = if dir == null then "" else "${dir}/";
      in
      acc
      ++ [
        {
          name = "${filePrefix}${file}.age";
          value = { inherit publicKeys; };
        }
      ]
    ) [ ] files;

  flatten = list: builtins.foldl' (acc: system: acc ++ system) [ ] list;
  mkSecrets = systems: builtins.listToAttrs (flatten systems);
in
mkSecrets [

  # Add secrets on another distro using: nix-shell -E 'let pkgs = import <nixpkgs> {}; src = builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"; agenix = pkgs.callPackage "${src}/pkgs/agenix.nix" {}; in pkgs.mkShell { packages = [ agenix ]; }'


  (mkSystem null allSystems [
    # TODO add keys for all
  ])

  (mkSystem "personal" personalSystems [
    "githubKey"
    "rnlgitlabKey"
    # TODO add rnl_gitlab + github keys 
  ])

  (mkSystem "zen"
    [ zenSystem thetis ]
    [
      # TODO add secrets
    ]
  )

]