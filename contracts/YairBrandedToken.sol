pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract YairBrandedToken is IERC20 {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, string indexed artworkId, uint256 count);

    string public name = "Yair Branded Token";
    string public symbol = "YBT";
    uint8 public decimals = 18;

    // The address of the contract creator
    address internal _creator;

    // the maximum supply on tokens that can be minted
    uint256 _maxSupply;

    // the total of minted tokens
    uint256 _totalSupply;

    // mapping storing the balance of each address
    mapping(address => uint256) internal _balances;

    // mapping storing the balance of each address for specific artwork
    mapping(string => mapping(address => uint256)) internal _balancesPerArtwork;

    // mapping storing the minted tokens for each artwork
    mapping(string => uint256) internal _totalSupplyPerArtwork;

    // A mapping of token owners
    mapping(uint256 => address) internal owners;

    constructor(uint initialSupply, uint256 maxSupply) public {
        require(msg.sender != address(0));
        require(initialSupply <= maxSupply);

        _maxSupply = maxSupply;
        _creator = msg.sender;

        // All initial tokens belong to creator, so set the balance
        _balances[msg.sender] = initialSupply;
    }

    function creator() external view returns (address) {
        return _creator;
    }

    /**
     * @dev returns the total minted token
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev returns the total minted supply of token for a specific artwork
     */
    function totalSupplyPerArtwork(string artworkId) external view returns (uint256) {
        return _totalSupplyPerArtwork[artworkId];
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /*function mintTokenForArtworkId(uint256 count, string artworkId) {
        // Make sure only the contract creator can call this
        require(msg.sender == _creator);
        require(count > 0);
        require(_totalSupply.add(count) < _maxSupply);

        _balances[msg.sender] = _balances[msg.sender].add(count);
        _balancesPerArtwork[artworkId][msg.sender] = _balancesPerArtwork[artworkId][msg.sender].add(count);

        _totalSupply = _totalSupply.add(count);
    }*/

    /**
     * @dev mint tokens for specific artwork and send them to a buyer
     * @param count uint256 The number of how many token will be minted
     * @param artworkId string The artwork ID for which the token will be minted
     * @param buyer address The buyer where the token will be send to
     */
    function mintTokenForArtworkIdAndSendTo(uint256 count, string artworkId, address buyer) {
        // Make sure only the contract creator can call this
        require(msg.sender == _creator);
        require(count > 0);
        require(buyer != address(0));

        // increase the generell token count for buyer
        _balances[buyer] = _balances[buyer].add(count);

        // increase the balances for artwork for the buyer
        _balancesPerArtwork[artworkId][buyer] = _balancesPerArtwork[artworkId][buyer].add(count);

        _totalSupply = _totalSupply.add(count);
        _totalSupplyPerArtwork[artworkId] = _totalSupplyPerArtwork[artworkId].add(count);
    }

    /**
     * @param owner Returns the number of tokens for specific owner
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @param owner the artwork
     * @param owner Returns the number of tokens for specific owner for a specific artwork
     */
    function balancePerArtworkOf(string artworkId, address owner) external view returns (uint256) {
        return _balancesPerArtwork[artworkId][owner];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return false;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        return false;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        return false;
    }

    function transferTokenForArtworkFrom(address from, address to, string artworkId, uint256 count) external returns (bool) {
        require(_isApprovedOrOwner(from, artworkId, count ));
        require(to != address(0));

        _removeTokenForArtworkFrom(from, artworkId, count);
        _addTokenForArtworkTo(to, artworkId, count);

        //emit Transfer(from, to, artworkId, count);
    }

    function _removeTokenForArtworkFrom(address from, string artworkId, uint256 count) internal {
        require(_buyerHoldsAsLeast(from, artworkId, count));
        _balances[from] = _balances[from].sub(count);
        _balancesPerArtwork[artworkId][from] = _balancesPerArtwork[artworkId][from].sub(count);
    }

    function _addTokenForArtworkTo(address to, string artworkId, uint256 count) internal {
        _balances[to] = _balances[to].add(count);
        _balancesPerArtwork[artworkId][to] = _balancesPerArtwork[artworkId][to].add(count);
    }

    /**
     * @dev Returns wether the given spender is allowed to transfer a given count of tokens for a specific artwork
     * @param spender address of the sepnder to query
     * @param artworkId string The specific artwork
     * @param count uint256 The number of token that needs to be approved to send
     * @return bool wether the msg.sender is approved for the given artworkId holding at least the requested number of tokens
     *   or is the creator with at least the required amount of minted token for the artwork
     */
    function _isApprovedOrOwner(address spender, string artworkId, uint256 count) internal view returns (bool) {
        return (
            // the creator is approved always if the specific number of requested tokens was minted currently
            (spender == _creator && _totalSupplyPerArtwork[artworkId] >= count)
            ||
            // or the spender holds a minimum of the minted requested token count
            _buyerHoldsAsLeast(spender, artworkId, count)
        );
    }

    function _buyerHoldsAsLeast(address spender, string artworkId, uint256 count) internal view returns (bool) {
        return _balancesPerArtwork[artworkId][spender] >= count;
    }
}

