/**
 * Contains facilities related to zeromq's message.
 * Authors: xaqq
 *
 */
module message;

import std.stdio;

/**
 * Represents a Message that can be read from or $(YELLOW written) to Socket.
 *
 */
class Message
{
public:
  this()
  {
    debug
      {
	writeln("New message created");
      }
  }

private:
  /**
   * Message's frames. A valid message should have at least one frame.
   */
  Frame[] frames_;
}

/**
 * A message's frame. A multi-part message has multiple frame
 * internally.
 * It's unlikely that this struct be used by library user.
 */
struct Frame
{
  
}
