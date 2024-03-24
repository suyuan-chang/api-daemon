#!/bin/bash

set -e -x

echo "Generating bindings for target $TARGET"

mkdir -p src/generated

INCPATH="-I ./libsignal-protocol-c/src/"

if [ "${TARGET}" != "x86_64-unknown-linux-gnu" ];
then
    INCPATH="${INCPATH} -I ${SYS_INCLUDE_DIR}"
fi

bindgen --allowlist-function "signal_context_create" \
        --allowlist-function "signal_context_destroy" \
        --allowlist-function "signal_context_set_crypto_provider" \
        --allowlist-function "signal_context_set_log_function" \
        --allowlist-function "signal_context_set_locking_functions" \
        --allowlist-function "signal_protocol_key_helper_generate_registration_id" \
        --allowlist-function "signal_protocol_key_helper_generate_identity_key_pair" \
        --allowlist-function "signal_protocol_key_helper_generate_pre_keys" \
        --allowlist-function "signal_protocol_key_helper_key_list_free" \
        --allowlist-function "signal_protocol_key_helper_generate_signed_pre_key" \
        --allowlist-function "ratchet_identity_key_pair_create" \
        --allowlist-function "ratchet_identity_key_pair_destroy" \
        --allowlist-function "session_pre_key_destroy" \
        --allowlist-function "signal_protocol_key_helper_generate_sender_signing_key" \
        --allowlist-function "ec_key_pair_destroy" \
        --allowlist-function "signal_protocol_key_helper_generate_sender_key" \
        --allowlist-function "signal_buffer_create" \
        --allowlist-function "signal_buffer_free" \
        --allowlist-function "signal_protocol_key_helper_generate_sender_key_id" \
        --allowlist-function "signal_protocol_store_context_create" \
        --allowlist-function "signal_protocol_store_context_set_session_store" \
        --allowlist-function "signal_protocol_store_context_set_pre_key_store" \
        --allowlist-function "signal_protocol_store_context_set_signed_pre_key_store" \
        --allowlist-function "signal_protocol_store_context_set_identity_key_store" \
        --allowlist-function "signal_protocol_store_context_set_sender_key_store" \
        --allowlist-function "signal_protocol_store_context_destroy" \
        --allowlist-function "session_builder_create" \
        --allowlist-function "session_builder_process_pre_key_bundle" \
        --allowlist-function "session_builder_free" \
        --allowlist-function "session_pre_key_bundle_create" \
        --allowlist-function "session_pre_key_bundle_destroy" \
        --allowlist-function "curve_generate_key_pair" \
        --allowlist-function "ec_key_pair_get_public" \
        --allowlist-function "session_cipher_create" \
        --allowlist-function "session_cipher_free" \
        --allowlist-function "session_cipher_encrypt" \
        --allowlist-function "session_cipher_decrypt_pre_key_signal_message" \
        --allowlist-function "session_cipher_decrypt_signal_message" \
        --allowlist-function "session_cipher_set_decryption_callback" \
        --allowlist-function "session_cipher_get_remote_registration_id" \
        --allowlist-function "ratchet_identity_key_pair_destroy" \
        --allowlist-function "ciphertext_message_destroy" \
        --allowlist-function "pre_key_signal_message_deserialize" \
        --allowlist-function "pre_key_signal_message_destroy" \
        --allowlist-function "signal_message_deserialize" \
        --allowlist-function "signal_message_destroy" \
        --allowlist-function "curve_calculate_agreement" \
        --allowlist-function "curve_verify_signature" \
        --allowlist-function "curve_calculate_signature" \
        --allowlist-function "curve_decode_point" \
        --allowlist-function "signal_int_list_alloc" \
        --allowlist-function "signal_int_list_push_back" \
        --allowlist-function "group_session_builder_create" \
        --allowlist-function "group_session_builder_free" \
        --allowlist-function "group_session_builder_create_session" \
        --allowlist-function "group_session_builder_process_session" \
        --allowlist-function "sender_key_distribution_message_deserialize" \
        --allowlist-function "sender_key_distribution_message_destroy" \
        --allowlist-function "ciphertext_message_get_serialized" \
        --allowlist-function "sender_key_message_deserialize" \
        --allowlist-function "sender_key_message_destroy" \
        --allowlist-function "group_cipher_create" \
        --allowlist-function "group_cipher_free" \
        --allowlist-function "group_cipher_encrypt" \
        --allowlist-function "group_cipher_decrypt" \
        --allowlist-function "group_cipher_set_decryption_callback" \
        --allowlist-type "ciphertext_message" \
        --allowlist-type "pre_key_signal_message" \
        --allowlist-type "signal_message" \
        --allowlist-type "signal_type_base" \
        --allowlist-type "signal_protocol_key_helper_pre_key_list_node" \
        --allowlist-type "ec_public_key" \
        --allowlist-type "ec_private_key" \
        --allowlist-type "ec_key_pair" \
        --allowlist-type "session_pre_key" \
        --allowlist-type "sender_key_distribution_message" \
        --blocklist-type "session_signed_pre_key" \
        --blocklist-type "signal_buffer" \
        --blocklist-type "__uint8_t" \
        --blocklist-type "__int32_t" \
        --blocklist-type "__uint32_t" \
        --blocklist-type "__uint64_t" \
        --output src/generated/ffi.rs \
        --no-layout-tests \
        --with-derive-default \
        wrapper.h \
        -- ${INCPATH}

# Add a #[allow(non_camel_case_types)] to silence warning for size_t

echo "#[allow(non_camel_case_types)]" > src/generated/ffi_.rs
cat src/generated/ffi.rs >> src/generated/ffi_.rs
cat custom-types.rs >> src/generated/ffi_.rs
mv src/generated/ffi_.rs src/generated/ffi.rs
