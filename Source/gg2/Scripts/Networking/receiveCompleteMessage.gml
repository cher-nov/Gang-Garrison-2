// This function attempts to read a message of the length given in arg1.
// It won't return unless the complete message is read or an error occurs.

// If the message is received completely, it returns 0
// If the socket had to be closed due to an error or loss of connection, it returns 2

// argument 0: Socket
// argument 1: size of the message to receive

var buffer;

do {
    if(socket_has_error(argument0)) {
        return 2;
    }
} until(tcp_receive(argument0, argument1));

return 0;
