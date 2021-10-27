# Remote backend 

This is the terraform configuration files to create the gateway terraform remote backend.

The gateway terraform remote backend has two components: 
* S3 bucket: to store states,
* Dynamodb table: for state locking and consistency checks.

The bucket supports versionning to allow for state recovery when needed and is destory protected in case of accidental deletions.

