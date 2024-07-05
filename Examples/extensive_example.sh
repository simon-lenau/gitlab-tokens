#!/usr/bin/env bash

# Load package functions
source "../gitlab_tokens/init"

# Get metadata
git_host=$(git_repo_info --type "host")
git_proj=$(git_repo_info --type "project")
git_registry=$(git_repo_info --type "registry")

# =================== > Project access token management < ==================== #
tokenfile="~/credentials/${git_host}/${git_proj}/auto_container_token"

# Check if current token is valid
if ! read_from_file --file="${tokenfile}" | git_token_valid; then
    # The current token is not valid
    #   => create or rotate it
    read_from_file --file "~/credentials/${git_host}/personal_token" |
        git_token_renew \
            --tokenfile "${tokenfile}" \
            --token_scopes=read_registry write_registry read_repository write_repository

    # Check if created token is valid
    if read_from_file --file "${tokenfile}" | git_token_valid; then
        # The created or rotated token is valid
        #   => export it
        export GITLAB_TOKEN=$(read_from_file --file ${tokenfile})
    else
        # Creating or rotating a token failed
        #   => throw error
        err \
            "Docker credentials invalid!" \
            "Please make sure that" \
            "\t$(eval "echo "~/credentials/${git_host}/personal_token"")" \
            "contains a gitlab token with \`api\` scope for" \
            "\t${git_host}" \
            "and/or" \
            "\t$(eval "echo ${tokenfile}")" \
            "contains a token with \`container_registry\` scope for" \
            "\t${git_registry}"
        exit 1
    fi
else
    # Current token is valid
    #   => export it
    export GITLAB_TOKEN=$(read_from_file --file ${tokenfile})
fi

# Provide this repo's job tokens access to containr
read_from_file --file "~/credentials/${git_host}/personal_token" |
    git_token_access \
        --to_project="c01sile/containr" \
        --action grant

# ────────────────────────────────── <end >─────────────────────────────────── #
