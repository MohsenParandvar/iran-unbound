![logo](https://raw.githubusercontent.com/MohsenParandvar/iran-unbound/refs/heads/main/logo.png)

# Iran Unbound 

> A simple Bash script to install and configure `dnsmasq` on Linux systems, enabling users to bypass Iran's boycotted domains while using the default DNS resolver for all other domains.

![GitHub license](https://img.shields.io/github/license/mohsenparandvar/iran-unbound)
![GitHub stars](https://img.shields.io/github/stars/mohsenparandvar/iran-unbound)
![GitHub issues](https://img.shields.io/github/issues/mohsenparandvar/iran-unbound)

---

## About The Project

**Iran-Unbound** is a lightweight and easy-to-use Bash script designed to help users bypass Iran's boycotted domains (e.g., Docker, Google Developer, Golang, etc.) by configuring [`dnsmasq`](https://thekelleys.org.uk/dnsmasq/doc.html) on their Linux systems. It solves the common `403 Forbidden` error when accessing these websites, ensuring a seamless browsing experience without requiring advanced technical knowledge.

The script is designed to:
- Automatically install and configure `dnsmasq`.
- Bypass **only** the boycotted domains while using the default DNS resolver for all other domains.
- Keep the list of boycotted domains up-to-date with periodic updates.

---

## Key Features

- **Easy Installation**: No technical expertise required—just run the script, and it handles everything.
- **Selective Bypass**: Only bypasses boycotted domains, ensuring all other domains resolve through your default DNS.
- **Fast and Secure**: Because of the Selective Bypass feature, your internet connection will be faster and safer.
- **Cross-Distribution Support**: Works on RHEL, Debian, and Arch based Linux distributions.
- **Automatic Updates**: The list of boycotted domains is updated periodically, ensuring you always have the latest configurations.
- **Lightweight**: Minimal resource usage, making it perfect for all systems.
- **Permanent and Hassle-Free**: Once set up, no need for further configuration—your system will automatically work with the service every time it powers on.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/MohsenParandvar/iran-unbound
   ```

2. Make the script executable:
   ```bash
   chmod +x iran-unbound
   ```

3. Run the installation:
   ```bash
   sudo ./iran-unbound.sh --install
   ```

For install non-interactively:
```bash
sudo ./iran-unbound.sh --install -y
```

## Update the Domain List
To manually update the list of boycotted domains, run:
```bash
sudo ./iran-unbound.sh --update
```

## Change the DNS Bypass Resolver
To change the DNS resolver used for bypassing boycotted domains, run:
```bash
sudo ./iran-unbound.sh --dns {dns_resolver_ip}
```

## Disable/Enable Service
for disable the service and restore to system default you can use this:

```bash
sudo ./iran-unbound.sh --disable
```

and for enable again, use:

```bash
sudo ./iran-unbound.sh --enable
```

## Uninstall
Restore to system defaults:
```bash
sudo ./iran-unbound.sh --uninstall
```

## Supported Distributions
- RHEL-based (e.g., CentOS, Fedora)
- Debian-based (e.g., Ubuntu, Debian)
- Arch-based (e.g., Arch Linux, Manjaro)

## Contact
If you have any questions, feedback, or issues, feel free to reach out:

GitHub Issues: Open an Issue

Email: Mohsen.Parandvar@yahoo.com

> We hope that such sanctions never come to pass, and that we can continue to use the internet freely without the need for such tools.

## Buy me a coffee
If you'd like, you can buy me a coffee! ;)

[BuyMeACoffee](https://www.buymeacoffee.com/mohsenparandvar) ☕
