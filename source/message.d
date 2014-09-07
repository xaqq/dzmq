module message;
/**
 * Authors: xaqq
 */

import std.stdio;

/**
 * Blabla
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
}

/**
 * A message's frame. A multi-part message has multiple frame
 * internally.
 * It's unlikely that this struct be used by library user.
 */
struct Frame
{
  
}
