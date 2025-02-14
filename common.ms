fn getAngle prev p = (	

    if classOf prev != Point3 then(
        flat2_v1 = normalize [prev.world_position.x, prev.world_position.y] 
        flat2_v2 = normalize [p.world_position.x, p.world_position.y]
    )
    else(
        flat2_v1 = normalize [prev.x, prev.y] 
        flat2_v2 = normalize [p.x, p.y]
    )

	local dot_prod = flat2_v1[1] * flat2_v2[1] + flat2_v1[2] * flat2_v2[2]
	
	local mag_a = sqrt ((pow flat2_v1[1] 2) + (pow flat2_v1[2] 2))
	local mag_b = sqrt ((pow flat2_v2[1] 2) + (pow flat2_v2[2] 2))

	local ans = acos (dot_prod/(mag_a * mag_b))
	
	local cross_prod = [0,0,(flat2_v1[1]*flat2_v2[2] - flat2_v2[1]*flat2_v1[2])]	
		
	if cross_prod.z < 0 then return (360 - ans)
	return ans
	
)