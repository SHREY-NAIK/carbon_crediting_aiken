
### TX 1 - Registry 
Inputs:
- Enough ADA to cover create registry and tx fees.

Outputs:
- UTxO with registry Information of carbon credit holders, customers and verifiers.

Conditions:
- There must be a datum that contains the registry information.
- The creation of the Registry token requires the signature of the Registry creator.
- Redeemer to update, delete Registry information.
 
### TX 2 - Minting
Inputs:
- utxo from carbon credit holders, customers wallet

Outputs:
- Tokens back to him 

Conditions:
- Only carbon credit holders, customers are allowed to mint tokens.


### TX 3 - offsetting and minting nft
-multi-sig from verifiers
-Only carbon credit holders, customers are allowed to offset tokens.
-successful offset will receive nft



