// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^2.0.0-alpha.0

const UPGRADER_ROLE: felt252 = selector!("UPGRADER_ROLE");

use starknet::ContractAddress;
#[starknet::interface]
pub trait IAgent<TContractState> {
    fn create(ref self: TContractState, to: ContractAddress, amount: u256, uri: ByteArray);
    fn update_liveness(ref self: TContractState, token_id: u256, calls_count: u256, msg_count: u256);
    fn update_token_metadata_uri(ref self: TContractState, token_id: u256, new_uri: ByteArray);
    fn die(ref self: TContractState, token_id: u256);
}

#[starknet::contract]
mod AIAssassins {
    use AccessControlComponent::Errors;
use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::{ClassHash, ContractAddress, storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess}};
    use super::UPGRADER_ROLE;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // External
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlCamelImpl = AccessControlComponent::AccessControlCamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlWithDelayImpl = AccessControlComponent::AccessControlWithDelayImpl<ContractState>;

    // Internal
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        counter: u256, // Added counter variable
        token_metadata: Map<u256, (ByteArray, bool, u256, u256)>, // Added mapping of u256 to ByteArray
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        NewAgent: AgentInfo,
    }

    #[derive(Drop, starknet::Event)]
    pub struct AgentInfo {
        pub token_id: u256,
        pub token_uri: ByteArray,
        pub alive: bool,
        pub calls_count: u256,
        pub msg_count: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        default_admin: ContractAddress,
        upgrader: ContractAddress,
    ) {
        self.erc721.initializer("AIAssassins", "AIA", "https://orange-quiet-toad-977.mypinata.cloud");
        self.accesscontrol.initializer();

        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(UPGRADER_ROLE, upgrader);
    }

    // Override the mint function
    #[abi(embed_v0)]
    impl AgentImpl of super::IAgent<ContractState> {
        fn create(ref self: ContractState, to: ContractAddress, amount: u256, uri: ByteArray) {
            let token_id = self.counter.read();
            self.erc721.mint(to, amount);
            self.token_metadata.write(token_id, (uri, false, 0, 0));
            self.counter.write(token_id + 1);
            let (curi, _, _, _) = self.token_metadata.read(token_id);

            self.emit(AgentInfo {
                token_id,
                token_uri: curi,
                alive: false,
                calls_count: 0,
                msg_count: 0,
            });
        }

        fn die(ref self: ContractState, token_id: u256) {
            let owner = self.erc721.owner_of(token_id);
            let caller = starknet::get_caller_address();
            assert(owner == caller, Errors::INVALID_CALLER);

            self.token_metadata.write(token_id, ("", false, 0, 0));
            self.erc721.burn(token_id);
        }

        fn update_token_metadata_uri(ref self: ContractState, token_id: u256, new_uri: ByteArray) {
            let owner = self.erc721.owner_of(token_id);
            let caller = starknet::get_caller_address();
            assert(owner == caller, Errors::INVALID_CALLER);

            let (_, alive, c1, c2) = self.token_metadata.read(token_id);
            self.token_metadata.write(token_id, (new_uri, alive, c1, c2));

            let (curi, alive, calls, msg) = self.token_metadata.read(token_id);
            self.emit(AgentInfo {
                token_id,
                token_uri: curi,
                alive: alive,
                calls_count: calls,
                msg_count: msg,
            });
        }

        fn update_liveness(ref self: ContractState, token_id: u256, calls_count: u256, msg_count: u256) {
            let owner = self.erc721.owner_of(token_id);
            let caller = starknet::get_caller_address();
            assert(owner == caller, Errors::INVALID_CALLER);

            let (uri, _, _calls_count, _msg_count) = self.token_metadata.read(token_id);

            assert(calls_count > _calls_count || msg_count > _msg_count, Errors::ALREADY_EFFECTIVE);

            self.token_metadata.write(token_id, (uri, true, calls_count, msg_count));
        }
    }

    #[abi(embed_v0)]
    fn get_token_metadata_uri(ref self: ContractState, token_id: u256) -> ByteArray {
        let (uri, alive, _, _) = self.token_metadata.read(token_id);
        if alive {
            return uri;
        } else {
            return "";
        }
    }

    #[abi(embed_v0)]
    fn is_alive(ref self: ContractState, token_id: u256) -> (bool, u256, u256) {
        let (_, alive, c_count, m_count) = self.token_metadata.read(token_id);
        return (alive, c_count, m_count);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.accesscontrol.assert_only_role(UPGRADER_ROLE);
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
