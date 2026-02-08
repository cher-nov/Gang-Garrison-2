var win;
receiveCompleteMessage(global.serverSocket, 5);
win = read_ubyte(global.serverSocket);
mvps[TEAM_RED] = read_ubyte(global.serverSocket);
mvps[TEAM_BLUE] = read_ubyte(global.serverSocket);
redWins = read_ubyte(global.serverSocket);
blueWins = read_ubyte(global.serverSocket);

for(i=0; i < mvps[TEAM_RED]; i+=1) {
    receiveCompleteMessage(global.serverSocket, 5);
    redMVP[i] = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
    redMVP[i].roundStats[KILLS] = read_ubyte(global.serverSocket);
    redMVP[i].roundStats[HEALING] = read_ushort(global.serverSocket);
    redMVP[i].roundStats[POINTS] = read_ubyte(global.serverSocket);
}

for(i=0; i < mvps[TEAM_BLUE]; i+=1) {
    receiveCompleteMessage(global.serverSocket, 5);
    blueMVP[i] = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
    blueMVP[i].roundStats[KILLS] = read_ubyte(global.serverSocket);
    blueMVP[i].roundStats[HEALING] = read_ushort(global.serverSocket);
    blueMVP[i].roundStats[POINTS] = read_ubyte(global.serverSocket);
}

doEventArenaEndRound(win);
