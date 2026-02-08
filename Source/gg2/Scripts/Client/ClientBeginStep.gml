// receive and interpret the server's message(s)
var i, playerObject, playerID, player, otherPlayerID, otherPlayer, sameVersion, buffer, usePlugins;

if(tcp_eof(global.serverSocket)) {
    if(gotServerHello)
        show_message("You have been disconnected from the server.");
    else
        show_message("Unable to connect to the server.");
    instance_destroy();
    exit;
}

if(room == DownloadRoom and keyboard_check(vk_escape))
{
    instance_destroy();
    exit;
}

if(downloadingMap)
{
    while(tcp_receive(global.serverSocket, min(1024, downloadMapBytes-buffer_size(downloadMapBuffer))))
    {
        write_buffer(downloadMapBuffer, global.serverSocket);
        if(buffer_size(downloadMapBuffer) == downloadMapBytes)
        {
            write_buffer_to_file(downloadMapBuffer, "Maps/" + downloadMapName + ".png");
            downloadingMap = false;
            buffer_destroy(downloadMapBuffer);
            downloadMapBuffer = -1;
            exit;
        }
    }
    exit;
}

roomchange = false;
do {
    if(tcp_receive(global.serverSocket,1)) {
        switch(read_ubyte(global.serverSocket)) {
        case HELLO:
            gotServerHello = true;
            global.joinedServerName = receiveString(global.serverSocket, 1);
            downloadMapName = receiveString(global.serverSocket, 1);
            advertisedMapMd5 = receiveString(global.serverSocket, 1);
            receiveCompleteMessage(global.serverSocket, 1);
            pluginsRequired = read_ubyte(global.serverSocket);
            plugins = receiveString(global.serverSocket, 2);

            if(string_pos("/", downloadMapName) != 0 or string_pos("\", downloadMapName) != 0)
            {
                show_message("Server sent illegal map name: "+downloadMapName);
                instance_destroy();
                exit;
            }
            ClientReserveSlot(global.serverSocket)
            socket_send(global.serverSocket);
            break;

        case RESERVE_SLOT:
            if (!noReloadPlugins && string_length(plugins))
            {
                usePlugins = pluginsRequired || !global.serverPluginsPrompt;
                if (global.serverPluginsPrompt)
                {
                    // Split up plugin list
                    var pluginList;
                    pluginList = split(plugins, ',');

                    // Iterate over list and make displayable list without hashes
                    var displayList, i;
                    displayList = '';
                    for (i = 0; i < ds_list_size(pluginList); i += 1)
                    {
                        var pluginParts;
                        pluginParts = split(ds_list_find_value(pluginList, i), '@');
                        displayList += '- ' + ds_list_find_value(pluginParts, 0) + '#';
                        ds_list_destroy(pluginParts);
                    }

                    // Destroy list
                    ds_list_destroy(pluginList);

                    var prompt;
                    if (pluginsRequired)
                    {
                        prompt = show_message_ext(
                            'You need these plugins to play on this server: #'
                            + displayList
                            + PLUGIN_SOURCE_NOTICE
                            + '#Do you want to download them and join the server?',
                            'Download and join',
                            '',
                            'Disconnect'
                        );
                        if (prompt != 1)
                        {
                            instance_destroy();
                            exit;
                        }
                    }
                    else
                    {
                        prompt = show_message_ext(
                            'These optional plugins are suggested for this server: #'
                            + displayList
                            + PLUGIN_SOURCE_NOTICE
                            + '#Do you want to download them?',
                            'Download',
                            '',
                            'Skip'
                        );
                        if (prompt == 1)
                        {
                            usePlugins = true;
                        }
                        else
                        {
                            // We set this so that we won't prompt for plugins again if we re-connect to download a map
                            skippedPlugins = true;
                        }
                    }
                }
                if (usePlugins)
                {
                    if (!loadserverplugins(plugins))
                    {
                        show_message("Error occurred loading server-sent plugins.");
                        instance_destroy();
                        exit;
                    }
                    global.serverPluginsInUse = true;
                }
            }
            noReloadPlugins = false;

            if(advertisedMapMd5 != "")
            {
                var download;
                download = not file_exists("Maps/" + downloadMapName + ".png");
                if(!download and CustomMapGetMapMD5(downloadMapName) != advertisedMapMd5)
                {
                    if(show_question("The server's copy of the map (" + downloadMapName + ") differs from ours.#Would you like to download this server's version of the map?"))
                        download = true;
                    else
                    {
                        instance_destroy();
                        exit;
                    }
                }

                if(download)
                {
                    write_ubyte(global.serverSocket, DOWNLOAD_MAP);
                    socket_send(global.serverSocket);
                    receiveCompleteMessage(global.serverSocket, 4);
                    downloadMapBytes = read_uint(global.serverSocket);
                    downloadMapBuffer = buffer_create();
                    downloadingMap = true;
                    roomchange=true;
                }
            }
            ClientPlayerJoin(global.serverSocket);
            if(global.rewardKey != "" and global.rewardId != "")
            {
                var rewardId;
                rewardId = string_copy(global.rewardId, 0, 255);
                write_ubyte(global.serverSocket, REWARD_REQUEST);
                writePrefixedString1(global.serverSocket, rewardId);
            }
            if(global.queueJumping == true)
            {
                write_ubyte(global.serverSocket, CLIENT_SETTINGS);
                write_ubyte(global.serverSocket, global.queueJumping);
            }
            socket_send(global.serverSocket);
            break;

        case JOIN_UPDATE:
            receiveCompleteMessage(global.serverSocket, 2);
            global.playerID = read_ubyte(global.serverSocket);
            global.currentMapArea = read_ubyte(global.serverSocket);
            break;

        case FULL_UPDATE:
            deserializeState(FULL_UPDATE);
            break;

        case QUICK_UPDATE:
            deserializeState(QUICK_UPDATE);
            break;

        case CAPS_UPDATE:
            deserializeState(CAPS_UPDATE);
            break;

        case INPUTSTATE:
            deserializeState(INPUTSTATE);
            break;

        case PLAYER_JOIN:
            player = instance_create(0,0,Player);
            player.name = receiveString(global.serverSocket, 1);

            ds_list_add(global.players, player);
            if(ds_list_size(global.players)-1 == global.playerID) {
                global.myself = player;
                instance_create(0,0,PlayerControl);
            }
            break;

        case PLAYER_LEAVE:
            // Delete player from the game, adjust own ID accordingly
            receiveCompleteMessage(global.serverSocket, 1);
            playerID = read_ubyte(global.serverSocket);
            player = ds_list_find_value(global.players, playerID);
            removePlayer(player);
            if(playerID < global.playerID) {
                global.playerID -= 1;
            }
            break;

        case PLAYER_DEATH:
            var causeOfDeath, assistantPlayerID, assistantPlayer;
            receiveCompleteMessage(global.serverSocket, 4);
            playerID = read_ubyte(global.serverSocket);
            otherPlayerID = read_ubyte(global.serverSocket);
            assistantPlayerID = read_ubyte(global.serverSocket);
            causeOfDeath = read_ubyte(global.serverSocket);

            player = ds_list_find_value(global.players, playerID);

            otherPlayer = noone;
            if(otherPlayerID != 255)
                otherPlayer = ds_list_find_value(global.players, otherPlayerID);

            assistantPlayer = noone;
            if(assistantPlayerID != 255)
                assistantPlayer = ds_list_find_value(global.players, assistantPlayerID);

            doEventPlayerDeath(player, otherPlayer, assistantPlayer, causeOfDeath);
            break;

        case BALANCE:
            receiveCompleteMessage(global.serverSocket, 1);
            balanceplayer = read_ubyte(global.serverSocket);
            if balanceplayer == 255 {
                if !instance_exists(Balancer) instance_create(x,y,Balancer);
                with(Balancer) notice=0;
            } else {
                receiveCompleteMessage(global.serverSocket, 1);
                player = ds_list_find_value(global.players, balanceplayer);
                player.class = read_ubyte(global.serverSocket);
                if(player.object != -1) {
                    with(player.object) {
                        instance_destroy();
                    }
                    player.object = -1;
                }
                if(player.team==TEAM_RED) {
                    player.team = TEAM_BLUE;
                } else {
                    player.team = TEAM_RED;
                }
                if !instance_exists(Balancer) instance_create(x,y,Balancer);
                Balancer.name=player.name;
                with (Balancer) notice=1;
            }
            break;

        case PLAYER_CHANGETEAM:
            receiveCompleteMessage(global.serverSocket, 2);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            if(player.object != -1) {
                with(player.object) {
                    instance_destroy();
                }
                player.object = -1;
            }
            player.team = read_ubyte(global.serverSocket);
            clearPlayerDominations(player);
            break;

        case PLAYER_CHANGECLASS:
            receiveCompleteMessage(global.serverSocket, 2);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            if(player.object != -1) {
                with(player.object) {
                    instance_destroy();
                }
                player.object = -1;
            }
            player.class = read_ubyte(global.serverSocket);
            break;

        case PLAYER_CHANGENAME:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            player.name = receiveString(global.serverSocket, 1);
            if player=global.myself {
                global.playerName=player.name
            }
            break;

        case PLAYER_SPAWN:
            receiveCompleteMessage(global.serverSocket, 3);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            doEventSpawn(player, read_ubyte(global.serverSocket), read_ubyte(global.serverSocket));
            break;

        case CHAT_BUBBLE:
            var bubbleImage;
            receiveCompleteMessage(global.serverSocket, 2);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            setChatBubble(player, read_ubyte(global.serverSocket));
            break;

        case BUILD_SENTRY:
            receiveCompleteMessage(global.serverSocket, 6);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            buildSentry(player, read_ushort(global.serverSocket)/5, read_ushort(global.serverSocket)/5, read_byte(global.serverSocket));
            break;

        case DESTROY_SENTRY:
            receiveCompleteMessage(global.serverSocket, 4);
            playerID = read_ubyte(global.serverSocket);
            otherPlayerID = read_ubyte(global.serverSocket);
            assistantPlayerID = read_ubyte(global.serverSocket);
            causeOfDeath = read_ubyte(global.serverSocket);

            player = ds_list_find_value(global.players, playerID);
            if(otherPlayerID == 255) {
                doEventDestruction(player, noone, noone, causeOfDeath);
            } else {
                otherPlayer = ds_list_find_value(global.players, otherPlayerID);
                if (assistantPlayerID == 255) {
                    doEventDestruction(player, otherPlayer, noone, causeOfDeath);
                } else {
                    assistantPlayer = ds_list_find_value(global.players, assistantPlayerID);
                    doEventDestruction(player, otherPlayer, assistantPlayer, causeOfDeath);
                }
            }
            break;

        case GRAB_INTEL:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            doEventGrabIntel(player);
            break;

        case SCORE_INTEL:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            doEventScoreIntel(player);
            break;

        case DROP_INTEL:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            doEventDropIntel(player);
            break;

        case RETURN_INTEL:
            receiveCompleteMessage(global.serverSocket, 1);
            doEventReturnIntel(read_ubyte(global.serverSocket));
            break;

        case GENERATOR_DESTROY:
            receiveCompleteMessage(global.serverSocket, 1);
            team = read_ubyte(global.serverSocket);
            doEventGeneratorDestroy(team);
            break;

        case UBER_CHARGED:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            doEventUberReady(player);
            break;

        case UBER:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            doEventUber(player);
            break;

        case OMNOMNOMNOM:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            if(player.object != -1) {
                with(player.object) {
                    omnomnomnom=true;
                    if(hp < 200)
                    {
                        canEat = false;
                        alarm[6] = eatCooldown / global.delta_factor; //10 second cooldown
                    }
                    omnomnomnomindex=0;
                    omnomnomnomend=32;
                    xscale=image_xscale;
                }
            }
            break;

        case TOGGLE_ZOOM:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            if player.object != -1 {
                toggleZoom(player.object);
            }
            break;

        case PASSWORD_REQUEST:
            if(!usePreviousPwd)
                global.clientPassword = get_string("Enter Password:", "");
            writePrefixedString1(global.serverSocket, global.clientPassword);
            socket_send(global.serverSocket);
            break;

        case PASSWORD_WRONG:
            show_message("Incorrect Password.");
            instance_destroy();
            exit;

        case INCOMPATIBLE_PROTOCOL:
            show_message("Incompatible server protocol version.");
            instance_destroy();
            exit;

        case KICK:
            receiveCompleteMessage(global.serverSocket, 1);
            reason = read_ubyte(global.serverSocket);
            if reason == KICK_NAME kickReason = "Name Exploit";
            else if reason == KICK_BAD_PLUGIN_PACKET kickReason = "Invalid plugin packet ID";
            else if reason == KICK_MULTI_CLIENT kickReason = "There are too many connections from your IP";
            else kickReason = "";
            show_message("You have been kicked from the server. "+kickReason+".");
            instance_destroy();
            exit;

        case ARENA_WAIT_FOR_PLAYERS:
            doEventArenaWaitForPlayers();
            break;

        case ARENA_STARTROUND:
            doEventArenaStartRound();
            break;

        case ARENA_ENDROUND:
            with ArenaHUD clientArenaEndRound();
            break;

        case ARENA_RESTART:
            doEventArenaRestart();
            break;

        case UNLOCKCP:
            doEventUnlockCP();
            break;

        case MAP_END:
            global.nextMap = receiveString(global.serverSocket, 1);
            receiveCompleteMessage(global.serverSocket, 2);
            global.winners = read_ubyte(global.serverSocket);
            global.currentMapArea = read_ubyte(global.serverSocket);
            global.mapchanging = true;
            if !instance_exists(ScoreTableController) instance_create(0,0,ScoreTableController);
            instance_create(0,0,WinBanner);
            break;

        case CHANGE_MAP:
            roomchange=true;
            global.mapchanging = false;
            global.currentMap = receiveString(global.serverSocket, 1);
            global.currentMapMD5 = receiveString(global.serverSocket, 1);
            if(global.currentMapMD5 == "") { // if this is an internal map (signified by the lack of an md5)
                if(findInternalMapName(global.currentMap) != "")
                    room_goto_fix(CustomMapRoom);
                else
                {
                    show_message("Error:#Server went to invalid internal map: " + global.currentMap + "#Exiting.");
                    instance_destroy();
                    exit;
                }
            } else { // it's an external map
                if(string_pos("/", global.currentMap) != 0 or string_pos("\", global.currentMap) != 0)
                {
                    show_message("Server sent illegal map name: "+global.currentMap);
                    instance_destroy();
                    exit;
                }
                if(!file_exists("Maps/" + global.currentMap + ".png") or CustomMapGetMapMD5(global.currentMap) != global.currentMapMD5)
                {   // Reconnect to the server to download the map
                    var oldReturnRoom;
                    oldReturnRoom = returnRoom;
                    returnRoom = DownloadRoom;
                    // Normally, GG2 is restarted when we disconnect, if plugins are in use
                    // As we're only disconnecting to download a map, we won't restart
                    if (global.serverPluginsInUse)
                        noUnloadPlugins = true;
                    event_perform(ev_destroy,0);
                    ClientCreate();
                    // Normally, GG2 will prompt to load plugins when connecting to a server
                    // If they're already loaded, or the user skipped them, we won't prompt again
                    if (global.serverPluginsInUse or skippedPlugins)
                        noReloadPlugins = true;
                    returnRoom = oldReturnRoom;
                    usePreviousPwd = true;
                    exit;
                }
                room_goto_fix(CustomMapRoom);
            }

            for(i=0; i<ds_list_size(global.players); i+=1) {
                player = ds_list_find_value(global.players, i);
                if global.currentMapArea == 1 {
                    player.stats[KILLS] = 0;
                    player.stats[DEATHS] = 0;
                    player.stats[CAPS] = 0;
                    player.stats[ASSISTS] = 0;
                    player.stats[DESTRUCTION] = 0;
                    player.stats[STABS] = 0;
                    player.stats[HEALING] = 0;
                    player.stats[DEFENSES] = 0;
                    player.stats[INVULNS] = 0;
                    player.stats[BONUS] = 0;
                    player.stats[DOMINATIONS] = 0;
                    player.stats[REVENGE] = 0;
                    player.stats[POINTS] = 0;
                    player.roundStats[KILLS] = 0;
                    player.roundStats[DEATHS] = 0;
                    player.roundStats[CAPS] = 0;
                    player.roundStats[ASSISTS] = 0;
                    player.roundStats[DESTRUCTION] = 0;
                    player.roundStats[STABS] = 0;
                    player.roundStats[HEALING] = 0;
                    player.roundStats[DEFENSES] = 0;
                    player.roundStats[INVULNS] = 0;
                    player.roundStats[BONUS] = 0;
                    player.roundStats[DOMINATIONS] = 0;
                    player.roundStats[REVENGE] = 0;
                    player.roundStats[POINTS] = 0;
                    player.team = TEAM_SPECTATOR;
                }
            }
            break;

        case SERVER_FULL:
            show_message("The server is full.");
            instance_destroy();
            exit;

        case REWARD_CHALLENGE_CODE:
            var challengeData;
            receiveCompleteMessage(global.serverSocket, 16);
            challengeData = read_binary_string(global.serverSocket, socket_receivebuffer_size(global.serverSocket));
            challengeData += socket_remote_ip(global.serverSocket);

            write_ubyte(global.serverSocket, REWARD_CHALLENGE_RESPONSE);
            write_binary_string(global.serverSocket, hmac_md5_bin(global.rewardKey, challengeData));
            socket_send(global.serverSocket);
            break;

        case REWARD_UPDATE:
            receiveCompleteMessage(global.serverSocket, 1);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            var rewardString;
            rewardString = receiveString(global.serverSocket, 2);
            doEventUpdateRewards(player, rewardString);
            break;

        case MESSAGE_STRING:
            var message, notice;
            message = receiveString(global.serverSocket, 1);
            with NoticeO instance_destroy();
            notice = instance_create(0, 0, NoticeO);
            notice.notice = NOTICE_CUSTOM;
            notice.message = message;
            break;

        case SENTRY_POSITION:
            receiveCompleteMessage(global.serverSocket, 5);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            if(player.sentry)
            {
                player.sentry.x = read_ushort(global.serverSocket) / 5;
                player.sentry.y = read_ushort(global.serverSocket) / 5;
                player.sentry.xprevious = player.sentry.x;
                player.sentry.yprevious = player.sentry.y;
                player.sentry.vspeed = 0;
            }
            break;

        case WEAPON_FIRE:
            receiveCompleteMessage(global.serverSocket, 9);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));

            if(player.object)
            {
                with(player.object)
                {
                    x = read_ushort(global.serverSocket) / 5;
                    y = read_ushort(global.serverSocket) / 5;
                    hspeed = read_byte(global.serverSocket) / 8.5;
                    vspeed = read_byte(global.serverSocket) / 8.5;
                    xprevious = x;
                    yprevious = y;
                }

                doEventFireWeapon(player, read_ushort(global.serverSocket));
            }
            break;

        case PLUGIN_PACKET:
            var packetID, packetLen, buf, success;

            // fetch full packet
            receiveCompleteMessage(global.serverSocket, 2);
            packetLen = read_ushort(global.serverSocket);
            receiveCompleteMessage(global.serverSocket, packetLen);

            packetID = read_ubyte(global.serverSocket);

            // get packet data
            buf = buffer_create();
            write_buffer_part(buf, global.serverSocket, buffer_bytes_left(global.serverSocket));

            // try to enqueue
            // give "noone" value for client since received from server
            success = _PluginPacketPush(packetID, buf, noone);

            // if it returned false, packetID was invalid
            if (!success)
            {
                // clear up buffer
                buffer_destroy(buf);
                show_error("ERROR when reading plugin packet: no such plugin packet ID " + string(packetID), true);
            }
            break;

        case CLIENT_SETTINGS:
            receiveCompleteMessage(global.serverSocket, 2);
            player = ds_list_find_value(global.players, read_ubyte(global.serverSocket));
            player.queueJump = read_ubyte(global.serverSocket);
            break;

        default:
            promptRestartOrQuit("The Server sent unexpected data.");
            exit;
        }
    } else {
        break;
    }
} until(roomchange);
