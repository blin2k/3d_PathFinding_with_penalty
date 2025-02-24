-- Load header and compute global bounding box from all objects whose name begins with "Box"
filein "header.ms"

-- Initialize extreme values:
minScene = [1e9, 1e9, 1e9]
maxScene = [-1e9, -1e9, -1e9]

for obj in $Box* do (
    verts = getObVerts obj
    for p in verts do (
        if p.x < minScene.x then minScene.x = p.x
        if p.y < minScene.y then minScene.y = p.y
        if p.z < minScene.z then minScene.z = p.z
        if p.x > maxScene.x then maxScene.x = p.x
        if p.y > maxScene.y then maxScene.y = p.y
        if p.z > maxScene.z then maxScene.z = p.z
    )
)

for p in #($pick.pos, $l2.pos) do (
    if p.x < minScene.x then minScene.x = p.x
    if p.y < minScene.y then minScene.y = p.y
    if p.z < minScene.z then minScene.z = p.z
    if p.x > maxScene.x then maxScene.x = p.x
    if p.y > maxScene.y then maxScene.y = p.y
    if p.z > maxScene.z then maxScene.z = p.z
)


-- Also precompute each box’s own bounding box (an array of [bMin, bMax])
boxes = #()
for obj in $Box* do (
    bMin = [1e9,1e9,1e9]
    bMax = [-1e9,-1e9,-1e9]
    verts = getObVerts obj
    for p in verts do (
        if p.x < bMin.x then bMin.x = p.x
        if p.y < bMin.y then bMin.y = p.y
        if p.z < bMin.z then bMin.z = p.z
        if p.x > bMax.x then bMax.x = p.x
        if p.y > bMax.y then bMax.y = p.y
        if p.z > bMax.z then bMax.z = p.z
    )
    append boxes #(bMin, bMax)
)

-- Define cGrid bounds. We assume one node per cubic metre.
-- Here we use floor() for the minimum and floor() for maximum so that each cell represents a full 1m³.
minX = floor minScene.x
minY = floor minScene.y
minZ = floor minScene.z
maxX = floor maxScene.x
maxY = floor maxScene.y
maxZ = floor maxScene.z

cGridSizeX = maxX - minX + 1
cGridSizeY = maxY - minY + 1
cGridSizeZ = maxZ - minZ + 1

totalNodes = cGridSizeX *cGridSizeY *cGridSizeZ
format "Total nodes: %\n" totalNodes

-- A helper “constructor” for cGrid nodes.
-- Each node has:
--   pos: its cGrid coordinate [i,j,k]
--   worldPos: the corresponding world coordinate (the cube’s minimum corner)
--   walkable: whether it is free (default true)
--   g, h, f: cost values for A*
--   parent: for path reconstruction
struct cNode(
    public
    pos,
    worldPos,
    walkable,
    g,
    h,
    f,
    parent
)

fn createNode i j k =
(
    return ( cNode pos: [i, j, k] worldPos: [minX + i, minY + j, minZ + k] walkable: true g: 0 h: 0 f: 0 parent: undefined)
)

-- Build a 3D cGrid as nested arrays.
cGrid = #()
for i = 0 to cGridSizeX - 1 do (
    cGrid[i+1] = #()
    for j = 0 to cGridSizeY - 1 do (
        cGrid[i+1][j+1] = #()
        for k = 0 to cGridSizeZ - 1 do (
            node = createNode i j k
            -- Determine the world-space cube for this node
            nodeMin = node.worldPos
            nodeMax = node.worldPos + [1,1,1]
            -- Check against each box: if our cube overlaps any box, mark it non–walkable.
            for b in boxes do (
                bMin = b[1]
                bMax = b[2]
                if ((nodeMax.x >= bMin.x and nodeMin.x <= bMax.x) and
                    (nodeMax.y >= bMin.y and nodeMin.y <= bMax.y) and
                    (nodeMax.z >= bMin.z and nodeMin.z <= bMax.z)) or nodeMin.z < 0 then
                (
                    node.walkable = false
                    exit  -- no need to check further boxes
                )
            )
            append cGrid[i+1][j+1] node
        )
    )
)

