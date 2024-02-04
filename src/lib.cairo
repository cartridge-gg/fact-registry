use cairo_verifier::deserialization::stark::StarkProofWithSerde;

mod component;

#[starknet::interface]
trait IFactRegistry<TContractState> {
    fn verify_and_register_fact(ref self: TContractState, stark_proof: StarkProofWithSerde);
    fn is_valid(self: @TContractState, fact: felt252) -> bool;
}

enum ProofState {
    NotFound,
    Pending,
    Verified,
}
impl ProofStateDefault of Default<ProofState> {
    fn default() -> Self {
        ProofState::NotFound
    }
}

#[starknet::contract]
mod FactRegistry {
    use cairo_verifier::{
        deserialization::stark::StarkProofWithSerde, stark::{StarkProof, StarkProofTrait},
    };
    use core::poseidon::{Poseidon, PoseidonImpl, HashStateImpl};

    #[storage]
    struct Storage {
        facts: LegacyMap<felt252, ProofState>,
    }

    #[abi(embed_v0)]
    impl FactRegistryImpl of super::IFactRegistry<ContractState> {
        fn register_fact(ref self: @ContractState, fact: felt252) {
            self.facts.write(fact, ProofState::Pending);
        }
        fn verify_and_register_fact(ref self: ContractState, stark_proof: StarkProofWithSerde) {
            let stark_proof: StarkProof = stark_proof.into();
            let (program_hash, program_output_hash) = stark_proof.verify();
            let fact = PoseidonImpl::new()
                .update(program_hash)
                .update(program_output_hash)
                .finalize();
            self.facts.write(fact, ProofState::Verified);
        }
        fn is_valid(self: @ContractState, fact: felt252) -> ProofState {
            self.facts.read(fact)
        }
    }
}
