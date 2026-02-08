var numInstances, newInstance;
with(argument0) {
    instance_destroy();
}
receiveCompleteMessage(global.serverSocket, 2);
numInstances = read_ushort(global.serverSocket);
repeat(numInstances) {
    newInstance = instance_create(0,0,argument0);
    with(newInstance) {
        event_user(11);
    }
}
