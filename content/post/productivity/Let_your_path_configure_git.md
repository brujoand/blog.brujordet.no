---
title: "Let your path configure git"
date: 2024-01-14T08:27:42+01:00
tags: ["bash", "git", "ssh"]
categories: ["productivity"]
draft: false
---

Sometimes you need to be multiple people and use different ssh keys even. When working
with git it's not always obvious how to make this work, without a lot of extra
steps.

## First there is identity

So you've probably seen a variation of this a million times:

```bash
git config --global user.name "FirstName LastName"
git config --global user.email "firstname.lastname@example.com"
```

With these two commands we add the following to our `~/.gitconfig`

```bash
[user]
  name = FirstName LastName
  email = firstname.lastname@example.com
```

We just set the git name and email for our user globally. Meaning these will be
the configured values for all git repositories we use on this machine. Except of
course unless we set some values within another git repo using `--local`
instead, which creates a local configuration override.
But that's a lot of work, and quite boring to maintain. And quite frankly, not
very cool.

Let's instead make this automatic. I usually have a folder called :drumroll: `~/src` :drumroll:
for my source code repositories. Within that folder I tend to create one folder for each
identity. Let's say I'm a consultant working for two clients BigPlant and
BigRock. Then I have `~/src/BigPlant` and `~/src/BigRock`. Then I can be a bit
sneaky with my `~/.gitconfig`:

```bash
[includeIf "gitdir:~/src/BigPlant/"]
  path = ~/.gitrc/bigplant.config
[includeIf "gitdir:~/src/BigRock/"]
  path = ~/.gitrc/bigrock.config
```

If we are under the BigRock path, use the bigrock.config file.
The `~/.gitrc` folder is just a folder I've created for these custom
configurations, and if we take a look at `~/.gitrc/bigrock.config`:

```bash
[user]
  name = Anders Brujordet
  email = anders.brujordet@bigrock.example.com
```

As we can see, it just set's the user configurations to what is expected in the
BigRock organization. This will now be my configured user whenever my current path is
under `~/src/BigRock`.


## But what about ssh keys?

Maybe these two companies both host their code on github.com, and being a good
engineer I use separate ssh keys for each organization. (Okay, we might actually
want to use separate machines or VMs in this case but I need an example so be cool please).
Git (or ssh rather) doesn't know which key to use unless I tell it, so let's do that using these `~/.gitrc`
files. For BigRock I would add something like this to `~/.gitrc/bigrock.config`:

```bash
[core]
  sshCommand = ssh -i ~/.ssh/id_rsa_bigrock
```

Now when I cd into a BigRock folder I will have the correct git identity and use
the correct ssh key. If however this doesn't work because you are explicitly
setting the `identity_file` in `~/.ssh/config` for instance, you can add `-F
/dev/null` to the command above to tell ssh to you an empty config file.

Now we can jump around between identities like some kind of secret agent with
powers to commit.
