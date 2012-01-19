Backup GitBucket - Backup all your GitHub and BitBucket repositories

# Introduction

backup_gitbucket.rb is a tiny Ruby-Script to backup all your GitHub and/or BitBucket repositories.
It uses the API to figure out the list of all repos (your's and organizational repos).

Git repositories are cloned in `--mirror` mode. So they will include all remote branches.

# Why?

I like GitHub's social features and BitBucket's private repos. But having a local backup feels nice too ;-)

# How to use?

- `gem install excon`
- `gem install json`
- edit config.yaml.sample to match your settings.
- `backup-gitbucket <config.yaml>`

# Known issues

The script works fine for me, but it currently lacks proper error-reporting. (Pull requests welcome.)

# What is the License?

Licensed under Apache License Version 2.0.

Enjoy,
Jens

