#register customer
cardano-cli transaction build \
--conway-era \
--testnet-magic 2 \
--tx-in $UTXO_IN \
--tx-out $CONTRACT_ADDRESS+$LOVELACE_TO_SEND \
--change-address $CUSTOMERADDRESS \
--tx-out-inline-datum-file CustomerDatum.json \
--out-file simple-tx.raw

#register verifier
cardano-cli transaction build \
--conway-era \
--testnet-magic 2 \
--tx-in $UTXO_IN \
--tx-out $CONTRACT_ADDRESS+$LOVELACE_TO_SEND \
--change-address $CUSTOMERADDRESS \
--tx-out-inline-datum-file verifierDatum.json \
--out-file simple-tx.raw


#register creditholder
cardano-cli transaction build \
--conway-era \
--testnet-magic 2 \
--tx-in $UTXO_IN \
--tx-out $CONTRACT_ADDRESS+$LOVELACE_TO_SEND \
--change-address $CUSTOMERADDRESS \
--tx-out-inline-datum-file creditholderDatum.json \
--out-file simple-tx.raw


#perchase token
--tx-in $customerutxo
--tx-in $collateral
--tx-out-inline-datum-file $DATUM_FILE \
--tx-out $CHADDRESS
--tx-out $customerADDRESS+ 2000000 + $TOKENS_FROM_FAUCET $FAUCET_ASSET\
--change-address $customerADDRESS \
--protocol-params-file protocol.json \
--out-file test.draft



#mint token
cardano-cli transaction build \
  --comway-era \
  --testnet-magic 2 \
  --tx-in $creditholder_utxo \
  --tx-out $creditholder_addr+"2000000 + $quantity $policy_id.$token_hex" \
  --mint "$quantity $policy_id.$token_hex" \
  --mint-script-file $mint_script_file_path \
  --change-address $creditholder_addr \
  --required-signer $mint_signing_key_file_path \
  --out-file mint-nft.draft





#burn token
cardano-cli transaction build \
  --comway-era \
  --testnet-magic 2 \
  --tx-in $customer_utxo \
  --tx-out $customer_addr+"2000000 + $-quantity $policy_id.$token_hex" \
  --mint "-$quantity $policy_id.$token_hex" \
  --mint-script-file $mint_script_file_path \
  --change-address $customer_addr \
  --required-signer $mint_signing_key_file_path \
  --out-file mint-nft.draft


#mint nft
cardano-cli transaction build \
  --conway-era \
  --testnet-magic 2 \
  --tx-in $tx_in \
  --tx-out $customer_addr+"2000000 + $quantity $policy_id.$token_hex" \
  --mint "$quantity $policy_id.$token_hex" \
  --mint-script-file $mint_script_file_path \
  --metadata-json-file $name \
  --change-address $customer_addr \
  --required-signer $mint_signing_key_file_path \
  --out-file mint-nft.draft




