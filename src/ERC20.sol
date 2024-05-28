// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

interface IPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.8.23;

//  _____  _    ____
// |_   _|/ \  | __ )
//   | | / _ \ |  _ \
//   | |/ ___ \| |_) |
//   |_/_/   \_\____/
//
// Twitter: https://twitter.com/TABerc20
// Website: https://www.tabbot.io/
// Community Telegram: https://t.me/TABPortal
// Tab Telegram Bot: https://t.me/AITradingAssistantBot
// Gitbook: https://tab-1.gitbook.io/tab

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TAB is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private swapping;
    bool public tradingEnabled;
    bool internal limits = true;

    address public taxWallet;

    uint256 public maxTxAmount;
    uint256 public maxHoldingAmount;
    uint8 public totalBuyTax;
    uint8 public totalSellTax;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event FeesCollected(uint256 indexed amount);

    constructor(
        address _taxWallet,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _buyTax,
        uint256 _sellTax,
        uint256 _caTokens
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(taxWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        uint256 ownerSupply = _maxSupply - _caTokens;
        _mint(owner(), ownerSupply * (10 ** 18));
        if (_caTokens > 0) _mint(address(this), _caTokens * (10 ** 18));
    }

    receive() external payable {}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Fuk: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function updateTaxes(
        uint8 _totalBuyTax,
        uint8 _totalSellTax
    ) external onlyOwner {
        require(
            _totalBuyTax <= 20 && _totalSellTax <= 20,
            "Cannot set taxes higher than 20%"
        );
        totalBuyTax = _totalBuyTax;
        totalSellTax = _totalSellTax;
    }

    function renounceOwnership() public virtual override {
        totalBuyTax = 4;
        totalSellTax = 4;
        super.renounceOwnership();
    }

    function removeLimits() external onlyOwner {
        limits = false;
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IRouter(newRouter);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(
        address newPair,
        bool value
    ) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "FS: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!_isExcludedFromFees[from] && limits) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

            if (automatedMarketMakerPairs[from])
                require(
                    balanceOf(to) + amount <= maxHoldingAmount,
                    "Max holding amount"
                );
        }

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 swapAmount = contractTokenBalance > amount
            ? amount
            : contractTokenBalance;

        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapAndLiquify(swapAmount);
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 100;
            else if (automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 100;

            amount = amount - feeAmt;
            super._update(from, address(this), feeAmt);
        }

        super._update(from, to, amount);
    }

    function swapAndLiquify(uint256 tokens) private {
        if (tokens > 0) {
            uint256 ETHbalance = swapTokensForETH(tokens);
            emit FeesCollected(ETHbalance);
        }
    }

    function swapTokensForETH(
        uint256 tokenAmount
    ) private returns (uint256 ETHbalance) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        ETHbalance = address(this).balance;
        payable(taxWallet).sendValue(ETHbalance);

        return ETHbalance;
    }
}
