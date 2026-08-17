{ pkgs, ... }:
let
  container = pkgs.unstable.container;
  startScript = pkgs.writeShellScript "container-system-start" ''
    exec >>"$HOME/Library/Logs/container-system-start.log" 2>&1
    apiserver="${container}/bin/container-apiserver"
    plist="$HOME/Library/Application Support/com.apple.container/apiserver/apiserver.plist"
    if /bin/launchctl print "gui/$(id -u)/com.apple.container.apiserver" > /dev/null 2>&1; then
      if [ "$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "$plist" 2> /dev/null)" = "$apiserver" ]; then
        exit 0
      fi
      # apiserver running from a stale store path; stop before re-registering
      ${container}/bin/container system stop
    fi
    exec ${container}/bin/container system start --enable-kernel-install
  '';
in
{
  environment.systemPackages = [ container ];

  launchd.user.agents.container-system-start = {
    command = toString startScript;
    serviceConfig.RunAtLoad = true;
  };
}
