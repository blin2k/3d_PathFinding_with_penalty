global visualize
visualize = false

struct cNode(
    public
    layer_id,
    ray_id,
    g,
    h,
    f,
    walkable = true,
    parent,
    world_position
)

fn drawLine source endpoint colour = (
    s = SplineShape()
    addNewSpline s
    addKnot s 1 #corner #line endpoint
    addKnot s 1 #corner #line source
    s.wirecolor = colour
    updateShape s
)

fn getObsVerts obs = (
    verts = #()
    for ob in obs do(
        if ClassOf ob == Box then(
            convertToPoly ob
        )
        num_verts = polyOp.getNumVerts ob
        for i in 1 to num_verts do(
            v = polyOp.getVert ob i
            append verts v
        )
    )
    return verts
)

fn getMap origin start obs goal = (
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
    verts = getObsVerts obs
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
                        cur_grid.walkable = false
                    )
                )
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

fn isPointInsideBox point box = (
    local bbMin = [0,0,0]
    local bbMax = [0,0,0]
    nodeGetBoundingBox box box.transform &bbMin &bbMax

    if (point.x >= bbMin.x and point.x <= bbMax.x) and
       (point.y >= bbMin.y and point.y <= bbMax.y) and
       (point.z >= bbMin.z and point.z <= bbMax.z) then (
        return true
    )
    else (
        return false
    )
)

fn arcIntersectsBoxes p1 p2 center obs = (
    numSamples = 10
    vec1 = p1 - center
    vec2 = p2 - center

    len1 = length vec1
    len2 = length vec2

    if len1 == 0 or len2 == 0 do return true  -- Avoid division by zero

    normVec1 = vec1 / len1
    normVec2 = vec2 / len2

    dotProduct = dot normVec1 normVec2
    theta = acos dotProduct

    if theta == 0 do return false  -- Vectors are the same, no arc to check

    for i = 0 to numSamples do (
        t = i / numSamples
        sinTheta = sin theta
        a = sin ((1 - t) * theta) / sinTheta
        b = sin (t * theta) / sinTheta
        vec = normVec1 * a + normVec2 * b
        vec = normalize vec
        radius = len1 * (1 - t) + len2 * t
        pos = center + vec * radius

        for ob in obs do (
            if isPointInsideBox pos ob do (
                return true  -- Arc crosses an obstacle
            )
        )
    )
    return false  -- Arc does not cross any obstacle
)

fn getNeighbours cur_node map obs origin = (
    cur_layer = cur_node.layer_id
    cur_ray = cur_node.ray_id
    neighbours = #()
    for p in map do(
        if p.layer_id == cur_layer or p.ray_id == cur_ray then(
            if not arcIntersectsBoxes cur_node.world_position p.world_position origin.pos obs then (
                append neighbours p
            )
        )
    )
    return neighbours
)

fn AStar start_node end_node map obs origin = (
    openSet = #()
    closedSet = #()
    
    start_node.g = 0.0
    start_node.f = start_node.g + start_node.h
    start_node.parent = undefined
    
    append openSet start_node
    
    while openSet.count > 0 do (
        current = undefined
        lowestF = undefined
        
        for node in openSet do (
            f = node.g + node.h
            if current == undefined or f < lowestF do (
                current = node
                lowestF = f
            )
        )
        
        if current == end_node then (
            path = #()
            node = current
            while node != undefined do (
                insertItem node path 1
                node = node.parent
            )
            return path
        )
        
        deleteItem openSet (findItem openSet current)
        append closedSet current
        
        neighbours = getNeighbours current map obs origin
        
        for neighbour in neighbours do (
            if findItem closedSet neighbour != 0 or neighbour.walkable == false then (
                continue
            )
            
            tentativeG = current.g + 1
            isBetter = false
            
            if findItem openSet neighbour == 0 then (
                append openSet neighbour
                isBetter = true
            ) else if tentativeG < neighbour.g then (
                isBetter = true
            )
            
            if isBetter then (
                neighbour.parent = current
                neighbour.g = tentativeG
                neighbour.f = neighbour.g + neighbour.h
            )
        )
    )
    
    return undefined  -- No path found
)