var playername;
write_ubyte(argument0, RESERVE_SLOT);
playername = string_copy(global.playerName, 1, MAX_PLAYERNAME_LENGTH);
writePrefixedString1(argument0, playername);
