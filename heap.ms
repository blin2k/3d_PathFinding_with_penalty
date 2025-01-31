/*
    createMinHeap() 
    Returns a MinHeap struct with:
      - data: An array storing the heap elements
      - push(value): Inserts a new value into the min-heap
      - pop(): Removes and returns the smallest value
*/

fn createMinHeap =
(
    struct MinHeap
    (
        data = #(),  -- Stores heap elements, 1-based indexing
        
        fn push value =
        (
            -- Add the new element at the end of the data array
            append data value
            
            -- Bubble up: move the newly added item up to maintain the heap property
            local idx = data.count
            while (idx > 1) do
            (
                -- Parent index in 1-based array is floor(idx/2)
                local parentIndex = idx / 2
                
                -- If the new item is less than its parent, swap
                if data[idx] < data[parentIndex] then
                (
                    swap data[idx] data[parentIndex]
                    idx = parentIndex
                )
                else
                (
                    exit
                )
            )
        ),
        
        fn pop =
        (
            -- If heap is empty, return undefined
            if data.count == 0 then
            (
                return undefined
            )
            
            -- The root (data[1]) is the smallest element
            local topVal = data[1]
            
            -- Move the last element to the root position
            data[1] = data[data.count]
            deleteItem data data.count  -- Remove the last element
            
            -- Bubble down: push the new root down to maintain heap property
            local idx = 1
            while true do
            (
                local left  = idx * 2
                local right = idx * 2 + 1
                local smallest = idx
                
                -- Compare left child
                if ((left <= data.count) and (data[left] < data[smallest])) do
                    smallest = left
                
                -- Compare right child
                if ((right <= data.count) and (data[right] < data[smallest])) do
                    smallest = right
                
                if smallest != idx then
                (
                    -- Swap root with the smaller child
                    swap data[idx] data[smallest]
                    idx = smallest
                )
                else
                (
                    -- The heap property is satisfied
                    exit
                )
            )
            
            return topVal
        )
    )
    
    MinHeap()
)