{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby
    bundler
    ruby-lsp
    rubocop
    rubyPackages.solargraph
    gnumake
    gcc
    sqlite
  ];
}
