filein "common.ms"

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
    for a in $sphere* do(
        delete a
    )

    for b in $path* do(
        delete b
    )
    -- for c in 
)

fn vectorsAreEqual v1 v2 eps:1e-6 =
(
    -- Compare length of difference with epsilon
    return (length (v1 - v2)) < eps
)


fn isSameRay prev p center = (
    -- return distance p.world_position center == distance prev.world_position center
    v1 = normalize (p.world_position - center)
    v2 = normalize (prev.world_position - center) 
    -- print("v1: " + v1 as string)
    -- print("v2: " + v2 as string)

    return vectorsAreEqual v1 v2
)

-- fn getAngle prev p = (	

--     if classOf prev != Point3 then(
--         flat2_v1 = normalize [prev.world_position.x, prev.world_position.y] 
--         flat2_v2 = normalize [p.world_position.x, p.world_position.y]
--     )
--     else(
--         flat2_v1 = normalize [prev.x, prev.y] 
--         flat2_v2 = normalize [p.x, p.y]
--     )

-- 	local dot_prod = flat2_v1[1] * flat2_v2[1] + flat2_v1[2] * flat2_v2[2]
	
-- 	local mag_a = sqrt ((pow flat2_v1[1] 2) + (pow flat2_v1[2] 2))
-- 	local mag_b = sqrt ((pow flat2_v2[1] 2) + (pow flat2_v2[2] 2))

-- 	local ans = acos (dot_prod/(mag_a * mag_b))
	
-- 	local cross_prod = [0,0,(flat2_v1[1]*flat2_v2[2] - flat2_v2[1]*flat2_v1[2])]	
		
-- 	if cross_prod.z < 0 then return (360 - ans)
-- 	return ans
	
-- )

fn drawLine source endpoint colour = (
    s = SplineShape()
    addNewSpline s
    addKnot s 1 #corner #line endpoint
    addKnot s 1 #corner #line source
    s.wirecolor = colour
    updateShape s
)

