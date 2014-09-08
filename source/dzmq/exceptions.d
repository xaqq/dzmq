/**
 * Defines library's custom exceptions.
 * Authors: xaqq
 */
module dzmq.exceptions;

import std.exception;

class InternalError : Exception
{
  this(string message = "")
  {
    super("Internal library error: " ~ message);
  }
}
