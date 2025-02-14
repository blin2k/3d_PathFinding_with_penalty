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

    for i in 0 to sector_num do(
        cur_sector_name = "level" + (inner_sec - i) as string
        cur_sector = getNodeByName cur_sector_name
        cur_sector.pos = cur_sector.pos + 10 * dir
    )
    
)

fn rotateSpinner theta isClockwise = (
    theta = mod theta 360

    spinner = $spinner
    if isClockwise != true then (
        rotate $spinner (eulerangles 0 0 theta)
    )
    else(
        rotate $spinner (eulerangles 0 0 -theta)
    )
)