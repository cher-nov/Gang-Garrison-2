// Write a string with an unsigned byte length descriptor to a buffer.

var data, length;
data = argument1;
length = string_length(data);
if(length > 255)
    show_error("String too long (" + string(length) + "): " + data, true);

write_ubyte(argument0, length);
write_binary_string(argument0, data);
return length;
