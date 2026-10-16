{
  description = "shell-hygiene-target-processes-by-pid: Coding-agent skill — stop or signal the process you started by its PID, never every process whose name or command line matches a pattern";

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
      skillName = "shell-hygiene-target-processes-by-pid";
      src = ./.;
    };
}
