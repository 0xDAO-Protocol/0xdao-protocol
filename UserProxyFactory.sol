// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./interfaces/IUserProxy.sol";
import "./interfaces/IUserProxyInterface.sol";
import "./UserProxy.sol";
import "./ProxyImplementation.sol";

/**
 * @title UserProxyFactory
 * @author 0xDAO
 * @notice Factory responsible for generating new user proxies
 * @dev Keeps track of user proxy addresses and mappings
 */
contract UserProxyFactory is ProxyImplementation {
    /*******************************************************
     *                     Configuration
     *******************************************************/

    // Template
    address public userProxyTemplateAddress;

    // UserProxy mapping variables
    mapping(address => address) public userProxyByAccount;
    mapping(uint256 => address) public userProxyByIndex;
    mapping(address => bool) public isUserProxy;
    uint256 public userProxiesLength;

    // oxLens
    address public oxLensAddress;

    // UserProxyInterface
    address public userProxyInterfaceAddress;

    // Implementations
    address[] public implementationsAddresses;

    // Constructor
    /**
     * @dev Since this is meant to be a proxy's implementation, DO NOT implement logic in this constructor, use initializeProxyStorage() instead
     */
    constructor(
        address _userProxyTemplateAddress,
        address[] memory _implementationsAddresses
    ) {
        initializeProxyStorage(
            _userProxyTemplateAddress,
            _implementationsAddresses
        );
    }

    /**
     * @notice Initializes proxy contract storage with what's supposed to be done in the constructor
     * @dev Don't forget to include logic from parent contracts' constructors as well
     */
    function initializeProxyStorage(
        address _userProxyTemplateAddress,
        address[] memory _implementationsAddresses
    ) public checkProxyInitialized {
        userProxyTemplateAddress = _userProxyTemplateAddress;
        implementationsAddresses = _implementationsAddresses;
    }

    /**
     * @notice Initialize
     * @param _userProxyInterfaceAddress Address of user proxy interface
     * @param _salt to avoid hash collision with proxy's initialize()
     */
    function initialize(address _userProxyInterfaceAddress, bool _salt)
        external
    {
        require(userProxyInterfaceAddress == address(0), "Already initialized");
        userProxyInterfaceAddress = _userProxyInterfaceAddress;
        oxLensAddress = IUserProxyInterface(userProxyInterfaceAddress)
            .oxLensAddress();
    }

    /**
     * @notice Create and or get a user's proxy
     * @param accountAddress Address for which to build or fetch the proxy
     */
    function createAndGetUserProxy(address accountAddress)
        public
        returns (address)
    {
        // Only create proxies if they don't exist already
        bool userProxyExists = userProxyByAccount[accountAddress] != address(0);
        if (!userProxyExists) {
            require(
                msg.sender == userProxyInterfaceAddress,
                "Only UserProxyInterface can register new user proxies"
            );
            address userProxyAddress = address(
                new UserProxy(userProxyTemplateAddress, accountAddress)
            );

            // Set initial implementations
            IUserProxy(userProxyAddress).initialize(
                accountAddress,
                userProxyInterfaceAddress,
                oxLensAddress,
                implementationsAddresses
            );

            // Update proxies mappings
            userProxyByAccount[accountAddress] = userProxyAddress;
            userProxyByIndex[userProxiesLength] = userProxyAddress;
            userProxiesLength++;
            isUserProxy[userProxyAddress] = true;
        }
        return userProxyByAccount[accountAddress];
    }
}