fn drawArc centerPoint startPoint endPoint arc_name =(
    --------------------------------------------------------------------------
    -- 1. Compute vectors and check collinearity
    --------------------------------------------------------------------------
    local v1 = startPoint - centerPoint
    local v2 = endPoint   - centerPoint
    
    local normalVec = cross v1 v2
    local normalLen = length normalVec
    if normalLen < 1e-6 do (
        format "Cannot create arc: the points are collinear.\n"
        return undefined
    )
    
    --------------------------------------------------------------------------
    -- 2. Define a local coordinate system where:
    --    * The origin is 'centerPoint'
    --    * The local X axis points from center -> start (v1)
    --    * The local Z axis is the plane normal
    --    * The local Y axis is their cross
    --------------------------------------------------------------------------
    local r    = length v1              -- radius = distance from center to start
    local xAxis = normalize v1          -- local X
    local zAxis = normalize normalVec   -- local Z
    local yAxis = cross zAxis xAxis     -- local Y (right-handed system)
    
    --------------------------------------------------------------------------
    -- 3. Convert v1, v2 to local coordinates in that system
    --    In local coords, start should be roughly (r, 0, 0)
    --------------------------------------------------------------------------
    -- Dot each vector with our local X/Y/Z to see its local x,y,z
    local stLocal = [dot v1 xAxis, dot v1 yAxis, dot v1 zAxis]
    local enLocal = [dot v2 xAxis, dot v2 yAxis, dot v2 zAxis]

    --------------------------------------------------------------------------
    -- 4. Compute each point's polar angle around local Z using atan2(y, x)
    --    The difference gives the sweep angle from v1 to v2
    --------------------------------------------------------------------------
    st = normalize stLocal
    en = normalize enLocal
    t = acos (dot st en)
    --------------------------------------------------------------------------
    -- 5. Create the Arc shape in local XY plane (no weird large angles)
    --    We'll sweep from 0 to 'angleDeg'.
    --------------------------------------------------------------------------
    local theArc = arc name:arc_name radius:r from:0 to:t wirecolor:yellow

    --------------------------------------------------------------------------
    -- 6. Finally, position/orient the arc in world space
    --    so that local X -> xAxis, local Y -> yAxis, local Z -> zAxis
    --------------------------------------------------------------------------
    local tM = matrix3 xAxis yAxis zAxis centerPoint
    theArc.transform = tM
    
    return theArc
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

/*
    Returns true if the arc from pStart to pEnd (centered at c) 
    intersects the axis-aligned box defined by boxMin and boxMax.
    
    - c       : Point3, center of the arc’s circle
    - pStart  : Point3, start point on the circle
    - pEnd    : Point3, end point on the circle
    - boxMin  : Point3, minimum corner (xMin, yMin, zMin) of the cube
    - boxMax  : Point3, maximum corner (xMax, yMax, zMax) of the cube
    - numSamples : Integer, how many points to sample along the arc
*/
fn isArcIntersectsCube c pStart pEnd boxMin boxMax numSamples:32 =
(
    -- 1) Compute radius
    local R = distance c pStart
    
    -- 2) Define the plane normal of the circle:
    --    n = (pStart - c) x (pEnd - c)
    local vStart = pStart - c
    local vEnd   = pEnd   - c
    local n = normalize (cross vStart vEnd)
    
    -- 3) Build two orthonormal vectors u, v in the circle plane.
    --    Let u = normalized vStart, and v = n x u.
    local u = normalize vStart
    local v = cross n u
    
    -- 4) Compute angles for pStart and pEnd w.r.t. u, v.
    --    pStart = c + R (cos(thetaStart)*u + sin(thetaStart)*v)
    --    pEnd   = c + R (cos(thetaEnd)*u   + sin(thetaEnd)*v)
    --    In practice, dot & cross can give the angle from u to vEnd.

    -- Let's define: 
    --    thetaStart = 0  (since pStart is our reference direction, i.e. "u")
    -- Then find the angle from pStart to pEnd using dot and cross:
    local cosVal   = dot (normalize vStart) (normalize vEnd)
    local angle    = acos (cosVal)
    local crossDir = dot (cross (normalize vStart) (normalize vEnd)) n
    
    -- We'll say: if crossDir >= 0, then arc goes from 0 to +angle,
    --            else from 0 to -angle. 
    -- This is a simplistic orientation check.
    local thetaStart = 0.0
    local thetaEnd   = angle
    if (crossDir < 0) do (
        thetaEnd = -angle
    )
    
    -- 5) Now sample the arc from thetaStart to thetaEnd:
    local stepCount = numSamples as float
    local stepAngle = (thetaEnd - thetaStart) / stepCount
    
    for i = 0 to numSamples do
    (
        local t = thetaStart + i * stepAngle
        -- Parametric point on the arc:
        local p = c + R * (u * cos t + v * sin t)
        if isBoomBlocked p obs or p.z < 0 then(
            return true
        ) 
        
        -- 6) Check if p is within the cube's bounding box
        if (p.x >= boxMin.x AND p.x <= boxMax.x) AND \
           (p.y >= boxMin.y AND p.y <= boxMax.y) AND \
           (p.z >= boxMin.z AND p.z <= boxMax.z) then
        (
            return true  -- found an intersection
        )
    )
    
    -- If we never found a point inside the bounding box, 
    -- assume no intersection (with the given sampling).
    return false
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
    if rlt.count == 0 do (messageBox("No solution found"))
    return rlt
)

fn isPathBlocked from_pos to_pos obs = (
    v1 = normalize (from_pos - $center.pos)
    v2 = normalize (to_pos - $center.pos)
    if vectorsAreEqual v1 v2 then(
        r = ray from_pos (to_pos - from_pos)
        for ob in obs do(
            hit = intersectRay ob r
            if hit != undefined then(
                return true
            )
        )
    )
    else(
        for ob in obs do(
            bbox = getNodeBBox ob
            if isArcIntersectsCube $center.pos from_pos to_pos bbox.min bbox.max do(
                return true
            )
        )
    )
    return false
)

fn isBoomBlocked to_pos obs =(
    hook_pos = to_pos + [0, 0, 10]
    dir = normalize (hook_pos - $core.pos)
    r = ray $core.pos dir
    for ob in obs do(
        if intersectRay ob r != undefined then(
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
                append neighbours p
            )
        )
    )
    return neighbours
)

fn getDistance current neighbour = (
    return (distance current.world_position neighbour.world_position)
)

fn getAngleRisk center neighbour min_angle max_angle = (
    direction = neighbour.world_position - center
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

fn AStar start_node end_node map obs origin safe_radius min_angle max_angle safe_mode center = (
    if safe_mode == true then print("With risk penalty") else print("Without penalty")
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
            print("It took " + cur_iter as string + " loops")
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
                -- tentativeG = current.g + 1 + (getCrowdedRisk current obs safe_radius 30) + 10 * (getHeightRisk current neighbour) + getAngleRisk center neighbour min_angle max_angle 
                tentativeG = current.g +  getCrowdedRisk current obs safe_radius 30 + 10 * (getHeightRisk current neighbour) + getAngleRisk center neighbour min_angle max_angle 
            )
            else(
                -- tentativeG = current.g + 1
                tentativeG = current.g + getDistance current neighbour
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