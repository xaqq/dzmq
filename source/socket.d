/**
 * Facilities to manage zmq's sockets.
 * Authors: xaqq
 */   
module socket;
import message;
import zmq;
import std.random;

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
  }

  bool write(Message m)
  {
    return true;
  }

private:
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
