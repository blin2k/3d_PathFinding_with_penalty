visualize = false

struct cNode(
    public
    layer_id,
    ray_id,
    g,
    h,
    walkable
)

fn drawLine source endpoint colour = (
    s = SplineShape()
    addNewSpline s
    addKnot s 1 #corner #line endpoint
    addKnot s 1 #corner #line source
    s.wirecolor = colour
    updateShape s
)

fn getMap origin start obs goals = (
    verts = #()
    radiuses = #()
    rays = #()
    hits = #()
    grids = #()
    
    append radiuses (distance origin.pos start.pos)
    append rays (Ray origin.pos (start.pos - origin.pos))
    if visualize then(
        drawLine origin.pos start.pos red
    )

    for goal in goals do(
        append radiuses (distance origin.pos goal.pos)
        append rays (ray origin.pos (goal.pos - origin.pos))
        if visualize then(
            drawLine origin.pos goal.pos red
        )
    )

    for ob in obs do(
        if ClassOf ob == Box then(
            convertToPoly ob
        )
        num_verts = polyOp.getNumVerts ob
        for i in 1 to num_verts do(
            v = polyOp.getVert ob i
            append verts v
            radius = distance origin.pos v
            append radiuses radius
            append rays (ray origin.pos (v - origin.pos))
            if visualize then(
                drawLine origin.pos v red
            )
        )
    )

    sort radiuses
    layer_id = 1
    for radius in radiuses do(
        s = sphere radius:radius pos:origin.pos
        ray_id = 1
        for r in rays do(
            hit = intersectRay s r
            if hit != undefined then(
                append hits hit.pos
                if visualize then(
                    sphere radius:0.6 pos:hit.pos segs:40
                )
                cur_grid = cNode layer_id:layer_id ray_id:ray_id h:(distance hit.pos start.pos)
                append grids cur_grid
            )
        ray_id += 1
        )
        delete s
        layer_id += 1
    )
    return grids
)