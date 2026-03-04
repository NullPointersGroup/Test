import pytest
from beartype.roar import BeartypeCallHintParamViolation
from add import add, subtract

def test_add() -> None:
   assert add(2,3)==5
   with pytest.raises(BeartypeCallHintParamViolation):
      add("a", 5)
   assert add (2,4) != 5
   
def test_subtract() -> None:
   assert subtract(2,3)==-1
   with pytest.raises(BeartypeCallHintParamViolation):
      add("a", 5)
   assert add (2,4) != 5