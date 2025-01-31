filein "heap.ms"

-- Example usage:
heap = createMinHeap()

-- Push elements
heap.push 10
heap.push 4
heap.push 15
heap.push 1
heap.push 7

format "Pop: %\n" (heap.pop())  -- Should return 1 (smallest element)
format "Pop: %\n" (heap.pop())  -- Next smallest element, e.g. 4