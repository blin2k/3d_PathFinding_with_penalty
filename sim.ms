filein "header.ms"
filein "crane.ms"

for a in $sphere* do(
    delete a
)

for b in $path* do(
    delete b
)

for c in $Shape* do(
    delete c
)

for d in $Arc* do(
    delete d
)

-- important parts
goals = $l* as array
obs = $Box* as array
clearance = 1.0
center = $center.pos
pick = $pick

-- get the node map
s1 = timestamp()
rlt = getMap center pick obs $l3 clearance
s2 = timestamp()
print("Map: " + (mod (s2 - s1) 1000) as string)
start_node = rlt[1]
end_node = rlt[2]
map = rlt[3]
print(map.count)

-- config
safe_radius = 10
safe_mode = true
min_angle = 10
max_angle = 90
boom_len = 60

ps = AStar start_node end_node map obs crane safe_radius min_angle max_angle safe_mode center
s3 = timestamp()
print("Path: " + (mod (s3 - s2) 1000) as string)
print("Total: " + (mod (s3 - s1) 1000) as string)
-- print(ps)

total_dist = 0.0
violate_obs = 0
violate_verts = 0
total_h = 0.0
path_len = 0.0
pv = ps[1]
for p in ps do(
    total_h += p.world_position.z
    path_len += distance pv.world_position p.world_position
    pv = p
)
print("path len: " + path_len as string)
for ob in obs do(
    verts = getObVerts ob
    for p in ps do(
        for v in verts do(
            total_dist += distance v p.world_position
            if (distance v p.world_position) < safe_radius do violate_verts += (distance v p.world_position)
        )

        if (distance ob.pos p.world_position) < safe_radius do violate_obs += (distance ob.pos p.world_position)
    )
)
print("Nodes: " + ps.count as string)
print("Total distance with obstacle is " + total_dist as string)
print("node-obs ave dist: " + (total_dist / (ps.count as float)) as string)
print("total Violation obs: " + (violate_obs ) as string)
print("obs violated per node: " + (violate_obs / (ps.count as float)) as string)
print("total Violation verts : " + (violate_verts ) as string)
print("verts violated per node: " + (violate_verts / (ps.count as float)) as string)
print("accumu h: " + total_h as string)
print("avg h: " + (total_h / (ps.count as float)) as string)

-- -- animation
print("------------------------------")
prev = ps[1]
animationRange = interval 0 (ps.count * 120)
if ps != undefined then(
    cur_time = 0
    with animate on(
        at time 0 (
            -- moveSpinner ps[1]
        )
        for p in ps do(
            cur_time = cur_time + 120
            at time cur_time (
                theta = getAngle prev p
                if theta != theta do theta = 0

                if not isSameRay prev p center then(
                    colour = blue
                    at time 0 (
                        drawArc center prev.world_position p.world_position "Arc_real"
                    )
                )
                else(
                    colour = red
                )
                drawLine prev.world_position p.world_position colour

                -- moveSpinner p

                pick.pos = p.world_position
                -- print(pick.pos as string + " " + p.world_position as string)
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