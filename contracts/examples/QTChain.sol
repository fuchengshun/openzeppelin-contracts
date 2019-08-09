pragma solidity ^0.5.0;

import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Detailed.sol";
import "../token/ERC20/ERC20Burnable.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract QTChain is ERC20, ERC20Detailed, ERC20Burnable {

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor () public ERC20Detailed("QTChain", "QTC", 18) {
    _mint(msg.sender, 1 * 1e8 * (10 ** uint256(decimals())));
  }
}
