# [ripgrep](https://github.com/BurntSushi/ripgrep)
```
'https://github.com/icebluey/brg/releases/latest/download/rg-el9.tar.xz'
'https://github.com/icebluey/brg/releases/latest/download/rg-ub2204.tar.xz'
```

```
mkdir /tmp/rg.tmp && cd /tmp/rg.tmp
wget 'https://github.com/icebluey/brg/releases/latest/download/rg-el9.tar.xz'
tar -xof rg-el9.tar.xz
rm -f /usr/bin/rg
install -v -m 0755 rg /usr/bin/
cd /tmp && rm -fr /tmp/rg.tmp
```

```
mkdir /tmp/rg.tmp && cd /tmp/rg.tmp
wget 'https://github.com/icebluey/brg/releases/latest/download/rg-ub2204.tar.xz'
tar -xof rg-ub2204.tar.xz
rm -f /usr/bin/rg
install -v -m 0755 rg /usr/bin/
cd /tmp && rm -fr /tmp/rg.tmp
```
