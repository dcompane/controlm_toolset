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

**3. Create a key pair (you may use different options for other cyphers or key lengths)**

```
gpg -v  --pinentry-mode loopback --quick-generate-key ctmagent@dc01 RSA
gpg: Note: RFC4880bis features are enabled.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
**Enter passphrase:         **(Later removed from output)
gpg: writing self signature
gpg: RSA/SHA256 signature from: "288CB14B71CF7113 [?]"
gpg: writing public key to '/home/ctmagent/.gnupg/pubring.kbx'
gpg: using pgp trust model
gpg: key 288CB14B71CF7113 marked as ultimately trusted
gpg: directory '/home/ctmagent/.gnupg/openpgp-revocs.d' created
gpg: writing to '/home/ctmagent/.gnupg/openpgp-revocs.d/E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113.rev'
gpg: RSA/SHA256 signature from: "288CB14B71CF7113 ctmagent@dc01"
gpg: revocation certificate stored as '/home/ctmagent/.gnupg/openpgp-revocs.d/E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113.rev'
public and secret key created and signed.
Note that this key cannot be used for encryption.  You may want to use
the command "--edit-key" to generate a subkey for this purpose.
pub   rsa3072 2025-12-10 [SC] [expires: 2027-12-10]
**      E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113**
uid                      ctmagent@dc01
```

**4. Show the database keys**

**4.1 list public keys**

```
gpg -kv
gpg: Note: RFC4880bis features are enabled.
gpg: using pgp trust model
**/home/ctmagent/.gnupg/**pubring.kbx
---------------------------------
pub   rsa3072 2025-12-10 [SC] [expires: 2027-12-10]
**      E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113**
uid           [ultimate] ctmagent@dc01
```

**4.2 list private keys**

```
gpg -Kv
gpg: Note: RFC4880bis features are enabled.
gpg: using pgp trust model
**/home/ctmagent/.gnupg/**pubring.kbx
---------------------------------
sec   rsa3072 2025-12-10 [SC] [expires: 2027-12-10]
**      E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113**
uid           [ultimate] ctmagent@dc01
```

**5. Export the public key**

**Note: always use armored (ascii) format**

```
gpg -v -a --export ctmagent@dc01
gpg: Note: RFC4880bis features are enabled.
gpg: writing to stdout
-----BEGIN PGP PUBLIC KEY BLOCK-----
mQGNBGk5pZgBDACWALAZLnEv4NSrAiqm8iT4AY004AKaPlfbgbp5fYzDRZSdR5aI
0muSl7I0gpE7kxllEk5pcqnZ++gssbpfL8K2a69ydDy7+Ix0itOLPPWhNdBKUMPe
Qih5Y290M7m5GeqPdX0AtDh5qgpCn/dtAYTkkrK8o98RF1XyzDbVJxEf8BslgUSL
/mV89sBBTFL24Fg81mKm/Mkq9UG4WgO3uV8aQXqjqGMBHA/0PrBbzH/6Xw4D9ydY
lztny6Evk04roYxkrjXsHJEvQSufZ60zQeJ6tHTnxqpSwn66b6lfgkjf33KKQrmL
l+V0t9MkxfH7T+O+cKZ3r98yqBeAX8l7T3Z0GyrIbvePJYOFOFOdqg6vwW3+c0GJ
cjhLCq1MsoaLVgfE80SB+jWC5OlCqTKmuy3PiVaFSEHT7/w1McGPkc4ijiEH/Afi
hI88jsY1pRhWlpoWkQixCU1NUVqGhsHTsTFftN3sUiIEyF0uHAAQcUYZ9fMxQmFS
M3Pt/HDmOe+skw8AEQEAAbQNY3RtYWdlbnRAZGMwMYkB2AQTAQgAQhYhBOfd+uDK
1D/DnCf+wSiMsUtxz3ETBQJpOaWYAhsDBQkDwmcABQsJCAcCAyICAQYVCgkICwIE
FgIDAQIeBwIXgAAKCRAojLFLcc9xExDLC/9T9RoEKEgnrjHVwQ/8IUzRtv41sjYL
x61rrGvNtT2cuVmIti//h2hCN4pVy9T7X7Sc5DG9JwQNcRweA1/IsocXTOxS3XvV
24vFdW8PyfIkF5ZCT5IwpBuJ1TcSxJIhS4FOmd/ljKN3CWpgdslkcIMTRn5ufOQ1
tBPDcAEMbujEeiGTE32KmOtKlFNaQT3AZzGsO4u2N2FX+Y9Pgn4GIBdUtbL5IVr4
**J+fatoWGkomcI10xI6u2YYQiO7YTh1GhCCS1R8yM7G/iL0nKa79aTirP//**xQBDLU
ZNXln368Opx+2dGRogSFoTmJxn8ImsFjjIwOEaQ9TYl0O0YbvpOPAAufghEHp+5w
**a72XowWhlwDWHWIinGwjG+gV56KcJ+cowWua1SsY/zDkQB7+m8gpWh/**lRAZHFsQv
I/Who7DqzOdXDR3E5hzdDjsbHu7KFNdasARt2jccZHNB7SNmGNWJ6km3In2pljCx
9x/e9r3Wvk85Se+Kx4DlrazsRnbxTVtwkGw=
**=**lXEx
-----END PGP PUBLIC KEY BLOCK-----
```

**6. Import client public key**

```
cat DanielCompaneetz_0xE08F3A71_public.asc | gpg -v -a --import --pinentry-mode loopback
```

**7. Show the database keys (again)**

**7.1 list public keys**

```
gpg -kv
gpg: Note: RFC4880bis features are enabled.
gpg: using pgp trust model
**/home/ctmagent/.gnupg/**pubring.kbx
---------------------------------
pub   rsa3072 2025-12-10 [SC] [expires: 2027-12-10]
**      E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113**
uid           [ultimate] ctmagent@dc01
pub   rsa2048 2020-03-18 [SCA]
**      32E362FD8B8F17818980E72E0C94B052E08F3A71**
uid           [ unknown] Daniel Companeetz <dcompane@gmail.com>
sub   rsa2048 2020-03-18 [E]
```


**7.2 list private keys**

```
gpg -Kv
Note: No changes in the private Keys
gpg: Note: RFC4880bis features are enabled.
gpg: using pgp trust model
**/home/ctmagent/.gnupg/**pubring.kbx
---------------------------------
sec   rsa3072 2025-12-10 [SC] [expires: 2027-12-10]
**      E7DDFAE0CAD43FC39C27FEC1288CB14B71CF7113**
uid           [ultimate] ctmagent@dc01
```
