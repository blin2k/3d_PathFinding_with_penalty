global visualize
visualize = true

struct cNode(
    public
    layer_id,
    ray_id,
    g,
    h,
    f,
    -- walkable = true,
    parent,
    world_position
    -- p
)

fn clean = (
    for a in $sphere* do(
        delete a
    )

    for b in $path* do(
        delete b
    )
)

fn getVertAng = (
    tip = getNodeByName "phelp_Pulley 002"
    return acos (dot (normalize tip.pos) [0,0,1])
)

fn getAngle flat2_v1 flat2_v2 = (	
	local dot_prod = flat2_v1[1] * flat2_v2[1] + flat2_v1[2] * flat2_v2[2]
	
	local mag_a = sqrt ((pow flat2_v1[1] 2) + (pow flat2_v1[2] 2))
	local mag_b = sqrt ((pow flat2_v2[1] 2) + (pow flat2_v2[2] 2))

	local ans = acos (dot_prod/(mag_a * mag_b))
	
	local cross_prod = [0,0,(flat2_v1[1]*flat2_v2[2] - flat2_v2[1]*flat2_v1[2])]	
		
	if cross_prod.z < 0 then return (360 - ans)
	return ans
	
)

fn drawLine source endpoint colour = (
    s = SplineShape()
    addNewSpline s
    addKnot s 1 #corner #line endpoint
    addKnot s 1 #corner #line source
    s.wirecolor = colour
    updateShape s
)

fn getObVerts ob = (
    verts = #()
    if ClassOf ob == Box then(
        convertToPoly ob
    )
    num_verts = polyOp.getNumVerts ob
    for i in 1 to num_verts do(
        v = polyOp.getVert ob i
        append verts v
    )
    return verts
)

fn isCollide obj1 obj2 =(
    if intersects obj1 obj2 then
    (
        local mesh1 = snapshotAsMesh obj1
        local mesh2 = snapshotAsMesh obj2
        (mesh1 * mesh2).numverts > 0
    )
    else
    (
        false
    )
)

fn maybeCollide obj obs =(
    for ob in obs do(
        if (distance ob obj) < 10 and (intersects ob obj) do(
            return true
        )
    )
    return false
)

fn isInsideOb obj ob = (
    cur_pos = obj.world_position 
    bb = getNodeBBox ob
    if cur_pos.x >= bb.min.x and cur_pos.x <= bb.max.x and 
        cur_pos.y >= bb.min.y and cur_pos.y <= bb.max.y and 
        cur_pos.z >= bb.min.z and cur_pos.z <= bb.max.z then(
            return true
        ) 
    else(
        return false
    )
)

fn getObsVerts obs = (
    verts = #()
    for ob in obs do(
        verts = verts + getObVerts ob
    )
    return verts
)

fn getEnvelopesVerts obs margin = (
    verts = #()
    for ob in obs do(
        bb = getNodeBBox ob
        new_bb_min = bb.min - margin
        if new_bb_min.z < 0 do new_bb_min.z = 0
        new_bb_max = bb.max + margin
        
        ttl = [new_bb_min.x, new_bb_max.y, new_bb_max.z]
        ttr = [new_bb_max.x, new_bb_max.y, new_bb_max.z]
        tbl = [new_bb_min.x, new_bb_min.y, new_bb_max.z]
        tbr = [new_bb_max.x, new_bb_min.y, new_bb_max.z]

        btl = [new_bb_min.x, new_bb_max.y, new_bb_min.z]
        btr = [new_bb_max.x, new_bb_max.y, new_bb_min.z]
        bbl = [new_bb_min.x, new_bb_min.y, new_bb_min.z]
        bbr = [new_bb_max.x, new_bb_min.y, new_bb_min.z]

        expanded_verts = #(ttl, ttr, tbl, tbr, btl, btr, bbl, bbr)
        verts = verts + expanded_verts
    )    
    return verts
)

fn getCrowdedRisk cur_node obs radius penalty = (
    risk = 0
    for ob in obs do(
        if isInsideOb cur_node ob then(
            return 1e9
        )
        else(
            d = distance cur_node.world_position ob.pos
            if d < radius then(
                risk += (radius - d)
                -- risk += penalty
            )
        )
    )
    return risk
)

fn getHeightRisk cur_node neighbour = (
    if neighbour.world_position.z > cur_node.world_position.z then(
        return (neighbour.world_position.z - cur_node.world_position.z)
    )
    else(
        return 0.0
    )
)

