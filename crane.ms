fn getVertAng = (
    tip = getNodeByName "phelp_Pulley 002"
    return acos (dot (normalize tip.pos) [0,0,1])
)

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

fn drawArc1 centerPoint startPoint endPoint =
(
    print("from pos: " + startPoint as string)
    Print("to pos: " + endPoint as string)
    -- Vectors from center to start/end
    local v1 = startPoint - centerPoint
    local v2 = endPoint - centerPoint
    
    -- Cross product to check if we have a valid plane
    local normalVec = cross v1 v2
    local normalLength = length normalVec
    
    if normalLength < 1e-6 then
    (
        format "Cannot create arc: the points are collinear or nearly so.\n"
        return undefined
    )
    
    -- Normalize
    local v1N = normalize v1
    local v2N = normalize v2
    local nN  = normalize normalVec
    
    -- Compute the *unsigned* angle between v1 and v2
    local angleRad = acos (dot v1N v2N)
    print("angle rad: " + angleRad as string)
    -- Check the direction (sign) via cross(v1N, v2N) dot normal
    -- If this is negative, it means we need to "flip" to the larger sweep
    local crossSign = dot (cross v1N v2N) nN
    if crossSign < 0.0 then
    (
        -- Instead of the smaller arc, take the "long" arc
        angleRad = 2.0 * pi - angleRad
    )
    
    local angleDeg = angleRad * 180.0 / pi
    angleDeg = mod angleDeg 360
    print("angle deg: " + angleDeg as string)
    
    -- Create an Arc in the local XY plane with the needed sweep
    local theArc = arc radius:(length v1) from:0 to:angleDeg wirecolor:yellow
    
    -- Build a transform so that:
    --  * local X-axis aligns with v1
    --  * local Z-axis aligns with the plane normal
    --  * local Y-axis = Z x X
    --  * origin = centerPoint
    local xAxis = v1N
    local zAxis = nN
    local yAxis = cross zAxis xAxis
    
    local theMatrix = matrix3 xAxis yAxis zAxis centerPoint
    theArc.transform = theMatrix
    
    return theArc
)


fn drawArc centerPoint startPoint endPoint =
(
    --------------------------------------------------------------------------
    -- 1) Compute vectors and check collinearity
    --------------------------------------------------------------------------
    local v1 = startPoint - centerPoint
    local v2 = endPoint   - centerPoint
    
    local normalVec = cross v1 v2
    local normalLen = length normalVec
    if normalLen < 1e-6 do
    (
        format "Cannot create arc: the points are collinear.\n"
        return undefined
    )
    
    --------------------------------------------------------------------------
    -- 2) Define a local coordinate system where:
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
    -- 3) Convert v1, v2 to local coordinates in that system
    --    In local coords, start should be roughly (r, 0, 0)
    --------------------------------------------------------------------------
    -- Dot each vector with our local X/Y/Z to see its local x,y,z
    local stLocal = [dot v1 xAxis, dot v1 yAxis, dot v1 zAxis]
    local enLocal = [dot v2 xAxis, dot v2 yAxis, dot v2 zAxis]
    
    --------------------------------------------------------------------------
    -- 4) Compute each point's polar angle around local Z using atan2(y, x)
    --    The difference gives the sweep angle from v1 to v2
    --------------------------------------------------------------------------
    local startAng = atan2 stLocal.y stLocal.x   -- angle of start in local XY
    local endAng   = atan2 enLocal.y enLocal.x   -- angle of end   in local XY
    local angleRad = endAng - startAng
    
    -- If negative, wrap it into [0..2π]
    if angleRad < 0.0 do angleRad += 2.0*pi
    
    local angleDeg = angleRad * 180.0 / pi
    -- At this point, angleDeg is guaranteed to be in [0..360]

    --------------------------------------------------------------------------
    -- 5) Create the Arc shape in local XY plane (no weird large angles)
    --    We'll sweep from 0 to 'angleDeg'.
    --------------------------------------------------------------------------
    local theArc = arc name:"ArcBetween3Points" radius:r from:0 to:angleDeg wirecolor:yellow
    
    --------------------------------------------------------------------------
    -- 6) Finally, position/orient the arc in world space
    --    so that local X -> xAxis, local Y -> yAxis, local Z -> zAxis
    --------------------------------------------------------------------------
    local tM = matrix3 xAxis yAxis zAxis centerPoint
    theArc.transform = tM
    
    return theArc
)

spinner = getNodeByName "Spinner_001"
top = getNodeByName "phelp_Pulley 002"
bar = getNodeByName "phelp_Boom Bar_001"