FROM docker.pkg.github.com/roang-zero1/factorio-mod-actions/factorio-mod:luarocks5.3-alpine

LABEL "repository"="https://github.com/Roang-zero1/factorio-create-release-action"
LABEL "homepage"="https://github.com/Roang-zero1/factorio-create-release-action"
LABEL "maintainer"="Roang_zero1 <lucas@brandstaetter.tech>"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
