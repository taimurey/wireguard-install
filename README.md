# wireguard-install

![Test](https://github.com/taimurey/wireguard-install/workflows/Test/badge.svg)
![Lint](https://github.com/taimurey/wireguard-install/workflows/Lint/badge.svg)

WireGuard installer for Debian, Ubuntu, and Fedora. This script automates the installation and configuration of a WireGuard VPN server in just a few minutes.

## Features

- Automated WireGuard server installation and configuration
- Docker-based deployment for enhanced isolation
- Comprehensive peer management system
- Mobile and desktop client support
- Automatic updates and security patches
- Built-in logging and monitoring
- Secure configuration with automatic backups
- IPv4 and IPv6 support
- Automated firewall configuration
- Backup and restore functionality

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

You need to run the script as root and have Docker installed (the script will install it if missing).

The first time you run it, you'll have to:

1. Create an admin user
2. Set up initial configuration
3. Choose number of peer configurations to create

When WireGuard is installed, you can run the script again, and you will get the choice to:

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

- The script is regularly tested against distributions marked with 🤖
- Only `amd64` architecture is officially supported
- The script requires `systemd` and `docker`

## Client Setup

### Windows

1. Download WireGuard from [wireguard.com/install](https://www.wireguard.com/install/)
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

- Container-based isolation through Docker
- Automated security updates
- Secure peer configuration storage
- Configuration backup system
- Continuous integration testing
- Unprivileged operation

## Troubleshooting

1. Container Status:

```bash
docker ps
docker logs wireguard
```

2. Port Verification:

```bash
sudo lsof -i :51820
```

3. Server Connectivity:

```bash
curl ifconfig.me
```

4. DNS Leak Testing:

- Visit https://dnsleaktest.com/
- Verify IP matches server IP

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

Please open an issue first for major changes.

## FAQ

**Q:** Which VPS providers do you recommend?

**A:** The following providers work well with WireGuard:

- [Vultr](https://vultr.com): Worldwide locations, IPv6 support, starting at $5/month
- [Hetzner](https://hetzner.com): Germany, Finland and USA locations, starting at 4.5€/month
- [DigitalOcean](https://digitalocean.com): Global infrastructure, starting at $4/month

---

**Q:** What is the recommended number of peers per server?

**A:** While WireGuard can handle many connections efficiently, consider your server's resources. A typical setup can manage 50+ peers comfortably on minimal hardware.

---

**Q:** Why use WireGuard over OpenVPN?

**A:** WireGuard provides:

- Superior performance
- Simpler codebase (easier to audit)
- Modern cryptography
- Lower overhead
- Faster connection establishment

However, choose based on your specific requirements.

## License

This project is under the MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- WireGuard project for the protocol
- LinuxServer.io for the Docker image
- All contributors and testers

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=taimurey/wireguard-install&type=Date)](https://star-history.com/#taimurey/wireguard-install&Date)
