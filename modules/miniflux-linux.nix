{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.miniflux;
  pgSuperUser = config.services.postgresql.superUser;

  minifluxCli = pkgs.writeShellScriptBin "miniflux-cli" ''
    exec sudo -u ${pgSuperUser} env \
      DATABASE_URL="user=${pgSuperUser} host=/run/postgresql dbname=miniflux" \
      ${lib.getExe cfg.package} "$@"
  '';
in
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = "/etc/miniflux.env";
    config = {
      LISTEN_ADDR = "127.0.0.1:8080";
      BASE_URL = "http://localhost:8080/";
    };
  };

  environment.systemPackages = [ minifluxCli ];
}
