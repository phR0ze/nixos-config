# Non-secret argument overrides for the macbook, layered on top of the root `args.nix`/`args.dec.json`
# --------------------------------------------------------------------------------------------------
{
  net = {
    dns = {
      # Don't force a global nameserver on this roaming laptop - the root args.dec.json sets
      # net.dns.primary to the home DNS server, which breaks DNS resolution on any other network
      # (hotel wifi, airline captive portals, etc.) since it stomps on the DHCP-provided per-link DNS.
      # Leaving primary empty lets each link's own DHCP-assigned DNS win, which is what makes captive
      # portal login pages resolve automatically. At home the router still hands out the same server
      # via DHCP, so it's used there anyway.
      primary = "";
      # Only used by resolved if a link provides no DNS at all.
      fallback = "1.1.1.1 8.8.8.8";
    };
  };
}
