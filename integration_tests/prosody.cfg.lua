admins = { }
plugin_paths = {}

modules_enabled = {
	-- Generally required
		"disco"; -- Service discovery
		"roster"; -- Allow users to have a roster. Recommended ;)
		"saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
		"tls"; -- Add support for secure TLS on c2s/s2s connections

	-- Not essential, but recommended
		"blocklist"; -- Allow users to block communications with other users
		"bookmarks"; -- Synchronise the list of open rooms between clients
		"carbons"; -- Keep multiple online clients in sync
		"dialback"; -- Support for verifying remote servers using DNS
		"limits"; -- Enable bandwidth limiting for XMPP connections
		"pep"; -- Allow users to store public and private data in their account
		"private"; -- Legacy account storage mechanism (XEP-0049)
		"smacks"; -- Stream management and resumption (XEP-0198)
		"vcard4"; -- User profiles (stored in PEP)
		"vcard_legacy"; -- Conversion between legacy vCard and PEP Avatar, vcard

	-- Nice to have
		"csi_simple"; -- Simple but effective traffic optimizations for mobile devices
		"invites"; -- Create and manage invites
		"invites_adhoc"; -- Allow admins/users to create invitations via their client
		"invites_register"; -- Allows invited users to create accounts
		"ping"; -- Replies to XMPP pings with pongs
		"register"; -- Allow users to register on this server using a client and change passwords
		"time"; -- Let others know the time here on this server
		"uptime"; -- Report how long server has been running
		"version"; -- Replies to server version requests

	-- SASL2
	        "sasl2";
		"sasl2_sm";
		"sasl2_fast";
		"sasl2_bind2";
}

s2s_secure_auth = false

-- Authentication
authentication = "internal_plain"

-- Storage
storage = "internal"
data_path = "/tmp/prosody-data/"
log = {
	debug = "*console";
}

pidfile = "/tmp/prosody.pid"

component_ports = { 8888 }
component_interfaces = { '127.0.0.1' }
VirtualHost "localhost"

Component "component.localhost"
    component_secret = "abc123"

Component "muc.localhost" "muc"
