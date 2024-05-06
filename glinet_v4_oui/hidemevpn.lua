--[[
	@object-name: hidemevpn
	@object-desc: hidemevpn settings
--]]

local cjson = require "cjson"
local uci = require "uci"

local M = {}

function error_invalid_params()
	return { err_code = -1, err_msg = "Invalid parameters" }
end

--[[
	@method-type:	call
	@method-name:	get_username
	@method-desc:	Get Hide.me VPN logged username

	@out string	username	Hide.me VPN username (may be set to "**unknown**" when logged in but username is not present)

	@in-example:	{"jsonrpc":"2.0","id":1,"method":"call","params":["","hidemevpn","get_username"]}
	@out-example:	{"jsonrpc": "2.0","id":1,"result":{"username": "jane"}}
--]]
function M.get_username()
	local c = uci.cursor()
	local token = c:get("hideme", "vpn", "accesstoken")

	if token == nil or token:len() == 0
	then
		return {}
	end

	local username = c:get("hideme", "vpn", "username")

	if username == nil
	then
		username = "**unknown**"
	end

	return {username=username}
end

--[[
	@method-type:	call
	@method-name:	login
	@method-desc:	Authorize/login user, obtain and store access token

	@in string	username	Username
	@in string	password	User's password
	@in string	?server		Server to authorize on (option, default: any.hideservers.net)

	@out string	username	Hide.me VPN username (may be set to "**unknown**" when logged in but username is not present)

	@out number	?err_code	Error code, -1:Invalid parameters, -2:Login failed
	@out string	?err_msg	Error message

	@in-example:	{"jsonrpc":"2.0","id":1,"method":"call","params":["","hidemevpn","update_servers", {"username":"jane","password":"somepassword"}]}
	@out-example:	{"jsonrpc": "2.0","id":1,"result":{"username": "jane"}}
--]]
function M.login(params)
	if not params or not params.username or not params.password then
		return error_invalid_params()
	end

	local proc = ngx.pipe.spawn({"/usr/sbin/hidemevpn", "login", params.username, params.password, params.server})
	local stdout = proc:stdout_read_all()
	local ok, status, err = proc:wait()

	if not ok then
		return { err_code = -2, err_msg = string.format("Login failed. Error code: %d", err) }
	end

	local accesstoken = stdout:gsub("\n", "")

	local c = uci.cursor()

	local hvpn = c:get("hideme", "vpn")

	if not hvpn or hvpn ~= "hideme" then
		c:set("hideme", "vpn", "hideme")
	end

	c:set("hideme", "vpn", "accesstoken", accesstoken)
	c:set("hideme", "vpn", "username", params.username)
	c:commit("hideme")

	c:set("network", "wgclient", "pre_setup_script", "/usr/sbin/hidemevpn connect")
	c:commit("network")

	return M.get_username()
end

--[[
	@method-type:	call
	@method-name:	logout
	@method-desc:	Logout user, remove credentials

	@in-example:	{"jsonrpc":"2.0","id":1,"method":"call","params":["","hidemevpn","logout"]}
	@out-example:	{"jsonrpc":"2.0","id": 1,"result":[]}
--]]
function M.logout()
	local c = uci.cursor()

	c:delete("hideme", "vpn", "accesstoken")
	c:delete("hideme", "vpn", "username")
    	c:commit("hideme")

	c:delete("network", "wgclient", "pre_setup_script", "/usr/sbin/hidemevpn connect")
	c:commit("network")

	return {}
end

--[[
	@method-type:	call
	@method-name:	update_servers
	@method-desc:	Update list of Hide.me VPN servers/locations

	@in number	group_id	Configuration group id where servers should be stored/updated
	@in string	?locale		Desired locale for servers/locations description (optional, default: en)

	@out number	?err_code	Error code, -1:Invalid parameters, -3:Servers update failed
	@out string	?err_msg	Error message

	@in-example:	{"jsonrpc":"2.0","id":1,"method":"call","params":["","hidemevpn","update_servers", {"group_id":1234,"locale":"en"}]}
	@out-example:	{"jsonrpc":"2.0","id": 1,"result":[]}
--]]
function M.update_servers(params)
	if not params or not params.group_id then
		return error_invalid_params()
	end

	local group_id = tonumber(params.group_id)

	if not group_id then
		return error_invalid_params()
	end

	c = uci.cursor()

	local group = c:get("wireguard", "group_" .. tostring(group_id))

	if not group or group ~= "groups" then
		return error_invalid_params()
	end

	local proc = ngx.pipe.spawn({"/usr/sbin/hidemevpn", "servers", params.locale})
	local json = proc:stdout_read_all()
	local ok, status, err = proc:wait()

	if not ok then
		return { err_code = -3, err_msg = string.format("Servers update failed. Error code: %d", err) }
	end

	local data = cjson.decode(json)

	if not data or not data['servers'] then
		return { err_code = -3, err_msg = "Servers update failed. Invalid response" }
	end

	local servers = {}

	for _, server in pairs(data['servers']) do
		servers[server['hostname']] = {
			name = server["displayName"],
			done = false
		}

		if server['children'] then
			for _, child in pairs(server['children']) do
				servers[child["hostname"]] = {
					name = server["displayName"] .. " - " .. child["displayName"],
					done = false
				}
			end
		end
	end

	c:foreach("wireguard", "peers", function(s)
		if not s["group_id"] then
			return
		end

		local gid = tonumber(s["group_id"])

		if gid ~= group_id then
			return
		end

		local hostname = s["end_point"]:match("[^:]+")

		if not servers[hostname] then
			c:delete("wireguard", s[".name"])
			return
		end

		servers[hostname].done = true

		if servers[hostname].name ~= s["name"] then
			c:set("wireguard", s[".name"], "name", servers[hostname].name)
		end
	end)

	math.randomseed(os.time())

	for hostname, server in pairs(servers) do
		if not server['done'] then

			local peer = nil
			local id = 0
			local n = 10

			while id == 0 and n > 0 do
				id = math.random(10000, 99999)
				peer = "peer_" .. id

				if c:get("wireguard", peer) then
					id = 0
					peer = nil
				end

				n = n - 1
			end

			if peer then
				c:set("wireguard", peer, "peers")
				c:set("wireguard", peer, "group_id", tostring(group_id))
				c:set("wireguard", peer, "name", server["name"])
				c:set("wireguard", peer, "listen_port", "0")
				c:set("wireguard", peer, "allowed_ips", "0.0.0.0/0,::/0")
				c:set("wireguard", peer, "ipv6_enable", "0")
				c:set("wireguard", peer, "presharedkey_enable", "1")
				c:set("wireguard", peer, "local_access", "0")
				c:set("wireguard", peer, "masq", "1")
				c:set("wireguard", peer, "persistent_keepalive", "20")
				c:set("wireguard", peer, "address_v4", "0.0.0.0")
				c:set("wireguard", peer, "private_key", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
				c:set("wireguard", peer, "public_key", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
				c:set("wireguard", peer, "end_point", hostname .. ":432")
			end
		end
	end

	c:commit("wireguard")

	return {}
end

return M
