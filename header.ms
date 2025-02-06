global visualize
visualize = false

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
    for a in $s* do(
        delete a
    )

    for b in $path* do(
        delete b
    )
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
    start_rad = distance origin.pos start.pos
    start_ray = Ray origin.pos (start.pos - origin.pos)
    append radiuses start_rad
    append rays start_ray
    if visualize == true then(
        drawLine origin.pos start.pos red
    )

    -- record and collect the rad&ray of the end point
    end_rad = distance origin.pos goal.pos
    end_ray = ray origin.pos (goal.pos - origin.pos)
    append radiuses end_rad
    append rays end_ray
    if visualize == true then(
        drawLine origin.pos goal.pos red
    )

    -- record and collect the rad&ray of the vertices
    verts = getEnvelopesVerts obs margin
    for v in verts do(
        radius = distance origin.pos v
        ob_ray = ray origin.pos (v - origin.pos)

        append radiuses radius
        append rays ob_ray
        append ob_rads radius
        append ob_rays ob_ray

        if visualize == true then(
            drawLine origin.pos v red
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
        s = sphere radius:radius pos:origin.pos
        ray_id = 1
        for r in rays do(
            hit = intersectRay s r
            if hit != undefined then(
                append hits hit.pos
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
        if p.layer_id == cur_layer or p.ray_id == cur_ray then(
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

fn getHeuristic current neighbour= (
    return (distance current.world_position neighbour.world_position)
)

fn AStar start_node end_node map obs origin safe_radius safe_mode = (
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
                tentativeG = current.g + getHeuristic current neighbour + getCrowdedRisk current obs safe_radius 1 + getHeightRisk current neighbour
            )
            else(
                tentativeG = current.g + getHeuristic current neighbour
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

fn angleBetween direction_A direction_B =
(	
	local dot_prod = direction_A[1] * direction_B[1] + direction_A[2] * direction_B[2]
	
	local mag_a = sqrt ((pow direction_A[1] 2) + (pow direction_A[2] 2))
	local mag_b = sqrt ((pow direction_B[1] 2) + (pow direction_B[2] 2))

	local ans = acos (dot_prod/(mag_a * mag_b))
	
	local cross_prod = [0,0,(direction_A[1]*direction_B[2] - direction_B[1]*direction_A[2])]	
		
	if cross_prod.z < 0 then (
        ans = 360 - ans
    )
    if ans > 180 then(
        ans = 360 - ans
    )
	return ans
)
