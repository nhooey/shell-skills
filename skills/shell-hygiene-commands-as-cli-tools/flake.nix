{
  description = "shell-hygiene-commands-as-cli-tools: Coding-agent skill — a command run more than once becomes a documented command-line tool in the project, with commands, options and a dev shell entry, never a scratchpad script or a recipe in prose";

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
      skillName = "shell-hygiene-commands-as-cli-tools";
      src = ./.;
    };
}
