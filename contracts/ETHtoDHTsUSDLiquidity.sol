//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract ETHtoDHTsUSDLiquidity {
    using SafeMath for uint256;
    
    address constant ETH = address(0);
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant sUSD = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    address constant DHT = address(0xca1207647Ff814039530D7d35df0e1Dd2e91Fa84);
    address constant SNX = address(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    address constant sUSD_DHT_LP = address(0x303ffcD201831DB88422b76f633458e94E05C33e);
    address constant UniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    receive() payable external {}
    
    function deposit() public payable {
        require(msg.sender.balance >= msg.value, "You do not have enough ETH.");
        
        IUniswapV2Router02 uniswap = IUniswapV2Router02(UniswapRouter);
        IERC20 DHT_ERC20 = IERC20(DHT);
        IERC20 sUSD_ERC20 = IERC20(sUSD);
        IERC20 sUSD_DHT_LP_ERC20 = IERC20(sUSD_DHT_LP);

        address[] memory WETH_to_DHT = new address[](2);
        WETH_to_DHT[0] = WETH;
        WETH_to_DHT[1] = DHT;
        
        uniswap.swapExactETHForTokens{value: msg.value}(1, WETH_to_DHT, address(this), now + 100000);
        
        DHT_ERC20.approve(UniswapRouter, DHT_ERC20.balanceOf(address(this)));
        
        address[] memory DHT_to_sUSD = new address[](2);
        DHT_to_sUSD[0] = DHT;
        DHT_to_sUSD[1] = sUSD;
        
        uniswap.swapExactTokensForTokens(DHT_ERC20.balanceOf(address(this)).div(2), 0, DHT_to_sUSD, address(this), now + 100000);
        
        sUSD_ERC20.approve(UniswapRouter, sUSD_ERC20.balanceOf(address(this)));
        
        uniswap.addLiquidity(sUSD, DHT, sUSD_ERC20.balanceOf(address(this)), DHT_ERC20.balanceOf(address(this)), 0, 0, address(this), now + 100000);
        
        sUSD_DHT_LP_ERC20.transfer(msg.sender, sUSD_DHT_LP_ERC20.balanceOf(address(this)));
    }
    
    
    function withdraw(uint256 _amount) public payable {
        IUniswapV2Router02 uniswap = IUniswapV2Router02(UniswapRouter);
        IERC20 DHT_ERC20 = IERC20(DHT);
        IERC20 sUSD_ERC20 = IERC20(sUSD);
        IERC20 sUSD_DHT_LP_ERC20 = IERC20(sUSD_DHT_LP);
        
        require(sUSD_DHT_LP_ERC20.balanceOf(msg.sender) >= _amount, "Not enough liqudity to remove.");
        
        sUSD_DHT_LP_ERC20.transferFrom(msg.sender, address(this), _amount);
        sUSD_DHT_LP_ERC20.approve(UniswapRouter, _amount);
        uniswap.removeLiquidity(sUSD, DHT, _amount, 0, 0, address(this), now + 100000);
        
        address[] memory DHT_to_WETH = new address[](2);
        DHT_to_WETH[0] = DHT;
        DHT_to_WETH[1] = WETH;
        
        DHT_ERC20.approve(UniswapRouter, DHT_ERC20.balanceOf(address(this)));
        uniswap.swapExactTokensForETH(DHT_ERC20.balanceOf(address(this)), 0, DHT_to_WETH, address(this), now + 100000);
        
        address[] memory sUSD_to_WETH = new address[](2);
        sUSD_to_WETH[0] = sUSD;
        sUSD_to_WETH[1] = WETH;
        
        sUSD_ERC20.approve(UniswapRouter, sUSD_ERC20.balanceOf(address(this)));
        uniswap.swapExactTokensForETH(sUSD_ERC20.balanceOf(address(this)), 0, sUSD_to_WETH, address(this), now + 100000);
        
        msg.sender.transfer(address(this).balance);
    }
    
}