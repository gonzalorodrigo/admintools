# admintools

### fs_check.sh

Tests if a any of the file systems has block errors that affect files
~~~
sudo disk/fs_check.sh 2> /dev/null | grep "Failure"
~~~
Output format:

- If no errors: no output
- If there is a failed block: 
~~~
Failure:disk:(disk_name)
~~~
- If there is a failed block that affects a file:
~~~
Failure:file:(disk_name):(failed_byte):(failed_lba):(file_name)
~~~
