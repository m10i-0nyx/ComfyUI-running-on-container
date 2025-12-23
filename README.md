# ComfyUI running on container

This repository provides a setup to run [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on a Linux container using Podman/Docker.

[Fedora Host computer](README.fedora.md)  

## Environment
私の実行環境紹介
- OS : Windows11 Pro 25H2
- Linux OS : Fedora Linux 43
- CPU : AMD Ryzen 7 9700X
- Memory : DDR5 64GB
- GPU : NVIDIA GeForce RTX 3060 12GB

```.wslconfig
[wsl2]
memory=32GB
swap=0
kernelCommandLine = cgroup_no_v1=all
```

```
> wsl --version
WSL バージョン: 2.6.3.0
カーネル バージョン: 6.6.87.2-1
WSLg バージョン: 1.0.71
MSRDC バージョン: 1.2.6353
Direct3D バージョン: 1.611.1-81528511
DXCore バージョン: 10.0.26100.1-240331-1435.ge-release
Windows バージョン: 10.0.26220.7523
```

## Thanks

Special thanks to everyone behind these awesome projects, without them, none of this would have been possible:

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
