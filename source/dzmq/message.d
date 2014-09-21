/**
 * Contains facilities related to zeromq's message.
 * Authors: xaqq
 *
 */
module dzmq.message;

import dzmq.zmq;
import std.stdio;
import std.string;

/**
 * Represents a Message that can be read from or $(YELLOW written) to Socket.
 *
 */
class Message
{
public:
  this()
  {
    debug writeln("New message created");
  }

  ~this()
  {
    debug writeln("Destroying message");
    foreach (Frame f; frames_)
      f.destroy();
    frames_ = [];
  }

  /**
   * Overload operator << to add some data to the message.
   * This effectevely create a new frame and appends it to the message.
   * Params:
   *	op = The operator we overload, "<<" in this case.
   *	data = The data we want to append.
   */
  Message opBinary(string op : "<<", T)(T data)
  {
    writeln("adding data");
    frames_ ~= new Frame(data);
    writeln("done adding data");
    return this;
  }

  /**
   * Get the number of frames contained in the Message.
   * Returns: The number of frame in the Message
   */
  ulong nbFrames() const
  {
    return frames_.length;
  }

  Frame[] frames()
  {
    return frames_;
  }
  
  /**
   * Get the total size (in bytes) of the message.
   */
  ulong byteSize()
  {
    ulong ret = 0;
    foreach (frame; frames_)
      {
	ret += frame.size();
      }
    return ret;
  }

  void reset()
  {
    debug writeln("Resetting message");
    foreach(f ; frames_)
      f.destroy();
    frames_ = [];
  }

private:
  /**
   * Message's frames. A valid message should have at least one frame.
   */
  Frame[] frames_;
}

/**
 * A message's frame. A multi-part message has multiple frame
 * internally.
 * It's unlikely that this class be used by library user.
 */
class Frame
{
  /**
   * Construct a new frame from a string
   */
  this(in string data)
  {
    assert(zmq_msg_init_size(&zmq_msg_, data.length) == 0);
    void *data_ptr = zmq_msg_data(&zmq_msg_);

    memcpy(data_ptr, data.toStringz(), data.length);
  }
  
  /**
   * Construct a new frame from any type.
   * This does a binary copy of the data.
   */
  this(T)(in T data)
  {
    assert(zmq_msg_init_size(&zmq_msg_, T.sizeof) == 0);
    void *data_ptr = zmq_msg_data(&zmq_msg_);

    memcpy(data_ptr, &data, T.sizeof);
  }

  bool no_destroy = true;

  ~this()
  {
    assert(no_destroy);
    no_destroy = false;

    debug writeln("Destroying frame");
    assert(zmq_msg_close(&zmq_msg_) == 0);
  }

  /**
   * Returns the size (in byte) of this message frame.
   */
  ulong size()
  {
    return zmq_msg_size(&zmq_msg_);
  }

  /**
   * Returns the internal pointer to zmq_msg_t;
   */
  zmq_msg_t *getNativePtr()
  {
    return &zmq_msg_;
  }


private:
  zmq_msg_t zmq_msg_;
}

unittest
{
  auto m = new Message();
  assert(m.nbFrames() == 0);
  assert(m.byteSize() == 0);
  string toto = "HelloAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
  int v = 42;

  m << toto;
  assert(m.nbFrames() == 1);
  assert(m.byteSize() == toto.length);
  m << v;

  assert(m.nbFrames() == 2);
  assert(m.byteSize() == toto.length + int.sizeof);
  m.destroy();
}
