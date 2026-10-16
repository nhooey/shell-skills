{
  description = "shell-hygiene-delete-named-paths: Coding-agent skill — delete the paths you created by name after listing them, never a glob, an unchecked variable or a whole tree";

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
      skillName = "shell-hygiene-delete-named-paths";
      src = ./.;
    };
}
