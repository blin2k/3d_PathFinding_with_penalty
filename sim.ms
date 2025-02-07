filein "header.ms"

clean() -- clean the extra parts in the scene

-- important parts
crane = getNodeByName "Spinner_001"
pick = getNodeByName "pick"
cable = getNodeByName "Hook Cable"
hook = getNodeByName "Crane Hook"
goals = $l* as array
obs = $Box* as array
clearance = 1.0

hook_wp = hook.transform.position
-- print(hook_wp)
bindToEndVert cable hook -- make sure the cable is extendable
hook.transform.position = hook_wp
-- print(hook.transform.position)

-- get the node map
rlt = getMap crane pick obs $l4 clearance
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]

-- config
safe_radius = 3
safe_mode = true
min_angle = 30
max_angle = 90

ps = AStar start_node end_node map obs crane safe_radius min_angle max_angle safe_mode

-- animation
print("------------------------------")
prev = ps[1]
if ps != undefined then(
    cur_time = 0
    with animate on(
        for p in ps do(
            cur_time = cur_time + 10
            at time cur_time (
                print(prev.world_position)
                print(p.world_position)
                ang = getAngle [prev.world_position.x, prev.world_position.y] [p.world_position.x, p.world_position.y]
                if ang != ang do ang = 0
                -- if (ang >= 0 and ang <= 0.1) or (ang <= 360 or ang >= 359.9) do ang = 0
                about crane.pivot rotate crane (quat 0 0 (sin ang/2) (cos ang/2))

                -- print(cur_flat)
                -- print(next_flat)
                print(ang)
                print("---")
                drawLine prev.world_position p.world_position blue

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
        animationRange = interval 0 cur_time
    )
)
else(
    messageBox("No solution was found.")
)