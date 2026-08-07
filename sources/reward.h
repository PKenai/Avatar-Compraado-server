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

#ifndef __REWARD__
#define __REWARD__
#include "container.h"

// Reward Mailbox (item 18358) - caixa de recompensas do sistema.
// - Apenas o SERVIDOR (actor == NULL) e ADMINISTRADORES (access >= 3) podem
//   COLOCAR itens dentro. Players comuns nao podem adicionar nada.
// - O player pode RETIRAR itens (e reorganizar os que ja estao la dentro).
// - Slots DINAMICOS: a caixa comeca com 1 slot e cresce conforme itens sao
//   adicionados (capacity = itens + 1, sempre 1 slot vazio), ate 5000 slots.
class Reward : public Container
{
	public:
		Reward(uint16_t type);
		virtual ~Reward() {}

		virtual Reward* getReward() {return this;}
		virtual const Reward* getReward() const {return this;}

		virtual void __addThing(Creature* actor, int32_t index, Thing* thing);
		virtual void __internalAddThing(Thing* thing);
		virtual void __internalAddThing(uint32_t index, Thing* thing);
		virtual void __removeThing(Thing* thing, uint32_t count);

		//cylinder implementations
		virtual Cylinder* getParent() {return Item::getParent();}
		virtual const Cylinder* getParent() const {return Item::getParent();}
		virtual bool isRemoved() const {return Item::isRemoved();}
		virtual Position getPosition() const {return Item::getPosition();}
		virtual Tile* getTile() {return Item::getTile();}
		virtual const Tile* getTile() const {return Item::getTile();}
		virtual Item* getItem() {return this;}
		virtual const Item* getItem() const {return this;}
		virtual Creature* getCreature() {return NULL;}
		virtual const Creature* getCreature() const {return NULL;}

		virtual ReturnValue __queryAdd(int32_t index, const Thing* thing, uint32_t count,
			uint32_t flags, Creature* actor = NULL) const;

		virtual ReturnValue __queryMaxCount(int32_t index, const Thing* thing, uint32_t count,
			uint32_t& maxQueryCount, uint32_t flags) const;

		virtual void postAddNotification(Creature* actor, Thing* thing, const Cylinder* oldParent,
			int32_t index, CylinderLink_t link = LINK_OWNER);
		virtual void postRemoveNotification(Creature* actor, Thing* thing, const Cylinder* newParent,
			int32_t index, bool isCompleteRemoval, CylinderLink_t link = LINK_OWNER);

		//overrides
		virtual bool canRemove() const {return false;}

	private:
		void updateCapacity();
};
#endif
