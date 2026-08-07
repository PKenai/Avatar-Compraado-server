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
#include "reward.h"
#include "player.h"
#include "tools.h"

Reward::Reward(uint16_t type):
	Container(type)
{
	// Slots dinamicos: comeca com 1 slot (items.xml containerSize=1) e
	// cresce conforme o servidor entrega itens (capacity = itens + 1).
	setCapacity(1);
}

void Reward::__addThing(Creature* actor, int32_t index, Thing* thing)
{
	Container::__addThing(actor, index, thing);
	updateCapacity();
}

void Reward::__internalAddThing(Thing* thing)
{
	Container::__internalAddThing(thing);
	updateCapacity();
}

void Reward::__internalAddThing(uint32_t index, Thing* thing)
{
	Container::__internalAddThing(index, thing);
	updateCapacity();
}

void Reward::__removeThing(Thing* thing, uint32_t count)
{
	Container::__removeThing(thing, count);
	updateCapacity();
}

void Reward::updateCapacity()
{
	// sempre 1 slot vazio: capacity = itens + 1, ate 5000 slots
	uint32_t newCapacity = size() + 1;
	if(newCapacity > 5000)
		newCapacity = 5000;

	setCapacity(newCapacity);
}


ReturnValue Reward::__queryAdd(int32_t index, const Thing* thing, uint32_t count,
	uint32_t flags, Creature* actor/* = NULL*/) const
{
	// Rewards da reward mailbox:
	// - Servidor (actor == NULL) e admins (access >= 3) podem COLOCAR itens.
	// - Players comuns nao podem adicionar NADA (so retirar/reorganizar).
	if(actor && actor->getPlayer())
	{
		Player* player = actor->getPlayer();
		if(player->getAccess() < 3)
		{
			const Item* item = thing ? thing->getItem() : NULL;
			// permite apenas reorganizar itens que JA estao dentro da caixa
			if(!item || item->getTopParent() != this)
				return RET_NOTPOSSIBLE;
		}
	}

	return Container::__queryAdd(index, thing, count, flags, actor);
}

ReturnValue Reward::__queryMaxCount(int32_t index, const Thing* thing, uint32_t count,
	uint32_t& maxQueryCount, uint32_t flags) const
{
	return Container::__queryMaxCount(index, thing, count, maxQueryCount, flags);
}

void Reward::postAddNotification(Creature* actor, Thing* thing, const Cylinder* oldParent,
	int32_t index, CylinderLink_t /*link = LINK_OWNER*/)
{
	if(getParent())
		getParent()->postAddNotification(actor, thing, oldParent, index, LINK_PARENT);
}

void Reward::postRemoveNotification(Creature* actor, Thing* thing, const Cylinder* newParent,
	int32_t index, bool isCompleteRemoval, CylinderLink_t /*link = LINK_OWNER*/)
{
	if(getParent())
		getParent()->postRemoveNotification(actor, thing, newParent, index, isCompleteRemoval, LINK_PARENT);
}
