Generate a new key pair:

```
wg genkey | tee new-privatekey | wg pubkey > new-publickey
```

Generate a new pre-shared key:

```
wg genpsk
```

Read a client file into a phone via QR:

```
qrencode -t ANSI256UTF8 -r filename
```

HOWTO: https://www.stavros.io/posts/how-to-configure-wireguard/
