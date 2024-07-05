
# gitlab-tokens



Utilities to create and modify Gitlab project access tokens from bash:

- create, rotate and revoke access tokens
- grant and revoke cross-repository CI job token permissions

# Core functions

## git_repo_info
<pre class="r-output"><code>git_repo_info   
   Return information about the current git project

   Arguments:      
      --type     &lt;str&gt; 
         The requested type of information about the repo
         Default: api
      --url      &lt;str&gt; 
         The url to obtain the requested info from
         Default: git@github.com:simon-lenau/gitlab-tokens.git

   Usage:      
      git_repo_info \
         --type     "api" \
         --url      "git@github.com:simon-lenau/gitlab-tokens.git"
</code></pre>

## git_token_renew
<pre class="r-output"><code>git_token_renew   
   Create or rotate gitlab token via API

   Arguments:      
      --tokenfile    &lt;str&gt;   
         The file to store the token
         Default: ~/path/to/file
      --api_secret   &lt;str&gt;   
         The API secret
         Default: glpat-aG2fJfixfGub6ULt2L5_
      --token_scopes &lt;array&gt; 
         The token scopes (if the token is created)
         Default: read_repository
      --url          &lt;str&gt;   
         The url to renew the token for
         Default: git@github.com:simon-lenau/gitlab-tokens.git

   Usage:      
      git_token_renew \
         --tokenfile    "~/path/to/file" \
         --api_secret   "glpat-aG2fJfixfGub6ULt2L5_" \
         --token_scopes "read_repository" \
         --url          "git@github.com:simon-lenau/gitlab-tokens.git"
</code></pre>

## git_token_access
<pre class="r-output"><code>git_token_access   
   Allow a job (CI) token from the current project to access another project's repo,
   e.g. to clone the repo or access its container registry.
   (Requires a token with API access).

   Arguments:      
      --from_project &lt;str&gt; 
         Project whichs job tokens should be able to access `to_project`
         Must be on the same host (e.g. github.com) as `to_project`.
         Default: simon-lenau/gitlab-tokens
      --to_project   &lt;str&gt; 
         Project which should be accessible using `from_project`s job token.
         Must be on the same host (e.g. github.com) as `from_project`.
         Default: simon-lenau/gitlab-tokens
      --action       &lt;str&gt; 
         Action to perform. Either 'grant' or 'revoke'
         to add or revoke access from `from_project` to `to_project`
         Default: grant
      --url          &lt;str&gt; 
         The url of either `from_project` or `to_project`
         Default: git@github.com:simon-lenau/gitlab-tokens.git
      --api_secret   &lt;str&gt; 
         The API secret
         Default: glpat-aG2fJfixfGub6ULt2L5_

   Usage:      
      git_token_access \
         --from_project "simon-lenau/gitlab-tokens" \
         --to_project   "simon-lenau/gitlab-tokens" \
         --action       "grant" \
         --url          "git@github.com:simon-lenau/gitlab-tokens.git" \
         --api_secret   "glpat-aG2fJfixfGub6ULt2L5_"
</code></pre>

# Examples



## Simple example

```bash
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

```

## More extensive example 


```bash
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

```
