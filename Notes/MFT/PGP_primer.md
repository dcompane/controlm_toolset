**1. Create the user database (keyring): use the list keys command**

```
gpg -k
gpg: /home/ctmagent/.gnupg/trustdb.gpg: trustdb created
```

**2. Show the database is empty of keys**

**2.1 list public keys**

```
gpg -kv
```

**2.2 list private keys**

**Note:** Empty results without errors indicate an empty keyring

```
gpg -Kv
```

**3. Create a key pair (you may use different options for other cyphers or key lengths)**

Use the `--full-gen-key option`. Uisng others like -`-quick-generate-key` will not create a signature subkey and may cause problems later.

In that case you can use `--quick-add-key` to add the signing subkey. Not worth the time investigating if it can be done right the first time

The` --pinentry-mode loopback` is needed for the passphrase request.

```
gpg -v --pinentry-mode loopback --full-gen-key
gpg (GnuPG) 2.3.3; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

gpg: Note: RFC4880bis features are enabled.
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
  (14) Existing key from card
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072)
Requested keysize is 3072 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
Key does not expire at all
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: Daniel Companeetz
Email address: dcompane@gmail.com
Comment: do not use this cert. just for demo
You selected this USER-ID:
    "Daniel Companeetz (do not use this cert. just for demo) <dcompane@gmail.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: writing self signature
gpg: RSA/SHA256 signature from: "BFB7A7678FC67E7E [?]"
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: writing key binding signature
gpg: RSA/SHA256 signature from: "BFB7A7678FC67E7E [?]"
gpg: writing public key to '/home/dcompane1/.gnupg/pubring.kbx'
gpg: using pgp trust model
gpg: key BFB7A7678FC67E7E marked as ultimately trusted
gpg: directory '/home/dcompane1/.gnupg/openpgp-revocs.d' created
gpg: writing to '/home/dcompane1/.gnupg/openpgp-revocs.d/AD8BC5E7981735A315C7F2C4BFB7A7678FC67E7E.rev'
gpg: RSA/SHA256 signature from: "BFB7A7678FC67E7E Daniel Companeetz (do not use this cert. just for demo) <dcompane@gmail.com>"
gpg: revocation certificate stored as '/home/dcompane1/.gnupg/openpgp-revocs.d/AD8BC5E7981735A315C7F2C4BFB7A7678FC67E7E.rev'
public and secret key created and signed.

pub   rsa3072 2025-12-11 [SC]
      AD8BC5E7981735A315C7F2C4BFB7A7678FC67E7E
uid                      Daniel Companeetz (do not use this cert. just for demo) <dcompane@gmail.com>
sub   rsa3072 2025-12-11 [E]

```

**4. Show the database keys**

**4.1 list public keys**

```
gpg -k --keyid-format LONG
/home/dcompane1/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072/BFB7A7678FC67E7E 2025-12-11 [SC]
      AD8BC5E7981735A315C7F2C4BFB7A7678FC67E7E
uid                 [ultimate] Daniel Companeetz (do not use this cert. just for demo) <dcompane@gmail.com>
sub   rsa3072/FA43076C75D2D379 2025-12-11 [E]

```

**4.2 list private keys**

```
gpg -K --keyid-format LONG
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/home/dcompane1/.gnupg/pubring.kbx
----------------------------------
sec   rsa3072/BFB7A7678FC67E7E 2025-12-11 [SC]
      AD8BC5E7981735A315C7F2C4BFB7A7678FC67E7E
uid                 [ultimate] Daniel Companeetz (do not use this cert. just for demo) <dcompane@gmail.com>
ssb   rsa3072/FA43076C75D2D379 2025-12-11 [E]
```

**5. Export the public key**

**Note: always use armored (ascii) format** (I prefer it to the default binary...)

```
gpg -a --export dcompane@gmail.com
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBF5xgYsBCACxcbgXCebhD3GldQrgGabN9xCCz+zhxsm12SGxvgCZgDaIeDdh
z7UCNUUPeElfReCKdLPpxe5xTy+S+7JKdBCpQP5pBAqRlmcn4HmGX2v8x2J9kOsE
38oeEP9Fr93IvwQUrqTWSbbS44iD8HSCMH7+NYfKedv+zP9js+2sO+iLRO13uAT8
NoALO0fR54z3u+85kzvQzIoR52E+yRv1cXVTrS008yc/klioE9G3ZuE22q7QjOtu
vOoiImHzsQbLx4grtq5pQpXBAlmOA5mywCP9RKInpFxgkl/nR7NIJPauN0IY8zOz
SR3+tyKch1ouBqxwlZnogzavrarnpooJBoX7ABEBAAG0JkRhbmllbCBDb21wYW5l
...
u5HNvGe6wSPbjDdqWQBacovv1PH2IwxkosWHyUNZASaUNlevArj2vBku3/KjvkD0
mPWAoHc/0jkWQzOlzsy0pHdZkYgOwMP0VA0Yv0blBborI5+1j2rRVvARJHhXVY11
aQzygoD/L8xEleH7qA8oCRDJyBb3BzplQVdnF3lk0q7NRCwdR0K3YFX0Fk9NUwl5
PKs12PuvRdvlYHfxvO9PhVSCBdPv9tffxyUHDG5dShmNUEEx4Zqvi6hD6FU+KnE6
5igXEHHgZXKLKpDLRrIQMJ4jY/LcisDU7p1gkhnn/jQ8SjviC2znO//7za2+wNJ4
19w=
=rQFt
-----END PGP PUBLIC KEY BLOCK-----

```

**6. Import the third party public key**

```
cat DanielCompaneetz_0xE08F3A71_public.asc | gpg -a --import
```

**7. Show the database keys (again)**

**7.1 list public keys**

```
gpg -k --keyid-format LONG
```

**7.2 list private keys**

```
gpg -K --keyid-format LONG
```
