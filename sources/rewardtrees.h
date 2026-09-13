////////////////////////////////////////////////////////////////////////
// OpenTibia - an opensource roleplaying game
////////////////////////////////////////////////////////////////////////
// ARVORES DE RECOMPENSA (tronco brilhante)
//
// O proprio servidor registra, durante o carregamento do mapa
// (IOMap::loadMap), todas as arvores que podem virar um tronco de
// recompensa. Nao precisa mexer no .otbm nem rodar gerador nenhum: a
// lista sai do mapa que o servidor acabou de ler.
//
// QUAIS arvores participam vem do config.lua, na chave rewardTreeIds:
//
//     rewardTreeIds = {2700, 2708, 2701, 2703, 2704, 2705, 2707}
//
// Sem essa chave no config vale a lista padrao (a de baixo). O sorteio
// (1 em cada N vira tronco, qual recompensa, quando a arvore volta) fica
// no Lua, em data/lib/rewardTreesLib.lua, que pega as posicoes pela
// funcao getRewardTreeCandidates().
////////////////////////////////////////////////////////////////////////

#ifndef __REWARDTREES__
#define __REWARDTREES__

#include <vector>

struct RewardTreeCandidate
{
	RewardTreeCandidate(uint16_t x, uint16_t y, uint8_t z, uint16_t id): x(x), y(y), z(z), id(id) {}

	uint16_t x, y, id;
	uint8_t z;
};

// ids das arvores que participam do sorteio (preenchido no loadMap)
inline std::vector<uint16_t>& rewardTreeIds()
{
	static std::vector<uint16_t> ids;
	return ids;
}

// troca a lista pelos ids que vieram do config.lua. Lista vazia (chave
// ausente no config) mantem a lista padrao.
inline void setRewardTreeIds(const std::vector<int64_t>& ids)
{
	static const uint16_t defaults[] = {2700, 2708, 2701, 2703, 2704, 2705, 2707};

	std::vector<uint16_t>& list = rewardTreeIds();
	list.clear();

	if(ids.empty())
	{
		list.assign(defaults, defaults + (sizeof(defaults) / sizeof(defaults[0])));
		return;
	}

	for(size_t i = 0; i < ids.size(); ++i)
	{
		if(ids[i] > 0 && ids[i] <= 0xFFFF)
			list.push_back((uint16_t)ids[i]);
	}
}

// true se o id for uma das arvores cadastradas no config.lua
inline bool isRewardTreeId(uint16_t id)
{
	const std::vector<uint16_t>& ids = rewardTreeIds();
	for(size_t i = 0; i < ids.size(); ++i)
	{
		if(ids[i] == id)
			return true;
	}
	return false;
}

// posicoes das arvores encontradas no ultimo carregamento de mapa
inline std::vector<RewardTreeCandidate>& rewardTreeCandidates()
{
	static std::vector<RewardTreeCandidate> candidates;
	return candidates;
}

#endif
