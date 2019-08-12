pragma solidity ^0.5.0;

import "../token/ERC20/SafeERC20.sol";
import "../ownership/Ownable.sol";
import "../math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract QTChainVesting is Ownable {
  // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
  // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
  // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
  // cliff period of a year and a duration of four years, are safe to use.
  // solhint-disable not-rely-on-time

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);

  // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
  uint256 constant private _firstMonthPercentage = 10;
  uint256 constant private _otherMonthlyPercentage = 15;
  uint256 constant private _hundred = 100;
  uint256 constant private _oneMonth = 30 days;
  uint256 constant private _duration = 180 days;
  uint256 private _start;
  IERC20 private _token;
  mapping(address => uint256) private _released;
  mapping(address => uint256) private _lockBalance;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * beneficiary, gradually in a linear fashion until start + duration. By then all
   * of the balance will have vested.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
   * @param start the time (as Unix time) at which point vesting starts
   * @param duration duration in seconds of the period in which the tokens will vest
   * @param revocable whether the vesting is revocable or not
   */
  constructor (IERC20 token, uint256 start) public {
    require(start > block.timestamp, "TokenVesting: start time is before current time");
    _token = token;
    _start = start;
  }

  /**
   * @return the start time of the token vesting.
   */
  function start() public view returns (uint256) {
    return _start;
  }

  /**
   * @return the amount of the token released.
   */
  function released(address beneficiary) public view returns (uint256) {
    return _released[beneficiary];
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(address beneficiary) public {
    uint256 unreleased = _releasableAmount(beneficiary);

    require(unreleased > 0, "TokenVesting: no tokens are due");

    _released[beneficiary] = _released[beneficiary].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit TokensReleased(beneficiary, unreleased);
  }


  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function _releasableAmount(address beneficiary) public view returns (uint256) {
    return _vestedAmount(beneficiary).sub(_released[beneficiary]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function _vestedAmount(address beneficiary) public view returns (uint256) {
    uint256 totalBalance = _lockBalance[beneficiary];
    return totalBalance.mul(currentPercentage()).div(_hundred);
  }

  /**
   * @dev Calculates the percentage that has already vested.
   */
  function _currentPercentage() public view returns (uint256) {
    if (block.timestamp < _start) {
      return 0;
    } else if (block.timestamp < _start.add(_oneMonth)) {
      return _firstMonthPercentage;
    } else if (block.timestamp >= _start.add(_duration)) {
      return _hundred;
    } else {
      uint256 periods = block.timestamp.sub(_start).sub(_oneMonth).div(_oneMonth);
      uint256 increasePercent = periods.mul(_otherMonthlyPercentage).add(_otherMonthlyPercentage);
      return _firstMonthPercentage.add(increasePercent);
    }
  }
}
