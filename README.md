# RexPort

Run external programs and talk to them over pipes.

## FAQs

**Q:**

When should I use this?

**A:**

**Almost never.**

This should only be used in the very rare case you have functionality trapped in a foreign language or utility you either can not find another more reliable way to integrate with, or which it is cost prohibitive to reimplement in Ruby.  Consider the requirements very carefully before deciding to use this method.

**Q:**

Are there any limitations to this I should know about?

**A:**

**Yes.**

Message request and response sizes are limited to sizes you can express as an Int-32 (thus around 2/4 gigs, depending on how the port application wants to treat the signedness of the integers).

## Port Protocol

The port protocol is a simple, language-agnostic interoperability method that comes from Erlang.

Processes talk to each other by sending messages over standard in and standard out to each other.

Invoking a port works like this:
1. Encode the size of the message you are going to send to the application as a big-endian four-byte integer.
2. Send that four-byte specifier to the STDIN of the child process, followed by the message itself.
3. Wait to read back in, from the STDOUT of the child process, four bytes.  These bytes are a big-endian value specifying the value of the response message.
4. Read the specified number of bytes back in from the STDOUT of the child process - this is your response message.

## Detailed Port Operation

The details of how a port is actually created and run are more complicated than simply talking over standard in and out.

What actually happens when we spin up a port is this:
1. We create 3 pairs of pipes in the host (Ruby) process:
   1. Ruby Writer <--> Child Reader
   2. Ruby Standard Reader <--> Child Writer
   3. Ruby Error Reader <--> Child Error
2. While booting the child (using arguments to the spawn command) we wire the pipes to the STDIN/STDOUT/STDERR of the child as follows:
   1. Child Reader ---> Child STDIN
   2. Child Writer ---> Child STDOUT
   3. Child Error ---> Child STDERR
3. After the child is spawned (and thus forks) we:
   1. Close the following 'parent' pipe sides in the child:
      1. Ruby Writer
      2. Ruby Standard Reader
      3. Ruby Error Reader
   2. Close the following 'child' pipe sides in the parent:
      1. Child STDIN
      2. Child STDOUT
      3. Child STDERR
4. Because of how pipes and fork work, we now have a command that is running, with the following benefits:
   1. Anything we write to the Ruby Writer pipe, the child will get as it's STDIN
   2. We can read anything the child writes to STDOUT from the Ruby Standard Reader pipe
   3. We can read any errors the child writes to STDERR from the Ruby Error Pipe
5. We now send messages by writing to our Ruby Writer Pipe and getting responses from our Ruby Standard Reader/Ruby Error Reader Pipe.  We also monitor the process to see if it dies, and spin up a new one if required.