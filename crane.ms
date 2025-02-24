filein "common.ms"

global min_len = 22
global max_len = 72
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
    if len < min_len or len > max_len do messageBox("Error: Illegal length")

    resetBoom()
    dir = normalize ($level6.pos - $core.pos)
    sector_num = ((len - 22)/10 as integer)

    for i in 0 to (sector_num - 1) do(
        cur_sector_name = "level" + ((inner_sec - i) as integer) as string
        cur_sector = getNodeByName cur_sector_name
        cur_sector.pos = cur_sector.pos + 10 * dir
    )
    
)

fn yawCounterclock theta = (
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
    cur = (getNodeByName "cable&hook").pos - $center.pos
    if ClassOf p != point3 then(
        goal = p.world_position - $center.pos
    )
    else(
        goal = p - $center.pos
    )

    cur_f = [cur.x, cur.y, 0]
    goal_f = [goal.x, goal.y, 0]
    theta_f = getAngle cur_f goal_f
    if theta_f != theta_f do theta_f = 0
    print("----")
    -- print(cur_f)
    -- print(goal_f)
    print(theta_f)
    yawCounterclock theta_f
    -- pitchDown theta_f

    -- d = distance $base.pos p.world_position
    -- print($base)
    -- print(p.world_position)
    -- print("distance: " + d as string)
    -- rescaleBoom d
)