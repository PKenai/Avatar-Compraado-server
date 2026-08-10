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

#ifndef __MOMOPOUCH__
#define __MOMOPOUCH__
#include "container.h"

// Momo Pouch (item 18435) - bolsa de loot com slots INFINITOS.
// - Capacidade DINAMICA: comeca com 1 slot e cresce conforme itens entram
//   (capacity = itens + 1, sempre 1 slot vazio), ate 5000 slots.
// - Diferente da Reward mailbox, o jogador pode adicionar/remover itens
//   normalmente (e a propria bolsa e o destino do loot automatico).
class MomoPouch : public Container
{
	public:
		MomoPouch(uint16_t type);
		virtual ~MomoPouch() {}

		virtual MomoPouch* getMomoPouch() {return this;}
		virtual const MomoPouch* getMomoPouch() const {return this;}

		virtual void __addThing(Creature* actor, int32_t index, Thing* thing);
		virtual void __internalAddThing(Thing* thing);
		virtual void __internalAddThing(uint32_t index, Thing* thing);
		virtual void __removeThing(Thing* thing, uint32_t count);

		// O pouch se comporta como mochila NORMAL: remove o FLAG_NOLIMIT antes
		// de consultar, entao a capacidade do char e respeitada em QUALQUER caminho
		// (o doAddContainerItem do loot passa FLAG_NOLIMIT, que no Player::__queryAdd
		// com childOwner pulava a checagem de cap).
		virtual ReturnValue __queryAdd(int32_t index, const Thing* thing, uint32_t count,
			uint32_t flags, Creature* actor = NULL) const;

	private:
		void updateCapacity();
};

#endif
