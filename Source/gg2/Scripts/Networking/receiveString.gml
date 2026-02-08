/* Receive a string with length prefix. Blocks until the complete string is read */

var socket, prefix_size;
socket = argument0;
prefix_size = argument1;

if(receiveCompleteMessage(socket, prefix_size) > 0) {
    return "";
}

var length;
if(prefix_size == 1) {
    length = read_ubyte(socket);
} else {
    length = read_ushort(socket);
}

if(receiveCompleteMessage(socket, length) > 0) {
    return "";
}

return read_binary_string(socket, length);
