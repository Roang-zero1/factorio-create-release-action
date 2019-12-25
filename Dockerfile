FROM alpine:3.9.3

LABEL "repository"="https://github.com/Roang-zero1/factorio-create-release-action"
LABEL "homepage"="https://github.com/Roang-zero1/factorio-create-release-action"
LABEL "maintainer"="Roang_zero1 <lucas@brandstaetter.tech>"

RUN apk add --no-cache curl jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
