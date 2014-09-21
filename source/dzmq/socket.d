/**
 * Facilities to manage zmq's sockets.
 * Authors: xaqq
 */   
module dzmq.socket;

debug import std.stdio;

import std.conv;
import std.exception : enforceEx;
import std.string;
import std.typecons;
import core.stdc.errno;
import dzmq.message;
import dzmq.zmq;
import dzmq.context;
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
    this(type, dzmq.context.default_context);
  }

  this(SocketType type, Context c)
  {
    type_ = type;
    zmq_socket_ = enforceEx!DZMQInternalError(
        zmq_socket(c.getNativePtr(), cast(int)type),
        "Cannot create socket");
  }

  ~this()
  {
    debug writeln("Destroying Socket");
    if (zmq_socket_)
      close();
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
   * If the context was terminated during the operation, the socket will be closed.
   * Throws: DZMQInternalError in case something went badly wrong.
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
	      if (ETERM == errno)
		{
		  close();
		  throw new DZMQContextTerminated();
		}
	      throw new DZMQInternalError("Unable to send a message");
	    }
	}
      m.reset();
      return true;
    }

  bool setOption(T)(SocketOption o, T value) if (!is(T == string))
  {
    assert(zmq_setsockopt(zmq_socket_, cast(int)o, &value, value.sizeof) == 0);
    return true;
  }

  bool setOption(T : string)(SocketOption o, T value)
    {
      assert(zmq_setsockopt(zmq_socket_, cast(int)o, value.toStringz(), value.length) == 0);
      return true;
    }

  T getOption(T)(SocketOption o)
  {
    T value;
    ubyte buff[300];
    size_t len = buff.sizeof;
    debug writeln("Len = ", len);
    static if (is(T == int))
      len = T.sizeof;
    assert(zmq_getsockopt(zmq_socket_, cast(int)o, &buff, &len) == 0);
    
    auto tmp = buff[0..len];
    static if (is(T == ubyte[]))
      {
	return tmp.dup;
      }
    static if (is(T == string))
      {
	value ~= cast(char[])tmp;
	debug writeln("hey:", value);
	return value;
      }
    static if (is(T == int))
      {
	memcpy(&value, &buff[0], len);
	return value;
      }
    else
      {
	// how to fail at compile time?
	//	static assert (0);
      }
  }
  
  /**
   * Close the socket.
   */
  void close()
  {
    assert(zmq_close(zmq_socket_) == 0);
    zmq_socket_ = null;
  }

  /**
   * Helper method to send a single string message.
   */
  bool write(in string msg, bool dontwait = true)
  {
    auto m = scoped!Message();
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
  auto s = scoped!Socket(SocketType.ROUTER);
  assert(s.bind("inproc://test-1"));
  assert(s.bind("inproc://test-2"));
  assert(!s.bind("inproc://test-2"));

  auto s2 = scoped!Socket(SocketType.DEALER);
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

  m.destroy();
  s.destroy();
}

unittest
{
  auto c = scoped!Context();
  auto s = scoped!Socket(SocketType.PUSH, c);

  assert(s.connect("tcp://127.0.0.1:4242"));
  assert(s.write("HELLO"));
  
  writeln("lama");
  s.setOption(SocketOption.linger, 1000);
}

/**
 * Tests that we can set and get socket options.
 */
unittest
{
  auto s = scoped!Socket(SocketType.PUSH);

  assert(s.setOption(SocketOption.identity, "lamaSticot \0\0llllllllllllllllllllllllllllllllllldada"));
  ubyte b[] = s.getOption!(ubyte[])(SocketOption.identity);
  assert(b == "lamaSticot \0\0llllllllllllllllllllllllllllllllllldada");
  string str = s.getOption!string(SocketOption.identity);
  assert(str == "lamaSticot \0\0llllllllllllllllllllllllllllllllllldada");

  //  string too_long = "a";
  //  foreach (int i ; 1..300)
  //    too_long ~= "a";

  //  assert(!s.setOption(SocketOption.identity, too_long));
  assert(s.getOption!int(SocketOption.linger) == -1, "wrong default linger value");
}
  
unittest {
  auto s = scoped!Socket(SocketType.REQ);
  auto m = new Message();
  m << "Hey";
  // assert(s.type_ == SocketType.REQ);
  // assert(!s.write(m));
  
  // auto s2 = scoped!Socket(SocketType.REP);
  // assert(s.write(m));
}


/**
 * Type of the socket. See $(LINK http://api.zeromq.org/4-1:zmq-socket) for
 * an overview of ZMQ's socket type.
 */
enum SocketType {
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
  
enum Flags {
    DONTWAIT = 1,
    SNDMORE = 2
}

enum SocketOption {
  linger = ZMQ_LINGER,
  identity = ZMQ_IDENTITY
}
