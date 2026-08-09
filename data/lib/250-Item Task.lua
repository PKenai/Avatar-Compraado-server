-- goldReq é qnt precisa pagar junto dos itens 
-- itensReward  se tiver false não dá recompensa caso contrario dá os itens listados 
-- givestorage é o storage q dá ao player qnd completar
-- storage é o que precisa pra começar essa missao

-- AMBOS SÃO SÓ DE EXEMPLO, PUS NUMEROS RANDOM
-- [] = nome da missao, precisa falar pro npc pra começar, ele lista com esse nome tambem nas disponiveis
-- storage usado pra registrar que ja terminou a task é "storageIdItemTask", exemplo "1ItemTask", só não repita nenhum que ta ok. Se quiser que exista 2 missões na qual so dê pra fazer 1, use o mesmo storage id

itemTaskInfo =
{
["war bear tamer"] = {storageId = 0, level = 1, itens = {{5896, 15}, {5902, 10}}, goldReq = 0, itensReward = {{5907, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["black sheep tamer"] = {storageId = 0, level = 1, itens = {{12638, 10}}, goldReq = 0, itensReward = {{17953, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["rapid boar tamer"] = {storageId = 0, level = 1, itens = {{5930, 70}}, goldReq = 0, itensReward = {{17949, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["titanica tamer"] = {storageId = 0, level = 1, itens = {{10550, 60}, {2487, 5}}, goldReq = 0, itensReward = {{17946, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["crystal wolf tamer"] = {storageId = 0, level = 1, itens = {{2171, 3}, {5879, 40}, {7290, 50}}, goldReq = 0, itensReward = {{17942, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["donkey tamer"] = {storageId = 0, level = 1, itens = {{12422, 30}}, goldReq = 0, itensReward = {{17938, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["dragonling tamer"] = {storageId = 0, level = 1, itens = {{2146, 100}, {2145, 80}, {12855, 5}}, goldReq = 0, itensReward = {{17941, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["draptor tamer"] = {storageId = 0, level = 1, itens = {{2146, 80}, {2145, 60}, {12855, 5}}, goldReq = 0, itensReward = {{17948, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["dromedary tamer"] = {storageId = 0, level = 1, itens = {{5902, 25}}, goldReq = 0, itensReward = {{17943, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["kingly deer tamer"] = {storageId = 0, level = 1, itens = {{5902, 40}, {5901, 100}}, goldReq = 0, itensReward = {{17947, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["iron blight tamer"] = {storageId = 0, level = 1, itens = {{2146, 100}, {2145, 80}, {13437, 5}}, goldReq = 0, itensReward = {{17950, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["magma crawler tamer"] = {storageId = 0, level = 1, itens = {{2146, 70}, {2145, 50}, {13437, 5}}, goldReq = 0, itensReward = {{17961, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["lady bug tamer"] = {storageId = 0, level = 1, itens = {{5922, 40}}, goldReq = 0, itensReward = {{17944, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["manta ray tamer"] = {storageId = 0, level = 1, itens = {{10550, 100}, {2145, 80}}, goldReq = 0, itensReward = {{17945, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["midnight panther tamer"] = {storageId = 0, level = 1, itens = {{5922, 80}}, goldReq = 0, itensReward = {{17951, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["noble lion tamer"] = {storageId = 0, level = 1, itens = {{12638, 30}}, goldReq = 0, itensReward = {{17956, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["panda tamer"] = {storageId = 0, level = 1, itens = {{5922, 70}}, goldReq = 0, itensReward = {{17939, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["scorpion king tamer"] = {storageId = 0, level = 1, itens = {{10602, 100}, {12436, 30}}, goldReq = 0, itensReward = {{17954, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["shock head tamer"] = {storageId = 0, level = 1, itens = {{2231, 100}, {10602, 60}, {12436, 5}}, goldReq = 0, itensReward = {{17963, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["tiger slug tamer"] = {storageId = 0, level = 1, itens = {{10584, 100}, {5902, 15}}, goldReq = 0, itensReward = {{17955, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["racing bird tamer"] = {storageId = 0, level = 1, itens = {{12640, 50}, {11190, 45}}, goldReq = 0, itensReward = {{17940, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["undead cavebear tamer"] = {storageId = 0, level = 1, itens = {{5896, 80}, {5902, 50}, {2231, 100}}, goldReq = 0, itensReward = {{17952, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["widow queen tamer"] = {storageId = 0, level = 1, itens = {{11328, 60}, {5879, 45}}, goldReq = 0, itensReward = {{17964, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0},
["water buffalo tamer"] = {storageId = 0, level = 1, itens = {{2145, 50}, {5902, 35}}, goldReq = 0, itensReward = {{17962, 1}}, goldReward = 0, effect = 0, storage = 0, givestorage = 0, normalTasks = 0}
}