fn getMap origin start obs goal margin = (
    radiuses = #()
    rays = #()
    hits = #()
    grids = #()
    ob_rads = #()
    ob_rays = #()

    -- record and collect the rad&ray of the start point
    start_rad = distance origin start.pos
    start_ray = Ray origin (start.pos - origin)
    append radiuses start_rad
    append rays start_ray
    if visualize == true then(
        drawLine origin start.pos red
    )

    -- record and collect the rad&ray of the end point
    end_rad = distance origin goal.pos
    end_ray = ray origin (goal.pos - origin)
    append radiuses end_rad
    append rays end_ray
    if visualize == true then(
        drawLine origin goal.pos red
    )

    -- record and collect the rad&ray of the vertices
    verts = getEnvelopesVerts obs margin
    for v in verts do(
        radius = distance origin v
        ob_ray = ray origin (v - origin)

        append radiuses radius
        append rays ob_ray
        append ob_rads radius
        append ob_rays ob_ray

        if visualize == true then(
            drawLine origin v red
        )
    )

    rlt = #()
    for i in 1 to 2 do(
        append rlt undefined
    )

    -- convert to node structures
    sort radiuses
    layer_id = 1
    for radius in radiuses do(
        s = sphere radius:radius pos:origin
        ray_id = 1
        for r in rays do(
            hit = intersectRay s r
            if hit != undefined then(
                append hits hit.pos
                -- if hit.pos.z < 0 then(
                --     posi = [hit.pos.x, hit.pos.y, 0]
                -- )
                -- else(
                --     posi = hit.pos
                -- )
                cur_grid = cNode layer_id:layer_id ray_id:ray_id h:(distance hit.pos goal.pos) world_position:hit.pos

                if visualize == true then(
                    p = sphere radius:0.6 pos:hit.pos segs:40
                )
                if r == start_ray and radius == start_rad then(
                    rlt[1] = cur_grid
                )
                else if r == end_ray and radius == end_rad then(
                    rlt[2] = cur_grid
                )
                for i in 1 to ob_rads.count do(
                    if ob_rads[i] == radius and ob_rays[i] == r then(
                        -- cur_grid.walkable = false
                    )
                )

                -- t = sphere radius:($pick.radius) pos:cur_grid.world_position
                -- for ob in obs do(
                --     if cur_grid.walkable != false and isCollide ob t do(
                --         cur_grid.walkable = false
                --         exit()
                --     )
                -- )
                -- delete t

                append grids cur_grid
            )
        ray_id += 1
        )
        delete s
        layer_id += 1
    )
    append rlt grids
    return rlt
)

fn isPathBlocked from_pos to_pos obs = (
    r = ray from_pos (to_pos - from_pos)
    for ob in obs do(
        hit = intersectRay ob r
        if hit != undefined then(
            -- print(hit)
            return true
        )
    )
    return false
)

fn getNeighbours cur_node map obs origin = (
    cur_layer = cur_node.layer_id
    cur_ray = cur_node.ray_id
    neighbours = #()
    for p in map do(
        if p.world_position.z >= 0 and (p.layer_id == cur_layer or p.ray_id == cur_ray) then(
            if not isPathBlocked cur_node.world_position p.world_position obs then (
                for ob in obs do(
                    -- s = sphere pos:p.world_position radius:0.1
                    -- if not intersects s ob do append neighbours p
                    -- delete s
                )
                append neighbours p
            )
        )
    )
    return neighbours
)

fn getHeuristic current neighbour = (
    return (distance current.world_position neighbour.world_position)
)

fn getAngleRisk centor neighbour min_angle max_angle = (
    direction = neighbour.world_position - centor
    horizontal_plane = [0, 0, 1]
    -- ang = angleBetween direction horizontal_plane
    ang = getAngle direction horizontal_plane
    -- ang = acos (dot (normalize direction) horizontal_plane)
    if ang > min_angle and ang < max_angle then (
        return 0
    )
    else (
        return 1e9
    )
)

fn AStar start_node end_node map obs origin safe_radius min_angle max_angle safe_mode centor = (
    max_iter = 10000
    cur_iter = 0
    openSet = #()
    closedSet = #()
    
    -- init the start node
    start_node.g = 0.0
    start_node.f = start_node.g + start_node.h
    start_node.parent = undefined
    
    -- init the open list
    append openSet start_node
    
    -- while the open list is not emply, pass the one with lowest f-value to the closed list, put its neighbours to the open list
    while cur_iter < max_iter and openSet.count > 0 do (
        cur_iter += 1
        if (mod cur_iter 100 == 0) do print(cur_iter)
        current = undefined
        lowestF = undefined
        
        -- find the one with the lowest f-value
        for node in openSet do (
            f = node.g + node.h
            if current == undefined or f < lowestF do (
                current = node
                lowestF = f
            )
        )
        
        -- retrieve the path if the goal is hit
        if current == end_node then (
            path = #()
            node = current
            while node != undefined do (
                insertItem node path 1
                node = node.parent
            )
            return path
        )
        
        -- pass it to the closed list
        deleteItem openSet (findItem openSet current)
        append closedSet current
        
        neighbours = getNeighbours current map obs origin
        
        for neighbour in neighbours do (
            -- pruning seen neighbours
            if findItem closedSet neighbour != 0 then (
                continue
            )
            
            -- assign g-value for neighbours
            if safe_mode == true then(
                tentativeG = current.g + 1 + getHeuristic current neighbour + getCrowdedRisk current obs safe_radius 1 + getHeightRisk current neighbour + getAngleRisk centor neighbour min_angle max_angle 
            )
            else(
                tentativeG = current.g + 1 + getHeuristic current neighbour
            )
            
            -- the neighbour is better than the current node if
            -- 1. it is not in the open list, which means 
            if findItem openSet neighbour == 0 then (
                neighbour.parent = current
                neighbour.g = tentativeG
                neighbour.f = neighbour.g + neighbour.h

                append openSet neighbour
            ) else if tentativeG < neighbour.g then (
                neighbour.parent = current
                neighbour.g = tentativeG
                neighbour.f = neighbour.g + neighbour.h
            )
            
        )
    )
    
    return undefined  -- No path found
)

