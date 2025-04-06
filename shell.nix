{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Ruby
    ruby
    bundler
    gcc
    gnumake
    sqlite

    # Language servers and formatters
    ruby-lsp
    rubocop
    rubyPackages.solargraph
    rubyPackages.erb-formatter
    rufo

    nodePackages."@tailwindcss/language-server"
    emmet-ls
    pkgs.vscode-langservers-extracted
  ];
}
