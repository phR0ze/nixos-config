# Upstream caddy with the caddy-dns/cloudflare DNS-01 plugin
#
# `cloudflarePluginTag`/`hash` come from `services.native.caddy.cloudflarePluginTag`/
# `cloudflarePluginHash` - see README.md for refreshing the hash.
#---------------------------------------------------------------------------------------------------
{ caddy, cloudflarePluginTag, hash }:

caddy.withPlugins {
  plugins = [ "github.com/caddy-dns/cloudflare@${cloudflarePluginTag}" ];
  inherit hash;
}
