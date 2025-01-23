filein "header.ms"

crane = getNodeByName "Teapot001"
pick = getNodeByName "pick"
goals = $l* as array
obs = $Box* as array
clearance = 1.0

getMap crane pick obs goals