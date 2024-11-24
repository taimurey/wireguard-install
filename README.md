# wireguard-install

![Test](https://github.com/taimurey/wireguard-install/workflows/Test/badge.svg)

WireGuard installer for Debian, Ubuntu, and Fedora. This script automates the installation and configuration of a WireGuard VPN server, making it easy to set up your own secure VPN in just a few minutes.

## Features

- 🚀 One-click WireGuard server installation
- 🔒 Docker-based deployment for enhanced security and isolation
- 👥 Easy peer management (add/revoke)
- 📱 Mobile-friendly (QR codes for phone configs)
- 🔄 Automatic updates and security patches
- 📝 Comprehensive logging
- 🔐 Secure configuration with automatic backups
- 🌐 IPv4 and IPv6 support
- 🛡️ Automatic firewall configuration
- 💾 Configuration backup system

## Prerequisites

- A Linux server (Debian/Ubuntu/Fedora)
- Root access or sudo privileges
- Port 51820/UDP open on your firewall
- Docker and Docker Compose (auto-installed by script)

## Usage

First, get the script and make it executable:

```bash
git clone https://github.com/taimurey/wireguard-install.git
cd wireguard-install
chmod +x wireguard-manager.sh
```

Then run it:

```bash
sudo ./wireguard-manager.sh
```

The first time you run it, you'll have to:

1. Create an admin user
2. Set up initial configuration
3. Choose number of peer configurations to create

When WireGuard is installed, running the script again gives you these options:

- Add a new peer
- Revoke existing peer
- Remove WireGuard
- Exit

Client configuration files are stored in `/opt/wireguard-server/config/peer[X]/peer[X].conf`.

## Compatibility

The script supports these Linux distributions:

| Distribution    | Support |
| --------------- | ------- |
| Ubuntu >= 22.04 | ✅ 🤖   |
| Debian >= 11    | ✅ 🤖   |
| Fedora >= 39    | ✅ 🤖   |

Notes:

- 🤖 indicates distributions that are regularly tested in CI
- Only `amd64` architecture is officially supported
- Script requires `systemd` and `docker`

## Client Setup

### Windows

1. Download [WireGuard](https://www.wireguard.com/install/)
2. Import the peer configuration file
3. Click "Activate"

### Mobile (Android/iOS)

1. Install WireGuard from your app store
2. Scan the QR code displayed during peer creation
3. Enable the VPN

### Linux

1. Install WireGuard:

```bash
sudo apt install wireguard
```

2. Copy peer configuration to `/etc/wireguard/wg0.conf`
3. Enable and start:

```bash
sudo systemctl enable --now wg-quick@wg0
```

## Configuration Files

```plaintext
/opt/wireguard-server/
├── docker-compose.yaml     # Main WireGuard configuration
├── config/                 # Peer configurations
│   ├── peer1/
│   │   └── peer1.conf
│   ├── peer2/
│   │   └── peer2.conf
├── backups/               # Automatic backups
└── revoked/              # Revoked peer configs
```

## Security Features

- Docker container isolation
- Automatic security updates
- Secure peer configuration storage
- Backup system for configurations
- Regular security audits via GitHub Actions
- No root access after initial setup

## Troubleshooting

1. Check container status:

```bash
docker ps
docker logs wireguard
```

2. Verify port is open:

```bash
sudo lsof -i :51820
```

3. Check server connectivity:

```bash
curl ifconfig.me
```

4. Test for DNS leaks:

- Visit https://dnsleaktest.com/
- Ensure your IP matches the server IP

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

Please open an issue first for major changes.

## FAQ

**Q:** Which VPS providers do you recommend?

**A:** These providers work well with WireGuard:

- [DigitalOcean](https://m.do.co/c/YOUR_REF_CODE)
- [Vultr](https://vultr.com)
- [Hetzner](https://hetzner.com)

---

**Q:** How many peers can I create?

**A:** The script allows unlimited peers, but consider your server's resources. A typical setup can easily handle 50+ peers.

---

**Q:** Is WireGuard better than OpenVPN?

**A:** WireGuard is generally:

- Faster (better performance)
- Simpler (less code, fewer potential vulnerabilities)
- More modern (newer cryptography)
- Easier to audit (smaller codebase)

However, choose based on your specific needs.

## License

This project is under the MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [WireGuard](https://www.wireguard.com/) for the excellent VPN protocol
- [LinuxServer.io](https://linuxserver.io/) for the Docker image
- All contributors and testers

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=taimurey/wireguard-install&type=Date)](https://star-history.com/#taimurey/wireguard-install&Date)
