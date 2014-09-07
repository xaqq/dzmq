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
  }

  ~this()
  {
    debug
      {
	writeln("Destroying Socket");
      }
    
  }

  bool write(Message m)
  {
    return true;
  }

private:
  /**
   * Pointer to the zmq socket. This pointer will not change.
   */
  const void *zmq_socket_;
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

unittest
  {
  auto s = new Socket(SocketType.REP);
  assert(s.type_ == SocketType.REP);
  assert(s.write(null));
  }
