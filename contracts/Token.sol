//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CRToken is ERC20, Ownable{
    bool public minting = true;
    mapping (address => bool) public blockedAccounts ;
    constructor() ERC20("CRToken", "CRT") public {
        
    } 
    function mint(address to, uint256 amount) public onlyOwner canMint {
        _mint(to, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(isBlocked(from) == false);
    }
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    

function blockAccount(address _account) public onlyOwner {
    blockedAccounts[_account] = true;
}


function unblockAccount(address _account) public onlyOwner { 
    blockedAccounts[_account] = false;
}
function isBlocked(address _account) public view returns (bool result) {
    return(blockedAccounts[_account] == true); 
}

modifier onlyNotBlocked(address _from) { 
    require(blockedAccounts[_from] == false);
    _; 
}
//todo:
//create fuction to stop any one from finishMinting
function finishMinting() public onlyOwner returns (bool) {
    minting = false;
    return true;
}
modifier canMint(){
    require(minting == true);
    _;
}
}