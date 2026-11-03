{
  description = "shell-hygiene-secrets-through-secretspec: Coding-agent skill — read secrets through SecretSpec with a reason, at the moment of use, and never write them anywhere";

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
      skillName = "shell-hygiene-secrets-through-secretspec";
      src = ./.;
    };
}
