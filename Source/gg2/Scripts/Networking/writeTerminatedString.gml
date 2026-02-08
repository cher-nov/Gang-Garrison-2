// Write a string with a string delimiter after it to a buffer.

var data, length;
data = argument1;
if (is_string(argument2)) data += argument2;
length = string_length(data);

write_binary_string(argument0, data);
return length;
