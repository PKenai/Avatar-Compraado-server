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

#include "spiritualrift.h"

#include "spawn.h"
#include "game.h"
#include "tools.h"
#include "tile.h"
#include "player.h"

#if defined(_WIN32) || defined(WINDOWS)
#include <windows.h>

static void setConsoleColor(WORD color)
{
	HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
	if(h != INVALID_HANDLE_VALUE && h != NULL)
		SetConsoleTextAttribute(h, color);
}

static void setConsoleBlue()
{
	setConsoleColor(FOREGROUND_BLUE | FOREGROUND_INTENSITY);
}

static void setConsoleDefault()
{
	setConsoleColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
}
#else
static void setConsoleBlue() {}
static void setConsoleDefault() {}
#endif

extern Game g_game;

SpiritualRift::SpiritualRift(Spawn* _spawn, uint32_t _spawnId, MonsterType* _mType,
	const Position& _pos, Direction _dir)
{
	spawn = _spawn;
	spawnId = _spawnId;
	mType = _mType;
	pos = _pos;
	dir = _dir;
	pulseEvent = 0;
	expiryEvent = 0;
	waveEvent = 0;
	triggered = false;
	closing = false;
}

SpiritualRift::~SpiritualRift()
{
	Scheduler::getInstance().stopEvent(pulseEvent);
	Scheduler::getInstance().stopEvent(expiryEvent);
	Scheduler::getInstance().stopEvent(waveEvent);
}

void SpiritualRift::open()
{
	// short blue console line: [RIFT] "Weeper" opened (225/593/8)
	setConsoleBlue();
	std::clog << "[RIFT] \"" << mType->name << "\" opened ("
		<< pos.x << "/" << pos.y << "/" << pos.z << ")" << std::endl;
	setConsoleDefault();

	// immediate pulse so the rift is visible right away
	g_game.addMagicEffect(pos, SPIRITUAL_RIFT_PULSE_EFFECT);
	pulseEvent = Scheduler::getInstance().addEvent(createSchedulerTask(
		SPIRITUAL_RIFT_PULSE_INTERVAL, boost::bind(&SpiritualRift::pulse, this)));

	// if nobody steps on it in time, the creature that was supposed to spawn appears instead
	expiryEvent = Scheduler::getInstance().addEvent(createSchedulerTask(
		SPIRITUAL_RIFT_DURATION, boost::bind(&SpiritualRift::close, this, true)));
}

void SpiritualRift::pulse()
{
	if(closing)
		return;

	g_game.addMagicEffect(pos, SPIRITUAL_RIFT_PULSE_EFFECT);
	pulseEvent = Scheduler::getInstance().addEvent(createSchedulerTask(
		SPIRITUAL_RIFT_PULSE_INTERVAL, boost::bind(&SpiritualRift::pulse, this)));
}

void SpiritualRift::trigger()
{
	if(triggered || closing)
		return;

	triggered = true;
	// the pulsing indicator stops as soon as someone steps on the rift
	Scheduler::getInstance().stopEvent(pulseEvent);
	pulseEvent = 0;
	setConsoleBlue();
	std::clog << "[RIFT] \"" << mType->name << "\" activated ("
		<< pos.x << "/" << pos.y << "/" << pos.z << ")" << std::endl;
	setConsoleDefault();
	spawnWave(0);
}

void SpiritualRift::spawnWave(uint32_t wave)
{
	if(closing)
		return;

	uint32_t count = 3;
	if(wave == 1)
		count = 6;
	else if(wave == 2)
		count = 12;

	std::vector<Position> candidates = getSpawnCandidates();
	for(uint32_t i = 0; i < count; ++i)
	{
		Monster* monster = Monster::createMonster(mType);
		if(!monster)
			continue;

		monster->setSpiritual(true);
		bool placed = false;
		for(std::vector<Position>::iterator it = candidates.begin(); it != candidates.end(); ++it)
		{
			if(g_game.placeCreature(monster, *it, false, false))
			{
				g_game.addMagicEffect(*it, SPIRITUAL_RIFT_SPAWN_EFFECT);
				placed = true;
				break;
			}
		}

		if(!placed)
			delete monster;
	}

	if(wave < 2)
		waveEvent = Scheduler::getInstance().addEvent(createSchedulerTask(
			SPIRITUAL_RIFT_WAVE_INTERVAL, boost::bind(&SpiritualRift::spawnWave, this, wave + 1)));
	else
		close(false);
}

