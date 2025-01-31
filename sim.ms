filein "header.ms"

clean()

crane = getNodeByName "Teapot001"
pick = getNodeByName "pick"
goals = $l* as array
obs = $Box* as array
clearance = 1.0

rlt = getMap crane pick obs $l2 clearance
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]

height_weight = -1

ps = AStar start_node end_node map obs crane height_weight
if ps != undefined then(
    cur_time = 0
    with animate on(
        for p in ps do(
            cur_time = cur_time + 10
            at time cur_time (
                next_pos = p.world_position
                pick.pos = next_pos
            )
            arr = $path_*
            if arr == undefined then(
                cnt = 0
            )
            else(
                cnt = (arr as array).count
            )
            s_name = ("path_" + cnt as string)
            sphere pos:p.world_position radius:0.5 color:red name:s_name
        )
        animationRange = interval 0 cur_time
    )
)
else(
    messageBox("No solution was found.")
)