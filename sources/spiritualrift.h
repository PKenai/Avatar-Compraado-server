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

#ifndef __SPIRITUALRIFT__
#define __SPIRITUALRIFT__

#include "otsystem.h"

#include "position.h"
#include "monster.h"

class Spawn;
class Player;
struct spawnBlock_t;

// Spiritual Rift system.
// The rift TAKES the creature's respawn: whenever a creature is about to
// respawn and there are fewer than SPIRITUAL_RIFT_MAX_ACTIVE rifts open, the
// rift opens at that creature's square instead of the creature spawning (the
// creature does not respawn while the rift holds the spot). The rift is a
// step-in: when a player walks over it, waves of spiritual creatures of the
// replaced type are summoned around it (3 -> 6 -> 12, one wave every 10
// seconds). If nobody steps on the rift within 5 minutes it closes and the
// creature that was supposed to spawn appears instead. Every creature born
// from a rift is spiritual (see Monster::setSpiritual).

#define SPIRITUAL_RIFT_MAX_ACTIVE 5        // maximum rifts open at the same time
#define SPIRITUAL_RIFT_DURATION 300000     // how long an untouched rift stays open (5 minutes, in ms)
#define SPIRITUAL_RIFT_WAVE_INTERVAL 10000 // delay between waves (10 seconds, in ms)
#define SPIRITUAL_RIFT_PULSE_INTERVAL 1000 // how often the pulsing effect is re-sent (effect 183 lasts ~1 second, so re-send every 1s)
#define SPIRITUAL_RIFT_PULSE_EFFECT 183    // effect id shown while the rift is open
#define SPIRITUAL_RIFT_SPAWN_EFFECT 38     // effect id released when a monster is summoned
#define SPIRITUAL_RIFT_BLOCK_COOLDOWN 1800000 // min time before the same spawn square can host a rift again (30 min, in ms)
#define SPIRITUAL_RIFT_REFILL_RETRY 15000   // how often the pool retries to refill when it could not fill right away (15 s, in ms)

class SpiritualRift
{
	public:
		SpiritualRift(Spawn* spawn, uint32_t spawnId, MonsterType* mType, const Position& pos, Direction dir);
		virtual ~SpiritualRift();

		Position getPosition() const {return pos;}
		MonsterType* getMonsterType() const {return mType;}
		const std::string& getCreatureName() const {return mType->name;}
		bool isTriggered() const {return triggered;}

		void open();    // starts the rift (pulse effect + expiry timer)
		void trigger(); // a player stepped on the rift: start the waves
		void close(bool forceRespawn); // closes the rift, releases the spawn hold
		void releaseSpawnHold(bool forceRespawn); // releases the spawn square back to the Spawn

	private:
		void pulse();
		void spawnWave(uint32_t wave);
		std::vector<Position> getSpawnCandidates();

		Spawn* spawn;
		uint32_t spawnId;
		MonsterType* mType;
		Position pos;
		Direction dir;

		uint32_t pulseEvent, expiryEvent, waveEvent;
		bool triggered, closing;
};

class SpiritualRifts
{
	public:
		virtual ~SpiritualRifts();
		static SpiritualRifts* getInstance()
		{
			static SpiritualRifts instance;
			return &instance;
		}

		bool tryOpenRift(Spawn* spawn, uint32_t spawnId, spawnBlock_t& sb); // called when a creature is about to respawn
		void openStartupRifts(); // opens the first rifts before the creatures are placed (no creature where there is a rift)
		void refillPool(); // opens rifts until the pool is full again (called when one closes)
		bool triggerAt(const Position& pos); // a player stepped on a rift tile
		SpiritualRift* getRiftAt(const Position& pos);

		Position getRiftTeleportPosition(Player* player); // free tile next to the nearest rift (!tprift)
		bool hasActiveRift() const {return !riftList.empty();}
		uint32_t getActiveCount() const {return (uint32_t)riftList.size();}

		void shutdown(); // closes every open rift (server shutdown / map reload)
		void removeRift(SpiritualRift* rift); // removes and deletes an expired/closed rift

	private:
		SpiritualRifts();

		void openRiftAt(Spawn* spawn, uint32_t spawnId, spawnBlock_t& sb); // holds the block and opens the rift

		typedef std::list<SpiritualRift*> RiftList;
		RiftList riftList;
		uint32_t refillEvent;
};
#endif
