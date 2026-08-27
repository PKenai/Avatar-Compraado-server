function onSay(cid, words, param, channel)
    doPlayerFeed(cid, 0)
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Você está com fome agora!")
    return TRUE
end
