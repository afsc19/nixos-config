# Agenix secrets, heavily inspired on Diogotcorreia's dotfiles.
let
  zenSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHh9INLI4sUow/VZaBoZGwdlr3ZoYa8/j58ahzSK1LPE";

  personalSystems = [
    zenSystem
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
  (mkSystem null allSystems [
    # TODO add keys for all
  ])

  (mkSystem "personal" personalSystems [
    "githubKey"
    "rnlgitlabKey"
    # TODO add rnl_gitlab + github keys 
  ])

  (mkSystem "zen"
    [ zenSystem ]
    [
      # TODO add secrets
    ]
  )

]