-- Helper: get node from cGrid by grid indices (our arrays are 1-indexed)
fn getNode i j k =
(
    return cGrid[i+1][j+1][k+1]
)

-- A simple Manhattan heuristic for A* (cGrid distances)
fn heuristic n1 n2 =
(
    return (abs(n1.pos.x - n2.pos.x) + abs(n1.pos.y - n2.pos.y) + abs(n1.pos.z - n2.pos.z))
)

-- Convert a world position to cGrid coordinate (using floor)
fn worldTocGrid pos =
(
    local i = floor pos.x - minX
    local j = floor pos.y - minY
    local k = floor pos.z - minZ
    return [i, j, k]
)

-- Get the start and end nodes from objects $pick and $l2.
startcGrid = worldTocGrid $pick.pos
endcGrid   = worldTocGrid $l2.pos

print(startcGrid)
print(endcGrid)
print(cGridSizeX)


-- Check that these indices are within the cGrid bounds.
if (startcGrid[1] < 0 or startcGrid[1] >=cGridSizeX or startcGrid[2] < 0 or startcGrid[2] >=cGridSizeY or startcGrid[3] < 0 or startcGrid[3] >=cGridSizeZ) then
(
    format "Start position is out of cGrid bounds.\n"
    -- return undefined
)
if (endcGrid[1] < 0 or endcGrid[1] >=cGridSizeX or endcGrid[2] < 0 or endcGrid[2] >=cGridSizeY or endcGrid[3] < 0 or endcGrid[3] >=cGridSizeZ) then
(
    format "End position is out of cGrid bounds.\n"
    -- return undefined
)

startNode = getNode startcGrid[1] startcGrid[2] startcGrid[3]
endNode   = getNode endcGrid[1]   endcGrid[2]   endcGrid[3]

-- Set up A* search.
openSet = #()
closedSet = #()

startNode.g = 0
startNode.h = heuristic startNode endNode
startNode.f = startNode.g + startNode.h
append openSet startNode

foundPath = false

cnt = 0

while cnt < 100000 and openSet.count > 0 do (
    cnt += 1
    if mod cnt 1000 == 0 do print(cnt)
    -- Find the node in openSet with the lowest f cost.
    current = openSet[1]
    for n in openSet do (
        if n.f < current.f then current = n
    )
    if current == endNode then (
        foundPath = true
        -- exit
    )
    deleteItem openSet (findItem openSet current)
    append closedSet current

    -- 6–directional neighbors (x±1, y±1, z±1)
    neighborOffsets = #([1,0,0], [-1,0,0], [0,1,0], [0,-1,0], [0,0,1], [0,0,-1])
    for offset in neighborOffsets do (
        ni = current.pos.x + offset[1]
        nj = current.pos.y + offset[2]
        nk = current.pos.z + offset[3]
        if (ni >= 0 and ni < cGridSizeX and nj >= 0 and nj <cGridSizeY and nk >= 0 and nk <cGridSizeZ) then (
            neighbor = getNode ni nj nk
            if neighbor.walkable and (findItem closedSet neighbor == 0) then (
                tentative_g = current.g + 1
                inOpen = (findItem openSet neighbor != 0)
                if (not inOpen) or (tentative_g < neighbor.g) then (
                    neighbor.g = tentative_g
                    neighbor.h = heuristic neighbor endNode
                    neighbor.f = neighbor.g + neighbor.h
                    neighbor.parent = current
                    if (not inOpen) then append openSet neighbor
                )
            )
        )
    )
)

if foundPath then (
    -- Reconstruct the path from end to start.
    path = #()
    n = endNode
    while n != undefined do (
        append path n
        n = n.parent
    )
    -- path = reverse path

    pv = path[1]
    for p in path do(
        drawline pv.worldPos p.worldPos green
        pv = p
    )

    format "Path found with % nodes:\n" path.count
    for n in path do (
        format "cGrid node: %\n" n.pos
    )
) else (
    format "No path found.\n"
)
