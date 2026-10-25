# spearmc-tunnel

Let players join a home Minecraft server through an Oracle Cloud VM, with no router port forwarding.

```
Player -> Oracle VM :25565 -> [WireGuard tunnel] -> Home MC server (10.13.13.2:25565)
```

Your home machine dials OUT to Oracle. Works with any server type (Fabric, Paper, Forge, vanilla).
The whitelist works by username/UUID.

## Repo layout

```
compose.base.yml     shared container settings
compose.yml          two services: `oracle` and `home` (both extend the base)
oracle/init.sh       builds the Oracle WireGuard config from oracle.env
home/init.sh         builds the home WireGuard config from home.env
scripts/gen-keys.sh  generates all keys and writes oracle.env + home.env
```

## One-time setup

### 1. Oracle Cloud console
Networking -> your VCN -> Security List (or NSG) -> add INGRESS rules, source 0.0.0.0/0:
- UDP 51820 (WireGuard)
- TCP 25565 (Minecraft)
- UDP 19132 too if you use Bedrock

### 2. Generate keys (once, on any machine with Docker, e.g. the home PC)
```
git clone <your-repo-url> spearmc-tunnel && cd spearmc-tunnel
./scripts/gen-keys.sh YOUR_ORACLE_PUBLIC_IP
```
This creates `oracle.env` and `home.env` (both gitignored).

### 3. Oracle VM
```
git clone <your-repo-url> spearmc-tunnel && cd spearmc-tunnel
# copy oracle.env here, e.g. from the machine in step 2:
#   scp oracle.env ubuntu@YOUR_ORACLE_PUBLIC_IP:~/spearmc-tunnel/
cp oracle.env .env
chmod +x oracle/init.sh
docker compose up -d oracle
docker logs spearmc-tunnel-oracle      # should say it wrote wg0.conf
```
If you used the earlier manual setup, run `docker compose down` in that old folder first and delete its `config/` folder.

### 4. Home Minecraft machine
```
cd spearmc-tunnel                      # home.env goes here
cp home.env .env
chmod +x home/init.sh
sudo systemctl disable --now wg-quick@wg0 2>/dev/null   # only if you set up WireGuard by hand before
docker compose up -d home
sudo ufw allow in on wg0 to any port 25565 proto tcp    # if you use ufw
ping 10.13.13.1                        # Oracle end of the tunnel
```
The Minecraft server must run on this machine (or in Docker with `network_mode: host`) so it is reachable at 10.13.13.2:25565.

### 5. Whitelist (`server.properties`)
```
online-mode=true
white-list=true
enforce-whitelist=true
```
Add players from the server console: `whitelist add PlayerName`. Keep `online-mode=true` so the whitelist is tied to real Mojang accounts.

### 6. Test
Connect to `YOUR_ORACLE_PUBLIC_IP:25565` from a network that is NOT your home LAN (phone data or a friend). Optionally point a DNS A record at the Oracle IP.

## Bedrock / Geyser (optional)
1. In `compose.yml`, uncomment the `19132:19132/udp` port line under `oracle`.
2. In `oracle.env`, set `FORWARD_UDP_PORTS=19132`.
3. Open UDP 19132 in the OCI rules, then `docker compose up -d --force-recreate oracle`.

## Troubleshooting
- Check the tunnel: `docker exec spearmc-tunnel-oracle wg show` and `docker exec spearmc-tunnel-home wg show`. Look for "latest handshake".
- No handshake: check UDP 51820 in the OCI rules and `ORACLE_PUBLIC_IP` in `home.env`.
- Tunnel up but players can't connect: confirm TCP 25565 in the OCI rules, check
  `docker exec spearmc-tunnel-oracle iptables -t nat -L PREROUTING -n` shows the 25565 rule, and confirm the Minecraft server is listening and allowed through the firewall on wg0.
- Oracle Ubuntu images sometimes have a blanket REJECT in host iptables: `sudo iptables -L INPUT -n --line-numbers`.
- "Connection throttled" when several players join: set `connection-throttle: -1` in `bukkit.yml` (Paper-based). All players appear to come from 10.13.13.1, so ban by username/UUID, not IP.
- Changing ports or keys: edit the `.env` file (and its `oracle.env`/`home.env` source), then `docker compose up -d --force-recreate oracle` (or `home`).

## Put it on GitHub
```
git init && git add . && git commit -m "Initial commit"
git branch -M main
git remote add origin git@github.com:YOU/spearmc-tunnel.git
git push -u origin main
```
`oracle.env`, `home.env` and `config/` are gitignored, so no keys or IPs get pushed.
