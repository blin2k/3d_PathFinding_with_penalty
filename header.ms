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

fn getMap origin start obs goal = (
    verts = #()
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
    for ob in obs do(
        if ClassOf ob == Box then(
            convertToPoly ob
        )
        num_verts = polyOp.getNumVerts ob
        for i in 1 to num_verts do(
            v = polyOp.getVert ob i
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

fn getNeighbours cur_node map = (
    cur_layer = cur_node.layer_id
    cur_ray = cur_node.ray_id
    neighbours = #()
    for p in map do(
        if p.layer_id == cur_layer or p.ray_id == cur_ray then(

            append neighbours p
        )
    )
    return neighbours
)

fn AStar start_node end_node map = (
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
        
        neighbours = getNeighbours current map
        
        for neighbour in neighbours do (
            if findItem closedSet neighbour != 0 or neighbour.walkable == false then (
                continue
            )
            
            tentativeG = current.g + distance current.world_position neighbour.world_position
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