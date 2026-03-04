import { useState } from 'react'

export default function Counter() {
  /**
  @brief Brief description
  @param Type Description
  @raise ExceptionType Condition or description
  @bug  actual problems
  @return Type Description
  @req RF-OB_1
   */
  const [count, setCount] = useState(0)

  return (
    <div className="card bg-sky-400">
      <button onClick={() => setCount((c) => c + 1)}>
        count is {count}
      </button>
    </div>
  )
}