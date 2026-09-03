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
#include "trashholder.h"

#include "game.h"
#include "spells.h"
#include "const.h"
#include "player.h"

extern Game g_game;

void TrashHolder::__addThing(Creature* actor, int32_t, Thing* thing)
{
	if(Item* item = thing->getItem())
	{
		if(item == this || !item->isMovable())
			return;

		if(g_game.isSwimmingPool(this, getTile(), true))
		{
			if(item->getID() == ITEM_WATERBALL_SPLASH)
				return;

			if(item->getID() == ITEM_WATERBALL)
			{
				g_game.transformItem(item, ITEM_WATERBALL_SPLASH);
				return;
			}
		}

		g_game.internalRemoveItem(actor, item);
		if(effect != MAGIC_EFFECT_NONE)
			g_game.addMagicEffect(getPosition(), effect);
	}
	else if(g_game.isSwimmingPool(this, getTile(), false) && thing->getCreature())
	{
		Player* player = thing->getCreature()->getPlayer();
		if(player)
		{
			// Apply vocation-based swimming outfit
			static Outfit_t swimmingOutfits[9] = {
				Outfit_t(267),   // index 0 (unused)
				Outfit_t(1345),  // 1 = Fire
				Outfit_t(1344),  // 2 = Water
				Outfit_t(1347),  // 3 = Air
				Outfit_t(1346),  // 4 = Earth
				Outfit_t(1345),  // 5 = Fire (promoted)
				Outfit_t(1344),  // 6 = Water (promoted)
				Outfit_t(1347),  // 7 = Air (promoted)
				Outfit_t(1346),  // 8 = Earth (promoted)
			};
			int32_t vocId = player->getVocationId();
			if(vocId < 1 || vocId > 8) vocId = 0;
			Spell::CreateIllusion(player, swimmingOutfits[vocId], -1);
		}
	}
}