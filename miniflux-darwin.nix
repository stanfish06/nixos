{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.users.users.stan.home;

  pgPackage = pkgs.postgresql_17;
  pgDataDir = "${home}/.local/share/postgresql/${pgPackage.psqlSchema}";
  pgSocket = "/tmp";
  pgPort = toString config.services.postgresql.port;

  listenAddr = "127.0.0.1:8080";
  databaseUrl = "user=miniflux dbname=miniflux host=${pgSocket} port=${pgPort} sslmode=disable";

  minifluxCli = pkgs.writeShellScriptBin "miniflux-cli" ''
    export DATABASE_URL=${lib.escapeShellArg databaseUrl}
    exec ${pkgs.miniflux}/bin/miniflux "$@"
  '';
in
{
  services.postgresql = {
    enable = true;
    package = pgPackage;
    dataDir = pgDataDir;

    identMap = ''
      # map-name    system-username  database-username
      darwin_peer   stan             postgres
      darwin_peer   stan             miniflux
    '';
    authentication = lib.mkForce ''
      local all all               peer map=darwin_peer
      host  all all 127.0.0.1/32  md5
      host  all all ::1/128       md5
    '';
  };

  launchd.user.agents.postgresql = {
    script = lib.mkBefore ''
      /bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf pgDataDir)}
    '';
    serviceConfig = {
      StandardOutPath = "${home}/Library/Logs/postgresql.log";
      StandardErrorPath = "${home}/Library/Logs/postgresql.log";
    };
  };

  launchd.user.agents.miniflux = {
    path = [
      pgPackage
      pkgs.coreutils
      pkgs.gnugrep
    ];
    script = ''
      set -eu

      # postgresql is a sibling agent with no ordering guarantee; without this
      # wait KeepAlive throttles miniflux into a 10s restart loop at login.
      for _ in $(seq 1 60); do
        # -U/-d only keep the probe out of the server log: pg_isready reports
        # "accepting connections" even when the connection is rejected.
        pg_isready -q -h ${pgSocket} -p ${pgPort} -U postgres -d postgres && break
        sleep 1
      done

      # nix-darwin's postgresql module does not implement ensureUsers /
      # ensureDatabases, so bootstrap them here. both checks are idempotent.
      psql -h ${pgSocket} -p ${pgPort} -U postgres -d postgres -tAc \
        "SELECT 1 FROM pg_roles WHERE rolname = 'miniflux'" | grep -q 1 ||
        createuser -h ${pgSocket} -p ${pgPort} -U postgres miniflux
      psql -h ${pgSocket} -p ${pgPort} -U postgres -d postgres -tAc \
        "SELECT 1 FROM pg_database WHERE datname = 'miniflux'" | grep -q 1 ||
        createdb -h ${pgSocket} -p ${pgPort} -U postgres -O miniflux miniflux

      exec ${pkgs.miniflux}/bin/miniflux
    '';
    environment = {
      DATABASE_URL = databaseUrl;
      RUN_MIGRATIONS = "1";
      LISTEN_ADDR = listenAddr;
      BASE_URL = "http://localhost:8080/";
    };
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${home}/Library/Logs/miniflux.log";
      StandardErrorPath = "${home}/Library/Logs/miniflux.log";
    };
  };

  environment.systemPackages = [ minifluxCli ];
}
