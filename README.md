# Let's Encrypt PRTG

This is a collection of scripts to automatically install a Let's Encrypt certificate for [PRTG](https://www.paessler.com/prtg).

## Certify the Web: Certify-PRTG.ps1

Post request script to install a Let's Encrypt certificate obtained with Certify the Web in PRTG.

## Win-ACME

Post request script to install a Let's Encrypt certificate obtained with Win-ACME in PRTG.

## Why not Posh-ACME?

[Posh-ACME](https://github.com/rmbolger/Posh-ACME) is a PowerShell module and ACME client to create publicly trusted SSL/TLS certificates from an ACME capable certificate authority such as Let's Encrypt.

It's a module I'm very familar with in my work, where I have written a few different automations for certificates and ACME. In order to create something that is general use, I would have to write a fully functional ACME client, with every possible verification method, or someone would find the implementation inadaquate. I don't feel a need to create my own implmentation of an general use ACME client when tools that will always be far superior exist. The existing tools just need a little bit of help to install a certificate for PRTG's custom web server. 
