# TODO temporary python fix
{ ... }:
final: prev:
{
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      jedi-language-server = python-prev.jedi-language-server.overridePythonAttrs (oldAttrs: {
        # 'jedi < 0.20'
        pythonRelaxDeps = (oldAttrs.pythonRelaxDeps or [ ]) ++ [ "jedi" ];
        doCheck = false;
      });
    })
  ];
}