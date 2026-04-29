{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  python3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ansible-language-server";
  version = finalAttrs.vscodeAnsibleVersion; # Language server version from the repo at packages/ansible-language-server/package.json is stuck at 0.0.0
  vscodeAnsibleVersion = "26.4.7"; # vscode-ansible version

  src = fetchFromGitHub {
    owner = "ansible";
    repo = "vscode-ansible";
    tag = "v${finalAttrs.vscodeAnsibleVersion}";
    hash = "sha256-9pgg4GFJKp+9S+uMIQye+Jiv/zOQqv0/nxz1BA+vzyk=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  pnpmWorkspaces = [ "@ansible/ansible-language-server" ];
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pnpmWorkspaces
      pname
      version
      src
      ;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-fWFV38q/ph+K/OlwKRuEZ/v3UNsYcLB7zTtdP78wkjU=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm --filter=@ansible/ansible-language-server run build:dist
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/ansible-language-server
    mkdir -p $out/bin

    mv packages/ansible-language-server/dist/* $out/lib/node_modules/ansible-language-server/

    makeWrapper ${lib.getExe nodejs} $out/bin/ansible-language-server \
      --prefix PATH : ${python3}/bin \
      --add-flags "$out/lib/node_modules/ansible-language-server/server.cjs" \
      --set NODE_PATH "$out/lib/node_modules/"
    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/ansible/vscode-ansible/releases/tag/v${finalAttrs.vscodeAnsibleVersion}";
    description = "Ansible Language Server";
    mainProgram = "ansible-language-server";
    homepage = "https://github.com/ansible/vscode-ansible";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      dtvillafana
      robsliwi
    ];
  };
})