std::vector<Position> SpiritualRift::getSpawnCandidates()
{
	// the rift square itself plus the surrounding tiles (radius 1..2), shuffled
	std::vector<Position> candidates;
	candidates.push_back(pos);
	for(int32_t dx = -2; dx <= 2; ++dx)
	{
		for(int32_t dy = -2; dy <= 2; ++dy)
		{
			if(dx == 0 && dy == 0)
				continue;

			candidates.push_back(Position(pos.x + dx, pos.y + dy, pos.z));
		}
	}

	std::random_shuffle(candidates.begin(), candidates.end());
	return candidates;
}

void SpiritualRift::releaseSpawnHold(bool forceRespawn)
{
	if(!spawn)
		return;

	spawn->releaseSpawn(spawnId, forceRespawn);
	spawn = NULL;
}

void SpiritualRift::close(bool forceRespawn)
{
	if(closing)
		return;

	closing = true;
	Scheduler::getInstance().stopEvent(pulseEvent);
	Scheduler::getInstance().stopEvent(expiryEvent);
	Scheduler::getInstance().stopEvent(waveEvent);

	releaseSpawnHold(forceRespawn);
	SpiritualRifts::getInstance()->removeRift(this);

	// keep the pool full: a new rift opens right away on ANOTHER square, so a
	// stepped-on rift never stays in the same place (each rift is stepped once)
	SpiritualRifts::getInstance()->refillPool();
}

SpiritualRifts::SpiritualRifts()
{
	refillEvent = 0;
}

SpiritualRifts::~SpiritualRifts()
{
}

bool SpiritualRifts::tryOpenRift(Spawn* spawn, uint32_t spawnId, spawnBlock_t& sb)
{
	if(getActiveCount() >= SPIRITUAL_RIFT_MAX_ACTIVE)
		return false;

	// this square recently hosted a rift: it must go to another corner
	if(sb.lastRift && OTSYS_TIME() < sb.lastRift + SPIRITUAL_RIFT_BLOCK_COOLDOWN)
		return false;

	openRiftAt(spawn, spawnId, sb);
	return true;
}

void SpiritualRifts::openStartupRifts()
{
	// the very first rifts also take the place of their creatures: they are
	// picked before the monsters are placed, so those creatures never spawn
	// (if there is a rift, there is no creature)
	refillPool();
}

void SpiritualRifts::refillPool()
{
	refillEvent = 0;
	while(getActiveCount() < SPIRITUAL_RIFT_MAX_ACTIVE)
	{
		Spawn* spawn = NULL;
		uint32_t spawnId = 0;
		spawnBlock_t* block = NULL;
		if(!Spawns::getInstance()->getRiftBlock(spawn, spawnId, block))
			break;

		openRiftAt(spawn, spawnId, *block);
	}

	// the pool must ALWAYS have 5 rifts: if it could not be filled right now
	// (e.g. the only alive creatures are visible to players, so none could be
	// consumed), retry shortly instead of leaving the pool short
	if(getActiveCount() < SPIRITUAL_RIFT_MAX_ACTIVE && refillEvent == 0)
		refillEvent = Scheduler::getInstance().addEvent(createSchedulerTask(
			SPIRITUAL_RIFT_REFILL_RETRY, boost::bind(&SpiritualRifts::refillPool, this)));
}

