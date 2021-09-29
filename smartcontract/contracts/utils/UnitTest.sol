pragma solidity >=0.6.0 <0.8.0;

contract UnitTest {
    int value;

    function InvokeRequireMessage(int i ) public{
        require(false, "Require is triggered");
        value = i;
    }

    function SetValue(int i ) public {
        value = i;
    }

}