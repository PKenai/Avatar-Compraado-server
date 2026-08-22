#include "otpch.h"

#include "wings.h"

#include "tools.h"

bool Wings::reload()
{
	wings.clear();
	return loadFromXml();
}

bool Wings::loadFromXml()
{
	xmlDocPtr doc = xmlParseFile("data/XML/wings.xml");
	if(!doc)
	{
		std::cout << "[Warning - Wings::loadFromXml] Cannot load data/XML/wings.xml" << std::endl;
		return false;
	}

	xmlNodePtr rootNode = xmlDocGetRootElement(doc);

	if(xmlStrcmp(rootNode->name, (const xmlChar*)"wings"))
	{
		std::cout << "[Warning - Wings::loadFromXml] Malformed XML file." << std::endl;
		xmlFreeDoc(doc);
		return false;
	}

	for(xmlNodePtr node = rootNode->children; node; node = node->next)
	{
		if(xmlStrcmp(node->name, (const xmlChar*)"wing"))
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

		wings.emplace_back(
			static_cast<uint8_t>(id),
			static_cast<uint16_t>(clientId),
			name,
			speed,
			premium
		);
	}

	wings.shrink_to_fit();
	xmlFreeDoc(doc);
	return true;
}

Wing* Wings::getWingByID(uint8_t id)
{
	for(auto& wing : wings)
	{
		if(wing.id == id)
			return &wing;
	}
	return NULL;
}

Wing* Wings::getWingByName(const std::string& name)
{
	for(auto& wing : wings)
	{
		if(_stricmp(wing.name.c_str(), name.c_str()) == 0)
			return &wing;
	}
	return NULL;
}

Wing* Wings::getWingByClientID(uint16_t clientId)
{
	for(auto& wing : wings)
	{
		if(wing.clientId == clientId)
			return &wing;
	}
	return NULL;
}
