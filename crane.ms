filein "common.ms"

global min_len = 20.5
global max_len = 70.5
global inner_sec = 6

fn getBoomLength = (
    edge = (getNodeByName "cable&hook")
    return distance $core.pos edge.pos
)

fn resetBoom = (
    base = getNodeByName "level1"
    for i in 2 to inner_sec do(
        cur_name = "level" + i as string
        cur = getNodeByName cur_name

        cur.pos = base.pos
    )
)

fn rescaleBoom len = (
    len += 3
    if len < min_len or len > max_len do messageBox("Error: Illegal length")

    resetBoom()
    dir = normalize ($level6.pos - $core.pos)
    rest = mod (len - min_len) 10
    tube_num = ((len - min_len - rest) / 10) as integer 

    cur_stage = inner_sec
    for i in 0 to (tube_num - 1) do(
        cur_tube_name = "level" + (cur_stage as integer) as string
        cur_tube = getNodeByName cur_tube_name
        cur_tube.pos = cur_tube.pos + 10 * dir

        cur_stage -= 1
    )
    last_tube_name = "level" + (cur_stage as integer) as string 
    last_tube = getNodeByName last_tube_name
    last_tube.pos = last_tube.pos + rest * dir
)

fn yawCntClk theta = (
    theta = mod theta 360

    spinner = $center
    about $center rotate $spinner (eulerangles 0 0 theta)
)

fn getPlaneNormal edge core center =
(
    local v1 = edge - core
    local v2 = center - core
    
    local normal = cross v1 v2
    
    return normalize normal
)

fn pitchDown theta = (
    cur = getNodeByName "cable&hook"
    orth = getPlaneNormal cur.pos $core.pos $center.pos
    local rotQuat = angleaxis theta orth
    about $core rotate $level1 rotQuat
)

fn moveSpinner p = (
    -- horizonal rotation (yawing)
    hook_pos = (getNodeByName "cable&hook").pos
    center_to_hook = hook_pos - $center.pos
    center_to_p = p.world_position - $center.pos

    cur_h = [center_to_hook.x, center_to_hook.y, 0]
    goal_h = [center_to_p.x, center_to_p.y, 0]

    theta_h = getAngle cur_h goal_h
    if theta_h != theta_h do theta_h = 0

    core_to_p = (p.world_position - $core.pos)

    yawCntClk theta_h

    -- vertical rotation (pitching)
    core_to_p = p.world_position - $core.pos
    core_to_hook = hook_pos - $core.pos

    v1 = normalize (core_to_p + [0,0,5])
    v2 = [0,0,1]
    v3 = normalize core_to_hook

    theta_p = acos (dot v1 v2)
    theta_hook = acos (dot v3 v2)

    if theta_p != theta_p then (
        theta_p = 0
    )
    else(
        theta_p = 90 - theta_p
    )

    if theta_hook != theta_hook then (
        theta_hook = 0
    )
    else(
        theta_hook = 90 - theta_hook
    )

    delta = theta_hook - theta_p
    pitchDown delta
    print("from: " + theta_hook as string + " to " + theta_p as string + " need to pitch down " + delta as string)

    -- radial movement (extension)
    l = distance $core.pos (p.world_position)
    rescaleBoom l
)