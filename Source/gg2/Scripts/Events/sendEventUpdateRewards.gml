/**
 * Notify all clients that a player has authenticated for some rewards
 *
 * argument0: The player who just did so
 * argument1: The reward string
 */

write_ubyte(global.sendBuffer, REWARD_UPDATE);
write_ubyte(global.sendBuffer, ds_list_find_index(global.players,argument0));
writePrefixedString2(global.sendBuffer, argument1);
