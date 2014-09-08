import std.exception;

class InternalError : Exception
{
  this(string message = "")
  {
    super("Internal library error: " ~ message);
  }
}
