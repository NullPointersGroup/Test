import pytest
from beartype.roar import BeartypeCallHintParamViolation
from add import add

def test_add() -> None:
   assert add(2,3)==5
   with pytest.raises(BeartypeCallHintParamViolation):
      add("a", 5)
   assert add (2,4) != 5