-- fn angleBetween v1 v2 =
-- (	
--     ans = acos (dot (normalize v1) (normalize v2))
--     -- if ans < 0 do ans = 360 - ans
-- 	return ans
-- )

-- bind the hook to the lower vertex of the given cable
fn bindToEndVert cable hook = (
	hook_pos = hook.pos
	hook.position.controller = Position_XYZ()
	hook.pos = hook_pos
	thePoint = point size:10 name:"end_vert"
    -- if thePoint.position.controller != position_script() then(
    thePoint.position.controller = position_script()
    ctrl = thePoint.position.controller
    ctrl.addNode "cable" cable
    ctrl.addConstant "curveIndex" 1
    ctrl.addConstant "vertexIndex" 2
    ctrl.script = "
        dependsOn cable
        getKnotPoint cable curveIndex vertexIndex	
    "
    hook.parent = thePoint
    hook.pos = thePoint.pos
    -- )
)

-- extend or shorten the cable until its lower vertex reaches the target height
fn extendToPos cable target_height = (
	top = getKnotPoint cable 1 1
	bot = getKnotPoint cable 1 2
	k = (top.z - target_height) / (top.z - bot.z)
	cable.scale.z = cable.scale.z * k
)

fn extend_boom size =
(	
    originRot = $crane.rotation
    $crane.rotation = quat 0 0 0 1
------------------- Defining variables -------------------
	groups_to_add = #($'Boom Box', $'Crane Bottom')
	boom_box = $'Boom Box'
	crane_top = $'Crane Top'
	collector = $'Boom Box'*
	deleter = #()
	moverX = 2.2
	moverZ = 1.859
    -- moverZ = 0.0
	global pivot_point = $Point001.position
	-- How many times to make the boom box
	num = 0
	input = ceil (size / 6.0) - 1
	counter = 1
		
------------------- Reset rotation for the code to work -------------------
	MBoom_position = $'Main BOOM'.position
	MBoom_rotation = $'Main BOOM'.rotation
	$'Main BOOM'.rotation = quat 0 0 0 1
	$'Main BOOM'.position = pivot_point

------------------- Ungroup original grouping to readjust boom length -------------------
	ungroup $'Main BOOM'

------------------- Delete previous boxes -------------------
	for obj in collector do
	(
		if matchPattern obj.name pattern:"Boom Box0*" then
		(
			-- print (obj.name + " has been deleted.")
			deleter += obj
		)
	)
	delete deleter
------------------- Creating adjustable boom -------------------
	while num != input do
	(
		maxOps.cloneNodes boom_box cloneType:#instance newNodes:&nnl
		-- Get location of new box
		Moving_distance_X = counter * moverX
		Moving_distance_Z = counter * moverZ
		move nnl [Moving_distance_X, 0, Moving_distance_Z]
		num += 1
		counter += 1
		groups_to_add += nnl
	)

------------------- Placing the crane top after the program is finished -------------------
	counter += input
	Moving_distance_X = (counter * moverX) - 2.25
	Moving_distance_Z = (counter * moverZ) - 1.9
    -- Moving_distance_Z = 0.0
	crane_top.position = $'Boom Box'.position + [4.779,0,4.988]
	move crane_top [Moving_distance_X, 0, Moving_distance_Z]
	groups_to_add += $'Crane Top'

------------------- Group Boom boxes together -------------------
	group groups_to_add name:"Main BOOM"

------------------- Move pivot point down -------------------
	global Main_Boom = $'Main BOOM'
	Main_Boom.pivot = pivot_point			--	[3.982, 3.618, 3.074]
	Main_Boom.transform = Main_Boom.transform * (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
	Main_Boom.rotation = MBoom_rotation
	Main_Boom.position = MBoom_position
		
	pc = Position_Constraint()
	$'Main BOOM'.position.controller = pc
	$'Main BOOM'.position.controller.appendTarget $'phelp_Boom Bar_001' 50
	oc = Orientation_Constraint()
	$'Main BOOM'.rotation.controller = oc
	$'Main BOOM'.rotation.controller.appendTarget $'phelp_Boom Bar_001' 50
	$'Main BOOM'.rotation.controller.relative = on
		
	crane_group = getNodeByName "Crane"
	attachNodesToGroup #($'Main BOOM') crane_group
	
    $crane.rotation = originRot 
)

fn extend_to_top p = (
    theta = getVertAng()
    flat_dist = distance [p.world_position.x, p.world_position.y, 0] [0,0,0]
    len = flat_dist/(sin theta)
    extend_boom len
)