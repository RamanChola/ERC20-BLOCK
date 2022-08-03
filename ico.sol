// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract Block is ERC20Interface {
    string public name = "Block"; //name of the token string public symbol ="BLK";

    string public decimal = "0";
    uint256 public override totalSupply;
    address public founder;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        totalSupply = 100000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        virtual
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens; //balances[to]=balances[to]+tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 noOfTokens)
    {
        return allowed[tokenOwner][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual override returns (bool success) {
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        balances[to] += tokens;
        return true;
    }
}

contract ICO is Block {
    address public manager;
    address payable public deposit;

    uint256 tokenPrice = 0.1 ether;

    uint256 public cap = 300 ether;

    uint256 public raisedAmount;

    uint256 public icoStart = block.timestamp;
    uint256 public icoEnd = block.timestamp + 3600; //1 hour=60*60 seconds;

    uint256 public tokenTradeTime = icoEnd + 3600;

    uint256 public maxInvest = 10 ether;
    uint256 public minInvest = 0.1 ether;

    enum State {
        beforeStart,
        afterEnd,
        running,
        halted
    }

    State public icoState;

    event Invest(address investor, uint256 value, uint256 tokens);

    constructor(address payable _deposit) {
        deposit = _deposit;
        manager = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyManger() {
        require(msg.sender == manager);
        _;
    }

    function halt() public onlyManger {
        icoState = State.halted;
    }

    function resume() public onlyManger {
        icoState = State.running;
    }

    function changeDepositAddr(address payable newDeposit) public onlyManger {
        deposit = newDeposit;
    }

    function getState() public view returns (State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < icoStart) {
            return State.beforeStart;
        } else if (block.timestamp >= icoStart && block.timestamp <= icoEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    function invest() public payable returns (bool) {
        icoState = getState();
        require(icoState == State.running);
        require(msg.value >= minInvest && msg.value <= maxInvest);

        raisedAmount += msg.value;

        require(raisedAmount <= cap);

        uint256 tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);
        return true;
    }

    function burn() public returns (bool) {
        icoState = getState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }

    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(block.timestamp > tokenTradeTime);
        super.transfer(to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        require(block.timestamp > tokenTradeTime);
        Block.transferFrom(from, to, tokens);
        return true;
    }

    receive() external payable {
        invest();
    }
}
