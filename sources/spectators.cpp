////////////////////////////////////////////////////////////////////////
// OpenTibia - an opensource roleplaying game
////////////////////////////////////////////////////////////////////////
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
////////////////////////////////////////////////////////////////////////
#include "otpch.h"
#include "spectators.h"

#include "player.h"
#include "chat.h"

#include "database.h"
#include "tools.h"

extern Chat g_chat;

bool Spectators::check(const std::string& _password)
{
	if(password.empty())
		return true;

	std::string t = _password;
	return trimString(t) == password;
}

void Spectators::handle(ProtocolGame* client, const std::string& text, uint16_t channelId)
{
	if(!owner)
		return;

	SpectatorList::iterator sit = spectators.find(client);
	if(sit == spectators.end())
		return;

	if(!auth || sit->second.second)
	{
		StringVec::const_iterator mit = std::find(mutes.begin(), mutes.end(), asLowerCaseString(sit->second.first));
		if(mit == mutes.end())
		{
			PrivateChatChannel* channel = g_chat.getPrivateChannel(owner->getPlayer());
			if(channel && channel->getId() == channelId)
				channel->talk(sit->second.first, MSG_CHANNEL_HIGHLIGHT, text);
		}
		else
			client->sendCreatureSay(owner->getPlayer(), MSG_PRIVATE, "You are muted.", NULL, 0);
	}
	else
		client->sendCreatureSay(owner->getPlayer(), MSG_PRIVATE, "This chat is protected, you have to authenticate first.", NULL, 0);
}

void Spectators::chat(uint16_t channelId)
{
	if(!owner)
		return;

	PrivateChatChannel* tmp = g_chat.getPrivateChannel(owner->getPlayer());
	if(!tmp || tmp->getId() != channelId)
		return;

	for(SpectatorList::iterator it = spectators.begin(); it != spectators.end(); ++it)
	{
		it->first->sendClosePrivate(channelId);
		it->first->sendCreatureSay(owner->getPlayer(), MSG_PRIVATE, "Chat has been disabled.", NULL, 0);
	}
}

void Spectators::kick(StringVec list)
{
	for(StringVec::const_iterator it = list.begin(); it != list.end(); ++it)
	{
		for(SpectatorList::iterator sit = spectators.begin(); sit != spectators.end(); ++sit)
		{
			if(asLowerCaseString(sit->second.first) == *it)
				sit->first->disconnect();
		}
	}
}

void Spectators::ban(StringVec _bans)
{
	StringVec::const_iterator it;
	for(DataList::iterator bit = bans.begin(); bit != bans.end(); )
	{
		it = std::find(_bans.begin(), _bans.end(), bit->first);
		if(it == _bans.end())
			bans.erase(bit++);
		else
			++bit;
	}

	for(it = _bans.begin(); it != _bans.end(); ++it)
	{
		for(SpectatorList::const_iterator sit = spectators.begin(); sit != spectators.end(); ++sit)
		{
			if(asLowerCaseString(sit->second.first) != *it)
				continue;

			bans[*it] = sit->first->getIP();
			sit->first->disconnect();
		}
	}
}

void Spectators::addSpectator(ProtocolGame* client)
{
	if(++id == 65536)
		id = 1;

	std::stringstream s;
	s << "Spectator [" << id << "]";

	spectators[client] = std::make_pair(s.str(), false);
	sendTextMessage(MSG_EVENT_ORANGE, s.str() + " joins your stream.");
}

void Spectators::removeSpectator(ProtocolGame* client)
{
	SpectatorList::iterator it = spectators.find(client);
	if(it == spectators.end())
		return;

	StringVec::iterator mit = std::find(mutes.begin(), mutes.end(), it->second.first);
	if(mit != mutes.end())
		mutes.erase(mit);

	sendTextMessage(MSG_EVENT_ORANGE, it->second.first + " leaves your stream.");
	spectators.erase(it);
}

void Spectators::sendChannelMessage(std::string author, std::string text, MessageClasses type, uint16_t channel)
{
	if(!owner)
		return;

	owner->sendChannelMessage(author, text, type, channel);
	PrivateChatChannel* tmp = g_chat.getPrivateChannel(owner->getPlayer());
	if(!tmp || tmp->getId() != channel)
		return;

	for(SpectatorList::iterator it = spectators.begin(); it != spectators.end(); ++it)
		it->first->sendChannelMessage(author, text, type, channel);
}

void Spectators::sendCreatureChannelSay(const Creature* creature, MessageClasses type, const std::string& text, uint16_t channelId, uint32_t statementId)
{
	if(!owner)
		return;

	owner->sendCreatureChannelSay(creature, type, text, channelId, statementId);
	PrivateChatChannel* tmp = g_chat.getPrivateChannel(owner->getPlayer());
	if(!tmp || tmp->getId() != channelId)
		return;

	for(SpectatorList::iterator it = spectators.begin(); it != spectators.end(); ++it)
		it->first->sendCreatureChannelSay(creature, type, text, channelId, statementId);
}

void Spectators::sendClosePrivate(uint16_t channelId)
{
	if(!owner)
		return;

	owner->sendClosePrivate(channelId);
	PrivateChatChannel* tmp = g_chat.getPrivateChannel(owner->getPlayer());
	if(!tmp || tmp->getId() != channelId)
		return;

	for(SpectatorList::iterator it = spectators.begin(); it != spectators.end(); ++it)
	{
		it->first->sendClosePrivate(channelId);
		it->first->sendCreatureSay(owner->getPlayer(), MSG_PRIVATE, "Chat has been disabled.", NULL, 0);
	}
}

void Spectators::sendCreatePrivateChannel(uint16_t channelId, const std::string& channelName)
{
	if(!owner)
		return;

	owner->sendCreatePrivateChannel(channelId, channelName);
	PrivateChatChannel* tmp = g_chat.getPrivateChannel(owner->getPlayer());
	if(!tmp || tmp->getId() != channelId)
		return;

	for(SpectatorList::iterator it = spectators.begin(); it != spectators.end(); ++it)
	{
		it->first->sendCreatePrivateChannel(channelId, channelName);
		it->first->sendCreatureSay(owner->getPlayer(), MSG_PRIVATE, "Chat has been enabled.", NULL, 0);
	}
}
