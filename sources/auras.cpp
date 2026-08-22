#include "otpch.h"

#include "auras.h"

#include "tools.h"

bool Auras::reload()
{
	auras.clear();
	return loadFromXml();
}

bool Auras::loadFromXml()
{
	xmlDocPtr doc = xmlParseFile("data/XML/auras.xml");
	if(!doc)
	{
		std::cout << "[Warning - Auras::loadFromXml] Cannot load data/XML/auras.xml" << std::endl;
		return false;
	}

	xmlNodePtr rootNode = xmlDocGetRootElement(doc);

	if(xmlStrcmp(rootNode->name, (const xmlChar*)"auras"))
	{
		std::cout << "[Warning - Auras::loadFromXml] Malformed XML file." << std::endl;
		xmlFreeDoc(doc);
		return false;
	}

	for(xmlNodePtr node = rootNode->children; node; node = node->next)
	{
		if(xmlStrcmp(node->name, (const xmlChar*)"aura"))
			continue;

		int32_t id = 0;
		if(!readXMLInteger(node, "id", id) || id <= 0 || id > 255)
			continue;

		int32_t clientId = 0;
		if(!readXMLInteger(node, "clientid", clientId))
			continue;

		std::string name;
		if(!readXMLString(node, "name", name))
			continue;

		int32_t speed = 0;
		readXMLInteger(node, "speed", speed);

		bool premium = false;
		int32_t premiumVal = 0;
		readXMLInteger(node, "premium", premiumVal);
		premium = (premiumVal != 0);

		auras.emplace_back(
			static_cast<uint8_t>(id),
			static_cast<uint16_t>(clientId),
			name,
			speed,
			premium
		);
	}

	auras.shrink_to_fit();
	xmlFreeDoc(doc);
	return true;
}

Aura* Auras::getAuraByID(uint8_t id)
{
	for(auto& aura : auras)
	{
		if(aura.id == id)
			return &aura;
	}
	return NULL;
}

Aura* Auras::getAuraByName(const std::string& name)
{
	for(auto& aura : auras)
	{
		if(_stricmp(aura.name.c_str(), name.c_str()) == 0)
			return &aura;
	}
	return NULL;
}

Aura* Auras::getAuraByClientID(uint16_t clientId)
{
	for(auto& aura : auras)
	{
		if(aura.clientId == clientId)
			return &aura;
	}
	return NULL;
}
