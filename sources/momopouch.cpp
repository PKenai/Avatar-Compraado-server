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
#include "momopouch.h"
#include "player.h"
#include "cylinder.h"
#include "tools.h"

MomoPouch::MomoPouch(uint16_t type):
	Container(type)
{
	// Slots dinamicos: comeca com 1 slot e cresce conforme itens entram
	// (capacity = itens + 1, sempre 1 slot vazio).
	setCapacity(1);
}

void MomoPouch::__addThing(Creature* actor, int32_t index, Thing* thing)
{
	Container::__addThing(actor, index, thing);
	updateCapacity();
}

void MomoPouch::__internalAddThing(Thing* thing)
{
	Container::__internalAddThing(thing);
	updateCapacity();
}

void MomoPouch::__internalAddThing(uint32_t index, Thing* thing)
{
	Container::__internalAddThing(index, thing);
	updateCapacity();
}

void MomoPouch::__removeThing(Thing* thing, uint32_t count)
{
	Container::__removeThing(thing, count);
	updateCapacity();
}

ReturnValue MomoPouch::__queryAdd(int32_t index, const Thing* thing, uint32_t count,
	uint32_t flags, Creature* actor) const
{
	// Somente o SISTEMA pode colocar itens dentro do pouch (o auto-loot usa
	// FLAG_NOLIMIT). Qualquer adicao iniciada pelo jogador (arrastar item para
	// dentro, usar item sobre o pouch, etc.) e bloqueada: o player apenas
	// RETIRA itens de dentro do pouch.
	if(!hasBitSet(FLAG_NOLIMIT, flags))
		return RET_NOTPOSSIBLE;

	// Adicoes do sistema continuam respeitando a capacidade do char (mochila
	// normal): remove o FLAG_NOLIMIT antes de consultar, entao o Container::
	// __queryAdd delega pro Player (top parent), que checa a capacidade.
	return Container::__queryAdd(index, thing, count, flags & ~FLAG_NOLIMIT, actor);
}

void MomoPouch::updateCapacity()
{
	// sempre 1 slot vazio: capacity = itens + 1
	// limite de 5000: o protocolo agora envia a capacity como U16 (2 bytes),
	// entao o client suporta containers com ate 65535 slots.
	uint32_t newCapacity = size() + 1;
	if(newCapacity > 5000)
		newCapacity = 5000;

	setCapacity(newCapacity);
}
