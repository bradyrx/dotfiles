# dotfiles

This setup is based on https://github.com/lukelbd/dotfiles, but built from the ground up rather than forking so I can better understand the process.

## Procedure on a new machine

0. Run `brew install coreutils` to get `gls` to work properly.

1. Run `bash setup`

2. Install miniconda or anaconda.

3. For a new conda environment, run `conda env -f conda/environment-analysis.yml` which will install mostly everything you need.

4. Add the following to `~/.ssh/config` on your laptop (you might have to make `~/.ssh/config` and `~/.ssh/connections`):

```bash
ControlMaster auto
ControlPath ~/.ssh/connections/%h_%p_%r
ControlPersist 1
```

## JupyterHub install custom kernel

To use a custom anaconda environment on JupyterHub, you just need to run the following: 
`python -m ipykernel install --user --name python3 --display-name python3`. 

Note that you need ipykernel installed in your environment for it to be detectable in JupyterHub. Also note that my custom environment is called python3 in that example case.

## Proxy Issues

There is sometimes issues with installing packages from conda/pip on government computers (like at LANL). You need to add the proper proxy to `.condarc` for conda, and type `export https_proxy=https://proxyout.lanl.gov:8080` for pip (for LANL for instance).

## Cancel All Slurm Jobs

Didn't know where else to put this, but it can be done like this:

```bash
squeue -u $USER | grep 427 | awk '{print $1}' | xargs -n 1 scancel
```

Where `427` is to be replaced by the prefix for the `JOBID`. This is useful when you have a bunch of pending `dask` workers.
