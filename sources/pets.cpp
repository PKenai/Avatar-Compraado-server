#include "otpch.h"

#include "pets.h"

#include "monsters.h"
#include "tools.h"

bool Pets::reload()
{
	pets.clear();
	unloadMonsterTypes();
	return loadFromXml();
}

Pets::~Pets()
{
	unloadMonsterTypes();
}

void Pets::unloadMonsterTypes()
{
	for(std::map<uint8_t, MonsterType*>::iterator it = monsterTypes.begin(); it != monsterTypes.end(); ++it)
		delete it->second;

	monsterTypes.clear();
}

bool Pets::loadFromXml()
{
	xmlDocPtr doc = xmlParseFile("data/XML/pets.xml");
	if(!doc)
	{
		std::clog << "[Warning - Pets::loadFromXml] Cannot load data/XML/pets.xml" << std::endl;
		return false;
	}

	xmlNodePtr rootNode = xmlDocGetRootElement(doc);

	if(xmlStrcmp(rootNode->name, (const xmlChar*)"pets"))
	{
		std::clog << "[Warning - Pets::loadFromXml] Malformed XML file." << std::endl;
		xmlFreeDoc(doc);
		return false;
	}

	for(xmlNodePtr node = rootNode->children; node; node = node->next)
	{
		if(xmlStrcmp(node->name, (const xmlChar*)"pet"))
			continue;

		int32_t id = 0;
		if(!readXMLInteger(node, "id", id) || id <= 0 || id > 255)
			continue;

		int32_t clientId = 0;
		if(!readXMLInteger(node, "clientid", clientId) || clientId <= 0)
			continue;

		std::string name;
		if(!readXMLString(node, "name", name))
			continue;

		bool premium = false;
		int32_t premiumVal = 0;
		readXMLInteger(node, "premium", premiumVal);
		premium = (premiumVal != 0);

		pets.emplace_back(
			static_cast<uint8_t>(id),
			static_cast<uint16_t>(clientId),
			name,
			premium
		);
	}

	pets.shrink_to_fit();
	xmlFreeDoc(doc);
	return true;
}

Pet* Pets::getPetByID(uint8_t id)
{
	for(Pet& pet : pets)
	{
		if(pet.id == id)
			return &pet;
	}
	return NULL;
}

Pet* Pets::getPetByName(const std::string& name)
{
	for(Pet& pet : pets)
	{
		if(_stricmp(pet.name.c_str(), name.c_str()) == 0)
			return &pet;
	}
	return NULL;
}

Pet* Pets::getPetByClientID(uint16_t clientId)
{
	for(Pet& pet : pets)
	{
		if(pet.clientId == clientId)
			return &pet;
	}
	return NULL;
}

MonsterType* Pets::getMonsterType(uint8_t petId)
{
	std::map<uint8_t, MonsterType*>::iterator it = monsterTypes.find(petId);
	if(it != monsterTypes.end())
		return it->second;

	Pet* pet = getPetByID(petId);
	if(!pet)
		return NULL;

	// Creatura fantasma: existe no mapa para ser enviada aos clientes (todo mundo
	// ve), mas nao tem IA, nao anda sozinha, nao ataca, nao toma dano, nao pode
	// ser empurrada/atacada e nao bloqueia o tile (Creature::canWalkthrough trata
	// Monster::isPet()). O corpo e o deslocamento ficam por conta do Player dono.
	MonsterType* mType = new MonsterType();

	mType->name = pet->name;
	mType->nameDescription = pet->name;
	mType->race = RACE_NONE;

	mType->outfit.lookType = pet->clientId;
	mType->outfit.lookTypeEx = 0;
	mType->outfit.lookAddons = 0;
	mType->outfit.lookMount = 0;

	mType->health = 1000;
	mType->healthMax = 1000;
	mType->healthMin = 0;
	mType->baseSpeed = 200; // nunca anda (onThink de pet nao roda IA), mas evita divisao por zero
	mType->lookCorpse = 0;
	mType->corpseUnique = 0;
	mType->corpseAction = 0;

	mType->isSummonable = false;
	mType->isIllusionable = false;
	mType->isConvinceable = false;
	mType->isLureable = false;
	mType->isAttackable = false;
	mType->isHostile = false;
	mType->isWalkable = true;
	mType->pushable = false;
	mType->canPushItems = false;
	mType->canPushCreatures = false;
	mType->hideName = true;
	mType->hideHealth = true;
	mType->eliminable = false;
	mType->lootPercent = false;

	mType->experience = 0;
	mType->maxSummons = 0;
	mType->changeTargetSpeed = 0;
	mType->changeTargetChance = 0;
	mType->staticAttackChance = 0;
	mType->yellChance = 0;
	mType->yellSpeedTicks = 0;
	mType->runAwayHealth = 0;
	mType->lightLevel = 0;
	mType->lightColor = 0;

	// Imune a tudo: nada que escape das checagens de alvo consegue machucar o pet.
	mType->damageImmunities = 0xFFFFFFFF;
	mType->conditionImmunities = 0xFFFFFFFF;

	monsterTypes[petId] = mType;
	return mType;
}