void SpiritualRifts::openRiftAt(Spawn* spawn, uint32_t spawnId, spawnBlock_t& sb)
{
	// the rift takes the creature's place: if a creature is still alive on this
	// square it is consumed (removed) - if there is a rift, there is no creature
	spawn->consumeCreature(spawnId);

	// the rift takes the creature's respawn: the creature does not spawn
	sb.riftHeld = true;
	sb.lastSpawn = OTSYS_TIME();
	sb.lastRift = OTSYS_TIME();
	SpiritualRift* rift = new SpiritualRift(spawn, spawnId, sb.mType, sb.pos, sb.direction);
	riftList.push_back(rift);
	rift->open();
}

bool SpiritualRifts::triggerAt(const Position& pos)
{
	SpiritualRift* rift = getRiftAt(pos);
	if(!rift || rift->isTriggered())
		return false;

	rift->trigger();
	return true;
}

SpiritualRift* SpiritualRifts::getRiftAt(const Position& pos)
{
	for(RiftList::iterator it = riftList.begin(); it != riftList.end(); ++it)
	{
		if((*it)->getPosition() == pos)
			return *it;
	}

	return NULL;
}

Position SpiritualRifts::getRiftTeleportPosition(Player* player)
{
	// pick the closest rift that can still be triggered. Rifts that were already
	// stepped on are still summoning their waves (they stay in the list for a
	// few seconds before closing) - skipping them makes !tprift always send the
	// player to a DIFFERENT rift instead of back to the one just activated.
	SpiritualRift* bestRift = NULL;
	int32_t bestDistance = 0;
	for(RiftList::iterator it = riftList.begin(); it != riftList.end(); ++it)
	{
		SpiritualRift* rift = *it;
		if(rift->isTriggered())
			continue;

		int32_t distance = std::max(std::abs(rift->getPosition().x - player->getPosition().x),
			std::abs(rift->getPosition().y - player->getPosition().y))
			+ std::abs(rift->getPosition().z - player->getPosition().z);
		if(!bestRift || distance < bestDistance)
		{
			bestRift = rift;
			bestDistance = distance;
		}
	}

	if(!bestRift)
		return Position(0, 0, 0);

	const Position& riftPos = bestRift->getPosition();
	// ring around the rift (radius 1..2), shuffled; never the rift square itself
	// (landing on the rift would trigger it instantly on arrival)
	std::vector<Position> candidates;
	for(int32_t dx = -2; dx <= 2; ++dx)
	{
		for(int32_t dy = -2; dy <= 2; ++dy)
		{
			if(dx == 0 && dy == 0)
				continue;

			candidates.push_back(Position(riftPos.x + dx, riftPos.y + dy, riftPos.z));
		}
	}
	std::random_shuffle(candidates.begin(), candidates.end());

	for(std::vector<Position>::iterator it = candidates.begin(); it != candidates.end(); ++it)
	{
		Tile* tile = g_game.getTile(*it);
		if(!tile || !tile->ground)
			continue;

		ReturnValue ret = tile->__queryAdd(0, player, 1, FLAG_IGNOREBLOCKITEM);
		if(ret == RET_NOTENOUGHROOM || (ret == RET_NOTPOSSIBLE && !player->hasCustomFlag(
			PlayerCustomFlag_CanMoveAnywhere)) || ret == RET_PLAYERISNOTINVITED)
			continue;

		return *it;
	}

	// no free tile around the rift
	return Position(0, 0, 0);
}

void SpiritualRifts::removeRift(SpiritualRift* rift)
{
	riftList.remove(rift);
	delete rift;
}

void SpiritualRifts::shutdown()
{
	Scheduler::getInstance().stopEvent(refillEvent);
	refillEvent = 0;
	while(!riftList.empty())
	{
		SpiritualRift* rift = riftList.front();
		riftList.pop_front();
		rift->releaseSpawnHold(false);
		delete rift;
	}
}
