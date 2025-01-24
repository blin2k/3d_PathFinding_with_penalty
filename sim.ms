filein "header.ms"

crane = getNodeByName "Teapot001"
pick = getNodeByName "pick"
goals = $l* as array
obs = $Box* as array
clearance = 1.0

rlt = getMap crane pick obs goals[1]
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]

ps = AStar start_node end_node map obs crane
for p in ps do(
    sphere pos:p.world_position radius:0.5 color:red
)