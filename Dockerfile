FROM roangzero1/factorio-mod:luarocks5.3-alpine as base

LABEL "com.github.actions.name"="GitHub Action for Factorio Mod Release"
LABEL "com.github.actions.description"="Uploada Factorio mod to the mod portal."
LABEL "com.github.actions.icon"="upload"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/Roang-zero1/factorio-create-release-action"
LABEL "homepage"="https://github.com/Roang-zero1/factorio-create-release-action"
LABEL "maintainer"="Roang_zero1 <lucas@brandstaetter.tech>"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
