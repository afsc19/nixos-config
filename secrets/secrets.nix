# Agenix secrets, heavily inspired on Diogotcorreia's dotfiles.
let
  zenSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHh9INLI4sUow/VZaBoZGwdlr3ZoYa8/j58ahzSK1LPE afsc@zen";
  zenVMSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBwzfN9ryebjm0PAKOGvfPSl1e9eeO7zgZL5qSkimUc afsc@zen";
  thetis = "age1fido2-hmac1qqpgqkdh6zc0q6cw5zwm9neeke0wgpj5pz7xrj8ewrl6hkav86ht50sp43tlvlvtwnjzesmwp7uyrf4f03auc9sq3psghzxem3yjplld4mmn6mj3klccuyaduqrgwvekfakam89f5qwsgag2utsa3vf32exe0vv756t4l9ym3078e257gju9eev4s4g9av4q5x5tvrc5r6l97aggn94cqnh40kgyn72fcrwg0p535wrx7898084tau2tq8stxg3g9c9wsvrlzwd";
  sylva = "";
  favillaSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLulyCMndsV54zdOmA4TjJ53kkkoW4n0UuL9DgL1VHC afsc@favilla";

  personalSystems = [
    zenSystem
    zenVMSystem
    thetis
  ];
  serverSystems = [
    sylva
    favillaSystem
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

  # Add secrets on another distro using: nix-shell -E 'let pkgs = import <nixpkgs> {}; src = builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"; agenix = pkgs.callPackage "${src}/pkgs/agenix.nix" {}; in pkgs.mkShell { packages = [ agenix pkgs.age-plugin-fido2-hmac ]; }'

  (mkSystem null allSystems [
    "nebulaCA"
  ])

  (mkSystem "personal" personalSystems [
    "githubKey"
    "githubPub"
    "rnlgitlabKey"
    "rnlgitlabPub"
    "pwncollegeKey"
    "pwncollegePub"
    "sylvaKey"
    "sylvaPub"
    "rclone"
  ])

  (mkSystem "zen"
    [ zenSystem zenVMSystem thetis ]
    [
      "nebulaCert"
      "nebulaKey"
    ]
  )

  (mkSystem "sylva"
    [ sylva zenSystem thetis ]
    [
      "nebulaCert"
      "nebulaKey"
    ]
  )

  (mkSystem "favilla"
    [ favillaSystem zenSystem thetis ]
    [
      "nebulaCert"
      "nebulaKey"
    ]
  )

]
