#!/bin/sh

# Simple hidemevpn OUI RPC test script

# Warning! Input values are not validated, and neither are escaped when encoding to JSON

[ -f ./config ] &&
	. ./config

if [ -z "$URL" -o -z "$SID" ]
then
	echo "No config"
	exit 1
fi

request()
{
	data='{"jsonrpc":"2.0","id":34,"method":"call","params":["'$SID'","hidemevpn","'$1'",'${2:-'{}'}']}'

	echo ">" curl -s "$URL" -X POST --data-raw \'$data\'
	echo -n "< "

	curl -s "$URL" -X POST --data-raw "$data"
}

case "$1" in
	login)
		read -p "Username: " username
		read -p "Password: " -s password
		echo
		read -p "Server: " server

		[ -n "$server" ] && serverjson=',"server":"'$server'"'
		data='{"username":"'$username'","password":"'$password'"'$serverjson'}'

		request "login" "$data"
		;;

	logout)
		request "logout"
		;;

	get_username)
		request "get_username"
		;;

	update_servers)
		read -p "Group ID: " group_id
		read -p "Locale: " locale

		[ -n "$locale" ] && localejson=',"locale":"'$locale'"'
		data='{"group_id":'${group_id}${localejson}'}'

		request "update_servers" "$data"
		;;

	*)
		echo "Usage: test.sh <cmd>"
		echo "Valid <cmd>s: login, logout, get_username, update_servers"
		;;
esac

exit $?
