#ifndef FS_PETS_H
#define FS_PETS_H

#include <cstdint>
#include <map>
#include <string>
#include <vector>

class MonsterType;

struct Pet
{
	Pet(uint8_t id, uint16_t clientId, std::string name, bool premium) :
		name(std::move(name)), clientId(clientId), id(id), premium(premium) {}

	std::string name;
	uint16_t clientId;
	uint8_t id;
	bool premium;
};

class Pets
{
	public:
		Pets() {}
		~Pets();

		bool reload();
		bool loadFromXml();
		Pet* getPetByID(uint8_t id);
		Pet* getPetByName(const std::string& name);
		Pet* getPetByClientID(uint16_t clientId);

		const std::vector<Pet>& getPets() const {
			return pets;
		}

		// Cada pet tem um MonsterType "fantasma" proprio, montado sob demanda a
		// partir do clientid (looktype) do pets.xml. O tipo fica vivo ate o
		// processo terminar, igual aos tipos carregados pelo g_monsters.
		MonsterType* getMonsterType(uint8_t petId);

	private:
		void unloadMonsterTypes();

		std::vector<Pet> pets;
		std::map<uint8_t, MonsterType*> monsterTypes;
};

#endif
