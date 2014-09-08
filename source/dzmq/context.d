/**
 * ZMQ's context and context configuration module.
 * Authors: xaqq
 */
module dzmq.context;
alias context = dzmq.context;

import std.stdio;
import core.stdc.errno;
import dzmq.exceptions;
import dzmq.zmq;

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
    
    // try to destroy the context. if we get EINTR, we keep trying.
    do
      {
	debug
	  {
	    writeln("Terminate ZMQ context");
	  }
	ret = zmq_ctx_term(zmq_ctx_);
	if (errno == EFAULT)
	  {
	    writeln("Invalid context...");
	    // i don't think we can throw in destructor in D (same with C++)
	    break;
	  }
      }
    while (ret == -1);
    zmq_ctx_ = null;
  }

  /**
   * Return the native zmq pointer to the context.
   * This should only be used by other component of the library.
   */
  void *getNativePtr()
  {
    return zmq_ctx_;
  }

private:
  void *zmq_ctx_;
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



unittest
{
  assert(context.default_context);
}
