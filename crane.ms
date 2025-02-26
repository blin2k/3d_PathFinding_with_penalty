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
    print("aim :" + len as string)
    len += 3
    if len < min_len or len > max_len do messageBox("Error: Illegal length")

    resetBoom()
    dir = normalize ($level6.pos - $core.pos)
    rest = mod (len - min_len) 10
    tube_num = ((len - min_len - rest) / 10) as integer 
    print(tube_num as string + " * 10 + " + min_len as string + " + " + rest as string)

    cur_stage = inner_sec
    for i in 0 to (tube_num - 1) do(
        print(cur_stage)
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
    hook_pos = (getNodeByName "cable&hook").pos
    center_to_hook = hook_pos - $center.pos
    center_to_p = p.world_position - $center.pos

    cur_h = [center_to_hook.x, center_to_hook.y, 0]
    goal_h = [center_to_p.x, center_to_p.y, 0]

    theta_h = getAngle cur_h goal_h
    if theta_h != theta_h do theta_h = 0

    core_to_p = (p.world_position - $core.pos)

    yawCntClk theta_h

    -- cur_v = [0, 0, core_to_hook.z + 10]
    -- goal_v = [0, 0, core_to_p.z + 10]

    core_to_hook = (hook_pos - $core.pos)
    print(core_to_hook)
    print(core_to_p)

    cur_v = normalize core_to_hook
    goal_v = normalize core_to_p

    theta_v = acos (dot cur_v goal_v)
    if theta_v != theta_v do theta_v = 0
    print("v: " + theta_v as string)
    -- pitchDown -theta_v

    l = distance $core.pos (p.world_position)
    rescaleBoom l
)