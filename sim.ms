filein "header.ms"

crane = getNodeByName "Teapot001"
pick = getNodeByName "pick"
goals = $l* as array
obs = $Box* as array
clearance = 1.0

rlt = getMap crane pick obs goals[3]
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]

ps = AStar start_node end_node map obs crane

cur_time = 0
with animate on(
    for p in ps do(
        cur_time = cur_time + 10
        at time cur_time (
            next_pos = p.world_position
            cur_flat = [pick.pos.x - crane.pos.x, pick.pos.y - crane.pos.y, 0]
            next_flat = [next_pos.x - crane.pos.x, next_pos.y - crane.pos.y, 0]
            print(cur_flat)
            print(next_flat)
            theta = angleBetween cur_flat next_flat
            print(theta)
            if theta >= 0 do(
                rotate crane (quat 0 0 (-sin (theta / 2)) (cos (theta / 2)))
            )
            print("---")
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