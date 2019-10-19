# GitHub Action for Factorio Mod Release

This action will upload you Mod to the [Factorio Mod Portal](https://mods.factorio.com/)

## Sample Workflow

A sample workflow that uses this action can be found at [Roang-zero1/factorio-mod-actions](https://github.com/Roang-zero1/factorio-mod-actions/blob/master/sample/push-check-release.yml)

## Inputs

### `factorio_user`

**Required** User that will be used to authenticate to the Factorio mod-portal.

### `factorio_password`

**Required** Password that will be used to authenticate to the Factorio mod-portal.

## Acknowledgements

Factorio build scripts based on:

- [Nexelas Mods](https://github.com/Nexela)
- [GitHub Action to automatically publish to the Factorio mod portal](https://github.com/shanemadden/factorio-mod-portal-publish)
- Shane Madden (Nymbia)
