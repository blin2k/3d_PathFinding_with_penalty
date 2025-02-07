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
rlt = getMap crane pick obs $l2 clearance
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
if ps != undefined then(
    cur_time = 0
    with animate on(
        for p in ps do(
            cur_time = cur_time + 10
            at time cur_time (
                cur_flat = normalize [pick.pos.x - crane.pos.x, pick.pos.y - crane.pos.x, 0]
                next_flat = normalize [p.world_position.x - crane.pos.x, p.world_position.y - crane.pos.x, 0]
                ang = angleBetween cur_flat next_flat
                about crane.pivot rotate crane (quat 0 0 (sin ang/2) (cos ang/2))

                -- print(cur_flat)
                -- print(next_flat)
                -- print(ang)
                -- print("---")

                pick.pos = p.world_position
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