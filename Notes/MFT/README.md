A collection of files showing MFT PGP configurations

* Connection Profiles
* PGP Templates
* Job definitions (look at the Workspace file)
* The output of the job executions
  * _\_E\__: Encryption files
  * _\_D\__: Decryption Files
* MFT Test file (created as Ascii Art :-))

In my tests, gpg would always start the agent. I understand this is the default behavior for gpg now. The --pinentry-mode loopback redirects the passphrase and other critical requests to the user.

There is a template for signing. If you have a single private key, you may not need the --local-user option. I would consider adding it always for proper self-documentation of the template.

The signature verification will be shown in the job output (see the second file transfer (decrypt and verify signature) [DCO_MFT_D_01_output_20251211014700_00001.txt](DCO_MFT_D_01_output_20251211014700_00001.txt))

The PGP primer shows some commands needed to start with gpg. In this case, since there were two ends that I manage, the steps were needed in both accounts. I used the Control-MN server account in my system,. but both BMC or I strongly discourage from using the central agent for anything other than core activities.

In some occasions, your implementation may not like the public key. It could be because
