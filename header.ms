fn visualizeRayAsLine theRay length:50 color:yellow =
(
    -- Create an empty shape
    local lineObj = splineShape name:"RayLine"
    
    -- Start a new spline
    addNewSpline lineObj
    
    -- Add two knots: origin and origin + direction * length
    local startPoint = theRay.origin
    local endPoint   = theRay.origin + (normalize theRay.dir * length)
    
    addKnot lineObj 1 #corner #line startPoint
    addKnot lineObj 1 #corner #line endPoint
    updateShape lineObj
    
    -- Set the wire color for easy identification in the viewport
    lineObj.wireColor = color
    
    return lineObj
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
    
    append radiuses (distance origin.pos start.pos)
    append rays (Ray origin.pos (start.pos - origin.pos))
    drawLine origin.pos start.pos red

    for goal in goals do(
        append radiuses (distance origin.pos goal.pos)
        append rays (ray origin.pos (goal.pos - origin.pos))
        drawLine origin.pos goal.pos red
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
            drawLine origin.pos v red
        )
    )

    sort radiuses
    for radius in radiuses do(
        s = sphere radius:radius pos:origin.pos
        for r in rays do(
            hit = intersectRay s r
            if hit != undefined then(
                append hits hit.pos
                sphere radius:0.6 pos:hit.pos segs:40
                -- visualizeRayAsLine r
            )
        )
        delete s
    )
    return hits
)