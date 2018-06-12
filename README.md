# Eldrimner Custom Ubuntu ISO

Custom Ubuntu Server ISO generator for Särimner.

## Preparation

Clone this repo and run `make init`.

An official Ubuntu 18.04 server amd64 (alternate installer) will be downloaded and extracted.
If another ISO is wanted, put it in the project root as `ubuntu.iso` before `make init`.

## Generate ISO

Run `make push-src` to sync the src folder with the installer files.

Then run `make generate-iso` to generate the ISO file. It will end up in the output folder.

`make all` does the two above in order.
