/**
 * Facilities to manage zmq's sockets.
 * Authors: xaqq
 */   
module socket;
import message;
import zmq;
import std.stdio;
import std.random;
import context;
import exceptions;

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

  bool write(Message m)
    in
      {
	assert(m);
      }
  body
    {
      foreach (int count, ref frame; m.frames())
	{
	  debug { writeln("count = ", count, "; nb frame = ", m.nbFrames()) ; }
	  assert(zmq_msg_send(frame.getNativePtr(),
		       zmq_socket_,
			      count + 1 < m.nbFrames() ? cast(int) Flags.SNDMORE : 0) == 0);
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
  assert(s.write(m));
  }
