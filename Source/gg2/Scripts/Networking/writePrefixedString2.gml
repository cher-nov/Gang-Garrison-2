// Write a string with an unsigned 2-byte length descriptor to a buffer.

var data, length;
data = string_copy(argument1, 1, 65535);
length = string_length(data);

write_ushort(argument0, length);
write_binary_string(argument0, data);
return length;
