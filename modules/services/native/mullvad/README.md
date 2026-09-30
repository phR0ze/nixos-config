# Mullvad VPN

Privacy-focused VPN using anonymous account numbers. No personal information required to register.

## Manual Setup

### Mullvad service configuration
After enabling, the daemon needs one-time configuration:

1. Verify daemon is running: `sudo systemctl status mullvad-daemon`
2. Log in with your account number: `mullvad account login <ACCOUNT_NUMBER>`
3. See [Mullvad config guide](https://github.com/phR0ze/tech-docs/tree/main/src/networking/overlay_networks/vpns/mullvad)

### Mullvad vopono configuration
See [Vopono config guide](https://github.com/phR0ze/tech-docs/tree/main/src/networking/overlay_networks/vpns/vopono)
