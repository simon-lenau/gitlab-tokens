#!/usr/bin/env bash

# Load package functions
source "../gitlab-tokens-init"

# Define token files and urls
project_token_file="$HOME/credentials/projects.cispa.saarland/example_token"
api_token_file="$HOME/credentials/projects.cispa.saarland/personal_token"

# Define git project url
proj_url="git@projects.cispa.saarland:c01sile/example.git"

if (
    # Check if the current token in
    # `$project_token_file`
    # is valid
    ! cat "${project_token_file}" |
        git_token_valid \
            --url="${proj_url}"
); then
    echo "Token in ${project_token_file} is invalid!"
    # Create or rotate token if current token is not valid
    cat "${api_token_file}" |
        git_token_renew \
            --tokenfile "${project_token_file}" \
            --url="${proj_url}" \
            --token_scopes=read_registry write_registry read_repository write_repository
fi