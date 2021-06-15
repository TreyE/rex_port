# RexPort

Run external programs and talk to them over pipes.

## Port Protocol

The port protocol is a simple, language-agnostic interoperability method that comes from Erlang.

Processes talk to each other by sending messages over standard in and standard out to each other.

Invoking a port works like this:
1. Encode the size of the message you are going to send to the application as a big-endian four-byte integer.
2. Send that four-byte specifier to the STDIN of the child process, followed by the message itself.
3. Wait to read back in, from the STDOUT of the child process, four bytes.  These bytes are a big-endian value specifying the value of the response message.
4. Read the specified number of bytes back in from the STDOUT of the child process - this is your response message.
