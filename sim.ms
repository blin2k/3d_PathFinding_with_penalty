filein "header.ms"
filein "crane.ms"

clean() -- clean the extra parts in the scene

-- important parts
goals = $l* as array
obs = $Box* as array
clearance = 1.0

-- get the node map
rlt = getMap center pick obs $l3 clearance
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]

-- config
safe_radius = 3
safe_mode = true
min_angle = 10
max_angle = 90
boom_len = 60

ps = AStar start_node end_node map obs crane safe_radius min_angle max_angle safe_mode center

-- animation
print("------------------------------")
prev = ps[1]
animationRange = interval 0 (ps.count * 120)
if ps != undefined then(
    cur_time = 0
    with animate on(
        for p in ps do(
            cur_time = cur_time + 120
            at time cur_time (
                f1 = normalize [prev.world_position.x, prev.world_position.y] 
                f2 = normalize [p.world_position.x, p.world_position.y]
                ang = getAngle f1 f2
                if ang != ang do ang = 0

                if distance p.world_position center == distance prev.world_position center then(
                    colour = blue
                    at time 0 (
                        drawArc center prev.world_position p.world_position
                    )
                    drawLine prev.world_position p.world_position colour
                )
                else(
                    colour = red
                    drawLine prev.world_position p.world_position colour
                )

                pick.pos = p.world_position
                prev = p
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
    )
)
else(
    messageBox("No solution was found.")
)