{
  description = "shell-hygiene-no-machine-wide-changes: Coding-agent skill — keep changes inside the project; ask before sudo, recursive permission changes, global package upgrades, store or cache pruning and dotfile edits";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agent-skill-flake.url = "github:nhooey/agent-skill-flake";
    agent-skill-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, agent-skill-flake, ... }:
    agent-skill-flake.lib.mkSkillFlake {
      inherit nixpkgs;
      source = import ../../source.nix;
      skillName = "shell-hygiene-no-machine-wide-changes";
      src = ./.;
    };
}
