/**
 * Facilities to manage zmq's sockets.
 * Authors: xaqq
 */   
module dzmq.socket;

import std.stdio;
import std.random;
import core.stdc.errno;
import dzmq.message;
import dzmq.zmq;
import context = dzmq.context;
import dzmq.exceptions;

/**
 * Wraps a ZeroMQ socket.
 */
class Socket
{
  /**
   * Construct a new Socket using the default Context.
   */
  this(SocketType type)
  {
    type_ = type;
    zmq_socket_ = zmq_socket(context.default_context.getNativePtr(), cast(int) type);

    if (!zmq_socket_)
      {
	throw new InternalError("cannot create socket");
      }
  }

  ~this()
  {
    assert(zmq_socket_);
    debug writeln("Destroying Socket");
    zmq_close(zmq_socket_);
  }

  bool write(Message m, bool dontwait = true)
    in
      {
	assert(m);
      }
  body
    {
      foreach (int count, ref frame; m.frames())
	{
	  debug { writeln("count = ", count, "; nb frame = ", m.nbFrames()) ; }
	  int flags = 0;
	  if (dontwait)
	    flags |= Flags.DONTWAIT;
	  if (count + 1 < m.nbFrames())
	    flags |= Flags.SNDMORE;

	  if (zmq_msg_send(frame.getNativePtr(), zmq_socket_, flags) == -1)
	    {
	      if (EAGAIN == errno)
		{
		  // should only block on first part
		  assert(count == 0);
		  return false;
		}
	      if (EINTR == errno)
		{
		  assert(dontwait == false);
		  if (count == 0)
		    return false;
		}
	      throw new InternalError();
	    }
	}
      return true;
    }

private:
  /**
   * Pointer to the zmq socket. This pointer will not change. 
   * how to const pointer?
   */
  void *zmq_socket_;
  immutable SocketType type_;
}

/**
 * Type of the socket. See $(LINK http://api.zeromq.org/4-1:zmq-socket) for
 * an overview of ZMQ's socket type.
 */
immutable enum SocketType
{
  PAIR = 0,
  PUB = 1,
  SUB = 2,
  REQ = 3,
  REP = 4,
  DEALER = 5,
  ROUTER = 6,
  PULL = 7,
  PUSH = 8,
  XPUB = 9,
  XSUB = 10,
  STREAM = 11
}
  
  immutable enum Flags
  {
  DONTWAIT = 1,
  SNDMORE = 2
  }
  
  unittest
  {
  auto s = new Socket(SocketType.REQ);
  auto m = new Message();
  m << "Hey";
  assert(s.type_ == SocketType.REQ);
  assert(!s.write(m));
  
  auto s2 = new Socket(SocketType.REP);
  assert(s.write(m));

  }
