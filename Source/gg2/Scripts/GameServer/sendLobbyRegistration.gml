if(!global.useLobbyServer)
    exit;

var noOfOccupiedSlots;
noOfOccupiedSlots = getNumberOfOccupiedSlots();

var lobbyBuffer;
lobbyBuffer = buffer_create();
set_little_endian(lobbyBuffer, false);

parseUuid("b5dae2e8-424f-9ed0-0fcb-8c21c7ca1352", lobbyBuffer); // Message Type "register"
write_buffer(lobbyBuffer, GameServer.serverId);
write_buffer(lobbyBuffer, global.gg2lobbyId);
write_ubyte(lobbyBuffer, 0); // TCP
write_ushort(lobbyBuffer, global.hostingPort);
write_ushort(lobbyBuffer, global.playerLimit);
write_ushort(lobbyBuffer, noOfOccupiedSlots);
write_ushort(lobbyBuffer, 0); // Number of bots
write_ushort(lobbyBuffer, global.serverPassword != "");

write_ushort(lobbyBuffer, 7); // Number of Key/Value pairs that follow
writeKeyValue(lobbyBuffer, "name", global.serverName);
writeKeyValue(lobbyBuffer, "game", GAME_NAME_STRING);
writeKeyValue(lobbyBuffer, "game_short", "gg2");
writeKeyValue(lobbyBuffer, "game_ver", GAME_VERSION_STRING);
writeKeyValue(lobbyBuffer, "game_url", GAME_URL_STRING);
writeKeyValue(lobbyBuffer, "map", global.currentMap);
writePrefixedString1(lobbyBuffer, "protocol_id");
write_ushort(lobbyBuffer, 16);
write_buffer(lobbyBuffer, global.protocolUuid);

udp_send(lobbyBuffer, LOBBY_SERVER_HOST, LOBBY_SERVER_PORT);
buffer_destroy(lobbyBuffer);
