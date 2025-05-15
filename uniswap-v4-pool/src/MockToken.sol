// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockERC20
 * @author Vladyslav gh:Fuga14
 * @notice Same ERC20 mock contract with Pausable, Burnable and Ownable extensions
 */
contract MockToken is ERC20, ERC20Pausable, ERC20Burnable, Ownable {
    /**
     * @notice Token decimals
     */
    uint8 public immutable DECIMALS;

    /**
     * @notice Constructor
     * @param _name The token name
     * @param _symbol The token symbol
     * @param _decimals The token decimals
     * @param _initialSupply The initial token supply
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply)
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        _mint(msg.sender, _initialSupply);
        DECIMALS = _decimals;
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Mints tokens
     * @param _to Address of the recipient
     * @param _amount The amount of tokens to be minted
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns tokens
     * @param _from The address from which the tokens will be burned
     * @param _amount The amount of tokens to be burned
     */
    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // The following function is an override required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
