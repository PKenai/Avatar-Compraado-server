#include "otpch.h"
#include "buff.h"

#include "game.h"

extern Game g_game;

bool Buff::executeBuff(Creature* creature, int32_t interval)
{
	if(!creature)
		return false;

	if(ticks == -1)
		return true;

	ticks = std::max<int32_t>(0, ticks - interval);
	return getEndTime() >= OTSYS_TIME();
}

void Buff::startBuff(Creature* creature)
{
}

void Buff::endBuff(Creature* creature)
{
}

const BuffType& Buff::getType() const
{
	return g_game.getBuffs()[getId()];
}
