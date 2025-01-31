import heapq

def find_least_complicated_path(layers, start, end, cost_fn, vertical_cost, turn_penalty):
    """
    Find the least complicated path for a crane moving through layered construction space.
    
    Args:
        layers (list of 2D lists): Each layer is a grid where True indicates unblocked.
        start (tuple): (x, y, z) starting position.
        end (tuple): (x, y, z) target position.
        cost_fn (function): Function taking z (layer) and returning horizontal movement cost.
        vertical_cost (int): Cost for moving vertically between layers.
        turn_penalty (int): Penalty for changing direction.
    
    Returns:
        list: Path as a list of (x, y, z) tuples, or None if no path exists.
    """
    # Directions: north, south, east, west, up, down. none for start.
    dirs = {
        'north': (-1, 0, 0),
        'south': (1, 0, 0),
        'east': (0, 1, 0),
        'west': (0, -1, 0),
        'up': (0, 0, 1),
        'down': (0, 0, -1),
        'none': (0, 0, 0)
    }
    
    # Initialize priority queue and cost dictionary
    heap = []
    heapq.heappush(heap, (0, start[0], start[1], start[2], 'none'))
    cost_so_far = {}
    cost_so_far[(start[0], start[1], start[2], 'none')] = 0
    came_from = {}
    
    max_z = len(layers) - 1  # Assuming layers[0] is z=0 or z=1?
    
    while heap:
        current_cost, x, y, z, last_dir = heapq.heappop(heap)
        
        # Check if current position is the end
        if (x, y, z) == end:
            # Reconstruct path
            path = []
            current_state = (x, y, z, last_dir)
            while current_state in came_from:
                x, y, z, _ = current_state
                path.append((x, y, z))
                current_state = came_from[current_state]
            x0, y0, z0, _ = current_state
            path.append((x0, y0, z0))
            path.reverse()
            return path
        
        # Generate possible moves
        for next_dir in dirs:
            dx, dy, dz = dirs[next_dir]
            new_x = x + dx
            new_y = y + dy
            new_z = z + dz
            
            # Check if move is valid
            if dz == 0:
                # Horizontal move
                if new_z < 0 or new_z >= len(layers):
                    continue
                if (new_x < 0 or new_x >= len(layers[new_z]) or
                    new_y < 0 or new_y >= len(layers[new_z][0])):
                    continue
                if not layers[new_z][new_x][new_y]:
                    continue  # Blocked cell
            else:
                # Vertical move (same x, y)
                new_x = x
                new_y = y
                if new_z < 0 or new_z >= len(layers):
                    continue
                if not layers[new_z][new_x][new_y]:
                    continue  # Blocked cell
            
            # Calculate new cost
            if dz == 0:
                move_cost = cost_fn(z)  # Horizontal cost in current layer
            else:
                move_cost = vertical_cost
            
            turn_cost = turn_penalty if (next_dir != last_dir and last_dir != 'none') else 0
            new_total_cost = current_cost + move_cost + turn_cost
            
            # Check if new state is better
            new_state = (new_x, new_y, new_z, next_dir)
            if (new_state not in cost_so_far or new_total_cost < cost_so_far[new_state]):
                cost_so_far[new_state] = new_total_cost
                heapq.heappush(heap, (new_total_cost, new_x, new_y, new_z, next_dir))
                came_from[new_state] = (x, y, z, last_dir)
    
    return None  # No path found

# Example usage:
# Define layers (0 is lowest, 1 is higher, etc.)
layers = [
    # Layer 0 (lowest, more buildings)
    [
        [True, True, False, True],
        [True, False, False, True],
        [True, True, True, True]
    ],
    # Layer 1 (higher, fewer buildings)
    [
        [True, True, True, True],
        [True, True, True, True],
        [True, True, True, True]
    ]
]

start = (0, 0, 0)
end = (2, 3, 0)
cost_fn = lambda z: 5 - z * 2  # Higher layers have lower cost
vertical_cost = 3  # Cost to move vertically
turn_penalty = 2   # Penalty for changing direction

path = find_least_complicated_path(layers, start, end, cost_fn, vertical_cost, turn_penalty)
print("Path:", path)