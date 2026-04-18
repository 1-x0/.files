{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cosmic-manager = {
      url = "github:heitoraugustoln/cosmic-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { nixpkgs, home-manager, impermanence, cosmic-manager, ... }:
  let
    const = import ./constants.nix;
  in {
    nixosConfigurations.${const.HOSTNAME} = nixpkgs.lib.nixosSystem {
      system = const.SYSTEM;
      specialArgs = { inherit const; };
      modules = [
        ./configuration.nix
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit const; };
          home-manager.users.${const.USERNAME} = {
            imports = [
              ./home.nix
              cosmic-manager.homeManagerModules.cosmic-manager
            ];
          };
        }
      ];
    };
  };
}
