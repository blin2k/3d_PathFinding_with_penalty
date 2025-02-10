filein "header.ms"

clean() -- clean the extra parts in the scene

-- important parts
crane = getNodeByName "Spinner_001"
pick = getNodeByName "pick"
cable = getNodeByName "Hook Cable"
hook = getNodeByName "Crane Hook"
pulley = getNodeByName "phelp_Pulley 002"
goals = $l* as array
obs = $Box* as array
clearance = 1.0

hook_wp = hook.transform.position
bindToEndVert cable hook -- make sure the cable is extendable
hook.transform.position = hook_wp
extendToPos cable 3
cable_len = pulley.pos.z

centor = crane.pos - [0,0,cable_len]

-- get the node map
rlt = getMap centor pick obs $l4 clearance
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]

-- config
safe_radius = 3
safe_mode = true
min_angle = 10
max_angle = 90

ps = AStar start_node end_node map obs crane safe_radius min_angle max_angle safe_mode centor

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
                -- if (ang >= 0 and ang <= 0.1) or (ang <= 360 or ang >= 359.9) do ang = 0
                -- about crane.pivot rotate crane (quat 0 0 (sin ang/2) (cos ang/2))
                about crane.pivot rotate crane (eulerangles 0 0 ang)
                -- extend_to_top p
                -- print(cur_flat)
                -- print(next_flat)
                print(ang)
                print("---")
                if distance p.world_position centor == distance prev.world_position centor then(
                    colour = blue
                )
                else(
                    colour = red
                )
                drawLine prev.world_position p.world_position colour

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