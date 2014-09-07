/**
 * ZMQ's context and context configuration module.
 * Authors: xaqq
 */
module context;

import std.stdio;
import exceptions;
import core.stdc.errno;
import zmq;

/**
 * Abstraction of a ZeroMQ context.
 * This class provide a static member used as a default context.
 */
final class Context
{
public:
  /**
   * Construct a context using default parameter.
   * Throws: InternalError if zmq fails to initialize a new context.
   */
  this()
  {
    zmq_ctx_ = zmq_ctx_new();
    if (!zmq_ctx_)
      {
	throw new InternalError();
      }
  }

  ~this()
  {
    assert(zmq_ctx_);
    int ret;
    do
      {
	debug
	  {
	    writeln("Terminate ZMQ context");
	  }
	ret = zmq_ctx_term(zmq_ctx_);
      }
    while (ret == EINTR);
    if (ret == EFAULT)
      throw new InternalError("invalid context");
    zmq_ctx_ = null;
  }


  static this()
  {
    default_context = new Context();
  }

  /**
   * For ease of use, dzmq define a default context.
   * All socket creation that do not explicitely passes a Context will use the
   * default context.
   */
  static Context default_context;

private:
  void *zmq_ctx_;
}

unittest
{
  assert(Context.default_context);
}
