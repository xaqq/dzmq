/**
 * Facilities to manage zmq's sockets.
 * Authors: xaqq
 */   
module dzmq.socket;

import std.stdio;
import std.random;
import core.stdc.errno;
import std.string;
import std.typecons;
import std.algorithm;
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

  /**
   * Bind the socket to an endpoint.
   */
  bool bind(in string endpoint)
  {
    return zmq_bind(zmq_socket_, endpoint.toStringz()) == 0;
  }

  /**
   * Connect the socket to an endpoint.
   */
  bool connect(in string endpoint)
  {
    return zmq_connect(zmq_socket_, endpoint.toStringz()) == 0;
  }

  /**
   * Write a message on the socket.
   * It is not safe to call this method with a null message.
   * After being sent, a message becomes empty: this is because zmq take ownership of data
   * so its not safe anymore to keep it.
   *
   * Throws: InternalError in case something went badly wrong.
   * Returns: true if the message was sent. false if dontwait is true and would have blocked.
   */
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
      
      // need to reset the object pointed to by m. similar to std::swap 
      //      m = new Message();
      return true;
    }

  /**
   * Helper method to send a single string message.
   */
  bool write(in string msg, bool dontwait = true)
  {
    auto m = new Message();
    //    auto m = scoped!Message();
    m << msg;

    return write(m, dontwait);
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
 * Test bind and connect and then send a message.
 */
unittest
{
  auto s = new Socket(SocketType.ROUTER);
  assert(s.bind("inproc://test-1"));
  assert(s.bind("inproc://test-2"));
  assert(!s.bind("inproc://test-2"));

  auto s2 = new Socket(SocketType.DEALER);
  assert(!s2.write("hello")); // fails because not connected yet and noblock
  assert(s2.connect("inproc://test-1"));
  assert(s2.write("hello"));
}

/**
 * Test sending a message, shows how message becomes empty after being sent.
 */
unittest
{
  auto s = new Socket(SocketType.DEALER);
  auto m = new Message();
  m << "Hey" << "bla";

  assert(s.connect("inproc://test")); // so message can be queued

  assert(m.nbFrames() == 2, "invalid number of frame");
  assert(m.byteSize() == 6, "invalid message size");

  assert(s.write(m));

  assert(m.nbFrames() == 0, "invalid number of frame");   // doesnt work yet
  assert(m.byteSize() == 0, "invalid message size");
}
  
  unittest
  {
  auto s = new Socket(SocketType.REQ);
  auto m = new Message();
  m << "Hey";
  // assert(s.type_ == SocketType.REQ);
  // assert(!s.write(m));
  
  // auto s2 = new Socket(SocketType.REP);
  // assert(s.write(m));

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
