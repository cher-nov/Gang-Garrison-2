// argument0 - map name
// argument1 - map md5
// argument2 - buffer

write_ubyte(argument2, CHANGE_MAP);
writePrefixedString1(argument2, argument0);
writePrefixedString1(argument2, argument1);
