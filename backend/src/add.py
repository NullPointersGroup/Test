from beartype import beartype

@beartype
def add(x: int, y: int) -> int:
   """
   @brief Brief description
   @param Type Description
   @raise ExceptionType Condition or description
   @bug  actual problems
   @return Type Description
   @req RF-OB_02
   """
   print("Ciao")
   return x + y

def subtract(x: int, y: int) -> int:
   """
   @brief Brief description
   @param Type Description
   @raise ExceptionType Condition or description
   @bug  actual problems
   @return Type Description
   @req RF-OB-3
   """
   print("Ciao")
   return x - y