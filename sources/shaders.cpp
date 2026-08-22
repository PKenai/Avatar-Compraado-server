#include "otpch.h"

#include "shaders.h"

#include "tools.h"

bool Shaders::reload()
{
	shaders.clear();
	return loadFromXml();
}

bool Shaders::loadFromXml()
{
	xmlDocPtr doc = xmlParseFile("data/XML/shaders.xml");
	if(!doc)
	{
		std::cout << "[Warning - Shaders::loadFromXml] Cannot load data/XML/shaders.xml" << std::endl;
		return false;
	}

	xmlNodePtr rootNode = xmlDocGetRootElement(doc);

	if(xmlStrcmp(rootNode->name, (const xmlChar*)"shaders"))
	{
		std::cout << "[Warning - Shaders::loadFromXml] Malformed XML file." << std::endl;
		xmlFreeDoc(doc);
		return false;
	}

	for(xmlNodePtr node = rootNode->children; node; node = node->next)
	{
		if(xmlStrcmp(node->name, (const xmlChar*)"shader"))
			continue;

		int32_t id = 0;
		if(!readXMLInteger(node, "id", id) || id <= 0 || id > 255)
			continue;

		std::string name;
		if(!readXMLString(node, "name", name))
			continue;

		bool premium = false;
		int32_t premiumVal = 0;
		readXMLInteger(node, "premium", premiumVal);
		premium = (premiumVal != 0);

		shaders.emplace_back(
			static_cast<uint8_t>(id),
			name,
			premium
		);
	}

	shaders.shrink_to_fit();
	xmlFreeDoc(doc);
	return true;
}

Shader* Shaders::getShaderByID(uint8_t id)
{
	for(auto& shader : shaders)
	{
		if(shader.id == id)
			return &shader;
	}
	return NULL;
}

Shader* Shaders::getShaderByName(const std::string& name)
{
	for(auto& shader : shaders)
	{
		if(_stricmp(shader.name.c_str(), name.c_str()) == 0)
			return &shader;
	}
	return NULL;
}
